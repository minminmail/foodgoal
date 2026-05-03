import 'package:uuid/uuid.dart';

/// v1 keeps auth as simple as possible: in-memory anonymous identity.
/// Each session gets a stable uid. No Firebase dependency.
class AuthService {
  static final String _uid = const Uuid().v4();

  String get currentUserUid => _uid;

  /// Returns the uid immediately — no network call needed.
  Future<String> ensureSignedIn() async => _uid;
}
