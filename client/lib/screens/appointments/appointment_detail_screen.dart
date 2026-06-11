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
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

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
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            return const Center(
                child: Text('Agendamento não encontrado.'));
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
                    Text(
                      a.service?.name ?? 'Serviço',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
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
                      _row('Prestador',
                          a.service?.providerName ?? a.providerId),
                      if (a.service != null)
                        _row('Valor',
                            'R\$ ${a.service!.price.toStringAsFixed(2)}'),
                      if (a.notes != null && a.notes!.isNotEmpty)
                        _row('Observações', a.notes!),
                    ],
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
                        side: const BorderSide(
                            color: AppTheme.statusCancelado),
                        minimumSize:
                            const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('✕  Cancelar agendamento'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
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
