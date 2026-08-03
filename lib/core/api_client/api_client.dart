import 'package:dio/dio.dart';
import '../config/env.dart';
import 'envelope_interceptor.dart';

/// Único lugar que conoce la URL real del backend y arma el cliente HTTP — ningún `data/` de un
/// dominio crea su propio `Dio` (ver `.claude/rules/flutter-architecture.md`).
///
/// El interceptor de Bearer/refresh-en-401 se agrega en la Fase 0002 una vez que
/// `openspec/decisions.md` confirme el mecanismo de almacenamiento seguro de tokens — hoy este
/// cliente solo desenvuelve el envelope `{success,data,message,timestamp,path}` del backend
/// (mismo contrato que `core/api-client/client.ts` en TekoApp-Web).
class ApiClient {
  ApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: Env.apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              headers: const {'Content-Type': 'application/json'},
            ),
          ) {
    _dio.interceptors.add(EnvelopeInterceptor());
  }

  final Dio _dio;

  Dio get raw => _dio;
}
