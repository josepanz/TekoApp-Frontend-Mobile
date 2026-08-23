import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tekoapp_mobile/core/locale/locale_provider.dart';

void main() {
  test('sin preferencia guardada, el estado inicial es null (sigue al sistema)',
      () async {
    // Arrange
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Act
    final locale = await container.read(localeControllerProvider.future);

    // Assert
    expect(locale, isNull);
  });

  test('setLocale persiste la elección y actualiza el estado', () async {
    // Arrange
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(localeControllerProvider.future);

    // Act
    await container
        .read(localeControllerProvider.notifier)
        .setLocale(const Locale('en'));

    // Assert
    expect(
      container.read(localeControllerProvider).value,
      const Locale('en'),
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_locale'), 'en');
  });

  test('setLocale(null) vuelve a seguir el idioma del sistema', () async {
    // Arrange
    SharedPreferences.setMockInitialValues({'app_locale': 'en'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(localeControllerProvider.future);

    // Act
    await container.read(localeControllerProvider.notifier).setLocale(null);

    // Assert
    expect(container.read(localeControllerProvider).value, isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_locale'), isNull);
  });
}
