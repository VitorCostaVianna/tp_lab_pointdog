import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/auth/auth_storage.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  bool get _isProvider => AuthStorage().role == 'PRESTADOR';

  int _selectedIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (_isProvider) {
      if (loc.startsWith('/provider/active'))   return 1;
      if (loc.startsWith('/provider/history'))  return 2;
      if (loc.startsWith('/provider/services')) return 3;
      return 0;
    }
    if (loc.startsWith('/appointments')) return 1;
    if (loc.startsWith('/pets'))         return 2;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    if (_isProvider) {
      const routes = [
        '/provider/pending',
        '/provider/active',
        '/provider/history',
        '/provider/services',
      ];
      context.go(routes[index]);
      return;
    }
    const routes = ['/services', '/appointments', '/pets'];
    context.go(routes[index]);
  }

  List<NavigationDestination> _destinations() {
    if (_isProvider) {
      return const [
        NavigationDestination(
          icon: Icon(Icons.inbox_outlined),
          selectedIcon: Icon(Icons.inbox),
          label: 'Pendentes',
        ),
        NavigationDestination(
          icon: Icon(Icons.sync_outlined),
          selectedIcon: Icon(Icons.sync),
          label: 'Em andamento',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: 'Histórico',
        ),
        NavigationDestination(
          icon: Icon(Icons.design_services_outlined),
          selectedIcon: Icon(Icons.design_services),
          label: 'Serviços',
        ),
      ];
    }
    return const [
      NavigationDestination(
        icon: Icon(Icons.content_cut_outlined),
        selectedIcon: Icon(Icons.content_cut),
        label: 'Serviços',
      ),
      NavigationDestination(
        icon: Icon(Icons.event_outlined),
        selectedIcon: Icon(Icons.event),
        label: 'Agenda',
      ),
      NavigationDestination(
        icon: Icon(Icons.pets_outlined),
        selectedIcon: Icon(Icons.pets),
        label: 'Pets',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(context),
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: _destinations(),
      ),
    );
  }
}
