import 'package:bancofalabella_app2/supabase_config.dart';
import 'package:bancofalabella_app2/views/home_page.dart';
import 'package:bancofalabella_app2/views/login_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var supabaseReady = false;
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      supabaseReady = true;
    } catch (_) {
      supabaseReady = false;
    }
  }

  runApp(BancoFalabellaApp(supabaseReady: supabaseReady));
}

class BancoFalabellaApp extends StatelessWidget {
  const BancoFalabellaApp({super.key, required this.supabaseReady});

  final bool supabaseReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Banco Falabella Fuerza de Ventas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007A3D)),
        scaffoldBackgroundColor: const Color(0xFFF3F6F4),
        useMaterial3: true,
      ),
      home: AuthGate(supabaseReady: supabaseReady),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.supabaseReady});

  final bool supabaseReady;

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured || !supabaseReady) {
      return const HomePage(demoMode: true, userEmail: 'alumno1@example.com');
    }

    final auth = Supabase.instance.client.auth;

    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = auth.currentSession;

        if (session == null) {
          return const LoginPage();
        }

        return HomePage(userEmail: session.user.email);
      },
    );
  }
}
