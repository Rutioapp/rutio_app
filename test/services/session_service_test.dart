import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rutio/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('legacy payload with pass is cleaned without exposing a password',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SessionService.userKey: jsonEncode(<String, dynamic>{
        'email': 'user@example.com',
        'pass': 'secret-password',
      }),
    });

    await SessionService.instance.cleanLegacyCredential();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(SessionService.userKey)!;
    final data = (jsonDecode(raw) as Map).cast<String, dynamic>();

    expect(data, <String, dynamic>{'email': 'user@example.com'});
    expect(raw, isNot(contains('secret-password')));
    expect(raw, isNot(contains('pass')));
    expect(raw, isNot(contains('password')));
  });

  test('new signUp write does not contain password', () async {
    final created = await SessionService.instance.signUp(
      email: 'new@example.com',
      pass: 'secret-password',
    );

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(SessionService.userKey)!;

    expect(created, isTrue);
    expect(raw, isNot(contains('secret-password')));
    expect(raw, isNot(contains('pass')));
    expect(raw, contains('new@example.com'));
  });

  test('payload without password is preserved', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SessionService.userKey: jsonEncode(<String, dynamic>{
        'email': 'safe@example.com',
      }),
    });

    await SessionService.instance.cleanLegacyCredential();

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(SessionService.userKey),
      jsonEncode(<String, dynamic>{'email': 'safe@example.com'}),
    );
  });

  test('corrupt JSON is removed fail-safe', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SessionService.userKey: '{broken-json',
    });

    await SessionService.instance.cleanLegacyCredential();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(SessionService.userKey), isFalse);
  });

  test('wrong password field type is cleaned without logging the value',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SessionService.userKey: jsonEncode(<String, dynamic>{
        'email': 'typed@example.com',
        'password': <String>['not', 'a', 'string'],
      }),
    });

    await SessionService.instance.cleanLegacyCredential();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(SessionService.userKey)!;
    expect(raw, contains('typed@example.com'));
    expect(raw, isNot(contains('password')));
    expect(raw, isNot(contains('not')));
  });

  test('legacy login is fail-closed and does not persist password on logout',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SessionService.userKey: jsonEncode(<String, dynamic>{
        'email': 'user@example.com',
        'pass': 'secret-password',
      }),
    });

    final loggedIn = await SessionService.instance.login(
      email: 'user@example.com',
      pass: 'secret-password',
    );
    await SessionService.instance.clear();

    final prefs = await SharedPreferences.getInstance();
    expect(loggedIn, isFalse);
    expect(prefs.containsKey(SessionService.userKey), isFalse);
  });
}
