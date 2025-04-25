import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:extract_app/part_detection.dart';
import 'base.dart';

class ChatbotScreen extends StatefulWidget {
  final String initialCategory;
  final String? initialImagePath;
  final List<String> initialDetections;
  final Map<dynamic, dynamic>? initialComponentImages; // Add this line
  final List<int>? initialBatch; // Add this to fields


const ChatbotScreen({
  super.key,
  required this.initialCategory,
  this.initialImagePath,
  this.initialDetections = const [],
  this.initialComponentImages,
  this.initialBatch, // Add this
});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  Map<String, Map<String, String>> _componentImagesPerImage = {};
  String _selectedCategory = '';
  bool _showCategorySelector = false;
  List<String> _detectedParts = [];
  Map<String, dynamic> _knowledgeBase = {};
  bool _showPartOptions = false;
  bool _hasDetectedParts = false;
  bool _imageUploaded = false;
  List<String> _imagePaths = [];
  int _currentImageIndex = 0;
  Map<String, List<String>> _detectedPartsPerImage = {};
  Map<int, String> _processedImagePathsMap = {}; 
  List<List<int>> _uploadBatches = []; // Track images uploaded in batches

  @override
  void initState() {
    super.initState();

    // Set initial category
    _selectedCategory = widget.initialCategory;

    // Add welcome message
    _addBotMessage("Hello! I'm your e-waste assistant. I can help you identify and extract valuable parts from your ${widget.initialCategory}.");

    // Process all images and their associated data
    if (widget.initialComponentImages != null) {
      widget.initialComponentImages!.forEach((imagePath, components) {
        if (!_imagePaths.contains(imagePath)) {
          _imagePaths.add(imagePath);
          _detectedPartsPerImage[imagePath] = (components as Map).keys.toList().cast<String>();
          _componentImagesPerImage[imagePath] = Map<String, String>.from(components);

          // Add image message
          _messages.add(ChatMessage(
            text: '',
            isUser: true,
            timestamp: DateTime.now(),
            imagePath: imagePath,
            imageIndex: _imagePaths.indexOf(imagePath),
          ));

          // Add detection results for this image
          final detectedParts = _detectedPartsPerImage[imagePath] ?? [];
          if (detectedParts.isNotEmpty) {
            _addBotMessage("I've detected the following parts in your ${widget.initialCategory}: ${detectedParts.join(', ')}");

            // Add component images message if available
            if (_componentImagesPerImage[imagePath] != null) {
              _addComponentImagesMessage(_componentImagesPerImage[imagePath]!);
            }
          } else {
            _addBotMessage("I couldn't detect any components in your image. Try a clearer image or different angle.");
          }
        }
      });
    }

    // Register batch from UploadOrCamera if provided
    if (widget.initialBatch != null && widget.initialBatch!.isNotEmpty) {
      _uploadBatches.add(widget.initialBatch!);
    }

    _loadKnowledgeBase();
  }

  void _navigateImages(int currentIndex, int direction) {
    if (_imagePaths.isEmpty) return;
    
    // Find which batch this image belongs to
    int batchIndex = -1;
    List<int> currentBatch = [];
    
    for (int i = 0; i < _uploadBatches.length; i++) {
      if (_uploadBatches[i].contains(currentIndex)) {
        batchIndex = i;
        currentBatch = _uploadBatches[i];
        break;
      }
    }
    
    if (batchIndex == -1 || currentBatch.isEmpty) {
      // If not found in a batch, fallback to navigating all images
      int newIndex = (currentIndex + direction) % _imagePaths.length;
      if (newIndex < 0) newIndex = _imagePaths.length - 1;
      
      setState(() {
        _currentImageIndex = newIndex;
        _updateDisplayedParts(newIndex);
      });
      return;
    }
    
    // Navigate within the current batch only
    int currentPosInBatch = currentBatch.indexOf(currentIndex);
    int newPosInBatch = (currentPosInBatch + direction) % currentBatch.length;
    if (newPosInBatch < 0) newPosInBatch = currentBatch.length - 1;
    
    int newIndex = currentBatch[newPosInBatch];
    
    setState(() {
      _currentImageIndex = newIndex;
      _updateDisplayedParts(newIndex);
    });
  }
  
  // Helper to update displayed parts based on current image
  void _updateDisplayedParts(int imageIndex) {
    if (imageIndex >= 0 && imageIndex < _imagePaths.length) {
      String imagePath = _imagePaths[imageIndex];
      if (_detectedPartsPerImage.containsKey(imagePath)) {
        // Set parts to only those detected in the current image
        _detectedParts = List<String>.from(_detectedPartsPerImage[imagePath]!);
        _hasDetectedParts = _detectedParts.isNotEmpty;
        _showPartOptions = _hasDetectedParts;
      } else {
        _detectedParts = [];
        _hasDetectedParts = false;
        _showPartOptions = false;
      }
    }
  }

