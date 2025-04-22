import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'upload_or_camera.dart';
import 'base.dart';

class SelectEwaste extends StatelessWidget {
  const SelectEwaste({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive layout
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Base(
      title: 'Select E-Waste Type',
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.02),
            Text(
              'Select a device type below to get started with part extraction and recycling instructions.',
              style: GoogleFonts.robotoCondensed(
                fontSize: screenHeight * 0.022,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.03),
            Expanded(
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: screenWidth * 0.04,
                mainAxisSpacing: screenHeight * 0.02,
                children: [
                  _buildCategoryButton(context, 'Smartphone', Icons.smartphone),
                  _buildCategoryButton(context, 'Laptop', Icons.laptop_mac),
                  _buildCategoryButton(context, 'Desktop', Icons.desktop_windows),
                  _buildCategoryButton(context, 'Router', Icons.router),
                ],
              ),
            ),
            _buildFullWidthButton(context, 'Landline Phone', Icons.phone),
            SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(BuildContext context, String label, IconData icon) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
          MaterialPageRoute(builder: (context) => UploadOrCamera(category: label)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF34A853), Color(0xFF0F9D58)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              color: Colors.white, 
              size: screenHeight * 0.08,
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: screenHeight * 0.022,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullWidthButton(BuildContext context, String label, IconData icon) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
          MaterialPageRoute(builder: (context) => UploadOrCamera(category: label)),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF34A853), Color(0xFF0F9D58)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
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
            Icon(
              icon, 
              color: Colors.white, 
              size: screenHeight * 0.08,
            ),
            SizedBox(width: screenWidth * 0.03),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: screenHeight * 0.022,
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