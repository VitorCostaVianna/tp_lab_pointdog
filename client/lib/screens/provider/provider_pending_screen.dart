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
      context.read<AppointmentsNotifier>().loadAll();
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
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'Nenhuma solicitação pendente.',
                      style: TextStyle(color: AppTheme.textMuted),
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
