import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'upload_or_camera.dart';
import 'base.dart';

class SelectEwaste extends StatelessWidget {
  const SelectEwaste({super.key});

  @override
  Widget build(BuildContext context) {
    return Base(
      title: 'Select E-Waste Type',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
                'Select a device type below to get started with part extraction and recycling instructions.',
                style: GoogleFonts.robotoCondensed(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Flexible(
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildCategoryButton(context, 'Smartphone', Icons.smartphone),
                  _buildCategoryButton(context, 'Laptop', Icons.laptop_mac),
                  _buildCategoryButton(context, 'Desktop', Icons.desktop_windows),
                  _buildCategoryButton(context, 'Router', Icons.router),
                ],
              ),
            ),
            _buildFullWidthButton(context, 'Landline Phone', Icons.phone),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }


  Widget _buildCategoryButton(BuildContext context, String label, IconData icon) {
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
            Icon(icon, 
            color: Colors.white, 
            size: 90),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 20,
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
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
          MaterialPageRoute(builder: (context) => UploadOrCamera(category: label)),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
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
            Icon(icon, 
            color: Colors.white, 
            size: 90),
            const SizedBox(width: 10),
            Text(
              label,
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
