import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
            icon: const Icon(Icons.logout, size: 20),
            onPressed: () => context.read<AuthNotifier>().logout(),
          ),
        ],
      ),
      body: Consumer<ServicesNotifier>(
        builder: (_, notifier, __) {
          if (notifier.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          }
          if (notifier.error != null) {
            return Center(
              child: Text(
                notifier.error!,
                style: const TextStyle(color: AppTheme.statusCancelado),
              ),
            );
          }
          if (notifier.services.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum serviço disponível.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifier.services.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final s = notifier.services[i];
              return InkWell(
                onTap: () => context.push('/services/${s.id}'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withAlpha(30),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text('✂️', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${s.durationMinutes} min · ${s.providerName ?? 'Prestador'}',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'R\$${s.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppTheme.accentAmber,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
