import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/auth/auth_storage.dart';
import 'core/theme.dart';
import 'models/service.dart';
import 'providers/auth_notifier.dart';
import 'providers/services_notifier.dart';
import 'providers/pets_notifier.dart';
import 'providers/appointments_notifier.dart';
import 'screens/app_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/services/services_list_screen.dart';
import 'screens/services/service_detail_screen.dart';
import 'screens/services/create_appointment_screen.dart';
import 'screens/appointments/appointments_list_screen.dart';
import 'screens/appointments/appointment_detail_screen.dart';
import 'screens/pets/pets_screen.dart';
import 'screens/provider/provider_pending_screen.dart';
import 'screens/provider/provider_active_screen.dart';
import 'screens/provider/provider_history_screen.dart';
import 'screens/provider/provider_appointment_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthStorage().init();
  runApp(const PointDogApp());
}

class PointDogApp extends StatefulWidget {
  const PointDogApp({super.key});

  @override
  State<PointDogApp> createState() => _PointDogAppState();
}

class _PointDogAppState extends State<PointDogApp> {
  late final AuthNotifier _authNotifier;
  late final AppointmentsNotifier _appointmentsNotifier;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authNotifier = AuthNotifier();
    _appointmentsNotifier = AppointmentsNotifier();
    _appointmentsNotifier.startListening();

    _router = GoRouter(
      initialLocation: '/login',
      refreshListenable: _authNotifier,
      redirect: (context, state) {
        final loggedIn = _authNotifier.isLoggedIn;
        final isAuth = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';
        if (!loggedIn && !isAuth) return '/login';
        if (loggedIn && isAuth) {
          return AuthStorage().role == 'PRESTADOR'
              ? '/provider/pending'
              : '/services';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        ShellRoute(
          builder: (context, state, child) => AppShell(child: child),
          routes: [
            GoRoute(
              path: '/services',
              builder: (_, __) => const ServicesListScreen(),
            ),
            GoRoute(
              path: '/appointments',
              builder: (_, __) => const AppointmentsListScreen(),
            ),
            GoRoute(
              path: '/pets',
              builder: (_, __) => const PetsScreen(),
            ),
            GoRoute(
              path: '/provider/pending',
              builder: (_, __) => const ProviderPendingScreen(),
            ),
            GoRoute(
              path: '/provider/active',
              builder: (_, __) => const ProviderActiveScreen(),
            ),
            GoRoute(
              path: '/provider/history',
              builder: (_, __) => const ProviderHistoryScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/services/:id',
          builder: (_, state) =>
              ServiceDetailScreen(serviceId: state.pathParameters['id']!),
        ),
        // /appointments/new DEVE vir antes de /appointments/:id
        GoRoute(
          path: '/appointments/new',
          builder: (_, state) =>
              CreateAppointmentScreen(service: state.extra as Service),
        ),
        GoRoute(
          path: '/appointments/:id',
          builder: (_, state) => AppointmentDetailScreen(
              appointmentId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/provider/appointments/:id',
          builder: (_, state) => ProviderAppointmentDetailScreen(
              appointmentId: state.pathParameters['id']!),
        ),
      ],
    );

    _authNotifier.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authNotifier),
        ChangeNotifierProvider(create: (_) => ServicesNotifier()),
        ChangeNotifierProvider(create: (_) => PetsNotifier()),
        ChangeNotifierProvider.value(value: _appointmentsNotifier),
      ],
      child: MaterialApp.router(
        title: 'PointDog',
        theme: AppTheme.dark,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
