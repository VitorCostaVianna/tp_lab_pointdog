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

  static const List<List<Color>> _palettes = [
    [Color(0xFFFF6B35), Color(0xFFFFB347)],
    [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    [Color(0xFF22C55E), Color(0xFF16A34A)],
    [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
  ];

  static const List<IconData> _icons = [
    Icons.content_cut,
    Icons.shower_outlined,
    Icons.medical_services_outlined,
    Icons.fitness_center_outlined,
    Icons.spa_outlined,
  ];

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
                  Text('✂️', style: TextStyle(fontSize: 48)),
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
                final palette = _palettes[i % _palettes.length];
                final icon    = _icons[i % _icons.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ServiceCard(
                    name: s.name,
                    provider: s.providerName ?? 'Prestador',
                    durationMinutes: s.durationMinutes,
                    price: s.price,
                    palette: palette,
                    icon: icon,
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
  final List<Color> palette;
  final IconData icon;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.name,
    required this.provider,
    required this.durationMinutes,
    required this.price,
    required this.palette,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface2,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: palette[0].withAlpha(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      palette[0].withAlpha(50),
                      palette[1].withAlpha(50),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: palette[0], size: 26),
              ),
              const SizedBox(width: 14),
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
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.access_time_outlined,
                            size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 3),
                        Text(
                          '$durationMinutes min',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.person_outline,
                            size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            provider,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          palette[0].withAlpha(40),
                          palette[1].withAlpha(40),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'R\$${price.toStringAsFixed(0)}',
                      style: GoogleFonts.bricolageGrotesque(
                        color: palette[0],
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppTheme.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
