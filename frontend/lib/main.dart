import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://osgqleoztvcbgngkfjfm.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9zZ3FsZW96dHZjYmduZ2tmamZtIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NzQ2OTM3MSwiZXhwIjoyMDkzMDQ1MzcxfQ.n6XaTZRW8RRrtXjbBVDxfjEGbno9JLr0odKNed3buPM',
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const GoaGreenApp());
}

class GoaGreenApp extends StatelessWidget {
  const GoaGreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoaGreen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}
