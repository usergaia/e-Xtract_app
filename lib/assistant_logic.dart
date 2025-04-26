import 'dart:convert';
import 'package:flutter/services.dart';

class AssistantLogic {
  final String category;
  final List<String> detectedComponents;
  final Map<String, Map<String, String>> componentImages;  // Update type here
  late Map<String, dynamic> _instructionsData;
  String currentNodeId = 'start';
  List<String> _instructionHistory = [];
  List<String> _componentSteps = [];
  List<Map<String, dynamic>> _currentOptions = [];
  bool _isAtEnd = false;

  // Add this mapping at the class level
  final Map<String, String> _componentToIssueMap = {
    'battery': 'battery_issue',
    'fan': 'fan_issue',
    'ram': 'ram_issue',
    'hard-drive': 'storage_issue',
    'ssd-nvme': 'storage_issue',
    'ssd-sata': 'storage_issue',
    'wifi-card': 'other_issue',
  };

  // Define fixed order for component extraction
  final List<String> _componentOrder = [
    'battery',
    'fan',
    'ram',
    'hard-drive',
    'ssd-nvme',
    'ssd-sata',
    'wifi-card'
  ];

  String? _disposalCause;
  String? _currentComponent;
  List<String> _remainingComponents = [];

  // Add instance counter at class level
  final Map<String, int> _instanceCounter = {};

  // Add this field to track unique component instances
  final List<String> _uniqueComponents = [];

  AssistantLogic({
    required this.category,
    required this.detectedComponents,
    required this.componentImages,  // Add this parameter
  });

  Future<void> initialize() async {
    String jsonString = await rootBundle.loadString(
      'assets/${category.toLowerCase()}_instructions.json'
    );
    _instructionsData = json.decode(jsonString);
    
    // Create list of unique components with their instance numbers
    for (var imageMap in componentImages.values) {
      for (var entry in imageMap.entries) {
        String fullKey = entry.key; // e.g. "ram_1", "ram_2"
        _uniqueComponents.add(fullKey);
      }
    }
    
    // Sort components according to extraction order
    _uniqueComponents.sort((a, b) {
      String typeA = a.split('_')[0];
      String typeB = b.split('_')[0];
      int aIndex = _componentOrder.indexOf(typeA);
      int bIndex = _componentOrder.indexOf(typeB);
      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;
      return aIndex.compareTo(bIndex);
    });

    _currentComponent = _uniqueComponents.isNotEmpty ? _uniqueComponents.first : null;
    currentNodeId = 'start';
  }

  void _generateInitialInstructions() {
    // Add general safety instructions first
    _componentSteps.addAll([
      'Ensure the device is powered off and unplugged',
      'Work in a clean, well-lit area',
      'Remove any jewelry and ground yourself to prevent static discharge',
    ]);

    // Get initial node and set options
    final currentNode = getCurrentNode();
    if (currentNode != null) {
      // Add question to history
      if (currentNode.containsKey('text')) {
        _instructionHistory.add(currentNode['text'] as String);
      }
      
      // Set up options from JSON
      if (currentNode.containsKey('options')) {
        _currentOptions = List<Map<String, dynamic>>.from(currentNode['options']);
      }
    }
  }

  Map<String, dynamic>? getCurrentNode() {
    final nodes = _instructionsData['nodes'] as List;
    return nodes.firstWhere(
      (node) => node['id'] == currentNodeId,
      orElse: () => null,
    );
  }

  List<String>? getCurrentOptions() {
    final currentNode = getCurrentNode();
    if (currentNode == null || !currentNode.containsKey('options')) {
      return null;
    }
    return List<String>.from(currentNode['options']);
  }

  List<String>? getCurrentSteps() {
    final currentNode = getCurrentNode();
    if (currentNode == null) return null;

    // Handle nodes with 'steps'
    if (currentNode.containsKey('steps')) {
      final steps = List<Map<String, dynamic>>.from(currentNode['steps']);
      steps.sort((a, b) => (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0));
      return steps.map((step) => step['action'] as String).toList();
    }
    
    // Handle nodes with 'instructions'
    if (currentNode.containsKey('instructions')) {
      final instructions = List<Map<String, dynamic>>.from(currentNode['instructions']);
      return instructions.map((instruction) => instruction['step'] as String).toList();
    }

    return null;
  }

