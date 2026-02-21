import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import '../services/meal_service.dart';
import '../services/workout_service.dart';
import '../services/user_service.dart';
import '../services/image_upload_service.dart';
import '../services/weight_service.dart';

import 'meal_list_screen.dart';
import 'workout_screen.dart';
import 'profile_screen.dart';
import 'weight_tracking_screen.dart';
import 'timer_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _currentUser;
  late final StreamSubscription<AuthState> _authStateSubscription;

  late final MealService _mealService;
  late final WorkoutService _workoutService;
  late final UserService _userService;
  late final ImageUploadService _imageUploadService;
  late final WeightService _weightService;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    _currentUser = supabase.auth.currentUser;

    _mealService = MealService(supabase);
    _workoutService = WorkoutService(supabase);
    _userService = UserService(supabase);
    _imageUploadService = ImageUploadService(supabase);
    _weightService = WeightService(supabase);

    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      setState(() {
        _currentUser = data.session?.user;
        if (_currentUser == null) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      });
    });
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

  final List<Widget> widgetOptions = <Widget>[
  _buildHomeDashboard(),
  const TimerScreen(),

  // ✅ 食事画面（AI対応）
  MealListScreen(
    mealService: _mealService,
    userService: _userService,
    supabase: supabase,
    flaskBaseUrl: _flaskBaseUrl,
  ),

  // ✅ ワークアウト画面（AI対応）
  WorkoutScreen(
    workoutService: _workoutService,
    userService: _userService,
    supabase: supabase,
    flaskBaseUrl: _flaskBaseUrl,
  ),

  WeightTrackingScreen(weightService: _weightService),
  ProfileScreen(
    userService: _userService,
    imageUploadService: _imageUploadService,
  ),
];


    return Scaffold(
      appBar: AppBar(
        title: const Text('APEXFIT'),
        centerTitle: false,
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.white54,
        backgroundColor: const Color(0xFF0B0B0D),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_rounded),
            label: '食事プラン',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_rounded),
            label: 'ワークアウト',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer_rounded),
            label: 'タイマー',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_weight_rounded),
            label: '体重',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'プロフィール',
          ),
        ],
      ),
    );
  }
}
