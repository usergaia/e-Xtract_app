import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Base extends StatelessWidget {
  final String title;
  final Widget child;

  const Base({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 30, 30, 30), // Common background color
      appBar: AppBar(
        title: Text(title,
         style: GoogleFonts.montserrat(
            fontSize: 23,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF34A853), Color(0xFF0F9D58)],
            )
          )
        ),
        centerTitle: true,
      ),
      body: Center(child: child),
    );
  }
}