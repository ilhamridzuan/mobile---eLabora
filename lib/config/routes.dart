import 'package:flutter/material.dart';
import 'package:elabora_app/pages/home_page.dart';
import 'package:elabora_app/pages/riwayat_page.dart';
import '../pages/landing_page.dart';
import '../pages/login_page.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const LandingPage(),
  '/login': (context) => const LoginPage(),
  '/home': (context) => const HomePage(),
  '/riwayat': (context) => const RiwayatPage(),
};
