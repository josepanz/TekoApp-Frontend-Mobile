import 'package:dio/dio.dart';

/// Intercepta `403 CONSENT_REQUIRED` (ver `RequiresActiveConsentGuard`,
/// `TekoApp-Backend/openspec/specs/data-and-media-consent.md`) en CUALQUIER response, delega en
/// [onConsentRequired] (puente hacia `ConsentGateway`, que navega a la pantalla de aceptación y
/// espera al usuario) y reintenta el request original si el usuario aceptó — el caller nunca ve el
/// 403 original, solo el resultado final (éxito o el error real si el reintento también falla).
///
/// `errorCode` (no el status 403 solo) es lo que distingue este caso de cualquier otro 403 — ver
/// `TekoApp-Backend/openspec/decisions.md`, amendment 2026-08-25.
class ConsentRequiredInterceptor extends Interceptor {
  ConsentRequiredInterceptor(
    this._dio,
    this._onConsentRequired, {
    this.consentTimeout = const Duration(seconds: 60),
  });

  final Dio _dio;
  final Future<bool> Function() _onConsentRequired;

  /// Cota máxima para esperar la resolución del flujo de consentimiento (ver M-06).
  /// 60s: suficiente para que una persona lea y acepte la pantalla de consentimiento,
  /// acotado para que un flujo que nunca resuelve (bridge sin listener, `push` que no
  /// vuelve, base de datos sin versiones de documento legal) no cuelgue la app para
  /// siempre. Al vencer, se trata como "no aceptó" y se propaga el 403 original.
  final Duration consentTimeout;

  static const _excludedPathPrefix = '/legal/consents';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;
    final errorCode = _extractErrorCode(err);
    if (err.response?.statusCode != 403 ||
        errorCode != 'CONSENT_REQUIRED' ||
        path.startsWith(_excludedPathPrefix)) {
      return handler.next(err);
    }

    final accepted = await _onConsentRequired().timeout(
      consentTimeout,
      onTimeout: () => false,
    );
    if (!accepted) {
      return handler.next(err);
    }

    try {
      final retryResponse = await _dio.fetch<dynamic>(err.requestOptions);
      return handler.resolve(retryResponse);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }

  String? _extractErrorCode(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic> && data['error'] is Map<String, dynamic>) {
      return (data['error'] as Map<String, dynamic>)['errorCode'] as String?;
    }
    return null;
  }
}
