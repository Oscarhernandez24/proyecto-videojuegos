import 'package:flutter/material.dart';

import 'config/app_theme.dart';
import 'core/session.dart';
import 'screens/blog_page.dart';
import 'screens/catalog_admin_page.dart';
import 'screens/forgot_password_page.dart';
import 'screens/login_user_page.dart';
import 'screens/post_form_page.dart';
import 'screens/profile_page.dart';
import 'screens/register_user_page.dart';
import 'screens/splash_page.dart';
import 'screens/users_page.dart';

void main() {
  runApp(const LoginApp());
}

class LoginApp extends StatelessWidget {
  const LoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blog de Videojuegos',
      navigatorKey: navigatorKey,
      theme: AppTheme.oscuro,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/blog': (context) => const BlogPage(),
        '/post-form': (context) => const PostFormPage(),
        '/users': (context) => const UsersPage(),
        '/genres-admin': (context) => const CatalogAdminPage(esGenero: true),
        '/categories-admin': (context) => const CatalogAdminPage(esGenero: false),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
