import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'screens/sign_in_screen.dart';
import 'screens/home_screen.dart';

class GparkApp extends StatelessWidget {
  const GparkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'gPark',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const _AuthGate(),
    );
  }

  ThemeData _buildTheme() {
    const primaryColor = Color(0xFF1A73E8);
    const errorColor = Color(0xFFD93025);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        error: errorColor,
        surface: const Color(0xFFFFFFFF),
        onSurface: const Color(0xFF202124),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Color(0xFF202124)),
        bodySmall: TextStyle(color: Color(0xFF5F6368)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}

/// Rule 7: Auth drives navigation.
/// Not authenticated → Sign-In screen. Authenticated → Home.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      authenticated: (user) => const HomeScreen(),
      unauthenticated: () => const SignInScreen(),
      error: (message) => SignInScreen(errorMessage: message),
    );
  }
}
