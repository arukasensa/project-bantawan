// จุดเริ่มต้นการทำงานหลักของแอปพลิเคชัน BANTAWAN (Application Entry Point)
// รับผิดชอบการ Initialize บริการพื้นฐาน (Services), ลงทะเบียน State Providers ด้วย MultiProvider,
// กำหนดระบบหลายภาษา (Localization ไทย/อังกฤษ), และเปิดหน้าจอแรก (SplashScreen)

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter1/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter1/features/home/services/language_service.dart';
import 'package:flutter1/features/home/screens/splash_screen.dart';

import 'package:flutter1/providers/profile_provider.dart';

import 'package:flutter1/features/survival/services/device_health_service.dart';
import 'package:flutter1/features/weather/services/weather_service.dart';
import 'package:flutter1/features/chat/services/nearby_service.dart';
import 'package:flutter1/features/emergency/services/emergency_tool_service.dart';
import 'package:flutter1/features/emergency/services/safety_check_service.dart';
import 'package:flutter1/features/survival/services/hike_service.dart';
import 'package:flutter1/features/map/services/map_offline_service.dart';
import 'package:flutter1/features/home/services/connectivity_service.dart';
import 'package:flutter1/providers/map_provider.dart';

import 'package:flutter1/features/notifications/services/notification_service.dart';

/// ฟังก์ชันหลักที่ทำงานเป็นลำดับแรกเมื่อแอปเริ่มทำงาน
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // กำหนดค่าและเตรียมความพร้อมของบริการต่างๆ (Service Initialization)
  await DeviceHealthService().init();
  await WeatherService.init();
  await ConnectivityService().init();
  await NearbyService().init();
  await NotificationService.instance.init();

  final mapOfflineService = MapOfflineService();
  mapOfflineService.listenToConnectivity(ConnectivityService());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        // Singletons: MUST use .value to prevent Flutter from calling dispose()
        // on the shared static instance which would destroy audio, streams, etc.
        ChangeNotifierProvider.value(value: NearbyService()),
        ChangeNotifierProvider.value(value: EmergencyToolService()),
        ChangeNotifierProvider(create: (_) => SafetyCheckService()),
        ChangeNotifierProvider(create: (_) => HikeService()),
        ChangeNotifierProvider.value(value: mapOfflineService),
        ChangeNotifierProvider.value(value: ConnectivityService()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider.value(value: DeviceHealthService()),
        ChangeNotifierProvider.value(value: NotificationService.instance),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BANTAWAN',
      theme: ThemeData(
        primarySwatch: Colors.red,
        // ปิด Page Transition Animation ทั้งหมดเพื่อให้แอปเปลี่ยนหน้าแบบฉับไว ไร้รอยต่อ (Snappy & Tactical)
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _NoAnimationPageTransitionsBuilder(),
            TargetPlatform.iOS: _NoAnimationPageTransitionsBuilder(),
            TargetPlatform.windows: _NoAnimationPageTransitionsBuilder(),
            TargetPlatform.macOS: _NoAnimationPageTransitionsBuilder(),
            TargetPlatform.linux: _NoAnimationPageTransitionsBuilder(),
          },
        ),
      ),
      locale: languageProvider.appLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('th'), // Thai
      ],
      home: const SplashScreen(),
    );
  }
}

/// ⚡ ตัด Animation การเปลี่ยนหน้าทิ้ง เพื่อให้หน้าจอเปิดขึ้นมาทันทีโดยไม่มีดีเลย์
class _NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

