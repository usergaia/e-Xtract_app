import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:extract_app/part_detection.dart';
import 'base.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  String _selectedCategory = '';
  bool _showCategorySelector = false;
  List<String> _detectedParts = [];
  Map<String, dynamic> _knowledgeBase = {};
  bool _showPartOptions = false;
  bool _hasDetectedParts = false;
  bool _imageUploaded = false;
  String? _lastImagePath;

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _addBotMessage("Hello! I'm your e-waste assistant. I can help you identify valuable parts in your electronic devices. What type of device do you have?");
    _showCategorySelector = true;
    _loadKnowledgeBase();
  }

  Future<void> _loadKnowledgeBase() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/knowledge-base.json');
      setState(() {
        _knowledgeBase = json.decode(jsonString);
      });
    } catch (e) {
      print("Error loading knowledge base: $e");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });
    
    // Scroll to bottom after message is added
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addBotMessage(String text) {
    _addMessage(text, false);
  }

  void _addUserMessage(String text) {
    _addMessage(text, true);
  }

  void _handlePredefinedResponse(String response) {
    _addUserMessage(response);
    
    // Process the predefined response
    if (response == "What parts can I extract?") {
      if (_selectedCategory.isNotEmpty) {
        _addBotMessage("Based on the image you uploaded, here are the parts I identified in your $_selectedCategory.");
      } else {
        _addBotMessage("Please select a device type first.");
        _showCategorySelector = true;
      }
    } else if (response == "How much are the parts worth?") {
      if (_selectedCategory.isNotEmpty) {
        _addBotMessage("I can provide an estimate of the value for each part. Select a part to see its value and more details.");
      } else {
        _addBotMessage("Please select a device type first.");
        _showCategorySelector = true;
      }
    } else if (response == "How do I recycle this device?") {
      if (_selectedCategory.isNotEmpty) {
        _addBotMessage("To properly recycle your $_selectedCategory, you can extract valuable parts first, then take the remaining components to a certified e-waste recycling center. Would you like to know how to extract specific parts?");
      } else {
        _addBotMessage("Please select a device type first.");
        _showCategorySelector = true;
      }
    } else if (response == "Change device type") {
      _selectedCategory = '';
      _showCategorySelector = true;
      _showPartOptions = false;
      _imageUploaded = false;
      _addBotMessage("Let's change your device type. What type of e-waste do you have?");
    } else if (_showPartOptions && (_detectedParts.contains(response) || response == "Camera" || response == "Battery")) {
      // Handle part extraction details
      _showPartExtractionDetails(response);
    }
  }

  void _showPartExtractionDetails(String partName) {
    if (_knowledgeBase.containsKey(_selectedCategory) && 
        _knowledgeBase[_selectedCategory].containsKey(partName)) {
      
      final partInfo = _knowledgeBase[_selectedCategory][partName];
      
      final value = partInfo['value'] ?? 'Unknown';
      final steps = partInfo['extraction_steps'] ?? [];
      final hazards = partInfo['hazards'] ?? [];
      final recyclingInfo = partInfo['recycling_info'] ?? 'No information available';
      
      String detailsMessage = "*$partName Details*\n\n";
      detailsMessage += "Value: $value\n\n";
      
      detailsMessage += "Extraction Steps:\n";
      for (int i = 0; i < steps.length; i++) {
        detailsMessage += "${i+1}. ${steps[i]}\n";
      }
      detailsMessage += "\n";
      
      detailsMessage += "Hazards:\n";
      for (final hazard in hazards) {
        detailsMessage += "• $hazard\n";
      }
      detailsMessage += "\n";
      
      detailsMessage += "Recycling Info: $recyclingInfo";
      
      _addBotMessage(detailsMessage);
      
      // Follow-up question
      _addBotMessage("Would you like to extract another part or get more information?");
    } else {
      _addBotMessage("I don't have detailed information about $partName for $_selectedCategory yet. Would you like to know about another part?");
    }
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _showCategorySelector = false;
      _hasDetectedParts = false;
      _showPartOptions = false;
      _imageUploaded = false;
    });
    _addBotMessage("Great! I can help identify valuable parts in your $category. Upload an image or take a photo to get started.");
  }

  Future<void> _getImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    
    try {
      final XFile? image = await picker.pickImage(source: source);
      
      if (image != null) {
        _lastImagePath = image.path;
        
        // Add image message
        setState(() {
          _messages.add(ChatMessage(
            text: '',
            isUser: true,
            timestamp: DateTime.now(),
            imagePath: image.path,
          ));
          _imageUploaded = true;
        });
        
        // Scroll to bottom
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
        
        // Processing message
        _addBotMessage("Processing your image...");
        
        // Navigate to part detection screen
        if (_selectedCategory.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PartDetectionScreen(
                category: _selectedCategory,
                imagePath: image.path,
              ),
            ),
          ).then((_) {
            // When returned from part detection, add a follow-up message
            if (_selectedCategory == 'Smartphone') {
              setState(() {
                _detectedParts = ['Camera', 'Battery', 'LCD Screen', 'Motherboard'];
                _hasDetectedParts = true;
                _showPartOptions = true;
              });
              _addBotMessage("I've analyzed your smartphone! I found these parts: Camera, Battery, LCD Screen, Motherboard. Which part would you like to extract first?");
            } else {
              _addBotMessage("I've analyzed your image. Unfortunately, I don't have detailed extraction information for this device type yet.");
            }
          });
        } else {
          _addBotMessage("Please select a device category first before uploading an image.");
          _showCategorySelector = true;
        }
      }
    } catch (e) {
      _addBotMessage("Sorry, there was an error processing your image. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Base(
      title: 'e-Waste Assistant',
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        body: Column(
          children: [
            // Chat messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildChatMessage(_messages[index]);
                },
              ),
            ),
            
            // Category selector
            if (_showCategorySelector)
              Container(
                height: 100,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildCategoryButton('Smartphone', Icons.smartphone),
                    _buildCategoryButton('Laptop', Icons.laptop_mac),
                    _buildCategoryButton('Desktop', Icons.desktop_windows),
                    _buildCategoryButton('Router', Icons.router),
                    _buildCategoryButton('Landline Phone', Icons.phone),
                  ],
                ),
              ),
              
            // Part options for smartphone
            if (_showPartOptions && _selectedCategory == 'Smartphone')
              Container(
                height: 55,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _detectedParts.map((part) => 
                    _buildPartButton(part)
                  ).toList(),
                ),
              ),
            
            // Predefined response buttons and actions container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Column(
                children: [
                  // Action buttons row
                  Row(
                    children: [
                      // Camera button
                      _buildIconButton(Icons.camera_alt, () => _getImage(ImageSource.camera)),
                      const SizedBox(width: 8),
                      
                      // Upload button
                      _buildIconButton(Icons.photo_library, () => _getImage(ImageSource.gallery)),
                      
                      const Spacer(),
                      
                      // Change device type button
                      _buildTextIconButton("Change device", Icons.refresh, () => 
                        _handlePredefinedResponse("Change device type")
                      ),
                    ],
                  ),
                  
                  // Only show these options after an image is uploaded
                  if (_imageUploaded) ...[
                    const SizedBox(height: 12),
                    
                    // Predefined responses grid
                    !_showPartOptions ? Row(
                      children: [
                        Expanded(
                          child: _buildResponseButton("What parts can I extract?", 
                            onTap: () => _handlePredefinedResponse("What parts can I extract?")),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildResponseButton("How much are the parts worth?", 
                            onTap: () => _handlePredefinedResponse("How much are the parts worth?")),
                        ),
                      ],
                    ) : const SizedBox.shrink(),
                    
                    !_showPartOptions ? const SizedBox(height: 8) : const SizedBox.shrink(),
                    
                    !_showPartOptions ? _buildResponseButton("How do I recycle this device?", 
                      onTap: () => _handlePredefinedResponse("How do I recycle this device?")
                    ) : const SizedBox.shrink(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar for bot messages
          if (!message.isUser)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.greenAccent, Colors.green],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 20,
              ),
            ),
          
          const SizedBox(width: 8),
          
          // Message content
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser ? const Color(0xFF34A853) : const Color(0xFF3A3A3A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(message.isUser ? 16 : 0),
                  topRight: Radius.circular(message.isUser ? 0 : 16),
                  bottomLeft: const Radius.circular(16),
                  bottomRight: const Radius.circular(16),
                ),
              ),
              child: message.imagePath != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(message.imagePath!),
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Image sent',
                          style: GoogleFonts.roboto(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  : SelectableText(
                      message.text,
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Avatar placeholder for user messages (for alignment)
          if (message.isUser)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, {Color color = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color == Colors.white ? const Color(0xFF3A3A3A) : color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildTextIconButton(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF3A3A3A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              text,
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseButton(String text, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF34A853), Color(0xFF0F9D58)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String category, IconData icon) {
    return GestureDetector(
      onTap: () => _selectCategory(category),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF34A853), Color(0xFF0F9D58)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              category.split(' ')[0],
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPartButton(String partName) {
    return GestureDetector(
      onTap: () => _handlePredefinedResponse(partName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF34A853),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          partName,
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imagePath;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imagePath,
  });
}