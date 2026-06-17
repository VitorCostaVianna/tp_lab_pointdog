import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/service.dart';
import '../../providers/services_notifier.dart';

class ProviderServiceFormScreen extends StatefulWidget {
  final Service? existing;
  const ProviderServiceFormScreen({super.key, this.existing});

  @override
  State<ProviderServiceFormScreen> createState() =>
      _ProviderServiceFormScreenState();
}

class _ProviderServiceFormScreenState
    extends State<ProviderServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _duration;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _name = TextEditingController(text: s?.name ?? '');
    _description = TextEditingController(text: s?.description ?? '');
    _price = TextEditingController(
        text: s != null ? s.price.toStringAsFixed(2) : '');
    _duration =
        TextEditingController(text: s != null ? '${s.durationMinutes}' : '');
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = context.read<ServicesNotifier>();
    final name = _name.text.trim();
    final description = _description.text.trim();
    final price = double.parse(_price.text.trim().replaceAll(',', '.'));
    final duration = int.parse(_duration.text.trim());

    bool ok;
    if (_isEdit) {
      ok = await notifier.updateService(
        widget.existing!.id,
        name: name,
        description: description,
        price: price,
        durationMinutes: duration,
      );
    } else {
      ok = await notifier.createService(
        name: name,
        description: description,
        price: price,
        durationMinutes: duration,
      );
    }

    if (!mounted) return;
    if (ok) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notifier.error ?? 'Erro ao salvar serviço'),
          backgroundColor: AppTheme.statusCancelado,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar Serviço' : 'Novo Serviço'),
      ),
      body: Consumer<ServicesNotifier>(
        builder: (_, notifier, __) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Field(
                  controller: _name,
                  label: 'Nome do serviço',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 16),
                _Field(
                  controller: _description,
                  label: 'Descrição',
                  minLines: 3,
                  maxLines: 5,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Informe a descrição'
                      : null,
                ),
                const SizedBox(height: 16),
                _Field(
                  controller: _price,
                  label: 'Preço (R\$)',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe o preço';
                    final n =
                        double.tryParse(v.trim().replaceAll(',', '.'));
                    if (n == null || n <= 0) return 'Preço inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _Field(
                  controller: _duration,
                  label: 'Duração (minutos)',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Informe a duração';
                    }
                    final n = int.tryParse(v.trim());
                    if (n == null || n <= 0) { return 'Duração inválida'; }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: notifier.loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: notifier.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEdit ? 'Salvar alterações' : 'Criar serviço',
                          style: const TextStyle(fontSize: 16),
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

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int minLines;
  final int? maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppTheme.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
      ),
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
