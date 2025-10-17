import 'package:default_project/model/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User Model Tests', () {
    test('should create User with name and password', () {
      // Arrange & Act
      final user = User('testUser', 'testPassword');

      // Assert
      expect(user.name, 'testUser');
      expect(user.password, 'testPassword');
      expect(user.typeUser, TypeUser.none);
      expect(user.allowedGroup, isEmpty);
    });

    test('should create empty User', () {
      // Arrange & Act
      final user = User.empty();

      // Assert
      expect(user.name, '');
      expect(user.password, '');
      expect(user.typeUser, TypeUser.none);
      expect(user.allowedGroup, isEmpty);
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final user = User('testUser', 'testPassword')
        ..typeUser = TypeUser.admin
        ..allowedGroup = ['group1', 'group2'];

      // Act
      final json = user.toJson();

      // Assert
      expect(json['name'], 'testUser');
      expect(json['password'], 'testPassword');
      expect(json['typeUser'], 'admin');
      expect(json['allowedGroup'], ['group1', 'group2']);
    });

    test('should deserialize from JSON correctly', () {
      // Arrange
      final json = {
        'name': 'testUser',
        'password': 'testPassword',
        'typeUser': 'editor',
        'allowedGroup': ['group1', 'group2'],
      };

      // Act
      final user = User.fromJson(json);

      // Assert
      expect(user.name, 'testUser');
      expect(user.password, 'testPassword');
      expect(user.typeUser, TypeUser.editor);
      expect(user.allowedGroup, ['group1', 'group2']);
    });

    test('should handle JSON with missing optional fields', () {
      // Arrange
      final json = {
        'name': 'testUser',
        'password': 'testPassword',
        'typeUser': 'none',
        'allowedGroup': <String>[],
      };

      // Act
      final user = User.fromJson(json);

      // Assert
      expect(user.name, 'testUser');
      expect(user.password, 'testPassword');
      expect(user.typeUser, TypeUser.none);
    });

    test('should copy user data correctly', () {
      // Arrange
      final originalUser = User('originalUser', 'originalPassword')
        ..typeUser = TypeUser.viewer
        ..allowedGroup = ['group1', 'group2'];

      final newUser = User('newUser', 'newPassword')
        ..typeUser = TypeUser.admin
        ..allowedGroup = ['group3', 'group4'];

      // Act
      originalUser.copy(newUser);

      // Assert
      expect(originalUser.name, 'newUser');
      expect(originalUser.password, 'newPassword');
      expect(originalUser.typeUser, TypeUser.admin);
      expect(originalUser.allowedGroup, ['group3', 'group4']);
    });

    test('should handle all TypeUser enum values', () {
      // Arrange & Act & Assert
      expect(TypeUser.none.index, 0);
      expect(TypeUser.viewer.index, 1);
      expect(TypeUser.editor.index, 2);
      expect(TypeUser.admin.index, 3);
      expect(TypeUser.superuser.index, 4);
    });

    test('should handle empty allowedGroup in copy', () {
      // Arrange
      final originalUser = User('originalUser', 'originalPassword')..allowedGroup = ['group1', 'group2'];

      final newUser = User('newUser', 'newPassword')..allowedGroup = [];

      // Act
      originalUser.copy(newUser);

      // Assert
      expect(originalUser.allowedGroup, isEmpty);
    });
  });

  group('TypeUser Enum Tests', () {
    test('should serialize TypeUser enum to JSON', () {
      // Arrange
      final user = User('test', 'test')..typeUser = TypeUser.superuser;

      // Act
      final json = user.toJson();

      // Assert
      expect(json['typeUser'], 'superuser');
    });

    test('should deserialize all TypeUser values from JSON', () {
      // Arrange & Act & Assert
      expect(User.fromJson({'name': 'test', 'password': 'test', 'typeUser': 'none', 'allowedGroup': <String>[]}).typeUser, TypeUser.none);
      expect(User.fromJson({'name': 'test', 'password': 'test', 'typeUser': 'viewer', 'allowedGroup': <String>[]}).typeUser, TypeUser.viewer);
      expect(User.fromJson({'name': 'test', 'password': 'test', 'typeUser': 'editor', 'allowedGroup': <String>[]}).typeUser, TypeUser.editor);
      expect(User.fromJson({'name': 'test', 'password': 'test', 'typeUser': 'admin', 'allowedGroup': <String>[]}).typeUser, TypeUser.admin);
      expect(User.fromJson({'name': 'test', 'password': 'test', 'typeUser': 'superuser', 'allowedGroup': <String>[]}).typeUser, TypeUser.superuser);
    });
  });
}
