import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/shell/app_shell.dart';

class ApexFitApp extends StatelessWidget {
  const ApexFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'APEXFIT',
      theme: buildApexFitTheme(),
      debugShowCheckedModeBanner: false,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, _) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) return const AuthScreen();
        return const AppShell();
      },
    );
  }
}
