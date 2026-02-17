import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'screens/sign_in_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

class GparkApp extends StatelessWidget {
  const GparkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'gPark',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const _AuthGate(),
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
      loading: () => Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      authenticated: (user) => const HomeScreen(),
      unauthenticated: () => const SignInScreen(),
      error: (message) => SignInScreen(errorMessage: message),
    );
  }
}
