import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'signup_view.dart';

class LoginView extends StatefulWidget {
  LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with TickerProviderStateMixin {
  final AuthController c = Get.put(AuthController());
  late AnimationController _bgController;
  late AnimationController _floatController;
  final primary = const Color(0xFF1A237E);

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      body: Stack(
        children: [
          // LIVE ANIMATED BACKGROUND
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFFF5F6FF), Color.lerp(const Color(0xFFE8EAF6), const Color(0xFFC5CAE9), _bgController.value)!],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              );
            },
          ),
          // FLOATING BLOBS - LIVE
          Positioned(
            top: -40,
            right: -30,
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _floatController.value * 12),
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withValues(alpha: 0.07 + _bgController.value * 0.05),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -40,
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, -_floatController.value * 15),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [primary.withValues(alpha: 0.12), primary.withValues(alpha: 0.02)]),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  // LOGO WITH LIVE PULSE
                  AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) => Transform.scale(
                      scale: 1 + _floatController.value * 0.05,
                      child: child,
                    ),
                    child: TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.elasticOut,
                      builder: (context, double val, child) => Transform.scale(scale: val, child: child),
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 12))],
                        ),
                        child: const Icon(Icons.inventory_2_rounded, size: 52, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _anim(0, child: const Text("StockPilot", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF1A237E), letterSpacing: 0.5))),
                  const SizedBox(height: 6),
                  _anim(1, child: Text("Login to your account", style: TextStyle(color: Colors.grey.shade600, fontSize: 14))),
                  const SizedBox(height: 36),

                  _anim(2, child: _field(controller: c.emailController, label: "Email", icon: Icons.email_rounded, type: TextInputType.emailAddress)),
                  const SizedBox(height: 16),
                  _anim(3, child: Obx(() => _field(
                    controller: c.passwordController,
                    label: "Password",
                    icon: Icons.lock_rounded,
                    isPass: true,
                    hidden: c.isPasswordHidden.value,
                    onToggle: () => c.isPasswordHidden.value = !c.isPasswordHidden.value,
                  ))),
                  const SizedBox(height: 28),

                  _anim(4, child: Obx(() => SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: c.isLoading.value ? null : c.signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: primary.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: c.isLoading.value
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Sign In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), SizedBox(width: 8), Icon(Icons.login_rounded, size: 20)]),
                    ),
                  ))),
                  const SizedBox(height: 20),
                  _anim(5, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Don't have account? ", style: TextStyle(color: Colors.grey.shade600)), TextButton(onPressed: () => Get.to(() => SignupView()), style: TextButton.styleFrom(foregroundColor: primary, padding: EdgeInsets.zero), child: const Text("Sign Up", style: TextStyle(fontWeight: FontWeight.bold)))])),
                  const SizedBox(height: 12),
                  _anim(6, child: Row(children: [Expanded(child: Divider(color: Colors.grey.shade300)), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text("SECURE LOGIN", style: TextStyle(color: Colors.grey.shade400, fontSize: 10, letterSpacing: 1.5))), Expanded(child: Divider(color: Colors.grey.shade300))])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _anim(int i, {required Widget child}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 650 + (i * 120)),
      curve: Curves.easeOutCubic,
      builder: (context, double v, _) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 28 * (1 - v)), child: child)),
    );
  }

  Widget _field({required TextEditingController controller, required String label, required IconData icon, TextInputType? type, bool isPass = false, bool hidden = false, VoidCallback? onToggle}) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))]),
      child: TextField(
        controller: controller,
        keyboardType: type,
        obscureText: isPass ? hidden : false,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1A237E)),
          suffixIcon: isPass ? IconButton(icon: Icon(hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey.shade600), onPressed: onToggle) : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5)),
        ),
      ),
    );
  }
}