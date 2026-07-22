import 'package:flutter/material.dart';
import 'package:my_app/pages/home.dart';
import 'package:my_app/services/api_service.dart';

void main() {
  ApiService.enableDemoMode();
  runApp(const GencCuzdan());
}

class GencCuzdan extends StatelessWidget {
  const GencCuzdan({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Genç Cüzdan',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6366F1),
        brightness: Brightness.light,
      ),
      home: const _AutoLoginWrapper(),
    );
  }
}

/// Automatically logs in with the demo account and navigates to HomePage.
/// No login screen is shown — the user goes straight into the app.
class _AutoLoginWrapper extends StatefulWidget {
  const _AutoLoginWrapper();

  @override
  State<_AutoLoginWrapper> createState() => _AutoLoginWrapperState();
}

class _AutoLoginWrapperState extends State<_AutoLoginWrapper>
    with SingleTickerProviderStateMixin {
  bool _ready = false;
  String? _error;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Demo account credentials
  static const String _demoEmail = 'demo@genccuzdan.com';
  static const String _demoPassword = 'demo123456';
  static const String _demoName = 'Demo Kullanıcı';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _autoLogin();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _autoLogin() async {
    try {
      // Try logging in with the demo account
      await ApiService.login(
        email: _demoEmail,
        password: _demoPassword,
      );
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      // If login fails, try registering the demo account first
      try {
        await ApiService.register(
          email: _demoEmail,
          password: _demoPassword,
          name: _demoName,
        );
        if (mounted) setState(() => _ready = true);
      } catch (e2) {
        // If both fail, try just setting a local user and proceeding
        // (the API might be unreachable, but we can still show the UI)
        try {
          await ApiService.login(
            email: _demoEmail,
            password: _demoPassword,
          );
          if (mounted) setState(() => _ready = true);
        } catch (e3) {
          if (mounted) {
            setState(() {
              _error = 'API bağlantısı kurulamadı. Lütfen internet bağlantınızı kontrol edin.';
            });
            // Auto-retry after 3 seconds
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted && !_ready) {
                setState(() => _error = null);
                _autoLogin();
              }
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return const HomePage();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated logo
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) => Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'GençCüzdan',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Web Demo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6366F1).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 48),
            if (_error != null) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFEF4444), size: 20),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Yeniden bağlanılıyor...',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _error != null ? 'Bağlantı bekleniyor...' : 'Demo hesabına giriş yapılıyor...',
              style: TextStyle(
                color: const Color(0xFF64748B).withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
