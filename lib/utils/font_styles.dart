import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FontStyles {
  static TextStyle cityTextStyle = GoogleFonts.poppins(
    color: Colors.white,
    fontSize: 30,
    fontWeight: FontWeight.w500,
  );

  static TextStyle tempTextStyle = GoogleFonts.poppins(
    color: Colors.white,
    fontSize: 80,
    fontWeight: FontWeight.w200,
  );

  static TextStyle conditionTextStyle = GoogleFonts.poppins(
    color: Colors.white70,
    fontSize: 18,
  );

  static TextStyle sectionTitleStyle = GoogleFonts.openSans(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle labelTextStyle = TextStyle(
    color: Colors.white54,
    fontSize: 10,
  );

  static const TextStyle valueTextStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 13,
  );
}