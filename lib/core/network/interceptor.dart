import 'package:pocketbase/pocketbase.dart';
import 'package:project_todo/core/log/logger.dart';
import 'package:project_todo/core/network/handler.dart';
import 'package:project_todo/core/storage/preferences.dart';

/// Owns the PocketBase client and the auth/connection bookkeeping that every
/// API method needs.
///
/// The Dart PocketBase SDK has no Dio-style request interceptor pipeline, so
/// this class plays that role instead: it guarantees a connected, authenticated
/// client before business code runs. [ApiService] delegates the repetitive
/// "if (_pb == null) connectDB()" guard to [ensureReady] so its methods can
/// focus purely on business logic.
///
/// Responsibilities:
///   - Lazily create the [PocketBase] client from stored config.
///   - Authenticate with the stored credentials on first use.
///   - Detect an expired/invalid auth store and re-authenticate transparently.
///   - Expose the authenticated user id and a readiness check.
class AuthInterceptor {
  AuthInterceptor(this._configService);

  final ConfigService _configService;

  PocketBase? _pb;
  RecordAuth? _authData;

  /// The underlying client. Throws [StateError] if accessed before
  /// [ensureReady] has succeeded — business code should go through
  /// [ensureReady] first.
  PocketBase get pb {
    final client = _pb;
    if (client == null) {
      throw StateError('PocketBase client not initialized; call ensureReady().');
    }
    return client;
  }

  /// The authenticated user's id, or null if not yet authenticated.
  String? get userId => _authData?.record.id;

  /// Whether the client exists and holds a valid (non-expired) token.
  bool get isReady => _pb != null && _pb!.authStore.isValid;

  /// Connects (or reconnects) to the backend using the stored config and
  /// authenticates with the stored credentials. Returns an [ApiResult] so the
  /// caller can distinguish a bad-config failure from a network failure.
  Future<ApiResult<bool>> connect() => guard(() async {
        final apiUrl = await _configService.getApiUrl();
        _pb = PocketBase(apiUrl);

        final username = await _configService.getUsername();
        final password = await _configService.getPassword();
        _authData = await _pb!
            .collection('users')
            .authWithPassword(username, password);

        return _authData != null && _pb!.authStore.isValid;
      });

  /// Guarantees a connected, authenticated client before returning.
  ///
  /// If the client is missing or the auth store has expired, this performs a
  /// (re)connect. API methods call this as their first line instead of each
  /// repeating the old "if (_pb == null) connectDB()" guard. A failed
  /// reconnect throws — the surrounding [guard] in [ApiService] converts that
  /// into an [ApiFailure].
  Future<void> ensureReady() async {
    if (_pb != null && _pb!.authStore.isValid) return;
    final result = await connect();
    if (result is ApiFailure<bool>) {
      final err = result.error;
      apiLogger.warning('AuthInterceptor.ensureReady failed: $err');
      // Surface as a generic exception so the caller's guard() classifies it
      // (network/unknown). A dedicated reconnect error type could be added
      // later if the VM needs to tell "not configured" apart from "server
      // down".
      throw Exception('Authentication failed ($err)');
    }
  }

  /// Clears the auth store, effectively logging the user out.
  Future<void> logout() async {
    await ensureReady();
    _pb!.authStore.clear();
    _authData = null;
  }

  /// Refreshes the auth token from the server.
  Future<bool> authRefresh() async {
    await ensureReady();
    _authData = await _pb!.collection('users').authRefresh();
    return _pb!.authStore.isValid;
  }
}
