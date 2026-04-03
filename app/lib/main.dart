import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/app_config.dart';
import 'core/constants/app_constants.dart';
import 'di/injection.dart';
import 'features/rooms/presentation/providers/rooms_provider.dart';
import 'features/voice_control/presentation/providers/voice_control_provider.dart';
import 'pages/home_page.dart';

void main() {
  // Initialize dependency injection with default config
  Injection.init(AppConfig.defaultConfig);

  runApp(const LumosApp());
}

class LumosApp extends StatelessWidget {
  const LumosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => RoomsProvider(Injection.getRooms),
        ),
        ChangeNotifierProvider(
          create: (_) => VoiceControlProvider(
            Injection.recordAndSendCommand,
            Injection.stopRecording,
          ),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        ),
        themeMode: ThemeMode.system,
        home: const HomePage(),
      ),
    );
  }
}
