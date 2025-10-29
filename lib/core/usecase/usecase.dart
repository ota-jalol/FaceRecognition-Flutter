import '../resources/data_state.dart';

/// Base use case interface
/// Defines a standard contract for all use cases in the application
abstract class UseCase<Type, Params> {
  /// Execute the use case with the given parameters
  Future<DataState<Type>> call({Params params});
}

/// Use case that doesn't require parameters
abstract class UseCaseNoParams<Type> {
  /// Execute the use case without parameters
  Future<DataState<Type>> call();
}

/// Use case without parameters
class NoParams {
  const NoParams();
}
