import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:notes/services/authService.dart';
import 'package:notes/services/loginOrRegister.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:developer';

/// A StatefulWidget that creates a drawer header showing the user's login status.
///
/// This widget listens to Firebase Authentication state changes to update the state of the UI.
/// It also uses Firebase Authentication to manage the user state.
class UserDrawerHeader extends StatefulWidget {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  /// Constructor of [UserDrawerHeader] class.
  const UserDrawerHeader({super.key, required this.auth, required this.firestore});

  @override
  State<UserDrawerHeader> createState() => _UserDrawerHeaderState();
}

/// The state class for [UserDrawerHeader], handling user authentication state.
/// Content of the [UserDrawerHeader] depends on whether the user si logged in.
class _UserDrawerHeaderState extends State<UserDrawerHeader> {
  /// The current user, obtained from Firebase Authentification.
  /// null when user is not logged in.
  User? user;

  /// Subscribtion to the authentification state changes.
  /// Listens for updates of the user's status and updates the UI.
  late final StreamSubscription<User?> authSubscription;

  late final AuthService _authService;

  /// Inicialization of the state
  /// Adding listener to the authentication state changes (login/logout) and update the UI by setting the current user.
  /// If an error occurs while listening, it is logged to the console.
  @override
  void initState() {
    super.initState();
    user = widget.auth.currentUser;
    _authService = AuthService(
      auth: widget.auth,
      firestore: widget.firestore,
      localizationProvider: (BuildContext context) => AppLocalizations.of(context)!,
    );
    authSubscription = widget.auth.authStateChanges().listen(
      (User? currentUser) {
        if (mounted) {
          setState(
            () {
              user = currentUser;
            },
          );
        }
      },
      onError: (error) {
        log('Error listening to authentification state changes: $error');
      },
    );
  }

  /// Cancel the subscription to auth state changes when the widget is disposed
  /// to prevent memory leaks and unnecessary processing.
  @override
  void dispose() {
    authSubscription.cancel();
    super.dispose();
  }

  /// Log out from Firebase Authentication.
  /// This method attempts to sign out the current user.
  /// If an error occurs, it logs the error message.
  void logout() async {
    String result = await _authService.logout();
    if (result == "Success") {
      log("Success");
    } else {
      log('Logout failed with error: $result');
    }
  }

  /// Builds the UI based on the user's authentication status.
  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      child: Column(
        children: [
          if (user == null) ...[
            Text(AppLocalizations.of(context)!.notLogged),
            FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginOrRegister(
                        auth: widget.auth, firestore: widget.firestore, showLoginPage: true),
                  ),
                );
              },
              child: Text(AppLocalizations.of(context)!.login),
            ),
            FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginOrRegister(
                        auth: widget.auth, firestore: widget.firestore, showLoginPage: false),
                  ),
                );
              },
              child: Text(AppLocalizations.of(context)!.registration),
            ),
          ] else ...[
            Text(AppLocalizations.of(context)!.loggedUser(user!.email),
                style: const TextStyle(fontSize: 16)),
            ElevatedButton(
              onPressed: () => logout(),
              child: Text(AppLocalizations.of(context)!.signOut),
            ),
          ],
        ],
      ),
    );
  }
}
