import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class SignupView extends StatelessWidget {
  SignupView({super.key});
  final AuthController c = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1A237E);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: primary),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // LOGO ANIMATION
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, double val, child) {
                  return Transform.scale(scale: val, child: child);
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: const Icon(Icons.person_add_rounded, size: 50, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, double val, child) => Opacity(opacity: val, child: Transform.translate(offset: Offset(0, 20 * (1 - val)), child: child)),
                child: Column(
                  children: [
                    const Text("Create Account", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primary)),
                    const SizedBox(height: 6),
                    Text("Join StockPilot today", style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // FORM FIELDS WITH STAGGERED ANIMATION
              _animatedField(0, child: _buildTextField(controller: c.emailController, label: "Email", icon: Icons.email_rounded, keyboardType: TextInputType.emailAddress)),
              const SizedBox(height: 16),
              _animatedField(1, child: Obx(() => _buildTextField(
                controller: c.passwordController,
                label: "Password (min 6 chars)",
                icon: Icons.lock_rounded,
                isPassword: true,
                isHidden: c.isPasswordHidden.value,
                onToggle: () => c.isPasswordHidden.value = !c.isPasswordHidden.value,
              ))),
              const SizedBox(height: 28),

              // SIGNUP BUTTON
              _animatedField(2, child: Obx(() => SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: c.isLoading.value ? null : c.signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: c.isLoading.value
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Sign Up", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ))),

              const SizedBox(height: 20),
              _animatedField(3, child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have account? ", style: TextStyle(color: Colors.grey.shade600)),
                  TextButton(
                    onPressed: () => Get.back(),
                    style: TextButton.styleFrom(foregroundColor: primary, padding: EdgeInsets.zero),
                    child: const Text("Sign In", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              )),

              const SizedBox(height: 10),
              _animatedField(4, child: Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text("StockPilot", style: TextStyle(color: Colors.grey.shade400, fontSize: 11, letterSpacing: 1.5))),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _animatedField(int index, {required Widget child}) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 120)),
      curve: Curves.easeOutCubic,
      builder: (context, double val, _) {
        return Opacity(
          opacity: val,
          child: Transform.translate(offset: Offset(0, 30 * (1 - val)), child: child),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool isHidden = false,
    VoidCallback? onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword ? isHidden : false,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1A237E)),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey.shade600),
            onPressed: onToggle,
          )
              : null,
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