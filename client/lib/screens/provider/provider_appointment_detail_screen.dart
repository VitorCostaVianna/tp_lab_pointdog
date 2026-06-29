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
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

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
                // Ticket card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.surface2,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 3, color: color),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      a.service?.name ?? 'Serviço',
                                      style: GoogleFonts.bricolageGrotesque(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: color.withAlpha(30),
                                      border: Border.all(
                                          color: color.withAlpha(75)),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      statusLabel(a.status),
                                      style: GoogleFonts.outfit(
                                        color: color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (a.service != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'R\$ ${a.service!.price.toStringAsFixed(2)}',
                                  style: GoogleFonts.dmMono(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.accent,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 18),
                          child: TicketDivider(),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                          child: Column(
                            children: [
                              _DetailRow(
                                  label: 'Pet',
                                  value: a.pet?.name ?? a.petId),
                              const SizedBox(height: 10),
                              _DetailRow(
                                label: 'Data',
                                value: _fmt(a.scheduledAt),
                                mono: true,
                              ),
                              const SizedBox(height: 10),
                              _DetailRow(
                                  label: 'Cliente',
                                  value: a.clientName ?? a.clientId),
                              if (a.notes != null &&
                                  a.notes!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                _DetailRow(
                                    label: 'Observações', value: a.notes!),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
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
            child: const Text('Aceitar'),
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
            child: const Text('Recusar'),
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
            child: const Text('Concluir'),
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
            child: const Text('Cancelar'),
          ),
        ),
      ];
    }
    return const [];
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const _DetailRow({
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        Flexible(
          child: Text(
            value,
            style: mono
                ? GoogleFonts.dmMono(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  )
                : const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
