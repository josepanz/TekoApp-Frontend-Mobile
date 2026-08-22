sealed class LocationsFailure implements Exception {
  const LocationsFailure();
}

class LocationsValidationFailure extends LocationsFailure {
  const LocationsValidationFailure();
}

class LocationsServiceUnavailableFailure extends LocationsFailure {
  const LocationsServiceUnavailableFailure();
}
