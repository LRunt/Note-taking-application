import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:notes/services/authService.dart';

class MockBuildContext extends Mock implements BuildContext {}

class MockUserCredential extends Mock implements UserCredential {}

class MockAppLocalizations extends Mock implements AppLocalizations {
  @override
  String get invalidEmail => 'Wrong format of email';
  @override
  String get fieldsAreNotFilled => "One or more fields are not filled!";
  @override
  String get userNotFound => "No user found with that email";
  @override
  String get weakPassword => 'Password is too short. Password must have at least 6 chars.';
  @override
  String get wrongPassword => "Wrong password";
  @override
  String get invalidCreditial => "Wrong email or password";
  @override
  String get networkRequestFailed => "No internet connection";
  @override
  String get accountWithEmailExists => "An account already exists for that email";
}

class MockFirebaseAuth extends Mock implements FirebaseAuth {
  @override
  Future<void> signOut() =>
      super.noSuchMethod(Invocation.method(#signOut, []), returnValue: Future<void>.value());

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String? email,
    required String? password,
  }) =>
      super.noSuchMethod(Invocation.method(#createUserWithEmailAndPassword, [email, password]),
          returnValue: Future.value(MockUserCredential()));

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String? email,
    required String? password,
  }) =>
      super.noSuchMethod(Invocation.method(#signInWithEmailAndPassword, [email, password]),
          returnValue: Future.value(MockUserCredential()));
}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  late MockBuildContext mockContext;
  late MockAppLocalizations mockLocalizations;
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockUserCredential mockUserCreditial;
  late AuthService authService;

  setUp(() {
    mockContext = MockBuildContext();
    mockLocalizations = MockAppLocalizations();
    mockFirestore = MockFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUserCreditial = MockUserCredential();
    authService = AuthService(
      auth: mockAuth,
      firestore: mockFirestore,
      localizationProvider: (_) => mockLocalizations,
    );
  });

  group('register tests', () {
    test('Registration - simple test (succesfull)', () async {
      const String email = "test@gmail.com";
      const String password = "password123";
      when(mockAuth.createUserWithEmailAndPassword(email: email, password: password))
          .thenAnswer((realInvocation) => Future.value(mockUserCreditial));

      final result = await authService.register(email, password);
      expect(result, mockUserCreditial);
    });

    test('Registration - registration failed', () async {
      const String email = "test@gmail.com";
      const String password = "paswrod123";
      final FirebaseAuthException exception = FirebaseAuthException(code: "auth-error");

      when(mockAuth.createUserWithEmailAndPassword(email: email, password: password))
          .thenThrow(exception);

      expect(() async => await authService.register(email, password), throwsA(isA<String>()));
    });
  });

  group('login tests', () {
    test('Login - simple test (succesfull)', () async {
      const String email = "test@gmail.com";
      const String password = "password123";
      when(mockAuth.signInWithEmailAndPassword(email: email, password: password))
          .thenAnswer((realInvocation) => Future.value(mockUserCreditial));

      final result = await authService.login(email, password);
      expect(result, mockUserCreditial);
    });

    test('Login - login failed', () async {
      const String email = "test@gmail.com";
      const String password = "paswrod123";
      final FirebaseAuthException exception = FirebaseAuthException(code: "auth-error");

      when(mockAuth.signInWithEmailAndPassword(email: email, password: password))
          .thenThrow(exception);

      expect(() async => await authService.login(email, password), throwsA(isA<String>()));
    });
  });

  group('logout tests', () {
    test('logout - simple test', () async {
      when(mockAuth.signOut()).thenAnswer((_) => Future<void>.value());

      expect(await authService.logout(), "Success");
    });
  });

  group('getErrorMessage tests', () {
    test('invalid-email error message', () {
      expect(authService.getErrorMessage('invalid-email', mockContext), 'Wrong format of email');
    });
    test('channel-error error message', () {
      expect(authService.getErrorMessage('channel-error', mockContext),
          'One or more fields are not filled!');
    });
    test('user-not-found error message', () {
      expect(authService.getErrorMessage('user-not-found', mockContext),
          'No user found with that email');
    });
    test('wrong-password error message', () {
      expect(authService.getErrorMessage('wrong-password', mockContext), 'Wrong password');
    });
    test('invalid-credential error message', () {
      expect(authService.getErrorMessage('invalid-credential', mockContext),
          'Wrong email or password');
    });
    test('network-request-failed error message', () {
      expect(authService.getErrorMessage('network-request-failed', mockContext),
          'No internet connection');
    });
    test('weak-password error message', () {
      expect(authService.getErrorMessage('weak-password', mockContext),
          'Password is too short. Password must have at least 6 chars.');
    });
    test('email-already-in-use error message', () {
      expect(authService.getErrorMessage('email-already-in-use', mockContext),
          'An account already exists for that email');
    });
    test('default error message', () {
      expect(authService.getErrorMessage('not-known-error', mockContext), 'not-known-error.');
    });
  });
}
