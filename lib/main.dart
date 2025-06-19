import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Indian Flag Colors
    const saffron = Color(0xFFFF671F);
    const white = Color(0xFFFFFFFF);
    const green = Color(0xFF046A38);
    const ashokaBlue = Color(0xFF0D47A1); // Navy blue for AppBar

    return MaterialApp(
      title: 'JanSampark',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: white,
        primaryColor: saffron,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: saffron,
          secondary: green,
          background: white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: ashokaBlue,
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color>(
              (states) {
                if (states.contains(MaterialState.disabled)) {
                  return saffron.withOpacity(0.5);
                }
                return saffron;
              },
            ),
            foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: green, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.black),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: saffron,
          unselectedLabelColor: green,
          indicator: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFFF671F), width: 3),
            ),
          ),
        ),
      ),
      home: LoginPage(),
    );
  }
}

