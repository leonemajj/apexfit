import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/palette.dart';
import '../../services/meal_service.dart';
import '../../services/workout_service.dart';
import '../../services/weight_service.dart';
import '../../services/user_service.dart';
import '../../services/image_upload_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../meals/meal_list_screen.dart';
import '../workouts/workout_screen.dart';
import '../weights/weight_screen.dart';
import '../profile/profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    final pages = [
      DashboardScreen(
        mealService: MealService(client),
        workoutService: WorkoutService(client),
        weightService: WeightService(client),
        userService: UserService(client),
      ),
      MealListScreen(mealService: MealService(client), userService: UserService(client)),
      WorkoutScreen(workoutService: WorkoutService(client), userService: UserService(client)),
      WeightScreen(weightService: WeightService(client)),
      ProfileScreen(
        userService: UserService(client),
        imageUploadService: ImageUploadService(client),
      ),
    ];

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        backgroundColor: Palette.surface,
        indicatorColor: Palette.accent.withOpacity(0.14),
        selectedIndex: _index,
        onDestinationSelected: (v) => setState(() => _index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'ホーム'),
          NavigationDestination(icon: Icon(Icons.restaurant_menu), label: '食事プラン'),
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'ワークアウト'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: '体重'),
          NavigationDestination(icon: Icon(Icons.person), label: 'プロフィール'),
        ],
      ),
    );
  }
}
