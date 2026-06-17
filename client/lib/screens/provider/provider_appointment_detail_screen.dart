import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/appointment.dart';
import '../../providers/appointments_notifier.dart';

class ProviderAppointmentDetailScreen extends StatefulWidget {
  final String appointmentId;
  const ProviderAppointmentDetailScreen({
    super.key,
    required this.appointmentId,
  });
  @override
  State<ProviderAppointmentDetailScreen> createState() =>
      _ProviderAppointmentDetailScreenState();
}

class _ProviderAppointmentDetailScreenState
    extends State<ProviderAppointmentDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentsNotifier>().loadById(widget.appointmentId);
    });
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/provider/pending');
    }
  }

  Future<void> _runAction(
    Future<bool> Function(String) action,
    String successMsg,
    Color color,
  ) async {
    final notifier = context.read<AppointmentsNotifier>();
    final ok = await action(widget.appointmentId);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMsg), backgroundColor: color),
      );
      _goBack();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notifier.error ?? 'Erro ao atualizar status'),
          backgroundColor: AppTheme.statusCancelado,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe da Solicitação')),
      body: Consumer<AppointmentsNotifier>(
        builder: (_, notifier, __) {
          if (notifier.loading && notifier.selected == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          }
          final a = notifier.selected;
          if (a == null) {
            return const Center(
              child: Text('Agendamento não encontrado.'),
            );
          }
          final color = statusColor(a.status);
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        a.service?.name ?? 'Serviço',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withAlpha(35),
                        border: Border.all(color: color.withAlpha(80)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        a.status,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      _row('Pet', a.pet?.name ?? a.petId),
                      _row('Data', _fmt(a.scheduledAt)),
                      _row('Cliente', a.clientId),
                      if (a.service != null)
                        _row('Valor',
                            'R\$ ${a.service!.price.toStringAsFixed(2)}'),
                      if (a.notes != null && a.notes!.isNotEmpty)
                        _row('Observações', a.notes!),
                    ],
                  ),
                ),
                const Spacer(),
                ..._actionButtons(a),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _actionButtons(Appointment a) {
    final notifier = context.read<AppointmentsNotifier>();
    if (a.status == 'PENDENTE') {
      return [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _runAction(
              notifier.confirm,
              'Solicitação aceita',
              AppTheme.statusConfirmado,
            ),
            child: const Text('✓  Aceitar'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _runAction(
              notifier.decline,
              'Solicitação recusada',
              AppTheme.statusCancelado,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.statusCancelado,
              side: const BorderSide(color: AppTheme.statusCancelado),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('✕  Recusar'),
          ),
        ),
      ];
    }
    if (a.status == 'CONFIRMADO') {
      return [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _runAction(
              notifier.complete,
              'Agendamento concluído',
              AppTheme.statusConcluido,
            ),
            child: const Text('✓  Concluir'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _runAction(
              notifier.decline,
              'Agendamento cancelado',
              AppTheme.statusCancelado,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.statusCancelado,
              side: const BorderSide(color: AppTheme.statusCancelado),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('✕  Cancelar'),
          ),
        ),
      ];
    }
    return const [];
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      );
}
