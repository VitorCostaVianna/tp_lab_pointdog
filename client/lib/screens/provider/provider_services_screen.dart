import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_storage.dart';
import '../../core/theme.dart';
import '../../models/service.dart';
import '../../providers/services_notifier.dart';
import '../../providers/auth_notifier.dart';

class ProviderServicesScreen extends StatefulWidget {
  const ProviderServicesScreen({super.key});
  @override
  State<ProviderServicesScreen> createState() => _ProviderServicesScreenState();
}

class _ProviderServicesScreenState extends State<ProviderServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = AuthStorage().userId;
      if (userId != null) {
        context.read<ServicesNotifier>().loadMine(userId);
      }
    });
  }

  Future<void> _confirmDelete(Service service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface2,
        title: const Text('Remover serviço'),
        content: Text('Remover "${service.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remover',
              style: TextStyle(color: AppTheme.statusCancelado),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final notifier = context.read<ServicesNotifier>();
    final ok = await notifier.deleteService(service.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              ok ? 'Serviço removido.' : (notifier.error ?? 'Erro ao remover')),
          backgroundColor:
              ok ? AppTheme.statusConfirmado : AppTheme.statusCancelado,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Serviços'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => context.read<AuthNotifier>().logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/provider/services/new'),
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Consumer<ServicesNotifier>(
        builder: (_, notifier, __) {
          if (notifier.loading && notifier.myServices.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          }
          if (notifier.myServices.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => notifier.loadMine(AuthStorage().userId ?? ''),
              child: ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withAlpha(18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.content_cut_outlined,
                              size: 28, color: AppTheme.accent),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum serviço cadastrado.',
                          style: GoogleFonts.bricolageGrotesque(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Toque em + para adicionar.',
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
            onRefresh: () => notifier.loadMine(AuthStorage().userId ?? ''),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
              itemCount: notifier.myServices.length,
              itemBuilder: (_, i) {
                final s = notifier.myServices[i];
                return Dismissible(
                  key: ValueKey(s.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    await _confirmDelete(s);
                    return false;
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.statusCancelado.withAlpha(35),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: AppTheme.statusCancelado),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ServiceCard(
                      service: s,
                      onEdit: () => context.push(
                          '/provider/services/${s.id}/edit',
                          extra: s),
                      onDelete: () => _confirmDelete(s),
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

class _ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServiceCard({
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = service;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            // Left accent strip
            Container(
              width: 3,
              height: 84,
              color: AppTheme.accent,
            ),
            const SizedBox(width: 14),
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.accent.withAlpha(18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.content_cut_outlined,
                color: AppTheme.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.name,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.description,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Text(
                          'R\$${s.price.toStringAsFixed(0)}',
                          style: GoogleFonts.dmMono(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${s.durationMinutes} min',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit,
                  color: AppTheme.textMuted,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: onDelete,
                  color: AppTheme.statusCancelado,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
