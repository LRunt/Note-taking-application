part of services;

/// A StatefulWidget that toggles between the login and register screens.
///
/// This widget serves as a container that decides whether to show the login screen
/// or the registration screen based on the user's choice. It provides a seamless way
/// for users to switch between the two screens without navigating back and forth in the app's navigation stack.
class LoginOrRegister extends StatefulWidget {
  /// Instance of [FirebaseAuth] (because of mocking)
  final FirebaseAuth auth;

  /// Instance of firebase firestore (because of mocking)
  final FirebaseFirestore firestore;

  /// What page will be shown first.
  final bool showLoginPage;

  /// Returns a signal when the login is success.
  final VoidCallback loginSuccess;

  /// Constructor of [LoginOrRegister] class.
  const LoginOrRegister({
    super.key,
    required this.auth,
    required this.firestore,
    required this.showLoginPage,
    required this.loginSuccess,
  });

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  /// A boolean value that determines which screen to show.
  /// `true`  - the login screen.
  /// `false` - the registration screen.
  late bool showLoginPage;

  /// Toggles the boolean value to switch between screens.
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  /// Initialization if firstly will be login or registration page shown.
  @override
  void initState() {
    showLoginPage = widget.showLoginPage;
    super.initState();
  }

  /// Builds the widget based on the current state.
  ///
  /// If `showLoginPage` is true, the [LoginPage] widget is returned, otherwise,
  /// the [RegisterPage] widget is returned. Each screen provides an option to toggle
  /// to the other screen via the `onTap` callback, which invokes [togglePages].
  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(
        auth: widget.auth,
        firestore: widget.firestore,
        onTap: togglePages,
        loginSuccess: widget.loginSuccess,
      );
    } else {
      return RegisterPage(
        auth: widget.auth,
        firestore: widget.firestore,
        onTap: togglePages,
      );
    }
  }
}
