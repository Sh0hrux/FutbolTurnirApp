class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server xatosi']);
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Internet aloqasi yo‘q']);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Xotira xatosi']);
}

class ValidationException implements Exception {
  final String message;
  const ValidationException([this.message = 'Validatsiya xatosi']);
}

class NotFoundException implements Exception {
  final String message;
  const NotFoundException([this.message = 'Ma‘lumot topilmadi']);
}