  void _showImageDetailsDialog(ChatMessage message) {
    if (message.imageIndex == null) return;
    int currentIdx = message.imageIndex!;
    
    // Find which batch this image belongs to
    List<int> currentBatch = [];
    for (var batch in _uploadBatches) {
      if (batch.contains(currentIdx)) {
        currentBatch = batch;
        break;
      }
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Get detected parts for the CURRENT image being viewed
            List<String> getPartsForCurrentImage() {
              try {
                if (currentIdx < _imagePaths.length) {
                  String currentImagePath = _imagePaths[currentIdx];
                  if (_detectedPartsPerImage.containsKey(currentImagePath)) {
                    return _detectedPartsPerImage[currentImagePath] ?? [];
                  }
                }
              } catch (e) {
                print("Error getting parts for image: $e");
              }
              return [];
            }
            
            // NEW - Get component images for the current image
            Map<String, String> getComponentImagesForCurrentImage() {
              try {
                if (currentIdx < _imagePaths.length) {
                  String currentImagePath = _imagePaths[currentIdx];
                  if (_componentImagesPerImage.containsKey(currentImagePath)) {
                    return _componentImagesPerImage[currentImagePath] ?? {};
                  }
                }
              } catch (e) {
                print("Error getting component images: $e");
              }
              return {};
            }
            
            // Get components for the current image index
            List<String> imageParts = getPartsForCurrentImage();
            Map<String, String> componentImages = getComponentImagesForCurrentImage();
            
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: double.maxFinite,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        automaticallyImplyLeading: false,
                        centerTitle: true,
                        title: Text(
                          message.isResult ? 'Detection Results' : 'Image ${currentIdx + 1}',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        bottom: TabBar(
                          tabs: [
                            Tab(text: 'Full Image'),
                            Tab(text: 'Components'),
                          ],
                          indicatorColor: Colors.green,
                          labelColor: Colors.white,
                        ),
                      ),
                      Flexible(
                        child: TabBarView(
                          children: [
                            // Tab 1: Full Image View
                            SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image with navigation overlay
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Display the image
                                      InteractiveViewer(
                                        minScale: 0.5,
                                        maxScale: 4.0,
                                        child: Image.file(
                                          File(message.isResult && _processedImagePathsMap.containsKey(currentIdx) 
                                              ? _processedImagePathsMap[currentIdx]!
                                              : _imagePaths[currentIdx]),
                                          width: double.infinity,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      
                                      // Navigation controls overlay
                                      if (currentBatch.length > 1)
                                        Positioned.fill(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              // Previous image button
                                              GestureDetector(
                                                onTap: () {
                                                  int curPos = currentBatch.indexOf(currentIdx);
                                                  int prevPos = (curPos - 1) % currentBatch.length;
                                                  if (prevPos < 0) prevPos = currentBatch.length - 1;
                                                  int prevIdx = currentBatch[prevPos];
                                                  
                                                  setDialogState(() {
                                                    currentIdx = prevIdx;
                                                    // Update parts list for this image
                                                    imageParts = getPartsForCurrentImage();
                                                    componentImages = getComponentImagesForCurrentImage();
                                                  });
                                                },
                                                child: Container(
                                                  margin: const EdgeInsets.only(left: 8),
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withOpacity(0.5),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.arrow_back_ios_new,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                              
                                              // Next image button
                                              GestureDetector(
                                                onTap: () {
                                                  int curPos = currentBatch.indexOf(currentIdx);
                                                  int nextPos = (curPos + 1) % currentBatch.length;
                                                  int nextIdx = currentBatch[nextPos];
                                                  
                                                  setDialogState(() {
                                                    currentIdx = nextIdx;
                                                    // Update parts list for this image
                                                    imageParts = getPartsForCurrentImage();
                                                    componentImages = getComponentImagesForCurrentImage();
                                                  });
                                                },
                                                child: Container(
                                                  margin: const EdgeInsets.only(right: 8),
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withOpacity(0.5),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.arrow_forward_ios,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  

                                ],
                              ),
                            ),
                            
                            // Tab 2: Component Images - NEW
                            SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (componentImages.isNotEmpty)
                                      ...componentImages.entries.map((entry) {
                                        final componentName = entry.key;
                                        final imagePath = entry.value;
                                        
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                componentName,
                                                style: GoogleFonts.roboto(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              GestureDetector(
                                                onTap: () {
                                                  try {
                                                    Navigator.pop(context); // First close the details dialog
                                                    _showFullScreenImageDialog(context, imagePath, title: componentName);
                                                  } catch (e) {
                                                    print("Error showing component image: $e");
                                                  }
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.green.withOpacity(0.5), width: 2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: Builder(
                                                      builder: (context) {
                                                        try {
                                                          if (File(imagePath).existsSync()) {
                                                            return Image.file(
                                                              File(imagePath),
                                                              width: double.infinity,
                                                              fit: BoxFit.contain,
                                                              errorBuilder: (ctx, error, stackTrace) {
                                                                return Container(
                                                                  width: double.infinity,
                                                                  height: 200,
                                                                  color: Colors.grey[800],
                                                                  child: const Center(
                                                                    child: Icon(Icons.broken_image, color: Colors.white, size: 50),
                                                                  ),
                                                                );
                                                              },
                                                            );
                                                          } else {
                                                            return Container(
                                                              width: double.infinity,
                                                              height: 200, 
                                                              color: Colors.grey[800],
                                                              child: const Center(
                                                                child: Text('Image not available', style: TextStyle(color: Colors.white70)),
                                                              ),
                                                            );
                                                          }
                                                        } catch (e) {
                                                          print("Error displaying image: $e");
                                                          return Container(
                                                            width: double.infinity,
                                                            height: 200,
                                                            color: Colors.grey[800],
                                                            child: const Center(
                                                              child: Icon(Icons.error_outline, color: Colors.red, size: 40),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              const Divider(color: Colors.white24),
                                            ],
                                          ),
                                        );
                                      }).toList()
                                    else
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 30.0),
                                          child: Column(
                                            children: [
                                              const Icon(Icons.crop_free, color: Colors.white38, size: 48),
                                              const SizedBox(height: 16),
                                              Text(
                                                'No component images available',
                                                style: GoogleFonts.roboto(
                                                  color: Colors.white70,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF34A853),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Container(
                            width: double.infinity,
                            alignment: Alignment.center,
                            child: Text(
                              'Close',
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
    List<XFile> selectedImages = [];
    
    if (source == ImageSource.gallery) {
      final List<XFile>? images = await picker.pickMultiImage();
      if (images == null || images.isEmpty) return;
      selectedImages = images;
    } else {
      final XFile? image = await picker.pickImage(source: source);
      if (image == null) return;
      selectedImages = [image];
    }
    
    // Create a new batch to track these images
    List<int> newBatch = [];
    
    // Add initial processing message for multiple images
    if (selectedImages.length > 1) {
      _addBotMessage("Processing ${selectedImages.length} images...");
    }
    
    // Process each selected image
    for (int i = 0; i < selectedImages.length; i++) {
      var image = selectedImages[i];
      final String imagePath = image.path;
      final int imageIndex = _imagePaths.length;

      // Add this image index to the current batch
      newBatch.add(imageIndex);

      setState(() {
        _imagePaths.add(imagePath);
        _currentImageIndex = imageIndex;

        // Add image message
        _messages.add(ChatMessage(
          text: selectedImages.length > 1 ? 'Image ${i + 1}' : '',
          isUser: true,
          timestamp: DateTime.now(),
          imagePath: imagePath,
          imageIndex: imageIndex,
        ));
        _imageUploaded = true;
      });

      _scrollToBottom();

      // Add per-image processing message
      _addBotMessage("Processing image ${i + 1} of ${selectedImages.length}...");

      // Process the image if a category is selected
      if (_selectedCategory.isNotEmpty) {
        try {
          final result = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(
              builder: (context) => PartDetectionScreen(
                category: _selectedCategory,
                imagePath: imagePath,
              ),
            ),
          );

          if (result != null) {
            // Extract data from the result map
            final processedImagePath = result['imagePath'] as String;
            final List<dynamic> detectedComponentsRaw = result['detectedComponents'] as List<dynamic>? ?? [];
            final List<String> detectedParts = detectedComponentsRaw.cast<String>();

            // Extract cropped component images
            final Map<dynamic, dynamic>? croppedImagesRaw = result['croppedComponentImages'] as Map<dynamic, dynamic>?;
            Map<String, String> croppedImages = {};
            if (croppedImagesRaw != null) {
              croppedImagesRaw.forEach((key, value) {
                croppedImages[key.toString()] = value.toString();
              });
              _componentImagesPerImage[imagePath] = croppedImages;
            }

            // Store processed image path mapped to its index for navigation
            _processedImagePathsMap[imageIndex] = processedImagePath;

            setState(() {
              // Store the detected parts specifically for this image
              _detectedPartsPerImage[imagePath] = detectedParts;

              // Only update the current parts if we're still looking at this image
              if (_currentImageIndex == imageIndex) {
                _detectedParts = List<String>.from(detectedParts);
                _hasDetectedParts = detectedParts.isNotEmpty;
                _showPartOptions = _hasDetectedParts;
              }
            });

            // Add a message for this image's detected components
            if (detectedParts.isNotEmpty) {
              _addBotMessage("I've analyzed image ${i + 1} of ${selectedImages.length}! Detected parts: ${detectedParts.join(', ')}");

              // Add a message with the cropped component images
              if (croppedImages.isNotEmpty) {
                _addComponentImagesMessage(croppedImages);
              }
            } else {
              _addBotMessage("I've analyzed image ${i + 1} of ${selectedImages.length}, but couldn't detect any components. Try a clearer image or different angle.");
            }

            // Add result message with the processed image
            _messages.add(ChatMessage(
              text: "Analysis results for image ${i + 1}",
              isUser: false,
              timestamp: DateTime.now(),
              imagePath: processedImagePath,
              imageIndex: imageIndex,
              isResult: true,
              detectedParts: List<String>.from(detectedParts),
            ));

            _scrollToBottom();
          }
        } catch (e) {
          print("Error processing image $i: $e");
          _addBotMessage("Error processing image ${i + 1}. Please try again.");
        }
      }
    }
    
    // Add this batch to our tracking once, after processing all images
    if (newBatch.isNotEmpty) {
      _uploadBatches.add(newBatch);
    }
    
    // Add summary message for multiple images
    if (selectedImages.length > 1) {
      _addBotMessage("All ${selectedImages.length} images have been processed. You can view the results by tapping on each image.");
    }
    
    if (_selectedCategory.isEmpty) {
      _addBotMessage("Please select a device category first before uploading images.");
      _showCategorySelector = true;
    }
  } catch (e) {
    print("Error processing images: $e");
    _addBotMessage("Sorry, there was an error processing your images. Please try again.");
  }
}

void _scrollToBottom() {
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

void _addComponentImagesMessage(Map<String, String> componentImages) {
  setState(() {
    _messages.add(ChatMessage(
      text: "Here are the components I detected:",
      isUser: false,
      timestamp: DateTime.now(),
      componentImages: componentImages,
    ));
  });
  
  _scrollToBottom();
}

// Add a new method to show a full-screen image popup
void _showFullScreenImageDialog(BuildContext context, String imagePath, {String? title, bool isComponentImage = false, bool isUserImage = false}) {
  if (!mounted) return;
  
  try {
    // Find out if this image is part of a component images collection
    // And which image index it has
    bool isComponent = isComponentImage;
    String? parentImagePath;
    Map<String, String> siblingComponentImages = {};
    String currentComponentName = title ?? 'Image';
    
    // Check if this is a component image
    for (var entry in _componentImagesPerImage.entries) {
      if (entry.value.containsValue(imagePath)) {
        isComponent = true;
        parentImagePath = entry.key;
        siblingComponentImages = Map<String, String>.from(entry.value);
        
        // Find the component name for this image
        for (var component in entry.value.entries) {
          if (component.value == imagePath) {
            currentComponentName = component.key;
            break;
          }
        }
        break;
      }
    }
    
    // Determine if we are viewing regular images or component images
    List<String> currentImageList = [];
    int currentIndex = 0;
    
    if (isComponent && siblingComponentImages.isNotEmpty) {
      // We're viewing component images
      currentImageList = siblingComponentImages.values.toList();
      currentIndex = currentImageList.indexOf(imagePath);
    } else {
      // We're viewing regular chat images
      currentImageList = _imagePaths;
      currentIndex = _imagePaths.indexOf(imagePath);
      
      // If not found in main images, check processed images
      if (currentIndex == -1) {
        for (var entry in _processedImagePathsMap.entries) {
          if (entry.value == imagePath) {
            currentIndex = entry.key;
            break;
          }
        }
      }
    }
    
    // If still not found, default to 0
    if (currentIndex == -1) currentIndex = 0;
    
    // Check if file exists
    final file = File(imagePath);
    bool fileExists = false;
    try {
      fileExists = file.existsSync();
    } catch (e) {
      print("Error checking if file exists: $e");
    }
    
    // Get component images for this image if it's not a component image itself
    Map<String, String> componentImages = {};
    if (!isComponentImage && _imagePaths.contains(imagePath)) {
      componentImages = _componentImagesPerImage[imagePath] ?? {};
    }
    
    Future.microtask(() {
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.9),
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              // Function to load the current image
              Widget buildCurrentImage() {
                final currentPath = currentImageList[currentIndex];
                final currentFile = File(currentPath);
                final exists = currentFile.existsSync();
                
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: exists
                    ? Image.file(
                        currentFile,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, error, stackTrace) {
                          return Container(
                            color: Colors.black,
                            child: const Center(
                              child: Icon(Icons.broken_image, color: Colors.white, size: 64),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.black,
                        child: const Center(
                          child: Text(
                            'Image not found',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ),
                );
              }
              
              // Get component images for the current image if not viewing a component
              Map<String, String> getCurrentComponentImages() {
                if (isComponentImage) return {};
                
                String currentPath = currentImageList[currentIndex];
                return _componentImagesPerImage[currentPath] ?? {};
              }
              
              // Get the title for the current image
              String getCurrentTitle() {
                if (isComponentImage) {
                  // Find the component name for the current image
                  String name = 'Component';
                  for (var entry in siblingComponentImages.entries) {
                    if (entry.value == currentImageList[currentIndex]) {
                      name = entry.key;
                      break;
                    }
                  }
                  return name;
                } else {
                  // For regular images
                  return title ?? 'Image ${currentIndex + 1}';
                }
              }
              
              // Function to navigate images
              void navigateImage(int direction) {
                int newIndex = (currentIndex + direction) % currentImageList.length;
                if (newIndex < 0) newIndex = currentImageList.length - 1;
                
                setDialogState(() {
                  currentIndex = newIndex;
                });
              }
              
              return Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: EdgeInsets.zero,
                child: Stack(
                  children: [
                    // Main content - Scrollable to accommodate both main image and component images
                    SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Safe area for top
                          SizedBox(height: MediaQuery.of(context).padding.top + 50),
                          
                          // Main image container with navigation
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Main image
                              Container(
                                width: MediaQuery.of(context).size.width,
                                constraints: BoxConstraints(
                                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                                ),
                                alignment: Alignment.center,
                                child: buildCurrentImage(),
                              ),
                              
                              // Navigation buttons (only if more than one image)
                            ],
                          ),
                          
                          // Component images section (if available and not viewing a component)
                          if (!isComponentImage) ...[
                            Builder(
                              builder: (context) {
                                final components = getCurrentComponentImages();
                                if (components.isEmpty) return const SizedBox.shrink();
                                
                                return Container(
                                  margin: const EdgeInsets.only(top: 16),
                                  padding: const EdgeInsets.all(16),
                                  width: double.infinity,
                                  color: Colors.black.withOpacity(0.5),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 12),
                                      GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                          childAspectRatio: 0.8,
                                        ),
                                        itemCount: components.length,
                                        itemBuilder: (context, index) {
                                          final componentName = components.keys.elementAt(index);
                                          final componentPath = components[componentName]!;
                                          
                                          return GestureDetector(
                                            onTap: () {
                                              // Close this dialog and open component in fullscreen
                                              Navigator.of(dialogContext).pop();
                                              _showFullScreenImageDialog(context, componentPath, title: componentName);
                                            },
                                            child: Column(
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: Colors.green, width: 2),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(6),
                                                      child: Builder(
                                                        builder: (ctx) {
                                                          try {
                                                            if (File(componentPath).existsSync()) {
                                                              return Image.file(
                                                                File(componentPath),
                                                                fit: BoxFit.cover,
                                                                errorBuilder: (ctx, error, stackTrace) {
                                                                  return const Center(
                                                                    child: Icon(Icons.broken_image, color: Colors.white, size: 30),
                                                                  );
                                                                },
                                                              );
                                                            } else {
                                                              return const Center(
                                                                child: Icon(Icons.image_not_supported, color: Colors.white, size: 30),
                                                              );
                                                            }
                                                          } catch (e) {
                                                            return const Center(
                                                              child: Icon(Icons.error, color: Colors.red, size: 30),
                                                            );
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  componentName,
                                                  style: GoogleFonts.roboto(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                          
                          // Bottom space
                          const SizedBox(height: 70),
                        ],
                      ),
                    ),
                    
                    // Title bar at top - updated to be dynamic
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 10,
                          bottom: 10,
                          left: 20,
                          right: 20,
                        ),
                        color: Colors.black.withOpacity(0.7),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                getCurrentTitle(),
                                style: GoogleFonts.roboto(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(dialogContext).pop(),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 24),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Close button at bottom center
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () => Navigator.of(dialogContext).pop(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34A853),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              'Close',
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    });
  } catch (e) {
    print("Error in _showFullScreenImageDialog: $e");
  }
}

// Modify the existing _showComponentImageDialog method to use the new fullscreen method
void _showComponentImageDialog(BuildContext context, String componentName, String imagePath) {
  _showFullScreenImageDialog(context, imagePath, title: componentName);
}

  @override
  Widget build(BuildContext context) {
    return Base(
      title: 'e-Waste Assistant',
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E1E),
        body: Column(
          children: [
            Expanded( // Ensure the chat messages take up available space without causing overflow
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildChatMessage(_messages[index]);
                },
              ),
            ),
            if (_showPartOptions && _selectedCategory == 'Smartphone')
              Container(
                height: 55,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _detectedParts.map((part) => _buildPartButton(part)).toList(),
                ),
              ),
            SingleChildScrollView( // Wrap the predefined response buttons to prevent overflow
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildIconButton(Icons.camera_alt, () => _getImage(ImageSource.camera)),
                        const SizedBox(width: 8),
                        _buildIconButton(Icons.photo_library, () => _getImage(ImageSource.gallery)),
                        const Spacer(),
                        _buildTextIconButton("Change device", Icons.refresh, () =>
                          _handlePredefinedResponse("Change device type")),
                      ],
                    ),
                    if (_imageUploaded) ...[
                      const SizedBox(height: 12),
                      if (!_showPartOptions)
                        Row(
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
                        ),
                      if (!_showPartOptions) const SizedBox(height: 8),
                      if (!_showPartOptions)
                        _buildResponseButton("How do I recycle this device?",
                          onTap: () => _handlePredefinedResponse("How do I recycle this device?")),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildChatMessage(ChatMessage message) {
  // Find batch information outside the widget tree
  List<int> currentBatch = [];
  int currentPosInBatch = -1;
  
  if (message.imageIndex != null) {
    for (var batch in _uploadBatches) {
      if (batch.contains(message.imageIndex!)) {
        currentBatch = batch;
        currentPosInBatch = currentBatch.indexOf(message.imageIndex!);
        break;
      }
    }
  }
  
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text content
                if (message.text.isNotEmpty)
                  SelectableText(
                    message.text,
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                
                // Main image - UPDATED to show processed image with bounding boxes for results
                if (message.imagePath != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      if (message.isResult) {
                        // Use improved dialog for result images to show detected components
                        String imagePath = message.imagePath!;
                        
                        // Use processed image with bounding boxes
                        if (message.imageIndex != null && _processedImagePathsMap.containsKey(message.imageIndex!)) {
                          imagePath = _processedImagePathsMap[message.imageIndex!]!;
                        }
                        
                        // Find detected parts for this image
                        List<String> detectedParts = [];
                        if (message.imageIndex != null && message.imageIndex! < _imagePaths.length) {
                          String originalImagePath = _imagePaths[message.imageIndex!];
                          detectedParts = _detectedPartsPerImage[originalImagePath] ?? [];
                        }
                        
                        // Get component images for this image
                        Map<String, String> componentImages = {};
                        if (message.imageIndex != null && message.imageIndex! < _imagePaths.length) {
                          String originalImagePath = _imagePaths[message.imageIndex!];
                          componentImages = _componentImagesPerImage[originalImagePath] ?? {};
                        }
                        
                        // Find current batch for navigation
                        List<int> currentBatch = [];
                        int currentPosInBatch = -1;
                        if (message.imageIndex != null) {
                          for (var batch in _uploadBatches) {
                            if (batch.contains(message.imageIndex!)) {
                              currentBatch = batch;
                              currentPosInBatch = currentBatch.indexOf(message.imageIndex!);
                              break;
                            }
                          }
                        }
                        
                        showDialog(
                          context: context,
                          builder: (dialogContext) => StatefulBuilder(
                            builder: (context, setDialogState) {
                              // Current image index for navigation
                              int currentIdx = message.imageIndex ?? 0;
                              
                              void navigateToImage(int direction) {
                                if (currentBatch.isEmpty) return;
                                
                                int newPos = (currentPosInBatch + direction) % currentBatch.length;
                                if (newPos < 0) newPos = currentBatch.length - 1;
                                int newIdx = currentBatch[newPos];
                                
                                // Update the current image and parts
                                String newImagePath = _processedImagePathsMap[newIdx] ?? _imagePaths[newIdx];
                                String originalImagePath = _imagePaths[newIdx];
                                List<String> newParts = _detectedPartsPerImage[originalImagePath] ?? [];
                                Map<String, String> newComponentImages = _componentImagesPerImage[originalImagePath] ?? {};
                                
                                setDialogState(() {
                                  currentIdx = newIdx;
                                  imagePath = newImagePath;
                                  detectedParts = newParts;
                                  componentImages = newComponentImages;
                                  currentPosInBatch = newPos;
                                });
                              }
                              
                              return Dialog(
                                backgroundColor: Colors.transparent,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A2A2A),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Header with close button
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Analysis Results',
                                                  style: GoogleFonts.roboto(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Image with navigation
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // Image
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.file(
                                                  File(imagePath),
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                            
                                            // Navigation buttons
                                            if (currentBatch.length > 1)
                                              Positioned.fill(
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    // Previous button
                                                    GestureDetector(
                                                      onTap: () => navigateToImage(-1),
                                                      child: Container(
                                                        margin: const EdgeInsets.only(left: 8),
                                                        width: 40,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          color: Colors.black.withOpacity(0.7),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.arrow_back_ios_new,
                                                          color: Colors.white,
                                                          size: 20,
                                                        ),
                                                      ),
                                                    ),
                                                    
                                                    // Next button
                                                    GestureDetector(
                                                      onTap: () => navigateToImage(1),
                                                      child: Container(
                                                        margin: const EdgeInsets.only(right: 8),
                                                        width: 40,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          color: Colors.black.withOpacity(0.7),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.arrow_forward_ios,
                                                          color: Colors.white,
                                                          size: 20,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        
                                        // Image counter
                                        if (currentBatch.length > 1)
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              'Image ${currentPosInBatch + 1} of ${currentBatch.length}',
                                              style: GoogleFonts.roboto(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        

                                        
                                        // Component images grid (if available)
                                        if (componentImages.isNotEmpty) ...[
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                            child: Text(
                                              'Component Images',
                                              style: GoogleFonts.roboto(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                            child: GridView.builder(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 2,
                                                crossAxisSpacing: 10,
                                                mainAxisSpacing: 10,
                                                childAspectRatio: 0.8,
                                              ),
                                              itemCount: componentImages.length,
                                              itemBuilder: (context, compIndex) {
                                                final componentName = componentImages.keys.elementAt(compIndex);
                                                final componentPath = componentImages[componentName]!;
                                                
                                                return GestureDetector(
                                                  onTap: () {
                                                    Navigator.pop(context);
                                                    showDialog(
                                                      context: context,
                                                      builder: (context) => Dialog(
                                                        backgroundColor: Colors.transparent,
                                                        child: Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Text(
                                                              componentName,
                                                              style: GoogleFonts.roboto(
                                                                color: Colors.white,
                                                                fontSize: 18,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 16),
                                                            ClipRRect(
                                                              borderRadius: BorderRadius.circular(12),
                                                              child: Image.file(
                                                                File(componentPath),
                                                                fit: BoxFit.contain,
                                                              ),
                                                            ),
                                                            const SizedBox(height: 16),
                                                            ElevatedButton(
                                                              onPressed: () => Navigator.pop(context),
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: const Color(0xFF34A853),
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius: BorderRadius.circular(20),
                                                                ),
                                                              ),
                                                              child: const Padding(
                                                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                                                child: Text('Close', style: TextStyle(color: Colors.white)),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                                    children: [
                                                      Expanded(
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                            border: Border.all(color: Colors.green, width: 2),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: ClipRRect(
                                                            borderRadius: BorderRadius.circular(6),
                                                            child: Image.file(
                                                              File(componentPath),
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (ctx, error, stackTrace) {
                                                                return const Center(
                                                                  child: Icon(Icons.broken_image, color: Colors.white, size: 30),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        componentName,
                                                        style: GoogleFonts.roboto(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                        ),
                                                        textAlign: TextAlign.center,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ] else ...[
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                                            child: Center(
                                              child: Column(
                                                children: [
                                                  Icon(
                                                    Icons.crop_free,
                                                    size: 48,
                                                    color: Colors.white.withOpacity(0.5),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    'No components detected',
                                                    style: GoogleFonts.roboto(
                                                      color: Colors.white70,
                                                      fontSize: 16,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Try uploading a clearer image or a different angle',
                                                    style: GoogleFonts.roboto(
                                                      color: Colors.white38,
                                                      fontSize: 14,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],

                                        
                                        // Close button
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: ElevatedButton(
                                            onPressed: () => Navigator.pop(context),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF34A853),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            child: Text(
                                              'Close',
                                              style: GoogleFonts.roboto(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      } else {
                        // For user uploaded images, also add navigation
                        if (message.imagePath != null && message.imageIndex != null) {
                          // Find current batch for navigation
                          List<int> currentBatch = [];
                          int currentPosInBatch = -1;
                          for (var batch in _uploadBatches) {
                            if (batch.contains(message.imageIndex!)) {
                              currentBatch = batch;
                              currentPosInBatch = currentBatch.indexOf(message.imageIndex!);
                              break;
                            }
                          }
              
                          showDialog(
                            context: context,
                            builder: (dialogContext) => StatefulBuilder(
                              builder: (context, setDialogState) {
                                // Current values for navigation
                                int currentIdx = message.imageIndex!;
                                String currentImagePath = message.imagePath!;
                                
                                void navigateToImage(int direction) {
                                  if (currentBatch.isEmpty) return;
                                  
                                  int newPos = (currentPosInBatch + direction) % currentBatch.length;
                                  if (newPos < 0) newPos = currentBatch.length - 1;
                                  int newIdx = currentBatch[newPos];
                                  
                                  setDialogState(() {
                                    currentIdx = newIdx;
                                    currentImagePath = _imagePaths[newIdx];
                                    currentPosInBatch = newPos;
                                  });
                                }
                                
                                return Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2A2A2A),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Header with close button
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            children: [
                                              Text(
                                                'Input Image',
                                                style: GoogleFonts.roboto(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Image with navigation
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // Image
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.file(
                                                  File(currentImagePath),
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                            
                                            // Navigation buttons
                                            if (currentBatch.length > 1)
                                              Positioned.fill(
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    // Previous button
                                                    GestureDetector(
                                                      onTap: () => navigateToImage(-1),
                                                      child: Container(
                                                        margin: const EdgeInsets.only(left: 8),
                                                        width: 40,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          color: Colors.black.withOpacity(0.7),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.arrow_back_ios_new,
                                                          color: Colors.white,
                                                          size: 20,
                                                        ),
                                                      ),
                                                    ),
                                                    
                                                    // Next button
                                                    GestureDetector(
                                                      onTap: () => navigateToImage(1),
                                                      child: Container(
                                                        margin: const EdgeInsets.only(right: 8),
                                                        width: 40,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          color: Colors.black.withOpacity(0.7),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.arrow_forward_ios,
                                                          color: Colors.white,
                                                          size: 20,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        
                                        // Image counter
                                        if (currentBatch.length > 1)
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              'Image ${currentPosInBatch + 1} of ${currentBatch.length}',
                                              style: GoogleFonts.roboto(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        
                                        
                                        // Close button
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: ElevatedButton(
                                            onPressed: () => Navigator.pop(context),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF34A853),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            child: Text(
                                              'Close',
                                              style: GoogleFonts.roboto(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          // Choose the right image path based on result status
                          Builder(
                            builder: (context) {
                              String imagePath = message.imagePath!;
                              
                              // For result images, use the processed image with bounding boxes
                              if (message.isResult && message.imageIndex != null) {
                                int originalIndex = message.imageIndex!;
                                if (_processedImagePathsMap.containsKey(originalIndex)) {
                                  imagePath = _processedImagePathsMap[originalIndex]!;
                                }
                              }
                              
                              return Image.file(
                                File(imagePath),
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, error, stackTrace) {
                                  print("Error loading image: $error");
                                  return Container(
                                    width: 200,
                                    height: 200,
                                    color: Colors.grey[800],
                                    child: const Center(
                                      child: Icon(Icons.broken_image, color: Colors.white70, size: 40),
                                    ),
                                  );
                                },
                              );
                            }
                          ),
                          if (message.isResult)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Results',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        message.isResult 
                            ? 'Analysis results' 
                            : 'Image ${message.imageIndex != null ? (message.imageIndex! + 1) : ""}',
                        style: GoogleFonts.roboto(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      // Navigation controls
                      if (_imagePaths.length > 1 && message.imageIndex != null && currentBatch.length > 1)
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                // Navigate to previous image in this batch
                                int prevPos = (currentPosInBatch - 1) % currentBatch.length;
                                if (prevPos < 0) prevPos = currentBatch.length - 1;
                                int prevIdx = currentBatch[prevPos];
                                
                                String imagePath = message.isResult && _processedImagePathsMap.containsKey(prevIdx)
                                    ? _processedImagePathsMap[prevIdx]!
                                    : _imagePaths[prevIdx];
                                
                                setState(() {
                                  // Update this message
                                  int idx = _messages.indexOf(message);
                                  if (idx >= 0) {
                                    _messages[idx] = ChatMessage(
                                      text: message.text,
                                      isUser: message.isUser,
                                      timestamp: message.timestamp,
                                      imagePath: imagePath,
                                      imageIndex: prevIdx,
                                      isResult: message.isResult,
                                      detectedParts: message.isResult && _detectedPartsPerImage.containsKey(_imagePaths[prevIdx])
                                          ? _detectedPartsPerImage[_imagePaths[prevIdx]] : null,
                                    );
                                  }
                                  
                                  // Also update current state
                                  _currentImageIndex = prevIdx;
                                  _updateDisplayedParts(prevIdx);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.white70,
                                  size: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${currentPosInBatch + 1}/${currentBatch.length}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                // Navigate to next image in this batch
                                int nextPos = (currentPosInBatch + 1) % currentBatch.length;
                                int nextIdx = currentBatch[nextPos];
                                
                                String imagePath = message.isResult && _processedImagePathsMap.containsKey(nextIdx)
                                    ? _processedImagePathsMap[nextIdx]!
                                    : _imagePaths[nextIdx];
                                
                                setState(() {
                                  // Update this message
                                  int idx = _messages.indexOf(message);
                                  if (idx >= 0) {
                                    _messages[idx] = ChatMessage(
                                      text: message.text,
                                      isUser: message.isUser,
                                      timestamp: message.timestamp,
                                      imagePath: imagePath,
                                      imageIndex: nextIdx,
                                      isResult: message.isResult,
                                      detectedParts: message.isResult && _detectedPartsPerImage.containsKey(_imagePaths[nextIdx])
                                          ? _detectedPartsPerImage[_imagePaths[nextIdx]] : null,
                                    );
                                  }
                                  
                                  // Also update current state
                                  _currentImageIndex = nextIdx;
                                  _updateDisplayedParts(nextIdx);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white70,
                                  size: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
                
                // NEW - Component images in a horizontal scrollable list
                if (message.componentImages != null && message.componentImages!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 140,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: message.componentImages!.length,
                      itemBuilder: (context, index) {
                        final componentName = message.componentImages!.keys.elementAt(index);
                        final imagePath = message.componentImages![componentName]!;
                        
                        return Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 10),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      try {
                                        // Show a simple image dialog instead of the complex one
                                        showDialog(
                                          context: context,
                                          builder: (context) => Dialog(
                                            backgroundColor: Colors.transparent,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Image.file(
                                                    File(imagePath),
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        width: 300,
                                                        height: 300,
                                                        color: Colors.grey[800],
                                                        child: const Center(
                                                          child: Icon(Icons.broken_image, color: Colors.white, size: 50),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  componentName,
                                                  style: GoogleFonts.roboto(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF34A853),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                  ),
                                                  child: const Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                                    child: Text('Close', style: TextStyle(color: Colors.white)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        print("Error showing component image: $e");
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Could not display image'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                    child: Ink(
                                      height: 100,
                                      width: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.green.withOpacity(0.7), width: 2),
                                      ),
                                      child: Builder(
                                        builder: (context) {
                                          try {
                                            if (File(imagePath).existsSync()) {
                                              return Image.file(
                                                File(imagePath),
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                                errorBuilder: (ctx, error, stackTrace) {
                                                  return const Center(
                                                    child: Icon(Icons.broken_image, color: Colors.white, size: 24),
                                                  );
                                                },
                                              );
                                            } else {
                                              return const Center(
                                                child: Icon(Icons.image_not_supported, color: Colors.white54, size: 28),
                                              );
                                            }
                                          } catch (e) {
                                            print("Error displaying component thumbnail: $e");
                                            return const Center(
                                              child: Icon(Icons.error_outline, color: Colors.red, size: 28),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                componentName,
                                style: GoogleFonts.roboto(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Avatar placeholder for user messages
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
  final int? imageIndex;
  final bool isResult;
  final List<String>? detectedParts;
  final Map<String, String>? componentImages; // NEW - Map of component name to image path

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.imagePath,
    this.imageIndex,
    this.isResult = false,
    this.detectedParts,
    this.componentImages,
  });
}