  void navigateToNode(String nodeId) {
    if (_instructionsData['nodes'].any((node) => node['id'] == nodeId)) {
      currentNodeId = nodeId;
      final node = getCurrentNode();
      
      if (node != null) {
        // Add text to history if present
        if (node.containsKey('text')) {
          _instructionHistory.add(node['text'] as String);
        }

        // Set options if present
        if (node.containsKey('options')) {
          _currentOptions = List<Map<String, dynamic>>.from(node['options']);
          _isAtEnd = false;
        }

        // Handle steps if present
        final steps = getCurrentSteps();
        if (steps != null) {
          _componentSteps.clear();  // Clear previous steps
          _componentSteps.addAll(steps);
          _isAtEnd = true;
        }
      }
    }
  }

  // Helper method to check if a specific component was detected
  bool hasComponent(String componentName) {
    return detectedComponents
        .map((c) => c.toLowerCase())
        .contains(componentName.toLowerCase());
  }

  // Get text for current node
  String? getCurrentNodeText() {
    final currentNode = getCurrentNode();
    return currentNode?['text'];
  }

  // Get all instructions given so far
  List<String> getInstructionHistory() => List.unmodifiable(_instructionHistory);

  // Get all component extraction steps
  List<String> getComponentSteps() => List.unmodifiable(_componentSteps);

  // Get next possible nodes based on detected components
  List<String> getNextPossibleNodes() {
    final currentNode = getCurrentNode();
    if (currentNode == null || !currentNode.containsKey('options')) {
      return [];
    }

    List<String> possibleNodes = [];
    for (var component in detectedComponents) {
      String normalizedComponent = component.toLowerCase().replaceAll(' ', '-');
      
      // Use the mapping instead of switch statement
      if (_componentToIssueMap.containsKey(normalizedComponent)) {
        String issueNode = _componentToIssueMap[normalizedComponent]!;
        
        if (currentNodeId == 'start') {
          possibleNodes.add(issueNode);
        } else if (currentNodeId == issueNode) {
          // Handle secondary navigation based on component type
          switch (normalizedComponent) {
            case 'battery':
              possibleNodes.add('battery_type');
              break;
            case 'fan':
              possibleNodes.add('extract_fan');
              break;
            case 'ram':
              possibleNodes.add('extract_ram_clips');
              break;
            case 'hard-drive':
              possibleNodes.add('hdd_flow');
              break;
            case 'ssd-nvme':
              possibleNodes.add('nvme_flow');
              break;
            case 'ssd-sata':
              possibleNodes.add('sata_flow');
              break;
            case 'wifi-card':
              possibleNodes.add('extract_wifi');
              break;
          }
        }
      }
    }
    return possibleNodes;
  }

  // Get the current options as user-friendly labels
  List<String> getCurrentOptionLabels() {
    final currentNode = getCurrentNode();
    if (currentNode == null || !currentNode.containsKey('options')) {
      return [];
    }

    _currentOptions = List<Map<String, dynamic>>.from(currentNode['options']);
    return _currentOptions.map((option) => option['label'] as String).toList();
  }

  // Select an option and navigate to next node
  void selectOption(int index) {
    final currentNode = getCurrentNode();
    if (currentNode == null || !currentNode.containsKey('options')) return;

    final options = List<Map<String, dynamic>>.from(currentNode['options']);
    if (index >= 0 && index < options.length) {
      final selectedOption = options[index];
      final nextNodeId = selectedOption['next'] as String;

      if (currentNodeId == 'start') {
        // Just store the disposal cause and start with first component
        _disposalCause = nextNodeId;
        if (_currentComponent != null) {
          // Always start with battery_type for the first component
          navigateToNode('battery_type');
        }
      } else {
        // Normal navigation within a component's flow
        navigateToNode(nextNodeId);
      }
    }
  }

