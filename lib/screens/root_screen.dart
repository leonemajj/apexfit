import 'package:flutter/material.dart';
import '../../core/palette.dart';
import '../dashboard/dashboard_screen.dart';
import '../meals/meals_screen.dart';
import '../workouts/workouts_screen.dart';
import '../weight/weight_screen.dart';
import '../profile/profile_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  final _pages = const [
    DashboardScreen(),
    MealsScreen(),
    WorkoutsScreen(),
    WeightScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppPalette.bg,
          border: Border(top: BorderSide(color: AppPalette.stroke.withOpacity(0.6))),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (v) => setState(() => _index = v),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'ホーム'),
            BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu_rounded), label: '食事プラン'),
            BottomNavigationBarItem(icon: Icon(Icons.fitness_center_rounded), label: 'ワークアウト'),
            BottomNavigationBarItem(icon: Icon(Icons.monitor_weight_rounded), label: '体重'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'プロフィール'),
          ],
        ),
      ),
    );
  }
}
