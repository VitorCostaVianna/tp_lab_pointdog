import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/services_notifier.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String serviceId;
  const ServiceDetailScreen({super.key, required this.serviceId});
  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServicesNotifier>().loadById(widget.serviceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes')),
      body: Consumer<ServicesNotifier>(
        builder: (_, notifier, __) {
          if (notifier.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          }
          final s = notifier.selected;
          if (s == null) {
            return const Center(child: Text('Serviço não encontrado.'));
          }
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.name,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      'R\$',
                      style: TextStyle(
                        color: AppTheme.accentAmber,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      s.price.toStringAsFixed(0),
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.accentAmber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _detailCard([
                  _row('Duração', '${s.durationMinutes} minutos'),
                  _row('Prestador', s.providerName ?? s.providerId),
                ]),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    s.description,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => context.push('/appointments/new', extra: s),
                  child: const Text('📅  Agendar este serviço'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailCard(List<Widget> rows) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(children: rows),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
}
