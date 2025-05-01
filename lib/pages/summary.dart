import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '/pages/base.dart';

class SummaryScreen extends StatefulWidget {
  final String deviceCategory;
  final List<String> extractedComponents;
  final Map<String, Map<String, String>> componentImages;

  const SummaryScreen({
    super.key,
    required this.deviceCategory,
    required this.extractedComponents,
    required this.componentImages,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  Map<String, Map<String, dynamic>>? _componentValues;

  @override
  void initState() {
    super.initState();
    _loadComponentValues();
  }

  Future<void> _loadComponentValues() async {
    try {
      // Normalize category name for file lookup
      // Make sure that your json file has a component_values node!
      final normalizedCategory = widget.deviceCategory.toLowerCase().replaceAll(' ', '_');
      final jsonPath = 'assets/${normalizedCategory}_instructions.json'; // Dynamic JSON loading based on e-waste category
      
      final String jsonString = await rootBundle.loadString(jsonPath); // Read JSON file contents
      final Map<String, dynamic> jsonData = json.decode(jsonString); // json.decode converts JSON string into Dart objects
      
      setState(() { // Updates state w/ loaded component values
        _componentValues = Map<String, Map<String, dynamic>>.from(
          jsonData['component_values'] as Map<String, dynamic> // Casts JSON data to a Map<String, dynamic>
        );
      });
    } catch (e) {
      print('Error loading component values for ${widget.deviceCategory}: $e');
    }
  }

  // Get images for a specific component
  List<String> _getComponentImages(String component) {
    List<String> images = []; // Create an empty list to store image paths
    for (var entry in widget.componentImages.entries) { // entry.key = source image path, entry.value = map of detected components
      for (var componentEntry in entry.value.entries) {
        if (componentEntry.key.toLowerCase().startsWith(component.toLowerCase())) { // Checks if component entry matches target component
          images.add(componentEntry.value);
        }
      }
    }
    return images;
  }

  void _showImageOverlay(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  color: Colors.black87,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.8,
                        maxWidth: MediaQuery.of(context).size.width * 0.9,
                      ),
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.file(
                          File(imagePath),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Counts how many times a component appears
  Map<String, int> _getComponentCounts() {
    Map<String, int> counts = {}; // Creates a list that stores the number of times a component appears
    for (String component in widget.extractedComponents) { // Loops through each component in the list
      // Get base component name by:
      // 1. Splitting on underscore (e.g., "ram_1" becomes ["ram", "1"])
      // 2. Taking first part [0]
      // 3. Converting to lowercase for consistent comparison
      String baseComponent = component.split('_')[0].toLowerCase();
      // Increment count for this component
      // ?? 0 provides default value of 0 if component doesn't exist in map yet
      // Then add 1 to current/default count
      counts[baseComponent] = (counts[baseComponent] ?? 0) + 1;
    }
    return counts;
  }

  // Get unique component types
  List<String> _getUniqueComponents() {
    return widget.extractedComponents
        .map((c) => c.split('_')[0].toLowerCase())
        .toSet()
        .toList();
  }

  // UI stuff
  @override
  Widget build(BuildContext context) {
    final componentCounts = _getComponentCounts();
    final uniqueComponents = _getUniqueComponents();
    
    // Calculate total estimated value before building UI
    double totalValue = 0;
    for (String component in uniqueComponents) {
      final values = _componentValues?[component.toLowerCase()];
      if (values != null && values['price'] != null) {
        totalValue += (values['price'] as double) * (componentCounts[component] ?? 1);
      }
    }

    return Base(
      title: 'Extraction Summary',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device info card
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF34A853), Color(0xFF0F9D58)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.deviceCategory,
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.extractedComponents.length} valuable components in your device',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Estimated Value',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '\₱${totalValue.toStringAsFixed(2)}',
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Components List
            ...uniqueComponents.map((component) {
              final values = _componentValues?[component.toLowerCase()] ?? 
                          {'price': 0.0, 'notes': 'No data available'};
              final count = componentCounts[component] ?? 1;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF34A853),
                    child: Icon(
                      _getIconForComponent(component),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    _formatComponentName(component),
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\₱${values['price'].toStringAsFixed(2)}',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF34A853),
                        ),
                      ),
                      Text(
                        'per piece (×$count)',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Component Images
                          if (_getComponentImages(component).isNotEmpty) ...[
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _getComponentImages(component).length,
                                itemBuilder: (context, index) {
                                  String imagePath = _getComponentImages(component)[index];
                                  return Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () => _showImageOverlay(context, imagePath),
                                      child: Container(
                                        width: 120,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(
                                            File(imagePath),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Notes section
                          Text(
                            values['notes'],
                            style: GoogleFonts.montserrat(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Helper method to get icons (copy from assistant.dart)
  IconData _getIconForComponent(String component) {
    switch (component.toLowerCase()) {
      case 'ram':
        return Icons.memory; // Memory stick icon
      case 'battery':
      case 'cmos':
        return Icons.battery_full; // Battery icon
      case 'fan':
      case 'cooler':
        return Icons.air; // Fan/air icon
      case 'wifi':
      case 'card':
        return Icons.wifi; // WiFi icon
      case 'drive':
      case 'hdd':
      case 'ssd':
      case 'disk':
        return Icons.storage; // Storage icon
      case 'cpu':
        return Icons.developer_board; // Circuit board icon
      case 'gpu':
        return Icons.videogame_asset; // Graphics/gaming icon
      case 'psu':
        return Icons.power; // Power icon
      case 'mboard':
        return Icons.dashboard; // Dashboard icon for motherboard
      case 'case':
        return Icons.computer; // Computer case icon
      default:
        return Icons.memory; // Default fallback icon
    }
  }

  // Helper method to format component names (copy from assistant.dart)
  String _formatComponentName(String name) {
    String firstPart = name.split('_')[0];
    return firstPart[0].toUpperCase() + firstPart.substring(1);
  }
}