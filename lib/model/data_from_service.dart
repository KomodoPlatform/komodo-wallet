class DataFromService<R, E> {
  DataFromService({this.data, this.error})
      : assert(data != null || error != null);
  final R? data;
  final E? error;
}
