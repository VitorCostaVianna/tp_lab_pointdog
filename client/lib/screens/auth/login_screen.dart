import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_notifier.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthNotifier>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Erro ao entrar'),
          backgroundColor: AppTheme.statusCancelado,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select<AuthNotifier, bool>(
      (n) => n.status == AuthStatus.loading,
    );
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _form,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.accent, AppTheme.accentAmber],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text('🐾', style: TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'PointDog',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accent,
                  ),
                ),
                Text(
                  'Agendamento para seu pet',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'EMAIL',
                    prefixIcon: Icon(Icons.email_outlined, size: 18),
                  ),
                  validator: (v) =>
                      v == null || !v.contains('@') ? 'Email inválido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'SENHA',
                    prefixIcon: Icon(Icons.lock_outline, size: 18),
                  ),
                  validator: (v) => v == null || v.length < 6
                      ? 'Mínimo 6 caracteres'
                      : null,
                ),
                const SizedBox(height: 20),
                loading
                    ? const CircularProgressIndicator(color: AppTheme.accent)
                    : ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Entrar'),
                      ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Text(
                    'Criar conta →',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
