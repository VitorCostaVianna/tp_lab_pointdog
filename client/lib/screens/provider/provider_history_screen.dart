import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/appointments_notifier.dart';
import '../../providers/auth_notifier.dart';
import 'provider_appointment_card.dart';

class ProviderHistoryScreen extends StatefulWidget {
  const ProviderHistoryScreen({super.key});
  @override
  State<ProviderHistoryScreen> createState() => _ProviderHistoryScreenState();
}

class _ProviderHistoryScreenState extends State<ProviderHistoryScreen> {
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
        title: const Text('Histórico'),
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
          final items = notifier.history;
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: notifier.loadAll,
              child: ListView(
                children: [
                  const SizedBox(height: 100),
                  const Icon(Icons.history_outlined,
                      size: 48, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Nenhum agendamento no histórico.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Agendamentos concluídos ou cancelados aparecerão aqui.',
                      style: TextStyle(
                          color: AppTheme.textMuted.withAlpha(140),
                          fontSize: 12),
                      textAlign: TextAlign.center,
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
              itemBuilder: (_, i) => ProviderAppointmentCard(
                appointment: items[i],
              ),
            ),
          );
        },
      ),
    );
  }
}
