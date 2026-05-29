import 'package:dio/dio.dart';

/// Logs outgoing requests (stripping the API key) and normalizes
/// common Perenual HTTP error codes into human-readable messages.
class ApiLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      final sanitized = options.uri.replace(
        queryParameters: {
          ...options.queryParameters,
          if (options.queryParameters.containsKey('key')) 'key': '***',
        },
      );
      // ignore: avoid_print
      print('[API] ${options.method} $sanitized');
      return true;
    }());
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    final String? overrideMsg = switch (statusCode) {
      401 => 'Clave de API Perenual inválida o ausente.',
      429 => 'Límite de solicitudes Perenual excedido. Intenta más tarde.',
      _ => null,
    };

    if (overrideMsg != null) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: overrideMsg,
          message: overrideMsg,
        ),
      );
      return;
    }
    handler.next(err);
  }
}
