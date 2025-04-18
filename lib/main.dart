import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'select_ewaste.dart';
import 'chatbot_screen.dart'; // Import the ChatbotScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'e-Xtract',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.greenAccent, Colors.green],
                ).createShader(bounds),
                child: Text(
                  'e-Xtract',
                  style: GoogleFonts.montserrat(
                    fontSize: 58,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Identify and extract valuable components in your e-waste instantly.',
                style: GoogleFonts.robotoCondensed(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 350,
                child: PageView(
                  children: [
                    _buildSlide(
                      icon: Icons.document_scanner_rounded,
                      title: 'Scan',
                      subtitle: 'Analyze e-waste using your camera',
                    ),
                    _buildSlide(
                      icon: Icons.precision_manufacturing_rounded,
                      title: 'Extract',
                      subtitle: 'Identify components for recovery',
                    ),
                    _buildSlide(
                      icon: Icons.attach_money_rounded,
                      title: 'Profit',
                      subtitle: 'Discover the value of recovered parts',
                    ),
                    _buildSlide(
                      icon: Icons.chat_bubble_outline,
                      title: 'Get Help',
                      subtitle: 'Chat with our AI assistant',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              // Get Started button
              _buildButton(
                context: context,
                text: 'Get Started',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SelectEwaste()),
                  );
                },
              ),

              const SizedBox(height: 16),
              
              // Chat with Assistant button
              _buildButton(
                context: context,
                text: 'Chat with Assistant',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatbotScreen()),
                  );
                },
                icon: Icons.chat_bubble_outline,
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlide({required IconData icon, required String title, required String subtitle}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 110,
          width: 110,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(2, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 70,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.robotoCondensed(
            fontSize: 19,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildButton({
    required BuildContext context, 
    required String text, 
    required VoidCallback onTap, 
    IconData? icon
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF34A853), Color(0xFF0F9D58)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 24,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
            ],
            Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}