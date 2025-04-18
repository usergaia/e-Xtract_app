import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:extract_app/part_detection.dart';
import 'base.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  String _selectedCategory = '';
  bool _showCategorySelector = false;

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _addBotMessage("Hello! I'm your e-waste assistant. I can help you identify valuable parts in your electronic devices. What type of device do you have?");
    _showCategorySelector = true;
  }

  @override
  void dispose() {
    _messageController.dispose();
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

  void _handleSendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      _addUserMessage(text);
      _messageController.clear();
      
      // Simple rule-based responses
      _processUserMessage(text);
    }
  }

  void _processUserMessage(String text) {
    final lowercaseText = text.toLowerCase();
    
    // If category is already selected
    if (_selectedCategory.isNotEmpty) {
      if (lowercaseText.contains('part') || 
          lowercaseText.contains('detect') || 
          lowercaseText.contains('identify')) {
        _addBotMessage("I can help identify parts in your $_selectedCategory. Please upload an image or take a photo to get started.");
      } else if (lowercaseText.contains('value') || 
                lowercaseText.contains('worth') || 
                lowercaseText.contains('price')) {
        _addBotMessage("The value of parts in your $_selectedCategory depends on the specific components. Upload an image, and I'll help identify valuable parts.");
      } else if (lowercaseText.contains('recycle') || 
                lowercaseText.contains('dispose')) {
        _addBotMessage("To properly recycle your $_selectedCategory, first identify valuable parts that can be recovered. I can help with that. Would you like to upload an image?");
      } else if (lowercaseText.contains('help') || 
                lowercaseText.contains('how')) {
        _addBotMessage("I'm here to help you identify valuable parts in your $_selectedCategory. Upload a photo or take a picture, and I'll analyze it for you.");
      } else if (lowercaseText.contains('change') || 
                lowercaseText.contains('different') || 
                lowercaseText.contains('another')) {
        _selectedCategory = '';
        _showCategorySelector = true;
        _addBotMessage("Let's change your device type. What type of e-waste do you have?");
      } else {
        _addBotMessage("I'm not sure how to help with that. I can identify parts in your $_selectedCategory if you upload an image or take a photo.");
      }
    } else {
      // Handle category selection from text
      if (lowercaseText.contains('phone') || 
          lowercaseText.contains('smartphone') || 
          lowercaseText.contains('mobile')) {
        _selectedCategory = 'Smartphone';
        _showCategorySelector = false;
        _addBotMessage("Great! I can help with your smartphone. Upload an image or take a photo of your device to identify valuable parts.");
      } else if (lowercaseText.contains('laptop')) {
        _selectedCategory = 'Laptop';
        _showCategorySelector = false;
        _addBotMessage("I can help with your laptop. Upload an image or take a photo of your laptop to identify valuable parts.");
      } else if (lowercaseText.contains('desktop') || 
                lowercaseText.contains('computer')) {
        _selectedCategory = 'Desktop';
        _showCategorySelector = false;
        _addBotMessage("I can help with your desktop computer. Upload an image or take a photo to identify valuable parts.");
      } else if (lowercaseText.contains('router') || 
                lowercaseText.contains('modem')) {
        _selectedCategory = 'Router';
        _showCategorySelector = false;
        _addBotMessage("I can help with your router. Upload an image or take a photo to identify valuable parts.");
      } else if (lowercaseText.contains('landline')) {
        _selectedCategory = 'Landline Phone';
        _showCategorySelector = false;
        _addBotMessage("I can help with your landline phone. Upload an image or take a photo to identify valuable parts.");
      } else {
        _addBotMessage("I'm not sure what type of device you have. Please select a category below or type 'smartphone', 'laptop', 'desktop', 'router', or 'landline'.");
        _showCategorySelector = true;
      }
    }
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _showCategorySelector = false;
    });
    _addBotMessage("Great! I can help identify valuable parts in your $category. Upload an image or take a photo to get started.");
  }

  Future<void> _getImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    
    try {
      final XFile? image = await picker.pickImage(source: source);
      
      if (image != null) {
        // Add image message
        setState(() {
          _messages.add(ChatMessage(
            text: '',
            isUser: true,
            timestamp: DateTime.now(),
            imagePath: image.path,
          ));
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
            _addBotMessage("I've analyzed your image. Do you have any questions about the detected parts?");
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
            
            // Input area
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
              child: Row(
                children: [
                  // Camera button
                  _buildIconButton(Icons.camera_alt, () => _getImage(ImageSource.camera)),
                  
                  // Upload button
                  _buildIconButton(Icons.photo_library, () => _getImage(ImageSource.gallery)),
                  
                  // Text input
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A3A3A),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: GoogleFonts.roboto(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: GoogleFonts.roboto(color: Colors.white60),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _handleSendMessage(),
                      ),
                    ),
                  ),
                  
                  // Send button
                  _buildIconButton(Icons.send, _handleSendMessage, color: const Color(0xFF34A853)),
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
                  : Text(
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