import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/appointments_notifier.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final String appointmentId;
  const AppointmentDetailScreen({super.key, required this.appointmentId});
  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
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

  Future<void> _cancel(AppointmentsNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface2,
        title: const Text('Cancelar agendamento'),
        content: const Text('Tem certeza?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sim',
              style: TextStyle(color: AppTheme.statusCancelado),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final ok = await notifier.cancel(widget.appointmentId);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agendamento cancelado'),
            backgroundColor: AppTheme.statusCancelado,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.statusConfirmado.withAlpha(25),
              border: Border.all(
                  color: AppTheme.statusConfirmado.withAlpha(60)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '● ao vivo',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppTheme.statusConfirmado,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Consumer<AppointmentsNotifier>(
        builder: (_, notifier, __) {
          if (notifier.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          }
          final a = notifier.selected;
          if (a == null) {
            return const Center(child: Text('Agendamento não encontrado.'));
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
                        // Status bar at top
                        Container(height: 3, color: color),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: service name + status
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
                                      border:
                                          Border.all(color: color.withAlpha(75)),
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

                        // Dashed divider (ticket stub line)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 18),
                          child: TicketDivider(),
                        ),

                        // Details (stub section)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                          child: Column(
                            children: [
                              _DetailRow(
                                label: 'Pet',
                                value: a.pet?.name ?? a.petId,
                              ),
                              const SizedBox(height: 10),
                              _DetailRow(
                                label: 'Data',
                                value: _fmt(a.scheduledAt),
                                mono: true,
                              ),
                              const SizedBox(height: 10),
                              _DetailRow(
                                label: 'Prestador',
                                value: a.service?.providerName ?? a.providerId,
                              ),
                              if (a.notes != null && a.notes!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                _DetailRow(
                                  label: 'Observações',
                                  value: a.notes!,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                if (a.canCancel)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _cancel(notifier),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.statusCancelado,
                        side: const BorderSide(color: AppTheme.statusCancelado),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancelar agendamento'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
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
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12,
          ),
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
