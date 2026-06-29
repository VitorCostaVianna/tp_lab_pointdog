import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/appointment.dart';

class ProviderAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onTap;

  const ProviderAppointmentCard({
    super.key,
    required this.appointment,
    this.onTap,
  });

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
    final a = appointment;
    final color = statusColor(a.status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
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
                      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: service + date/time
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  a.service?.name ?? 'Agendamento',
                                  style: GoogleFonts.bricolageGrotesque(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
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
                                  size: 12, color: AppTheme.textMuted),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  a.pet?.name ?? a.petId,
                                  style: const TextStyle(
                                      color: AppTheme.textMuted, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (a.clientName != null) ...[
                                const SizedBox(width: 6),
                                const Text('·',
                                    style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12)),
                                const SizedBox(width: 6),
                                const Icon(Icons.person_outline,
                                    size: 12, color: AppTheme.textMuted),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    a.clientName!,
                                    style: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(28),
                                  border:
                                      Border.all(color: color.withAlpha(65)),
                                  borderRadius: BorderRadius.circular(8),
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
                              if (onTap != null) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.chevron_right,
                                    size: 16, color: AppTheme.textMuted),
                              ],
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
  }
}
