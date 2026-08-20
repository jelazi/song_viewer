import 'package:default_project/blocs/export_blocs.dart';
import 'package:default_project/config/features.dart';
import 'package:default_project/model/user.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for [UsersState.canManageLibrary].
///
/// `Features.sharedServer` is a compile-time constant and these run without
/// `--dart-define`, so only the local-first branch is covered here. The
/// shared-server branch needs a separate run with
/// `--dart-define-from-file=config/personal.json`.
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
