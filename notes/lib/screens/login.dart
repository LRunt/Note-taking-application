import 'package:flutter/material.dart';
import 'dart:developer';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginPage> {
  static const loginString = "Login";
  static const pleaseLogin = "Please Login";

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  ///Clean up the controllers when widget is removed from the tree.
  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void login() {
    String username = usernameController.text;
    String password = passwordController.text;

    log('Loging user: $username, password: $password');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(loginString),
      ),
      body: Center(
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              children: [
                const Icon(Icons.message, size: 80),
                const Text(pleaseLogin),
                const TextField(
                  decoration: InputDecoration(
                    hintText: "Username",
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                const TextField(
                  obscureText: true,
                  obscuringCharacter: "*",
                  decoration: InputDecoration(
                    hintText: "Password",
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                ElevatedButton(
                  onPressed: () {
                    login();
                  },
                  child: const Text(loginString),
                ),
                const SizedBox(
                  height: 40,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an acount?"),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        "Create new here!",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            )),
      ),
    );
  }
}
