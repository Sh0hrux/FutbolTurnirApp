import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = "Tarmoq bilan aloqa yo'q. Internetni tekshiring"]);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = "Serverda xatolik yuz berdi"]);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = "Kiritilgan ma'lumotlar noto'g'ri"]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = "Ma'lumot topilmadi"]);
}

class ConflictFailure extends Failure {
  const ConflictFailure([super.message = "Zidlik yuz berdi"]);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = "Xotira bilan ishlashda xatolik yuz berdi"]);
}

