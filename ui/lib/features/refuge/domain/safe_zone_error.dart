/// Typed errors of the safe-zone platform port. One per contract error code.
sealed class SafeZoneError implements Exception {
  const SafeZoneError(this.message);

  /// Reason reported by native, when there is one. Not shown verbatim as
  /// guidance: the view maps the type to its own copy.
  final String? message;

  @override
  String toString() => '$runtimeType(${message ?? ''})';
}

/// `invalid_config`: native rejected the config.
class InvalidConfigError extends SafeZoneError {
  const InvalidConfigError([super.message]);
}

/// `permission_missing`: the message lists what is missing.
class PermissionMissingError extends SafeZoneError {
  const PermissionMissingError([super.message]);
}

/// `unavailable`, or this device is not Android.
class UnavailableError extends SafeZoneError {
  const UnavailableError([super.message]);
}

/// `invalid_argument`.
class InvalidArgumentError extends SafeZoneError {
  const InvalidArgumentError([super.message]);
}

/// `failed`, and any code the contract does not name.
class FailedError extends SafeZoneError {
  const FailedError([super.message]);
}
