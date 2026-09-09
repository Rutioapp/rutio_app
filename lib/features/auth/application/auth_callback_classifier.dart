import '../domain/auth_callback_intent.dart';
import '../domain/auth_callback_type.dart';
import '../../../core/supabase/rutio_supabase_config.dart';

sealed class AuthCallbackClassification {
  const AuthCallbackClassification();
}

class AuthCallbackEmailConfirmation extends AuthCallbackClassification {
  const AuthCallbackEmailConfirmation(this.intent);
  final AuthCallbackIntent intent;
}

class AuthCallbackPasswordRecovery extends AuthCallbackClassification {
  const AuthCallbackPasswordRecovery(this.intent);
  final AuthCallbackIntent intent;
}

class AuthCallbackUnsupported extends AuthCallbackClassification {
  const AuthCallbackUnsupported();
}

class AuthCallbackMalformed extends AuthCallbackClassification {
  const AuthCallbackMalformed();
}

/// Pure parser/classifier. It never returns the original URI or secret values.
class AuthCallbackClassifier {
  const AuthCallbackClassifier({
    this.canonicalCallbackUri = RutioSupabaseConfig.authCallbackUri,
  });
  final String canonicalCallbackUri;

  AuthCallbackClassification classify(
    Uri uri, {
    DateTime? receivedAt,
    bool isColdStart = false,
  }) {
    if (uri.scheme.isEmpty || uri.host.isEmpty || uri.path.isEmpty) {
      return const AuthCallbackMalformed();
    }
    final canonical = Uri.tryParse(canonicalCallbackUri);
    if (canonical == null ||
        uri.scheme.toLowerCase() != canonical.scheme.toLowerCase() ||
        uri.host.toLowerCase() != canonical.host.toLowerCase() ||
        uri.path != canonical.path ||
        uri.port != canonical.port) {
      return const AuthCallbackUnsupported();
    }
    final type = _safeType(uri);
    if (type == null) return const AuthCallbackUnsupported();
    final intent = AuthCallbackIntent(
      type: type,
      scheme: uri.scheme.toLowerCase(),
      host: uri.host.toLowerCase(),
      path: uri.path,
      receivedAt: (receivedAt ?? DateTime.now()).toUtc(),
      isColdStart: isColdStart,
      safeParameters: <String, String>{
        'type': type == AuthCallbackType.passwordRecovery
            ? 'recovery'
            : 'confirmation'
      },
    );
    return type == AuthCallbackType.passwordRecovery
        ? AuthCallbackPasswordRecovery(intent)
        : AuthCallbackEmailConfirmation(intent);
  }

  AuthCallbackType? _safeType(Uri uri) {
    Map<String, String> fragmentParameters = const <String, String>{};
    if (uri.fragment.isNotEmpty) {
      try {
        fragmentParameters = Uri.splitQueryString(uri.fragment);
      } on FormatException {
        return null;
      }
    }
    final values = <String>[
      uri.queryParameters['type'] ?? '',
      fragmentParameters['type'] ?? '',
    ].map((value) => value.toLowerCase().trim());
    if (values.contains('recovery') || values.contains('password_recovery')) {
      return AuthCallbackType.passwordRecovery;
    }
    if (values.contains('signup') ||
        values.contains('email_confirmation') ||
        values.contains('confirmation') ||
        values.contains('magiclink') ||
        uri.queryParameters.containsKey('code') ||
        fragmentParameters.containsKey('access_token')) {
      return AuthCallbackType.emailConfirmation;
    }
    return null;
  }
}
