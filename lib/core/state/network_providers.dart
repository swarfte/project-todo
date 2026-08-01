import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_todo/core/network/api.dart';
import 'package:project_todo/core/network/interceptor.dart';
import 'package:project_todo/core/storage/preferences.dart';

/// Provides the singleton [ConfigService] used across the app.
///
/// [ConfigService] is itself a hand-written singleton, but exposing it through
/// a provider keeps DI consistent (everything the UI/VM layer touches comes
/// from Riverpod) and lets tests override it without touching shared prefs.
final Provider<ConfigService> configServiceProvider = Provider(
  (ref) => ConfigService(),
);

/// Provides the singleton [AuthInterceptor] wired to [configServiceProvider].
final Provider<AuthInterceptor> authInterceptorProvider = Provider(
  (ref) => AuthInterceptor(ref.watch(configServiceProvider)),
);

/// Provides the application's single [ApiService].
///
/// Centralising it here (instead of the old `APIService()` factory singleton)
/// means every VM reads the same instance, and tests can swap it out via
/// `providerScope.overrides`. The VMs never `new` an [ApiService] themselves.
final Provider<ApiService> apiServiceProvider = Provider(
  (ref) => ApiService(auth: ref.watch(authInterceptorProvider)),
);
