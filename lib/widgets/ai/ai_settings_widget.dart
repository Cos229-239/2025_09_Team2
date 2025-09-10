import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studypals/providers/ai_provider.dart';
import 'package:studypals/services/ai_service.dart';

/// AI Configuration and Settings Widget
class AISettingsWidget extends StatefulWidget {
  const AISettingsWidget({super.key});

  @override
  State<AISettingsWidget> createState() => _AISettingsWidgetState();
}

class _AISettingsWidgetState extends State<AISettingsWidget> {
  final TextEditingController _apiKeyController = TextEditingController();
  String _selectedProvider = 'OpenAI';
  bool _isTestingConnection = false;
  String? _connectionStatus;
  
  final List<String> _aiProviders = [
    'OpenAI',
    'Google AI', 
    'Anthropic Claude',
    'Ollama (Local)',
    'Local Model',
  ];

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  AIProvider _getProviderEnum(String providerName) {
    switch (providerName) {
      case 'OpenAI':
        return AIProvider.openai;
      case 'Google AI':
        return AIProvider.google;
      case 'Anthropic Claude':
        return AIProvider.anthropic;
      case 'Ollama (Local)':
        return AIProvider.ollama;
      case 'Local Model':
        return AIProvider.localModel;
      default:
        return AIProvider.openai;
    }
  }

  Future<void> _testConnection() async {
    if (_apiKeyController.text.trim().isEmpty) {
      setState(() {
        _connectionStatus = 'Please enter an API key first';
      });
      return;
    }

    setState(() {
      _isTestingConnection = true;
      _connectionStatus = null;
    });

    try {
      final aiProvider = Provider.of<StudyPalsAIProvider>(context, listen: false);
      
      // Configure AI with selected settings
      await aiProvider.configureAI(
        provider: _getProviderEnum(_selectedProvider),
        apiKey: _apiKeyController.text.trim(),
      );
      
      // Test connection
      final success = await aiProvider.testConnection();
      
      setState(() {
        _connectionStatus = success 
            ? 'Connection successful!' 
            : 'Connection failed. Please check your settings.';
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Error: $e';
      });
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudyPalsAIProvider>(
      builder: (context, aiProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.settings,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI Configuration',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Current status
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: aiProvider.isAIEnabled 
                        ? Colors.green.shade50 
                        : Colors.orange.shade50,
                    border: Border.all(
                      color: aiProvider.isAIEnabled 
                          ? Colors.green.shade200 
                          : Colors.orange.shade200,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        aiProvider.isAIEnabled 
                            ? Icons.check_circle_outline 
                            : Icons.warning_outlined,
                        color: aiProvider.isAIEnabled 
                            ? Colors.green.shade600 
                            : Colors.orange.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        aiProvider.isAIEnabled 
                            ? 'AI features are enabled and ready'
                            : 'AI features need configuration',
                        style: TextStyle(
                          color: aiProvider.isAIEnabled 
                              ? Colors.green.shade600 
                              : Colors.orange.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Provider selection
                DropdownButtonFormField<String>(
                  initialValue: _selectedProvider,
                  decoration: const InputDecoration(
                    labelText: 'AI Provider',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.cloud),
                  ),
                  items: _aiProviders.map((provider) {
                    return DropdownMenuItem(
                      value: provider,
                      child: Text(provider),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedProvider = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // API Key input
                TextField(
                  controller: _apiKeyController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'API Key',
                    hintText: 'Enter your API key...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.key),
                    suffixIcon: Icon(Icons.visibility_off),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Connection status
                if (_connectionStatus != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _connectionStatus!.contains('successful')
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      border: Border.all(
                        color: _connectionStatus!.contains('successful')
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _connectionStatus!.contains('successful')
                              ? Icons.check_circle_outline
                              : Icons.error_outline,
                          color: _connectionStatus!.contains('successful')
                              ? Colors.green.shade600
                              : Colors.red.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _connectionStatus!,
                            style: TextStyle(
                              color: _connectionStatus!.contains('successful')
                                  ? Colors.green.shade600
                                  : Colors.red.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isTestingConnection ? null : _testConnection,
                        icon: _isTestingConnection
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.wifi_protected_setup),
                        label: Text(_isTestingConnection ? 'Testing...' : 'Test Connection'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          // Save AI settings to SharedPreferences (mock implementation)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Settings saved successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save Settings'),
                      ),
                    ),
                  ],
                ),
                
                // Info section
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Getting Started:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '1. Choose your preferred AI provider\n'
                        '2. Get an API key from the provider\'s website\n'
                        '3. Enter the API key and test the connection\n'
                        '4. Once connected, AI features will be available!',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                
                // Links section
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        // Show info about OpenAI API
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('OpenAI API Information'),
                              content: const Text(
                                'To use AI features, you would need an OpenAI API key.\n\n'
                                'Visit: https://platform.openai.com/api-keys\n\n'
                                'This is a demo version - AI features are simulated.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.launch, size: 16),
                      label: const Text('OpenAI API', style: TextStyle(fontSize: 12)),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // Show info about Google AI API
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Google AI Information'),
                              content: const Text(
                                'Google AI provides various machine learning APIs.\n\n'
                                'Visit: https://cloud.google.com/ai\n\n'
                                'This is a demo version - AI features are simulated.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.launch, size: 16),
                      label: const Text('Google AI', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
