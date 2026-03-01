import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'core/network/api_client.dart'; // ✅ ADD THIS IMPORT
import 'providers/auth_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/news_provider.dart';
import 'providers/ml_provider.dart';
import 'providers/forum_provider.dart';
import 'providers/shop_provider.dart';
import 'providers/language_provider.dart';
import 'providers/notification_provider.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }

  // ✅ CRITICAL FIX: load saved JWT token from SharedPreferences before app starts
  await ApiClient().init();

  await NotificationService().initialize();
  await NotificationService().requestPermissions();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
        ChangeNotifierProvider(create: (_) => MLProvider()),
        ChangeNotifierProvider(create: (_) => ForumProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(
          create: (_) => LanguageProvider()..loadLanguage(),
        ),
      ],
      child: _AppInit(),
    );
  }
}

class _AppInit extends StatefulWidget {
  @override
  State<_AppInit> createState() => _AppInitState();
}

class _AppInitState extends State<_AppInit> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final languageProvider = context.read<LanguageProvider>();
      final notificationProvider = context.read<NotificationProvider>();

      authProvider.setLanguageProvider(languageProvider);
      authProvider.setNotificationProvider(notificationProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Govi Sahaya',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
