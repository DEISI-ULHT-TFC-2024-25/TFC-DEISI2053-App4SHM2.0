import 'package:flutter/material.dart';

Future<ThemeData> darkTheme() async {
  return ThemeData(
    brightness: Brightness.dark,
    colorSchemeSeed: const Color(0xFF01dea0),
    useMaterial3: true,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
        backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFF01dea0)),
        elevation: MaterialStateProperty.all<double>(0),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      ),
    ),
  );
}

Future<ThemeData> lightTheme() async {
  return ThemeData(
    brightness: Brightness.light,
    colorSchemeSeed: const Color(0xFF01dea0),
    useMaterial3: true,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
        backgroundColor: MaterialStateProperty.all<Color>(const Color(0xFF01dea0)),
        elevation: MaterialStateProperty.all<double>(0),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      ),
    ),
  );
}