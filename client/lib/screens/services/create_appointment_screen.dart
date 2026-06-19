import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/pet.dart';
import '../../models/service.dart';
import '../../providers/appointments_notifier.dart';
import '../../providers/pets_notifier.dart';

class CreateAppointmentScreen extends StatefulWidget {
  final Service service;
  const CreateAppointmentScreen({super.key, required this.service});
  @override
  State<CreateAppointmentScreen> createState() =>
      _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  Pet? _selectedPet;
  DateTime _scheduledAt = DateTime.now().add(const Duration(days: 1));
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PetsNotifier>().loadAll();
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(data: AppTheme.dark, child: child!),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
      builder: (ctx, child) => Theme(data: AppTheme.dark, child: child!),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (_selectedPet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um pet')),
      );
      return;
    }
    setState(() => _submitting = true);
    final ok = await context.read<AppointmentsNotifier>().create(
          petId: _selectedPet!.id,
          serviceId: widget.service.id,
          providerId: widget.service.providerId,
          scheduledAt: _scheduledAt,
          notes: _notesCtrl.text,
        );
    setState(() => _submitting = false);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agendamento criado!'),
          backgroundColor: AppTheme.statusConfirmado,
        ),
      );
      context.go('/appointments');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao criar agendamento'),
          backgroundColor: AppTheme.statusCancelado,
        ),
      );
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Agendamento')),
      body: Consumer<PetsNotifier>(
        builder: (_, petsNotifier, __) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service summary card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.accent.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withAlpha(18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.pets,
                          color: AppTheme.accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.service.name,
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '${widget.service.durationMinutes} min · ${widget.service.providerName ?? "Prestador"}',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'R\$${widget.service.price.toStringAsFixed(0)}',
                      style: GoogleFonts.dmMono(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _SectionLabel('Seu Pet'),
              const SizedBox(height: 8),
              petsNotifier.loading
                  ? const LinearProgressIndicator(color: AppTheme.accent)
                  : DropdownButtonFormField<Pet>(
                      value: _selectedPet,
                      hint: const Text(
                        'Selecionar pet',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                      dropdownColor: AppTheme.surface2,
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 14),
                      decoration: const InputDecoration(),
                      items: petsNotifier.pets
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text('${p.name} — ${p.breed}'),
                              ))
                          .toList(),
                      onChanged: (p) => setState(() => _selectedPet = p),
                    ),
              const SizedBox(height: 20),

              _SectionLabel('Data e Hora'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 18, color: AppTheme.accent),
                      const SizedBox(width: 10),
                      Text(
                        _formatDate(_scheduledAt),
                        style: GoogleFonts.dmMono(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _SectionLabel('Observações (opcional)'),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Ex: trazer comedouro, alérgico a...',
                ),
              ),
              const SizedBox(height: 32),

              _submitting
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.accent))
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Confirmar Agendamento'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.outfit(
        color: AppTheme.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}
