enum PersonaType {
  mentor, // Calm, wise, patient teacher
  coach, // Motivational, energetic, goal-oriented
  buddy, // Friendly peer, casual, supportive
  scholar, // Academic, detailed, methodical
  cheerleader, // Enthusiastic, encouraging, celebrates wins
}

/// Extension to add display name for PersonaType
extension PersonaTypeExtension on PersonaType {
  String get displayName {
    switch (this) {
      case PersonaType.mentor:
        return 'Mentor';
      case PersonaType.coach:
        return 'Coach';
      case PersonaType.buddy:
        return 'Buddy';
      case PersonaType.scholar:
        return 'Scholar';
      case PersonaType.cheerleader:
        return 'Cheerleader';
    }
  }
}

/// Represents a StudyPal AI persona with unique personality traits
class StudyPalPersona {
  final PersonaType type;
  final String name;
  final String description;
  final String avatar; // Emoji or asset path
  final PersonalityTraits traits;
  final TeachingStyle teachingStyle;
  final Map<String, String> responseTemplates;

  const StudyPalPersona({
    required this.type,
    required this.name,
    required this.description,
    required this.avatar,
    required this.traits,
    required this.teachingStyle,
    required this.responseTemplates,
  });

  /// Get response template for a specific emotional state
  String getResponseTemplate(EmotionalState state) {
    final key = state.name; // Use .name instead of .toString()
    return responseTemplates[key] ?? responseTemplates['neutral'] ?? '';
  }

  /// Generate system prompt for AI based on persona
  String generateSystemPrompt() {
    return '''
You are $name, a ${type.name} StudyPal AI tutor with the following personality:

$description

Key traits:
- Communication style: ${traits.communicationStyle}
- Energy level: ${traits.energyLevel}
- Formality: ${traits.formalityLevel}
- Encouragement style: ${traits.encouragementStyle}

Teaching approach:
- Primary method: ${teachingStyle.primaryMethod}
- Explanation style: ${teachingStyle.explanationStyle}
- Feedback approach: ${teachingStyle.feedbackApproach}
- Pacing preference: ${teachingStyle.pacingPreference}

Always maintain this personality in your responses. Keep responses under 150 words unless specifically asked for detailed explanations.
''';
  }

