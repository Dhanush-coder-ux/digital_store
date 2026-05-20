import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../widgets/custom_bottom_bar.dart';
import '../theme/app_theme.dart';
import 'home_page.dart';
import 'stores_page.dart';
import 'cart_page.dart';
import 'profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static final ValueNotifier<int> pageIndexNotifier = ValueNotifier<int>(0);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomePage(),
    const StoresPage(),
    const CartPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    MainScreen.pageIndexNotifier.addListener(_onPageIndexChanged);
  }

  void _onPageIndexChanged() {
    setState(() {
      _currentIndex = MainScreen.pageIndexNotifier.value;
    });
  }

  @override
  void dispose() {
    MainScreen.pageIndexNotifier.removeListener(_onPageIndexChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          MainScreen.pageIndexNotifier.value = index;
        },
      ),
    );
  }
}
