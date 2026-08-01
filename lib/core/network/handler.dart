import 'package:pocketbase/pocketbase.dart';

/// Coarse classification of an API failure, independent of the raw HTTP status
/// code. The VM layer maps these onto user-facing messages without needing to
/// know PocketBase's status-code details.
enum ApiError {
  /// 400 — the request was malformed or rejected by the server's validation.
  badRequest,

  /// 401 — the auth token is missing, invalid, or expired.
  unauthorized,

  /// 404 — the requested record (or collection) does not exist.
  notFound,

  /// 5xx — something went wrong on the server.
  serverError,

  /// The request never reached the server or the response never came back
  /// (e.g. no network, timeout, DNS failure).
  network,

  /// Anything not covered by the above.
  unknown,
}

/// The outcome of any API call routed through [guard]. This is a sealed type
/// so callers must handle both branches at compile time — there is no "forget
/// to check for errors" path.
sealed class ApiResult<T> {
  const ApiResult();

  /// True when this is [ApiSuccess].
  bool get isSuccess => this is ApiSuccess<T>;

  /// True when this is [ApiFailure].
  bool get isFailure => this is ApiFailure<T>;

  /// The wrapped value when successful, otherwise null.
  T? get dataOrNull => switch (this) {
        ApiSuccess<T>(:final data) => data,
        ApiFailure<T>() => null,
      };

  /// The error when failed, otherwise null.
  ApiError? get errorOrNull => switch (this) {
        ApiSuccess<T>() => null,
        ApiFailure<T>(:final error) => error,
      };

  /// Translates the result into a value, mapping success and failure through
  /// the given callbacks. Convenient for converting an [ApiResult] into a
  /// bool or a message inside a VM.
  R when<R>({
    required R Function(T data) success,
    required R Function(ApiError error) failure,
  }) => switch (this) {
        ApiSuccess<T>(:final data) => success(data),
        ApiFailure<T>(:final error) => failure(error),
      };
}

/// A successful API call carrying [data].
final class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.data);
  final T data;
}

/// A failed API call classified into [error].
final class ApiFailure<T> extends ApiResult<T> {
  const ApiFailure(this.error);
  final ApiError error;
}

/// Runs [action] and wraps its outcome in an [ApiResult].
///
/// PocketBase's Dart SDK reports failures by throwing a [ClientException]
/// carrying a `statusCode`, so the network layer classifies those into
/// [ApiError]s rather than letting raw exceptions reach the VM. Any other
/// throw (e.g. a [TimeoutException] or socket error) is treated as a network
/// failure. This keeps business code free of try/catch boilerplate and gives
/// every caller a single, exhaustive type to react to.
Future<ApiResult<T>> guard<T>(Future<T> Function() action) async {
  try {
    return ApiSuccess(await action());
  } on ClientException catch (e) {
    switch (e.statusCode) {
      case 400:
        return ApiFailure<T>(ApiError.badRequest);
      case 401:
        return ApiFailure<T>(ApiError.unauthorized);
      case 404:
        return ApiFailure<T>(ApiError.notFound);
      default:
        return ApiFailure<T>(
          e.statusCode >= 500 ? ApiError.serverError : ApiError.unknown,
        );
    }
  } catch (_) {
    // Anything that isn't a ClientException (timeouts, socket exceptions,
    // JSON parse errors, etc.) is treated as a connectivity/network issue.
    return ApiFailure<T>(ApiError.network);
  }
}
