import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'utils/app_theme.dart';
import 'utils/data_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize data store
  await DataStore.init();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.bgPrimary,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProductivitySuiteApp());
}

class ProductivitySuiteApp extends StatelessWidget {
  const ProductivitySuiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Productivity Suite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: AppTheme.accent,
          secondary: AppTheme.accent2,
          surface: AppTheme.bgCard,
          background: AppTheme.bgPrimary,
        ),
        scaffoldBackgroundColor: AppTheme.bgPrimary,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          bodyLarge: GoogleFonts.inter(color: AppTheme.textPrimary),
          bodyMedium: GoogleFonts.inter(color: AppTheme.textSecondary),
          titleLarge: GoogleFonts.inter(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        cardColor: AppTheme.bgCard,
        dividerColor: AppTheme.border,
        appBarTheme: AppBarTheme(
          backgroundColor: AppTheme.bgSecondary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
          iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppTheme.bgInput,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
          ),
          labelStyle: const TextStyle(color: AppTheme.textSecondary),
          hintStyle: const TextStyle(color: AppTheme.textMuted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppTheme.bgSecondary,
          selectedItemColor: AppTheme.accent2,
          unselectedItemColor: AppTheme.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