  void handleComponent(String component) {
    // Only show issue flow if we're handling the component that matches the disposal cause
    if (_componentToIssueMap[component] == _disposalCause) {
      navigateToNode(_disposalCause!);
    } else {
      // Show default extraction flow
      switch (component) {
        case 'battery':
          navigateToNode('battery_type');
          break;
        case 'fan':
          navigateToNode('extract_fan');
          break;
        case 'ram':
          navigateToNode('extract_ram_clips');
          break;
        case 'hard-drive':
          navigateToNode('hdd_default');
          break;
        case 'ssd-nvme':
          navigateToNode('nvme_flow');
          break;
        case 'ssd-sata':
          navigateToNode('sata_flow');
          break;
        case 'wifi-card':
          navigateToNode('extract_wifi');
          break;
      }
    }
  }

  void _moveToComponentFlow(String component) {
    // Get the default starting node for each component type
    switch (component) {
      case 'battery':
        navigateToNode('battery_type');
        break;
      case 'fan':
        if (_disposalCause == 'fan_issue') {
          navigateToNode('fan_issue');
        } else {
          navigateToNode('extract_fan');
        }
        break;
      case 'ram':
        if (_disposalCause == 'ram_issue') {
          navigateToNode('ram_issue');
        } else {
          navigateToNode('extract_ram_clips');
        }
        break;
      case 'hard-drive':
      case 'ssd-nvme':
      case 'ssd-sata':
        if (_disposalCause == 'storage_issue') {
          navigateToNode('storage_issue');
        } else {
          navigateToNode('hdd_default');
        }
        break;
      case 'wifi-card':
        navigateToNode('other_issue');
        break;
    }
  }

  // Check if we're at an end node
  bool isAtEnd() => _isAtEnd;

  // Get the current instruction or question text
  String getCurrentInstruction() {
    final node = getCurrentNode();
    if (node == null) return '';

    // Only return the node's text content
    if (node.containsKey('text')) {
      return node['text'] as String;
    }
    
    // Don't include "Steps:" header since it's handled in the UI
    if (node.containsKey('steps')) {
      final steps = List<Map<String, dynamic>>.from(node['steps']);
      steps.sort((a, b) => (a['order'] as int? ?? 0).compareTo(b['order'] as int? ?? 0));
      return steps.map((step) => '• ${step['action']}').join('\n');
    }
    
    if (node.containsKey('instructions')) {
      final instructions = List<Map<String, dynamic>>.from(node['instructions']);
      return instructions.map((instruction) => '• ${instruction['step']}').join('\n');
    }
    
    return '';
  }

  // Reset to start
  void reset() {
    currentNodeId = 'start';
    _instructionHistory.clear();
    _componentSteps.clear();
    _currentOptions.clear();
    _isAtEnd = false;
    _generateInitialInstructions();
  }

  // Add method to move to next component
  bool moveToNextComponent() {
    if (_uniqueComponents.isEmpty || _currentComponent == null) {
      return false;
    }
    
    int currentIndex = _uniqueComponents.indexOf(_currentComponent!);
    if (currentIndex < 0 || currentIndex >= _uniqueComponents.length - 1) {
      return false;
    }
    
    _componentSteps.clear();
    _currentOptions.clear();
    _currentComponent = _uniqueComponents[currentIndex + 1];
    handleComponent(_currentComponent!.split('_')[0]);
    return true;
  }

  // Update hasMoreComponents to check if there's more than one component left
  bool hasMoreComponents() {
    if (_currentComponent == null) return false;
    
    int currentIndex = _uniqueComponents.indexOf(_currentComponent!);
    // Return true only if there are components after the current one
    return currentIndex < _uniqueComponents.length - 1;
  }

  // Add method to get name of next component
  String? getNextComponentName() {
    if (_currentComponent == null) return null;
    
    int currentIndex = _uniqueComponents.indexOf(_currentComponent!);
    // Check if there's a next component
    if (currentIndex < _uniqueComponents.length - 1) {
      // Return the base component name without instance number
      return _uniqueComponents[currentIndex + 1].split('_')[0];
    }
    return null;
  }

  // Update getCurrentComponentImage to track instances
  String? getCurrentComponentImage() {
    if (_currentComponent == null) return null;
    
    // Look through all images to find exact match for current component
    for (var imageMap in componentImages.values) {
      if (imageMap.containsKey(_currentComponent)) {
        return imageMap[_currentComponent];
      }
    }
    return null;
  }

  String? getCurrentComponent() {
    return _currentComponent;
  }
}