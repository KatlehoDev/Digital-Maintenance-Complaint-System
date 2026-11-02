import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/hcm/hcm_home.dart';
import 'screens/maintenance/maintenance_home.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with your project credentials
  await Supabase.initialize(
    url: 'https://prmdirmjqssymavcuuka.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBybWRpcm1qcXNzeW1hdmN1dWthIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI0ODkzNTcsImV4cCI6MjEwODA2NTM1N30.X5bWDlutm0lpCZ01GoVKt-Xdxy_yuEofh519FZQ_8xU', // <-- MAKE SURE THIS IS YOUR ANON KEY
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CUT Maintenance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2A2665)),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Listen to auth changes (login/logout)
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return const LoginScreen();
    return const RoleRouter();
  }
}

class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});
  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  String? _role;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final role = await AuthService.getCurrentUserRole();
      if (!mounted) return;
      setState(() {
        _role = role;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    // Route based on role
    if (_role == 'maintenance') {
      return const MaintenanceHome();
    } else if (_role == 'hcm') {
      return const HcmHome();
    } else if (_role == 'admin') {
      return const Scaffold(
        body: Center(child: Text('Admin accounts use the ASP.NET web portal.')),
      );
    } else {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No role assigned. Contact an administrator.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
  }
}