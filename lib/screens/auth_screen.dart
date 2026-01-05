import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_manager.dart';
import '../services/auth_service.dart';
import '../widgets/modern_button.dart';
import '../widgets/background.dart';
import 'main_menu_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModernBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // LOGO
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(color: Colors.white54, width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.5),
                          blurRadius: 30)
                    ]),
                child: const Icon(Icons.style, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text("UNO\nURBAN",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.blackOpsOne(
                      fontSize: 40, color: Colors.white, height: 0.9)),
              const SizedBox(height: 10),
              Text("The Ultimate Card Battle",
                  style:
                      GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
              const Spacer(),

              // ACTIONS
              ModernButton(
                label: "LOGIN",
                icon: Icons.login,
                baseColor: Colors.blueAccent,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
              ),
              const SizedBox(height: 20),
              ModernButton(
                label: "SIGN UP",
                icon: Icons.person_add,
                baseColor: Colors.purpleAccent,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SignupScreen())),
              ),
              const SizedBox(height: 20),

              Row(children: [
                const Expanded(child: Divider(color: Colors.white24)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text("OR",
                      style: GoogleFonts.poppins(color: Colors.white54)),
                ),
                const Expanded(child: Divider(color: Colors.white24)),
              ]),
              const SizedBox(height: 20),

              ModernButton(
                label: "CONTINUE AS GUEST",
                icon: Icons.person_outline,
                baseColor: Colors.grey,
                onTap: () async {
                  DataManager.isGuest = true;
                  DataManager.playerName =
                      "Guest_${DateTime.now().millisecondsSinceEpoch % 1000}";
                  DataManager.email = null;
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MainMenuScreen()));
                },
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailC = TextEditingController();
  final TextEditingController _passC = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    if (_emailC.text.isEmpty || _passC.text.isEmpty) return;

    setState(() => _isLoading = true);
    String? error =
        await AuthService.login(_emailC.text.trim(), _passC.text.trim());

    if (error == null) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainMenuScreen()),
            (r) => false);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _googleLogin() async {
    setState(() => _isLoading = true);
    String? error = await AuthService.googleLogin();
    setState(() => _isLoading = false);

    if (error == null) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainMenuScreen()),
            (r) => false);
      }
    } else {
      if (error != "Sign in cancelled" && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red));
      }
    }
  }

  void _forgot() async {
    if (_emailC.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Enter email first!")));
      return;
    }

    setState(() => _isLoading = true);
    String? error = await AuthService.forgotPassword(_emailC.text.trim());
    setState(() => _isLoading = false);

    if (error == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Reset email sent! Check your inbox."),
            backgroundColor: Colors.green));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: ModernBackground(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white))),
              const Spacer(),
              Text("LOGIN",
                  style: GoogleFonts.blackOpsOne(
                      fontSize: 40, color: Colors.white)),
              const SizedBox(height: 30),
              _field("Email", Icons.email, _emailC),
              const SizedBox(height: 15),
              _field("Password", Icons.lock, _passC, obscure: true),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: _forgot,
                    child: Text("Forgot Password?",
                        style: GoogleFonts.poppins(color: Colors.blueAccent))),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ModernButton(
                    label: "Login",
                    icon: Icons.arrow_forward,
                    baseColor: Colors.blueAccent,
                    onTap: _login),
              const SizedBox(height: 20),
              Text("Or login with",
                  style: GoogleFonts.poppins(color: Colors.white54)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _googleLogin,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50)),
                  child: const Icon(Icons.g_mobiledata,
                      color: Colors.blue, size: 40),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, IconData icon, TextEditingController c,
      {bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24)),
      child: TextField(
        controller: c,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white54),
            hintText: label,
            hintStyle: const TextStyle(color: Colors.white24),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameC = TextEditingController();
  final TextEditingController _emailC = TextEditingController();
  final TextEditingController _passC = TextEditingController();
  bool _isLoading = false;

  void _signup() async {
    if (_nameC.text.isEmpty || _emailC.text.isEmpty || _passC.text.isEmpty)
      return;

    setState(() => _isLoading = true);
    String? error = await AuthService.signUp(
        _emailC.text.trim(), _passC.text.trim(), _nameC.text.trim());

    if (error == null) {
      if (mounted) {
        showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
                  backgroundColor: Colors.black87,
                  title: const Text("Verify Email",
                      style: TextStyle(color: Colors.white)),
                  content: Text(
                      "A verification link has been sent to ${_emailC.text}. Please verify to login.",
                      style: const TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pop(
                              context); // Go back to Auth Screen (Login)
                        },
                        child: const Text("OK"))
                  ],
                ));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: ModernBackground(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white))),
              const Spacer(),
              Text("SIGN UP",
                  style: GoogleFonts.blackOpsOne(
                      fontSize: 40, color: Colors.white)),
              const SizedBox(height: 30),
              _field("Player Name", Icons.person, _nameC),
              const SizedBox(height: 15),
              _field("Email", Icons.email, _emailC),
              const SizedBox(height: 15),
              _field("Password", Icons.lock, _passC, obscure: true),
              const SizedBox(height: 30),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ModernButton(
                    label: "Data Save & Signup",
                    icon: Icons.check,
                    baseColor: Colors.purpleAccent,
                    onTap: _signup),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, IconData icon, TextEditingController c,
      {bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24)),
      child: TextField(
        controller: c,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white54),
            hintText: label,
            hintStyle: const TextStyle(color: Colors.white24),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
      ),
    );
  }
}
