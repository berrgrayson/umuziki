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
          // Check if user exists
          if (snapshot.hasData) {
            // Force refresh user data to get latest email verification status
            return FutureBuilder<User?>(
              future: FirebaseAuth.instance.currentUser?.reload().then(
                    (_) => FirebaseAuth.instance.currentUser,
                  ),
              builder: (context, userSnapshot) {
                if (userSnapshot.hasData && userSnapshot.data!.emailVerified) {
                  return const HomePage();
                } else {
                  return const VerificationPage();
                }
              },
            );
          }
          // user is NOT logged in
          return const LoginOrRegisterPage();
        },
      ),
    );
  }
}
