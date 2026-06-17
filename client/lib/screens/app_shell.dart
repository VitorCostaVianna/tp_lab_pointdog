import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/auth/auth_storage.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  bool get _isProvider => AuthStorage().role == 'PRESTADOR';

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (_isProvider) {
      if (location.startsWith('/provider/active')) return 1;
      if (location.startsWith('/provider/history')) return 2;
      if (location.startsWith('/provider/services')) return 3;
      return 0; // /provider/pending
    }
    if (location.startsWith('/appointments')) return 1;
    if (location.startsWith('/pets')) return 2;
    return 0; // /services
  }

  void _onTap(BuildContext context, int index) {
    if (_isProvider) {
      switch (index) {
        case 0:
          context.go('/provider/pending');
        case 1:
          context.go('/provider/active');
        case 2:
          context.go('/provider/history');
        case 3:
          context.go('/provider/services');
      }
      return;
    }
    switch (index) {
      case 0:
        context.go('/services');
      case 1:
        context.go('/appointments');
      case 2:
        context.go('/pets');
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _isProvider
        ? const [
            BottomNavigationBarItem(
              icon: Text('📥', style: TextStyle(fontSize: 22)),
              label: 'Pendentes',
            ),
            BottomNavigationBarItem(
              icon: Text('🔄', style: TextStyle(fontSize: 22)),
              label: 'Em Andamento',
            ),
            BottomNavigationBarItem(
              icon: Text('📜', style: TextStyle(fontSize: 22)),
              label: 'Histórico',
            ),
            BottomNavigationBarItem(
              icon: Text('🛠', style: TextStyle(fontSize: 22)),
              label: 'Serviços',
            ),
          ]
        : const [
            BottomNavigationBarItem(
              icon: Text('🐾', style: TextStyle(fontSize: 22)),
              label: 'Serviços',
            ),
            BottomNavigationBarItem(
              icon: Text('📅', style: TextStyle(fontSize: 22)),
              label: 'Agendamentos',
            ),
            BottomNavigationBarItem(
              icon: Text('🐶', style: TextStyle(fontSize: 22)),
              label: 'Pets',
            ),
          ];

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex(context),
        onTap: (index) => _onTap(context, index),
        items: items,
      ),
    );
  }
}
