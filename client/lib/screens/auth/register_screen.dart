import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_notifier.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthNotifier>();
    final ok = await auth.register(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta criada! Faça login.'),
          backgroundColor: AppTheme.statusConfirmado,
        ),
      );
      context.go('/login');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Erro ao criar conta'),
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
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _form,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'NOME COMPLETO'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'EMAIL'),
                  validator: (v) =>
                      v == null || !v.contains('@') ? 'Email inválido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'SENHA'),
                  validator: (v) => v == null || v.length < 6
                      ? 'Mínimo 6 caracteres'
                      : null,
                ),
                const SizedBox(height: 24),
                loading
                    ? const CircularProgressIndicator(color: AppTheme.accent)
                    : ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Criar conta'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
