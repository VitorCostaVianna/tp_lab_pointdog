import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/appointments_notifier.dart';
import '../../providers/auth_notifier.dart';
import 'provider_appointment_card.dart';

class ProviderPendingScreen extends StatefulWidget {
  const ProviderPendingScreen({super.key});
  @override
  State<ProviderPendingScreen> createState() => _ProviderPendingScreenState();
}

class _ProviderPendingScreenState extends State<ProviderPendingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final n = context.read<AppointmentsNotifier>();
      if (n.appointments.isEmpty && !n.loading) n.loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitações Pendentes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => context.read<AuthNotifier>().logout(),
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
          final items = notifier.pending;
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: notifier.loadAll,
              child: ListView(
                children: [
                  const SizedBox(height: 100),
                  const Icon(Icons.inbox_outlined,
                      size: 48, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Nenhuma solicitação pendente.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Aguardando clientes agendarem serviços.',
                      style: TextStyle(
                          color: AppTheme.textMuted.withAlpha(140),
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: notifier.loadAll,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final a = items[i];
                return ProviderAppointmentCard(
                  appointment: a,
                  onTap: () => context.go('/provider/appointments/${a.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
