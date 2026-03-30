import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/api_service.dart';

import '../theme/design_system.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  bool _isLoginMode = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    // Shake animation could be added here
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Lütfen tüm alanları doldurun');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError('Lütfen tüm alanları doldurun');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Şifreler uyuşmuyor');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('Şifre en az 6 karakter olmalıdır');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ApiService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorMessage = null;
    });
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.background,
      body: Stack(
        children: [
          // Background Gradient Patterns
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DesignSystem.primaryIndigo.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DesignSystem.primaryIndigo.withOpacity(0.05),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Identity
                      Hero(
                        tag: 'app_logo',
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: DesignSystem.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [DesignSystem.premiumCard().boxShadow![0]],
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 52,
                            color: DesignSystem.primaryIndigo,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'GençCüzdan',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: DesignSystem.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLoginMode ? 'Geleceğini bugün yönetmeye başla' : 'Finansal özgürlüğe ilk adımını at',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: DesignSystem.gray.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Glassmorphism Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: DesignSystem.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: DesignSystem.white.withOpacity(0.5),
                                width: 1.5,
                              ),
                              boxShadow: [DesignSystem.premiumCard().boxShadow![0]],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isLoginMode ? 'Giriş Yap' : 'Kayıt Ol',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: DesignSystem.black,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                
                                if (!_isLoginMode) ...[
                                  _buildTextField(
                                    controller: _nameController,
                                    hint: 'Ad Soyad',
                                    icon: Icons.person_outline,
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                _buildTextField(
                                  controller: _emailController,
                                  hint: 'E-posta',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 16),

                                _buildTextField(
                                  controller: _passwordController,
                                  hint: 'Şifre',
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  obscureText: _obscurePassword,
                                  onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                
                                if (!_isLoginMode) ...[
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _confirmPasswordController,
                                    hint: 'Şifreyi Onayla',
                                    icon: Icons.lock_reset_outlined,
                                    isPassword: true,
                                    obscureText: _obscureConfirmPassword,
                                    onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                  ),
                                ],

                                if (_isLoginMode)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {},
                                      child: Text(
                                        'Şifremi Unuttum?',
                                        style: TextStyle(
                                          color: DesignSystem.primaryIndigo,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                
                                const SizedBox(height: 24),

                                if (_errorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(color: DesignSystem.accentCoral, fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ),

                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : (_isLoginMode ? _handleLogin : _handleRegister),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: DesignSystem.primaryIndigo,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            _isLoginMode ? 'Giriş Yap' : 'Hesap Oluştur',
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Toggle Mode
                      GestureDetector(
                        onTap: _toggleMode,
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(color: DesignSystem.gray, fontSize: 15),
                            children: [
                              TextSpan(text: _isLoginMode ? 'Hesabın yok mu? ' : 'Zaten üye misin? '),
                              TextSpan(
                                text: _isLoginMode ? 'Üye Ol' : 'Giriş Yap',
                                style: const TextStyle(
                                  color: DesignSystem.primaryIndigo,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      // Demo info for testing
                      if (_isLoginMode)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: DesignSystem.primaryIndigo.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: DesignSystem.primaryIndigo.withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline, size: 18, color: DesignSystem.primaryIndigo),
                            const SizedBox(width: 8),
                            Text(
                              'Demo: demo@example.com / demo123',
                              style: TextStyle(color: DesignSystem.primaryIndigo.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: DesignSystem.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignSystem.lightGray.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: DesignSystem.gray.withOpacity(0.5)),
          prefixIcon: Icon(icon, size: 22, color: DesignSystem.primaryIndigo.withOpacity(0.7)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                    color: DesignSystem.gray.withOpacity(0.5),
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
