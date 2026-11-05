import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/transaction_provider.dart';
import 'screens/splash_screen.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
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
          );
        },
      ),
    );
  }
}
