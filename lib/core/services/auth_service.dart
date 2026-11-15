import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_config.dart';
import '../utils/app_log.dart';

/// Authentication service encapsulating Supabase OAuth and session management.
class AuthService {
  final SupabaseClient _supabase;
  final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  AuthService({SupabaseClient? supabase, AppLinks? appLinks})
    : _supabase = supabase ?? Supabase.instance.client,
      _appLinks = appLinks ?? AppLinks();

  SupabaseClient get client => _supabase;
  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Initializes deep link listeners for capturing OAuth callbacks on Android and Windows.
  void initializeDeepLinks() {
    _linkSubscription?.cancel();
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) async {
        await handleAuthUri(uri);
      },
      onError: (err) {
        AppLog.e('AppLinks stream error', err);
      },
    );

    _appLinks
        .getInitialLink()
        .then((uri) {
          if (uri != null) {
            handleAuthUri(uri);
          }
        })
        .catchError((err) {
          AppLog.e('AppLinks getInitialLink error', err);
        });
  }

  /// Handles incoming redirect URIs containing auth tokens or PKCE codes.
  Future<void> handleAuthUri(Uri uri) async {
    final isCustomScheme =
        uri.scheme == 'io.anchor.app' || uri.scheme == 'io.execute.app';
    final hasAuthParams =
        uri.queryParameters.containsKey('code') ||
        uri.fragment.contains('access_token') ||
        uri.fragment.contains('error');

    if (isCustomScheme || hasAuthParams) {
      try {
        await _supabase.auth.getSessionFromUrl(uri);
      } catch (e) {
        AppLog.e('AuthService: Error parsing auth session from URI', e);
      }
    }
  }

  /// Initiates Google OAuth sign-in flow.
  Future<bool> signInWithGoogle() async {
    final redirect = kIsWeb ? Uri.base.origin : SupabaseConfig.redirectUrl;
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirect,
      queryParams: const {
        'prompt': 'select_account',
      },
    );
  }

  /// Signs the current user out.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Disposes active deep-link subscriptions.
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }
}

/// Provider for the singleton [AuthService].
final authServiceProvider = Provider<AuthService>((ref) {
  final service = AuthService();
  service.initializeDeepLinks();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Stream provider for Supabase [AuthState] changes.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Provider for the currently signed-in [User].
final currentUserProvider = Provider<User?>((ref) {
  final authStateAsync = ref.watch(authStateProvider);
  return authStateAsync.maybeWhen(
    data: (state) => state.session?.user,
    orElse: () => ref.read(authServiceProvider).currentUser,
  );
});
