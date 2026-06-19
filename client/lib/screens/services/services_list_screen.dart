import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_notifier.dart';
import '../../providers/services_notifier.dart';

class ServicesListScreen extends StatefulWidget {
  const ServicesListScreen({super.key});
  @override
  State<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends State<ServicesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServicesNotifier>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Serviços'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, size: 20),
            onPressed: () => context.read<AuthNotifier>().logout(),
            tooltip: 'Sair',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Consumer<ServicesNotifier>(
        builder: (_, notifier, __) {
          if (notifier.loading && notifier.services.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          }
          if (notifier.error != null && notifier.services.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppTheme.statusCancelado, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    notifier.error!,
                    style: const TextStyle(color: AppTheme.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: notifier.loadAll,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }
          if (notifier.services.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pets_outlined,
                      size: 48, color: AppTheme.textMuted),
                  SizedBox(height: 12),
                  Text(
                    'Nenhum serviço disponível.',
                    style: TextStyle(color: AppTheme.textMuted),
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
              itemCount: notifier.services.length,
              itemBuilder: (_, i) {
                final s = notifier.services[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ServiceCard(
                    name: s.name,
                    provider: s.providerName ?? 'Prestador',
                    durationMinutes: s.durationMinutes,
                    price: s.price,
                    onTap: () => context.push('/services/${s.id}'),
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

class _ServiceCard extends StatelessWidget {
  final String name;
  final String provider;
  final int durationMinutes;
  final double price;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.name,
    required this.provider,
    required this.durationMinutes,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppTheme.accent.withAlpha(15),
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
                // Left accent strip
                Container(
                  width: 3,
                  height: 76,
                  color: AppTheme.accent,
                ),
                const SizedBox(width: 14),
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withAlpha(18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.pets,
                    color: AppTheme.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_outlined,
                              size: 11, color: AppTheme.textMuted),
                          const SizedBox(width: 3),
                          Text(
                            '$durationMinutes min',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.person_outline,
                              size: 11, color: AppTheme.textMuted),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              provider,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Price
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    'R\$${price.toStringAsFixed(0)}',
                    style: GoogleFonts.dmMono(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
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
