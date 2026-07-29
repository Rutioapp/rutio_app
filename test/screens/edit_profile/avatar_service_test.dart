import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:rutio/core/identity/user_namespace.dart';
import 'package:rutio/screens/edit_profile/services/avatar_service.dart';

void main() {
  test('A and B receive distinct stable avatar namespaces', () async {
    final root = await Directory.systemTemp.createTemp('rutio_avatar_test_');
    addTearDown(() => root.delete(recursive: true));
    final source = File(p.join(root.path, 'picked.jpg'))
      ..writeAsStringSync('avatar-bytes');

    final savedA = await const AvatarService().persistAvatarFileForUser(
      source: source,
      userId: 'user-a',
      baseDirectory: root,
      timestamp: DateTime.fromMillisecondsSinceEpoch(1),
      environmentId: 'prod',
    );
    final savedB = await const AvatarService().persistAvatarFileForUser(
      source: source,
      userId: 'user-b',
      baseDirectory: root,
      timestamp: DateTime.fromMillisecondsSinceEpoch(1),
      environmentId: 'prod',
    );

    expect(savedA.path, isNot(savedB.path));
    expect(savedA.path, contains(safeUserNamespace('user-a')));
    expect(savedB.path, contains(safeUserNamespace('user-b')));
  });

  test('same user path is stable for namespace and separated by environment',
      () async {
    final root =
        await Directory.systemTemp.createTemp('rutio_avatar_env_test_');
    addTearDown(() => root.delete(recursive: true));
    final source = File(p.join(root.path, 'picked.png'))
      ..writeAsStringSync('avatar-bytes');

    final prod = await const AvatarService().persistAvatarFileForUser(
      source: source,
      userId: ' same-user ',
      baseDirectory: root,
      timestamp: DateTime.fromMillisecondsSinceEpoch(2),
      environmentId: 'prod',
    );
    final staging = await const AvatarService().persistAvatarFileForUser(
      source: source,
      userId: 'same-user',
      baseDirectory: root,
      timestamp: DateTime.fromMillisecondsSinceEpoch(2),
      environmentId: 'staging',
    );

    expect(prod.path, contains('${p.separator}prod${p.separator}'));
    expect(staging.path, contains('${p.separator}staging${p.separator}'));
    expect(prod.path, isNot(staging.path));
  });

  test('malicious identifier cannot escape avatar directory', () async {
    final root =
        await Directory.systemTemp.createTemp('rutio_avatar_safe_test_');
    addTearDown(() => root.delete(recursive: true));
    final source = File(p.join(root.path, 'picked.jpg'))
      ..writeAsStringSync('avatar-bytes');

    final saved = await const AvatarService().persistAvatarFileForUser(
      source: source,
      userId: '../other-user',
      baseDirectory: root,
      timestamp: DateTime.fromMillisecondsSinceEpoch(3),
      environmentId: '../prod',
    );
    final relative = p.relative(saved.path, from: root.path);

    expect(p.isWithin(root.path, saved.path), isTrue);
    expect(relative, isNot(contains('..')));
    expect(
        saved.path,
        contains(base64Url
            .encode(utf8.encode('../other-user'))
            .replaceAll('=', '')));
  });

  test('empty user id is rejected', () {
    expect(() => safeUserNamespace('  '), throwsArgumentError);
  });
}
