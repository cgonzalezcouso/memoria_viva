import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/env.dart';
import '../../features/assistance/caregiver_dashboard_screen.dart';
import '../../features/assistance/daily_routine_screen.dart';
import '../../features/assistance/manage_care_screen.dart';
import '../../features/assistance/medication_reminder_screen.dart';
import '../../features/assistance/routines_hub_screen.dart';
import '../../features/auth/link_patient_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/profile_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/stimulation/attention_exercise_screen.dart';
import '../../features/stimulation/calculation_exercise_screen.dart';
import '../../features/stimulation/category_exercise_screen.dart';
import '../../features/stimulation/memory_game_screen.dart';
import '../../features/stimulation/orientation_exercise_screen.dart';
import '../../features/stimulation/sequence_exercise_screen.dart';
import '../../features/stimulation/stimulation_hub_screen.dart';
import '../../features/stimulation/emotion_exercise_screen.dart';
import '../../features/stimulation/intruder_exercise_screen.dart';
import '../../features/stimulation/recall_exercise_screen.dart';
import '../../features/stimulation/music_exercise_screen.dart';
import '../../features/stimulation/family_exercise_screen.dart';
import '../../features/stimulation/nature_exercise_screen.dart';
import '../../features/stimulation/kitchen_exercise_screen.dart';
import '../../features/stimulation/proverbs_exercise_screen.dart';
import '../../features/settings/accessibility_settings_screen.dart';
import '../../features/settings/supabase_settings_screen.dart';
import '../../features/settings/report_email_settings_screen.dart';
import '../../features/stimulation/weekly_report_screen.dart';
import '../models/user_role.dart';
import '../providers/auth_providers.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const register = '/registro';
  static const linkPatient = '/vincular';
  static const profile = '/perfil';
  static const accessibility = '/accesibilidad';
  static const supabaseSettings = '/configuracion/supabase';
  static const home = '/';
  static const stimulation = '/estimulacion';
  static const weeklyReport = '/estimulacion/informe';
  static const memoryGame = '/estimulacion/memoria';
  static const attention = '/estimulacion/atencion';
  static const orientation = '/estimulacion/orientacion';
  static const categories = '/estimulacion/categorias';
  static const sequences = '/estimulacion/secuencias';
  static const calculation = '/estimulacion/calculo';
  static const emotions = '/estimulacion/emociones';
  static const intruder = '/estimulacion/intruso';
  static const recall = '/estimulacion/recuerdo';
  static const music = '/estimulacion/musica';
  static const family = '/estimulacion/familia';
  static const nature = '/estimulacion/naturaleza';
  static const kitchen = '/estimulacion/cocina';
  static const proverbs = '/estimulacion/refranes';
  static const reportEmailSettings = '/informes/email';
  static const routines = '/rutinas';
  static const dailyRoutine = '/rutinas/diarias';
  static const medication = '/rutinas/medicacion';
  static const manageCare = '/rutinas/gestionar';
  static const caregiver = '/rutinas/cuidador';

  static const _publicRoutes = {login, register, supabaseSettings, accessibility};
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(routerRefreshProvider);

  ref.listen(authControllerProvider, (_, __) {
    refresh.notify();
  });

  return GoRouter(
    initialLocation: Env.isSupabaseConfigured ? AppRoutes.login : AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (!Env.isSupabaseConfigured) {
        return null;
      }

      final auth = ref.read(authControllerProvider);
      final isAuthRoute = AppRoutes._publicRoutes.contains(location);
      final isAuthenticated = auth.value?.isAuthenticated ?? false;

      if (auth.isLoading) {
        return null;
      }

      if (location == AppRoutes.linkPatient) {
        final role = auth.value?.profile?.role;
        if (!isAuthenticated || role != UserRole.caregiver) {
          return isAuthenticated ? AppRoutes.home : AppRoutes.login;
        }
      }

      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }

      final hasSession = auth.value?.session != null;
      final hasProfile = auth.value?.profile != null;

      if (hasSession && hasProfile && isAuthRoute && location != AppRoutes.accessibility) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.linkPatient,
        builder: (context, state) => const LinkPatientScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.accessibility,
        builder: (context, state) => const AccessibilitySettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.supabaseSettings,
        builder: (context, state) => const SupabaseSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.reportEmailSettings,
        builder: (context, state) => const ReportEmailSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.stimulation,
        builder: (context, state) => const StimulationHubScreen(),
      ),
      GoRoute(
        path: AppRoutes.weeklyReport,
        builder: (context, state) => const WeeklyReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.memoryGame,
        builder: (context, state) => const MemoryGameScreen(),
      ),
      GoRoute(
        path: AppRoutes.attention,
        builder: (context, state) => const AttentionExerciseScreen(),
      ),
      GoRoute(
        path: AppRoutes.orientation,
        builder: (context, state) => const OrientationExerciseScreen(),
      ),
      GoRoute(
        path: AppRoutes.categories,
        builder: (context, state) => const CategoryExerciseScreen(),
      ),
      GoRoute(
        path: AppRoutes.sequences,
        builder: (context, state) => const SequenceExerciseScreen(),
      ),
      GoRoute(
        path: AppRoutes.calculation,
        builder: (context, state) => const CalculationExerciseScreen(),
      ),
      GoRoute(
        path: AppRoutes.emotions,
        builder: (context, state) => const EmotionExerciseScreen(),
      ),
      GoRoute(
        path: AppRoutes.intruder,
        builder: (context, state) => const IntruderExerciseScreen(),
      ),
      GoRoute(
        path: AppRoutes.recall,
        builder: (context, state) => const RecallExerciseScreen(),
      ),
      GoRoute(
        path: AppRoutes.music,
        builder: (context, state) => const MusicExerciseScreen(),
      ),
      GoRoute(
        path: AppRoutes.family,
        builder: (context, state) => const FamilyExerciseScreen(),
      ),
      GoRoute(
        path: AppRoutes.nature,
        builder: (context, state) => const NatureExerciseScreen(),
      ),
      GoRoute(
        path: AppRoutes.kitchen,
        builder: (context, state) => const KitchenExerciseScreen(),
      ),
      GoRoute(
        path: AppRoutes.proverbs,
        builder: (context, state) => const ProverbsExerciseScreen(),
      ),
      GoRoute(
        path: AppRoutes.routines,
        builder: (context, state) => const RoutinesHubScreen(),
      ),
      GoRoute(
        path: AppRoutes.dailyRoutine,
        builder: (context, state) => const DailyRoutineScreen(),
      ),
      GoRoute(
        path: AppRoutes.medication,
        builder: (context, state) => const MedicationReminderScreen(),
      ),
      GoRoute(
        path: AppRoutes.manageCare,
        builder: (context, state) => const ManageCareScreen(),
      ),
      GoRoute(
        path: AppRoutes.caregiver,
        builder: (context, state) => const CaregiverDashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text('Página no encontrada')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('Volver al inicio'),
          ),
        ),
      );
    },
  );
});
