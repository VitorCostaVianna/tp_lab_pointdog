import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/appointments')) return 1;
    if (location.startsWith('/pets')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex(context),
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/services');
            case 1:
              context.go('/appointments');
            case 2:
              context.go('/pets');
          }
        },
        items: const [
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
        ],
      ),
    );
  }
}
