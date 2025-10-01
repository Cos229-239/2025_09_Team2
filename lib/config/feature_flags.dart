// feature_flags.dart
// Feature flags for gradual rollout of AI tutor enhancements

/// Feature flags for controlling AI tutor enhancement rollout
class FeatureFlags {
  // Global feature switches
  static bool memoryValidation = false;
  static bool mathValidation = false;
  static bool styleAdaptation = false;
  static bool profileStorage = false;
  
  // Rollout percentage (0.0 to 1.0)
  static double rolloutPercentage = 0.0;
  
  // Beta user IDs for early access
  static Set<String> betaUsers = {};
  
  // Internal/dev user IDs (always enabled)
  static Set<String> internalUsers = {};
  
  /// Check if a feature is enabled for a specific user
  static bool isEnabled(String feature, String userId) {
    // Internal users get all features
    if (internalUsers.contains(userId)) {
      return true;
    }
    
    // Beta users get all enabled features
    if (betaUsers.contains(userId)) {
      return _isFeatureEnabled(feature);
    }
    
    // Check rollout percentage
    if (rolloutPercentage > 0.0) {
      final hash = userId.hashCode.abs();
      final bucket = (hash % 100) / 100.0;
      
      if (bucket < rolloutPercentage) {
        return _isFeatureEnabled(feature);
      }
    }
    
    return false;
  }
  
  /// Check if feature is globally enabled
  static bool _isFeatureEnabled(String feature) {
    switch (feature) {
      case 'memoryValidation':
        return memoryValidation;
      case 'mathValidation':
        return mathValidation;
      case 'styleAdaptation':
        return styleAdaptation;
      case 'profileStorage':
        return profileStorage;
      default:
        return false;
    }
  }
  
  /// Enable feature for all users
  static void enableGlobal(String feature) {
    switch (feature) {
      case 'memoryValidation':
        memoryValidation = true;
        break;
      case 'mathValidation':
        mathValidation = true;
        break;
      case 'styleAdaptation':
        styleAdaptation = true;
        break;
      case 'profileStorage':
        profileStorage = true;
        break;
    }
  }
  
  /// Disable feature for all users
  static void disableGlobal(String feature) {
    switch (feature) {
      case 'memoryValidation':
        memoryValidation = false;
        break;
      case 'mathValidation':
        mathValidation = false;
        break;
      case 'styleAdaptation':
        styleAdaptation = false;
        break;
      case 'profileStorage':
        profileStorage = false;
        break;
    }
  }
  
  /// Add user to beta program
  static void addBetaUser(String userId) {
    betaUsers.add(userId);
  }
  
  /// Remove user from beta program
  static void removeBetaUser(String userId) {
    betaUsers.remove(userId);
  }
  
  /// Add internal user
  static void addInternalUser(String userId) {
    internalUsers.add(userId);
  }
  
  /// Set rollout percentage (0.0 to 1.0)
  static void setRolloutPercentage(double percentage) {
    rolloutPercentage = percentage.clamp(0.0, 1.0);
  }
  
  /// Get current configuration
  static Map<String, dynamic> getConfiguration() {
    return {
      'memoryValidation': memoryValidation,
      'mathValidation': mathValidation,
      'styleAdaptation': styleAdaptation,
      'profileStorage': profileStorage,
      'rolloutPercentage': rolloutPercentage,
      'betaUserCount': betaUsers.length,
      'internalUserCount': internalUsers.length,
    };
  }
  
  /// Reset all flags (for testing)
  static void reset() {
    memoryValidation = false;
    mathValidation = false;
    styleAdaptation = false;
    profileStorage = false;
    rolloutPercentage = 0.0;
    betaUsers.clear();
    // Don't clear internal users in production
  }
  
  /// Preset configurations for different environments
  
  /// Development: All features enabled for all users
  static void setDevelopmentMode() {
    memoryValidation = true;
    mathValidation = true;
    styleAdaptation = true;
    profileStorage = true;
    rolloutPercentage = 1.0;
  }
  
  /// Staging: All features enabled for beta/internal only
  static void setStagingMode() {
    memoryValidation = true;
    mathValidation = true;
    styleAdaptation = true;
    profileStorage = true;
    rolloutPercentage = 0.0; // Only beta/internal users
  }
  
  /// Production: Gradual rollout
  static void setProductionMode({double percentage = 0.0}) {
    memoryValidation = true;
    mathValidation = true;
    styleAdaptation = false; // Enable later
    profileStorage = false; // Requires user consent UI first
    rolloutPercentage = percentage;
  }
}
