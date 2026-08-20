import 'package:default_project/blocs/export_blocs.dart';
import 'package:default_project/config/features.dart';
import 'package:default_project/model/user.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests for [UsersState.canManageLibrary].
///
/// Tests run without `--dart-define`, so `Features.sharedServer` is false here
/// — the store build's local-first configuration. That is exactly the case the
/// getter exists for, and the case a plain role check got wrong: a build that
/// never authenticates has no `currentUser`, so every role check failed closed
/// and a fresh install could not create its first song.
///
/// The shared-server branch cannot be exercised from this suite: the flag is a
/// compile-time constant, so covering it would need a second test run built
/// with `FEATURE_SHARED_SERVER=true`. The guard below states that assumption
/// out loud rather than letting the other tests silently pass for the wrong
/// reason if the default ever changes.
void main() {
  group('UsersState.canManageLibrary', () {
    UsersState stateWith(User? user) => UsersState(users: const [], currentUser: user);

    test('the test suite runs as a local-first build', () {
      expect(Features.sharedServer, isFalse,
          reason: 'These tests describe the FEATURE_SHARED_SERVER=false build. '
              'Run them without --dart-define, or they assert the wrong branch.');
    });

    test('a build with no shared server grants full rights with no user', () {
      expect(stateWith(null).canManageLibrary, isTrue);
    });

    test('a build with no shared server ignores the role entirely', () {
      final viewer = User('viewer', 'pwd')..typeUser = TypeUser.viewer;
      final none = User('nobody', 'pwd')..typeUser = TypeUser.none;

      expect(stateWith(viewer).canManageLibrary, isTrue);
      expect(stateWith(none).canManageLibrary, isTrue);
    });

    test('copyWith keeps the answer stable when users change', () {
      final state = stateWith(null).copyWith(users: [User('someone', 'pwd')]);

      expect(state.canManageLibrary, isTrue);
    });
  });
}