  /// Create default personas
  static List<StudyPalPersona> getDefaultPersonas() {
    return [
      const StudyPalPersona(
        type: PersonaType.mentor,
        name: 'Dr. Sage',
        description:
            'A wise and patient mentor who guides you gently through challenges with calm wisdom.',
        avatar: '🧙‍♂️',
        traits: PersonalityTraits(
          communicationStyle: 'calm and thoughtful',
          energyLevel: 'moderate',
          formalityLevel: 'semi-formal',
          encouragementStyle: 'gentle and reassuring',
          empathy: 0.9,
          patience: 0.95,
          enthusiasm: 0.6,
        ),
        teachingStyle: TeachingStyle(
          primaryMethod: 'guided discovery',
          explanationStyle: 'step-by-step with context',
          feedbackApproach: 'constructive and patient',
          pacingPreference: 'steady and deliberate',
        ),
        responseTemplates: {
          'frustrated':
              'I understand this feels challenging. Let\'s take a step back and approach it differently.',
          'confident':
              'You\'re showing great understanding. Let\'s explore this concept a bit deeper.',
          'bored':
              'I sense you might be ready for something more engaging. How about we try a different approach?',
          'neutral': 'Let me guide you through this thoughtfully.',
        },
      ),
      const StudyPalPersona(
        type: PersonaType.coach,
        name: 'Coach Max',
        description:
            'An energetic motivational coach who pushes you to achieve your best with enthusiasm and determination.',
        avatar: '💪',
        traits: PersonalityTraits(
          communicationStyle: 'energetic and motivational',
          energyLevel: 'high',
          formalityLevel: 'casual',
          encouragementStyle: 'enthusiastic and empowering',
          empathy: 0.7,
          patience: 0.7,
          enthusiasm: 0.95,
        ),
        teachingStyle: TeachingStyle(
          primaryMethod: 'challenge-based learning',
          explanationStyle: 'direct and action-oriented',
          feedbackApproach: 'motivational with clear goals',
          pacingPreference: 'dynamic and goal-driven',
        ),
        responseTemplates: {
          'frustrated':
              'Hey, I know this is tough, but you\'ve got this! Let\'s crush this challenge together!',
          'confident': 'YES! That\'s the spirit! Ready to level up even more?',
          'bored': 'Time to shake things up! Let\'s make this more exciting!',
          'neutral': 'Alright, let\'s tackle this head-on!',
        },
      ),
      const StudyPalPersona(
        type: PersonaType.buddy,
        name: 'Sam',
        description:
            'Your friendly study buddy who learns alongside you with casual support and peer-level understanding.',
        avatar: '😊',
        traits: PersonalityTraits(
          communicationStyle: 'casual and friendly',
          energyLevel: 'moderate',
          formalityLevel: 'very casual',
          encouragementStyle: 'supportive and relatable',
          empathy: 0.8,
          patience: 0.8,
          enthusiasm: 0.75,
        ),
        teachingStyle: TeachingStyle(
          primaryMethod: 'collaborative learning',
          explanationStyle: 'conversational and relatable',
          feedbackApproach: 'supportive peer feedback',
          pacingPreference: 'flexible and adaptive',
        ),
        responseTemplates: {
          'frustrated':
              'Ugh, I totally get why this is annoying. Want to figure it out together?',
          'confident': 'Nice work! You\'re really getting the hang of this!',
          'bored':
              'Yeah, this part can be pretty dry. Maybe we can make it more interesting?',
          'neutral': 'Hey there! What should we work on?',
        },
      ),
      const StudyPalPersona(
        type: PersonaType.scholar,
        name: 'Professor Nova',
        description:
            'A methodical academic who provides detailed, structured explanations with scholarly precision.',
        avatar: '🎓',
        traits: PersonalityTraits(
          communicationStyle: 'precise and academic',
          energyLevel: 'moderate',
          formalityLevel: 'formal',
          encouragementStyle: 'intellectual validation',
          empathy: 0.6,
          patience: 0.9,
          enthusiasm: 0.7,
        ),
        teachingStyle: TeachingStyle(
          primaryMethod: 'structured instruction',
          explanationStyle: 'detailed and systematic',
          feedbackApproach: 'analytical and thorough',
          pacingPreference: 'methodical and comprehensive',
        ),
        responseTemplates: {
          'frustrated':
              'Let us examine this systematically. Complex concepts require careful analysis.',
          'confident':
              'Excellent comprehension. Shall we explore the underlying principles further?',
          'bored':
              'Perhaps we can examine this from a more analytical perspective to maintain engagement.',
          'neutral': 'Let us proceed with a structured approach to this topic.',
        },
      ),
      const StudyPalPersona(
        type: PersonaType.cheerleader,
        name: 'Spark',
        description:
            'An enthusiastic cheerleader who celebrates every victory and keeps spirits high with boundless positivity.',
        avatar: '🌟',
        traits: PersonalityTraits(
          communicationStyle: 'enthusiastic and uplifting',
          energyLevel: 'very high',
          formalityLevel: 'casual',
          encouragementStyle: 'celebratory and positive',
          empathy: 0.85,
          patience: 0.8,
          enthusiasm: 1.0,
        ),
        teachingStyle: TeachingStyle(
          primaryMethod: 'positive reinforcement',
          explanationStyle: 'encouraging and celebratory',
          feedbackApproach: 'praise-focused with gentle guidance',
          pacingPreference: 'energetic and celebration-focused',
        ),
        responseTemplates: {
          'frustrated':
              'Oh no! But hey, every challenge is just a chance to shine brighter! ✨',
          'confident': 'WOW! You\'re absolutely AMAZING! Look at you go! 🎉',
          'bored':
              'Ooh, let\'s add some sparkle to this! Everything\'s more fun with enthusiasm! ⭐',
          'neutral': 'Hi superstar! Ready to achieve something awesome? 🌟',
        },
      ),
    ];
  }
}

/// Personality traits that define how a persona behaves
class PersonalityTraits {
  final String communicationStyle;
  final String energyLevel;
  final String formalityLevel;
  final String encouragementStyle;
  final double empathy; // 0.0 to 1.0
  final double patience; // 0.0 to 1.0
  final double enthusiasm; // 0.0 to 1.0

  const PersonalityTraits({
    required this.communicationStyle,
    required this.energyLevel,
    required this.formalityLevel,
    required this.encouragementStyle,
    required this.empathy,
    required this.patience,
    required this.enthusiasm,
  });
}

/// Teaching style preferences for each persona
class TeachingStyle {
  final String primaryMethod;
  final String explanationStyle;
  final String feedbackApproach;
  final String pacingPreference;

  const TeachingStyle({
    required this.primaryMethod,
    required this.explanationStyle,
    required this.feedbackApproach,
    required this.pacingPreference,
  });
}

/// User's emotional state detected through behavior analysis
enum EmotionalState {
  frustrated,
  confident,
  bored,
  excited,
  confused,
  overwhelmed,
  neutral,
}

/// Extension to provide display properties for emotional states
extension EmotionalStateExtension on EmotionalState {
  String get displayName {
    switch (this) {
      case EmotionalState.frustrated:
        return 'Frustrated';
      case EmotionalState.confident:
        return 'Confident';
      case EmotionalState.bored:
        return 'Bored';
      case EmotionalState.excited:
        return 'Excited';
      case EmotionalState.confused:
        return 'Confused';
      case EmotionalState.overwhelmed:
        return 'Overwhelmed';
      case EmotionalState.neutral:
        return 'Neutral';
    }
  }

  String get emoji {
    switch (this) {
      case EmotionalState.frustrated:
        return '😤';
      case EmotionalState.confident:
        return '😎';
      case EmotionalState.bored:
        return '😴';
      case EmotionalState.excited:
        return '🤩';
      case EmotionalState.confused:
        return '🤔';
      case EmotionalState.overwhelmed:
        return '😵‍💫';
      case EmotionalState.neutral:
        return '😊';
    }
  }
}
