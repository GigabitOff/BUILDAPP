class LicenseException implements Exception {
  final String code;
  final String message;

  const LicenseException({required this.code, required this.message});

  @override
  String toString() => message;
}

bool isLicenseErrorCode(String? code) {
  switch (code) {
    case 'LICENSE_BLOCKED':
    case 'LICENSE_EXPIRED':
    case 'LICENSE_INACTIVE':
    case 'LICENSE_NOT_FOUND':
    case 'NO_COMPANY':
      return true;
    default:
      return false;
  }
}

void throwLicenseIfNeeded(Map<String, dynamic> data) {
  final code = data['code']?.toString();

  if (isLicenseErrorCode(code)) {
    throw LicenseException(
      code: code ?? 'LICENSE_ERROR',
      message: data['message']?.toString() ?? 'Доступ до застосунку обмежено',
    );
  }

  throw StateError('Response is not a license error');
}
