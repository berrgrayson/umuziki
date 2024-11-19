import 'package:authentification/pages/home_page.dart';
import 'package:authentification/pages/login_or_register_page.dart';
import 'package:authentification/pages/verification_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // user is logged in and verified
          if (snapshot.hasData && snapshot.data!.emailVerified) {
            return const HomePage();
          }
          // user is logged in but not verified
          else if (snapshot.hasData && !snapshot.data!.emailVerified) {
            return const VerificationPage();
          }
          // user is NOT logged in
          else {
            return const LoginOrRegisterPage();
          }
        },
      ),
    );
  }
}
