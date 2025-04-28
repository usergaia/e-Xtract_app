import 'package:flutter/material.dart'; 
import '/pages/upload_or_camera.dart';
import '/pages/base.dart'; 


class Category extends StatelessWidget {
  const Category({super.key}); 

  @override
  Widget build(BuildContext context) {
    // Main UI of the screen
    return Base(
      title: 'Select E-Waste Type', // Title for the Base widget
      child: Padding(
        padding: const EdgeInsets.all(24.0), // Add space around the content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Center content horizontally
            children: [
            const Text(
              // Instructional text
              'Select a device type below to get started with part extraction and recycling instructions.',
              textAlign: TextAlign.center, // Center the text
              style: TextStyle(
              fontSize: 16, // Font size
              color: Colors.white70, // Light white text color
              height: 1.5, // Line spacing
              ),
            ),
            const SizedBox(height: 30), // Add vertical space

            // Grid layout with 2 columns for the 4 e-waste types
            GridView.count(
              shrinkWrap: true, // Let grid take only needed space
              physics: const NeverScrollableScrollPhysics(), // Disable scrolling in grid
              crossAxisCount: 2, // 2 columns
              crossAxisSpacing: 16, // Horizontal spacing
              mainAxisSpacing: 16, // Vertical spacing
              children: [
              // Each box is created using a helper method
              _buildDeviceCard(
                context: context,
                icon: Icons.smartphone, // Icon for smartphone
                label: 'Smartphone',
              ),
              _buildDeviceCard(
                context: context,
                icon: Icons.laptop, // Icon for laptop
                label: 'Laptop',
              ),
              _buildDeviceCard(
                context: context,
                icon: Icons.desktop_mac, // Icon for desktop
                label: 'Desktop',
              ),
              _buildDeviceCard(
                context: context,
                icon: Icons.router, // Icon for router
                label: 'Router',
              ),
              ],
            ),

            const SizedBox(height: 16), // Space before next button

            // A full-width button for Landline Phone option
            SizedBox(
              width: double.infinity, // Make button take full width
              height: 80, // Button height
              child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UploadPage(category: 'Landline'),
                ),
                );
              }, // Action when button is pressed
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CD97B), // Green background color
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), // Rounded corners
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // Center items inside button
                children: const [
                Icon(
                  Icons.call, // Icon for landline
                  color: Colors.white, // Icon color
                  size: 28, // Icon size
                ),
                SizedBox(width: 12), // Space between icon and text
                Text(
                  'Landline Phone', // Button label
                  style: TextStyle(
                  fontSize: 18, // Text size
                  fontWeight: FontWeight.bold, // Bold text
                  color: Colors.white, // White text color
                  ),
                ),
                ],
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // A reusable widget that creates a device card with icon, label and its functionalities
  Widget _buildDeviceCard({
    required BuildContext context, // Required context for UI
    required IconData icon, // Icon for the device
    required String label, // Label text for the device
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4CD97B), // Green background for card
        borderRadius: BorderRadius.circular(20), // Rounded corners
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UploadPage(category: label),
            ),
          );
        }, 
        
        borderRadius: BorderRadius.circular(20), // Ripple effect matches card shape
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
          children: [
            Icon(
              icon, // Icon passed as parameter
              color: Colors.white, // White icon color
              size: 40, // Icon size
            ),
            const SizedBox(height: 8), // Space between icon and text
            Text(
              label, // Label passed as parameter
              style: const TextStyle(
                color: Colors.white, // White text color
                fontSize: 16, // Font size
                fontWeight: FontWeight.bold, // Bold text
              ),
            ),
          ],
        ),
      ),
    );
  }
}
