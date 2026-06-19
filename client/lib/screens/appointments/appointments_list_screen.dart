import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/appointments_notifier.dart';

class AppointmentsListScreen extends StatefulWidget {
  const AppointmentsListScreen({super.key});
  @override
  State<AppointmentsListScreen> createState() =>
      _AppointmentsListScreenState();
}

class _AppointmentsListScreenState extends State<AppointmentsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppointmentsNotifier>().loadAll();
    });
  }

  String _fmtDate(DateTime dt) {
    const months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendamentos'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.statusConfirmado.withAlpha(20),
              border: Border.all(
                  color: AppTheme.statusConfirmado.withAlpha(55)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _PulseDot(),
                const SizedBox(width: 5),
                Text(
                  'ao vivo',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppTheme.statusConfirmado,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<AppointmentsNotifier>(
        builder: (_, notifier, __) {
          if (notifier.loading && notifier.appointments.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          }
          if (notifier.appointments.isEmpty) {
            return RefreshIndicator(
              onRefresh: notifier.loadAll,
              color: AppTheme.accent,
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_outlined,
                            size: 48, color: AppTheme.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'Nenhum agendamento ainda.',
                          style: TextStyle(color: AppTheme.textMuted),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Explore os serviços para começar.',
                          style: TextStyle(
                              color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: notifier.loadAll,
            color: AppTheme.accent,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: notifier.appointments.length,
              itemBuilder: (_, i) {
                final a = notifier.appointments[i];
                final color = statusColor(a.status);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: AppTheme.surface2,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => context.push('/appointments/${a.id}'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Row(
                            children: [
                              // Status left strip
                              Container(
                                width: 3,
                                height: 90,
                                color: color,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      14, 13, 14, 13),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header: service + date/time
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              a.service?.name ?? 'Serviço',
                                              style: GoogleFonts
                                                  .bricolageGrotesque(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: AppTheme.textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${_fmtDate(a.scheduledAt)} · ${_fmtTime(a.scheduledAt)}',
                                            style: GoogleFonts.dmMono(
                                              color: AppTheme.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      const TicketDivider(),
                                      const SizedBox(height: 10),
                                      // Stub: pet + status
                                      Row(
                                        children: [
                                          const Icon(Icons.pets_outlined,
                                              size: 12,
                                              color: AppTheme.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            a.pet?.name ?? 'Pet',
                                            style: const TextStyle(
                                              color: AppTheme.textMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 9, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: color.withAlpha(28),
                                              border: Border.all(
                                                  color: color.withAlpha(65)),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  statusLabel(a.status),
                                                  style: GoogleFonts.outfit(
                                                    color: color,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                Icon(
                                                  Icons.content_cut,
                                                  size: 10,
                                                  color: color.withAlpha(140),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _anim,
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: AppTheme.statusConfirmado,
            shape: BoxShape.circle,
          ),
        ),
      );
}
