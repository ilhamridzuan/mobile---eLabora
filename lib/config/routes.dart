import 'package:flutter/material.dart';
import '../pages/landing_page.dart';
import '../pages/login_page.dart';
import '../pages/home_page.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const LandingPage(),
  '/login': (context) => const LoginPage(),
  '/home': (context) => const HomePage(),
};
