sealed class Either<L, R> {
  const Either();

  bool get isLeft => this is Left<L, R>;
  bool get isRight => this is Right<L, R>;

  L? get leftOrNull => fold((l) => l, (r) => null);
  R? get rightOrNull => fold((l) => null, (r) => r);

  T fold<T>(T Function(L left) ifLeft, T Function(R right) ifRight);

  Either<L, T> map<T>(T Function(R right) fn) {
    return fold(
      (l) => Left(l),
      (r) => Right(fn(r)),
    );
  }

  Either<L, T> flatMap<T>(Either<L, T> Function(R right) fn) {
    return fold(
      (l) => Left(l),
      (r) => fn(r),
    );
  }
}

class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);

  @override
  T fold<T>(T Function(L left) ifLeft, T Function(R right) ifRight) => ifLeft(value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Left<L, R> && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Left($value)';
}

class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);

  @override
  T fold<T>(T Function(L left) ifLeft, T Function(R right) ifRight) => ifRight(value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Right<L, R> && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Right($value)';
}

