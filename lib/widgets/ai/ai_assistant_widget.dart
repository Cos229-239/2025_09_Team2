import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ai_provider.dart';
import '../../models/study_pal_persona.dart';
import 'ai_tutor_chat.dart';

/// AI Assistant Widget with Persona Selection
class AIAssistantWidget extends StatefulWidget {
  const AIAssistantWidget({super.key});

  @override
  State<AIAssistantWidget> createState() => _AIAssistantWidgetState();
}

class _AIAssistantWidgetState extends State<AIAssistantWidget> {
  StudyPalPersona? _selectedPersona;
  final List<StudyPalPersona> _personas = StudyPalPersona.getDefaultPersonas();

  @override
  void initState() {
    super.initState();
    // Default to the first persona (Dr. Sage - Mentor)
    _selectedPersona = _personas.first;
  }

  void _showPersonaMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Choose Your Study Pal',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Personas list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _personas.length,
                itemBuilder: (context, index) {
                  final persona = _personas[index];
                  final isSelected = _selectedPersona?.type == persona.type;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: isSelected ? 4 : 1,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedPersona = persona;
                        });
                        Navigator.pop(context);
                        _showAIChat();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Text(
                                  persona.avatar,
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Persona info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        persona.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .onPrimaryContainer
                                                  : null,
                                            ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getPersonaColor(persona.type)
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          persona.type.displayName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                _getPersonaColor(persona.type),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    persona.description,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: isSelected
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .onPrimaryContainer
                                              : Colors.grey[600],
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  // Traits preview
                                  Wrap(
                                    spacing: 4,
                                    children: [
                                      _buildTraitChip(
                                          persona.traits.communicationStyle),
                                      _buildTraitChip(
                                          persona.traits.energyLevel),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTraitChip(String trait) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        trait,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
        ),
      ),
    );
  }

  Color _getPersonaColor(PersonaType type) {
    switch (type) {
      case PersonaType.mentor:
        return Colors.purple;
      case PersonaType.coach:
        return Colors.orange;
      case PersonaType.buddy:
        return Colors.green;
      case PersonaType.scholar:
        return Colors.blue;
      case PersonaType.cheerleader:
        return Colors.pink;
    }
  }

  void _showAIChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Text(_selectedPersona?.avatar ?? '🤖'),
                const SizedBox(width: 8),
                Text(_selectedPersona?.name ?? 'AI Assistant'),
              ],
            ),
            actions: [
              IconButton(
                onPressed: _showPersonaMenu,
                icon: const Icon(Icons.swap_horiz),
                tooltip: 'Switch Persona',
              ),
            ],
          ),
          body: AITutorChat(selectedPersona: _selectedPersona),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudyPalsAIProvider>(
      builder: (context, aiProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A3050),
            borderRadius: Theme.of(context).cardTheme.shape
                    is RoundedRectangleBorder
                ? (Theme.of(context).cardTheme.shape as RoundedRectangleBorder)
                    .borderRadius
                : BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFF8B67F),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: aiProvider.isAIEnabled
                  ? _showAIChat
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please configure AI settings first'),
                        ),
                      );
                    },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header with hamburger menu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'AI Assistant',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          onPressed:
                              aiProvider.isAIEnabled ? _showPersonaMenu : null,
                          icon: Icon(
                            Icons.menu,
                            color: aiProvider.isAIEnabled
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            size: 20,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          padding: EdgeInsets.zero,
                          tooltip: 'Choose Persona',
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Avatar and status
                    if (aiProvider.isAIEnabled) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getPersonaColor(
                                  _selectedPersona?.type ?? PersonaType.mentor),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: _getPersonaColor(
                                          _selectedPersona?.type ??
                                              PersonaType.mentor)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              _selectedPersona?.avatar ?? '🤖',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedPersona?.name ?? 'AI Assistant',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                _selectedPersona?.type.displayName ??
                                    'Assistant',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                      fontSize: 10,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.smart_toy_outlined,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Configure AI',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
