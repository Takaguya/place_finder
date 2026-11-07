/// The outcome of an operation that can fail in an expected way.
///
/// Repositories return this instead of throwing, so the compiler makes every
/// caller handle both cases.
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class Failed<T> extends Result<T> {
  const Failed(this.failure);

  final Failure failure;
}

/// An expected failure, described in words a user can act on.
class Failure {
  const Failure(this.message);

  final String message;
}
