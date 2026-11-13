import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'providers/transaction_provider.dart';
import 'config/supabase_config.dart';
import 'screens/splash_screen.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    debugPrint('[main] initializeDateFormatting error: $e');
  }
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('[main] SupabaseConfig.initialize error: $e');
  }
  runApp(const YotroApp());
}

class YotroApp extends StatelessWidget {
  const YotroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            title: 'Yotro',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: provider.themeMode,
            navigatorObservers: [routeObserver],
            home: const SplashScreen(),
            builder: (context, child) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final overlayStyle = SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
                statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
                systemNavigationBarColor: isDark ? AppColors.background : const Color(0xFFF4F5F7),
                systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
                systemNavigationBarDividerColor: Colors.transparent,
              );
              SystemChrome.setSystemUIOverlayStyle(overlayStyle);
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: overlayStyle,
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
