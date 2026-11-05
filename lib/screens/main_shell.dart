import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/bottom_nav_bar.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'budget_screen.dart';
import 'wallets_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'add_transaction_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  DateTime? _lastBackPressTime;
  final List<ScrollController> _tabControllers =
      List.generate(6, (_) => ScrollController());

  @override
  void dispose() {
    for (final controller in _tabControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      // Reset scroll position of target screen to top when entering
      if (_tabControllers[index].hasClients) {
        _tabControllers[index].jumpTo(0.0);
      }
      setState(() => _currentIndex = index);
    } else {
      // Tap active tab to scroll to top
      if (_tabControllers[index].hasClients) {
        _tabControllers[index].animateTo(
          0.0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        onNavigateTab: _onTabSelected,
        scrollController: _tabControllers[0],
      ),
      TransactionsScreen(scrollController: _tabControllers[1]),
      BudgetScreen(scrollController: _tabControllers[2]),
      WalletsScreen(scrollController: _tabControllers[3]),
      AnalyticsScreen(
        onNavigateTab: _onTabSelected,
        scrollController: _tabControllers[4],
      ),
      SettingsScreen(scrollController: _tabControllers[5]),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Requirement 5: If on another tab, return to Beranda first
        if (_currentIndex != 0) {
          _onTabSelected(0);
          return;
        }

        // If on Beranda, require second back press within 2s to exit
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tekan sekali lagi untuk keluar dari Yotro',
                style: GoogleFonts.manrope(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: isDark ? const Color(0xFF131A26) : const Color(0xFF0F172A),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 92),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          return;
        }

        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF1C2229) : const Color(0xFFF4F5F7),
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNavBar(
                currentIndex: _currentIndex,
                onIndexChanged: _onTabSelected,
                onAddTap: () {
                  Navigator.push(
                    context,
                    AddTransactionScreen.route(),
                  ).then((_) {
                    if (_tabControllers[_currentIndex].hasClients) {
                      _tabControllers[_currentIndex].jumpTo(0.0);
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
