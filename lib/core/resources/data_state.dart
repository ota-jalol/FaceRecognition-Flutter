/// Generic data state wrapper for handling success and error states
abstract class DataState<T> {
  final T? data;
  final String? error;

  const DataState({this.data, this.error});
}

/// Success state with data
class DataSuccess<T> extends DataState<T> {
  const DataSuccess(T data) : super(data: data);
}

/// Error state with error message
class DataFailed<T> extends DataState<T> {
  const DataFailed(String error) : super(error: error);
}
