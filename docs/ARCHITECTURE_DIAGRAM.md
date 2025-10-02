# AI Tutor Enhancement - System Architecture Diagram

```
┌────────────────────────────────────────────────────────────────────────────┐
│                           STUDYPALS AI TUTOR                                │
│                        (Enhanced with Middleware)                           │
└────────────────────────────────────────────────────────────────────────────┘

                              User Input Message
                                      │
                                      ▼
         ┌────────────────────────────────────────────────────────┐
         │          FEATURE FLAGS CHECK                           │
         │  (Determines which enhancements are enabled)           │
         │  - memoryValidation: ON/OFF                            │
         │  - mathValidation: ON/OFF                              │
         │  - styleAdaptation: ON/OFF                             │
         │  - rolloutPercentage: 0% - 100%                        │
         └────────────────────────────────────────────────────────┘
                                      │
                                      ▼
╔══════════════════════════════════════════════════════════════════════════╗
║                         PRE-PROCESSING PHASE                             ║
╠══════════════════════════════════════════════════════════════════════════╣
║                                                                          ║
║  ┌─────────────────────┐      ┌──────────────────────┐                 ║
║  │  SessionContext     │      │  UserProfileStore    │                 ║
║  │  ─────────────────  │      │  ──────────────────  │                 ║
║  │  • Last 50 messages │      │  • Learning prefs    │                 ║
║  │  • Topic tracking   │      │  • Skill scores      │                 ║
║  │  • Semantic search  │      │  • Opt-in flags      │                 ║
║  └─────────────────────┘      └──────────────────────┘                 ║
║            │                            │                               ║
║            └────────────┬───────────────┘                               ║
║                         ▼                                               ║
║              ┌──────────────────────┐                                   ║
║              │ LearningStyleDetector│                                   ║
║              │ ──────────────────── │                                   ║
║              │ • Visual: 0.8        │                                   ║
║              │ • Auditory: 0.4      │                                   ║
║              │ • Kinesthetic: 0.5   │                                   ║
║              │ • Reading: 0.6       │                                   ║
║              │ • Depth: "detailed"  │                                   ║
║              └──────────────────────┘                                   ║
║                         │                                               ║
║                         ▼                                               ║
║         ┌──────────────────────────────────┐                           ║
║         │    ENHANCED SYSTEM PROMPT        │                           ║
║         │  ─────────────────────────────   │                           ║
║         │  Context:                        │                           ║
║         │  - Session: 42 messages          │                           ║
║         │  - Topics: algebra, calculus     │                           ║
║         │  - Style: Visual (80%)           │                           ║
║         │  - Profile: Math enthusiast      │                           ║
║         │                                  │                           ║
║         │  Rules:                          │                           ║
║         │  1. Verify memory claims         │                           ║
║         │  2. Structure: Short + Expand    │                           ║
║         │  3. Show math steps              │                           ║
║         │  4. Adapt to visual style        │                           ║
║         └──────────────────────────────────┘                           ║
║                         │                                               ║
╚══════════════════════════════════════════════════════════════════════════╝
                          │
                          ▼
         ┌────────────────────────────────────────────────────┐
         │           EXISTING LLM SERVICE                     │
         │        (Unchanged - Just uses enhanced prompt)     │
         │                                                    │
         │  • OpenAI / Google / Anthropic                    │
         │  • Generates response based on enhanced context   │
         └────────────────────────────────────────────────────┘
                          │
                          ▼
╔══════════════════════════════════════════════════════════════════════════╗
║                        POST-PROCESSING PHASE                             ║
╠══════════════════════════════════════════════════════════════════════════╣
║                                                                          ║
║  ┌─────────────────────────────────────────────────────────────────┐   ║
║  │  STEP 1: Memory Claim Validation                                │   ║
║  │  ──────────────────────────────────────                         │   ║
║  │  Scans for: "we discussed", "you mentioned", "you told me"      │   ║
║  │                                                                  │   ║
║  │  ✓ Claim: "We discussed algebra"                                │   ║
║  │    → Check session context... FOUND ✓                           │   ║
║  │                                                                  │   ║
║  │  ✗ Claim: "You said you love physics"                           │   ║
║  │    → Check session context... NOT FOUND ✗                       │   ║
║  │    → Replace with: "I don't have a record of that.              │   ║
║  │       Would you like to discuss physics?"                       │   ║
║  └─────────────────────────────────────────────────────────────────┘   ║
║                          │                                              ║
║                          ▼                                              ║
║  ┌─────────────────────────────────────────────────────────────────┐   ║
║  │  STEP 2: Math Validation                                        │   ║
║  │  ───────────────────────                                        │   ║
║  │  Extracts: "2 + 2 = 5"                                          │   ║
║  │                                                                  │   ║
║  │  ✗ Calculation error detected!                                  │   ║
║  │    Expected: 4                                                  │   ║
║  │    Got: 5                                                       │   ║
║  │                                                                  │   ║
║  │  → Append correction:                                           │   ║
║  │    "Math Verification:                                          │   ║
║  │     ✗ 2 + 2 = 5 (incorrect)                                     │   ║
║  │     ✓ 2 + 2 = 4 (correct)"                                      │   ║
║  └─────────────────────────────────────────────────────────────────┘   ║
║                          │                                              ║
║                          ▼                                              ║
║  ┌─────────────────────────────────────────────────────────────────┐   ║
║  │  STEP 3: Safety Fallback Check                                  │   ║
║  │  ──────────────────────────────                                 │   ║
║  │  If multiple validation failures:                               │   ║
║  │                                                                  │   ║
║  │  Replace with safe fallback:                                    │   ║
║  │  "I want to ensure accuracy. I can:                             │   ║
║  │   1. Quick Summary                                              │   ║
║  │   2. Step-by-Step Solution                                      │   ║
║  │   3. Extended Explanation                                       │   ║
║  │   Which would help you most?"                                   │   ║
║  └─────────────────────────────────────────────────────────────────┘   ║
║                          │                                              ║
║                          ▼                                              ║
║         ┌──────────────────────────────────────┐                       ║
║         │     FINAL CORRECTED RESPONSE         │                       ║
║         │  + Metadata & Telemetry              │                       ║
║         └──────────────────────────────────────┘                       ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝
                          │
                          ▼
         ┌────────────────────────────────────────────────────┐
         │           UPDATE SESSION CONTEXT                   │
         │  • Add user message to history                     │
         │  • Add AI response to history                      │
         │  • Update topic tracking                           │
         │  • Store telemetry                                 │
         └────────────────────────────────────────────────────┘
                          │
                          ▼
                    RESPONSE TO USER


═══════════════════════════════════════════════════════════════════════════
                           TELEMETRY COLLECTED
═══════════════════════════════════════════════════════════════════════════

{
  "memoryClaimsDetected": 2,
  "invalidMemoryClaims": 1,
  "memoryClaimsCorrected": true,
  "mathExpressionsFound": 1,
  "mathErrors": 1,
  "mathCorrected": true,
  "learningStyleDetected": "visual",
  "styleConfidence": 0.85,
  "corrections": ["Corrected false memory claims", "Added math verification"],
  "processingTimeMs": 234,
  "usedFallback": false
}


═══════════════════════════════════════════════════════════════════════════
                         DATA PERSISTENCE (Opt-in)
═══════════════════════════════════════════════════════════════════════════

Firestore Collection: user_profiles/{userId}
{
  "userId": "user_123",
  "displayName": "Alex",
  "learningPreferences": {
    "visual": 0.8,
    "auditory": 0.4,
    "kinesthetic": 0.5,
    "reading": 0.6,
    "preferredDepth": "detailed"
  },
  "skillScores": {
    "subjectMastery": {
      "mathematics": 0.75,
      "science": 0.60
    }
  },
  "optInFlags": {
    "profileStorage": true,
    "learningAnalytics": true,
    "personalization": true,
    "semanticMemory": false
  },
  "lastSeen": "2025-10-01T10:30:00Z"
}


═══════════════════════════════════════════════════════════════════════════
                          FEATURE FLAGS CONTROL
═══════════════════════════════════════════════════════════════════════════

Development Mode:
  memoryValidation:  ✓ ENABLED
  mathValidation:    ✓ ENABLED  
  styleAdaptation:   ✓ ENABLED
  profileStorage:    ✓ ENABLED
  rolloutPercentage: 100%

Production Mode (Week 2):
  memoryValidation:  ✓ ENABLED
  mathValidation:    ✓ ENABLED
  styleAdaptation:   ✗ DISABLED (coming Week 3)
  profileStorage:    ✗ DISABLED (requires UI)
  rolloutPercentage: 10%
  betaUsers:        [dev_1, dev_2, beta_user_42]
```

## Key Benefits

1. **Non-Invasive**: Wraps existing LLM without replacing it
2. **Toggleable**: Any feature can be enabled/disabled instantly
3. **Safe**: Fallback responses when validation fails
4. **Privacy-First**: All storage is opt-in
5. **Measurable**: Complete telemetry on every interaction
6. **Testable**: Automated regression suite

## Performance Impact

- Pre-processing: ~50ms (context loading + style detection)
- Post-processing: ~150ms (memory + math validation)
- **Total overhead: ~200ms** (acceptable for improved quality)

## Data Flow Summary

1. User → Feature Flags Check → Pre-processing
2. Pre-processing → Enhanced Prompt → LLM
3. LLM → Post-processing → Validation & Correction
4. Final Response → User + Telemetry + Optional Storage
