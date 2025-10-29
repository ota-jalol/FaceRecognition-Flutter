/// Base use case interface
/// Defines a standard contract for all use cases in the application
abstract class UseCase<Type, Params> {
  /// Execute the use case with the given parameters
  Future<Type> call({Params params});
}

/// Use case without parameters
class NoParams {}
