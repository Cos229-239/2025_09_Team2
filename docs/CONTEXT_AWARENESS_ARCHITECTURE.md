# 🎨 ChatGPT Context Awareness - Visual Architecture

## 📊 System Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         STUDENT INTERACTION                         │
└────────────────────────────────┬────────────────────────────────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │  User sends message:   │
                    │ "My favorite color is  │
                    │        blue"           │
                    └───────────┬────────────┘
                                │
                                ▼
                    ┌────────────────────────┐
                    │   SessionContext       │
                    │   addMessage()         │
                    │   ✅ Stored (1/100)    │
                    └───────────┬────────────┘
                                │
                                ▼
                    ┌────────────────────────┐
                    │  AI responds with      │
                    │  acknowledgment        │
                    └───────────┬────────────┘
                                │
                                ▼
                    ┌────────────────────────┐
                    │   SessionContext       │
                    │   addMessage()         │
                    │   ✅ Stored (2/100)    │
                    └───────────┬────────────┘
                                │
                                ▼
                    ┌────────────────────────┐
                    │  User asks:            │
                    │ "What's my favorite    │
                    │      color?"           │
                    └───────────┬────────────┘
                                │
                ┌───────────────┴────────────────┐
                ▼                                ▼
    ┌───────────────────────┐      ┌─────────────────────────┐
    │ _buildConversationHist│      │ Memory Query Detected!  │
    │ Gets last 20 messages │      │ Keywords: "favorite",   │
    │                       │      │          "color"        │
    └───────┬───────────────┘      └────────┬────────────────┘
            │                                │
            │                                ▼
            │                  ┌─────────────────────────────┐
            │                  │ _findRelevantPastMessages() │
            │                  │ Semantic Search Engine      │
            │                  │ ┌─────────────────────────┐ │
            │                  │ │ 1. Extract keywords     │ │
            │                  │ │ 2. Score all messages   │ │
            │                  │ │ 3. Apply recency bonus  │ │
            │                  │ │ 4. Sort by relevance    │ │
            │                  │ │ 5. Return top 5         │ │
            │                  │ └─────────────────────────┘ │
            │                  └────────┬────────────────────┘
            │                           │
            │                           ▼
            │                  ┌─────────────────────────────┐
            │                  │ _buildRelevantContext()     │
            │                  │ Formats semantic matches    │
            │                  │                             │
            │                  │ RELEVANT PAST CONTEXT:      │
            │                  │ [STUDENT - 2m ago]:         │
            │                  │ "My favorite color is blue" │
            │                  └────────┬────────────────────┘
            │                           │
            └───────────────┬───────────┘
                            │
                            ▼
              ┌──────────────────────────────────┐
              │   _buildAdaptivePrompt()         │
              │   Constructs complete prompt:    │
              │                                  │
              │   CONVERSATION HISTORY:          │
              │   [STUDENT - 2m ago]: My         │
              │   favorite color is blue         │
              │   [AI TUTOR - 1m ago]: Great!    │
              │   [STUDENT - just now]: What's   │
              │   my favorite color?             │
              │                                  │
              │   RELEVANT PAST CONTEXT:         │
              │   [STUDENT - 2m ago]: My         │
              │   favorite color is blue         │
              │                                  │
              │   CRITICAL MEMORY RETRIEVAL:     │
              │   Check conversation history     │
              │   above and answer accurately!   │
              └─────────────┬────────────────────┘
                            │
                            ▼
              ┌──────────────────────────────────┐
              │     AI Model Processing          │
              │  Reads full context including:   │
              │  • Last 20 messages              │
              │  • Relevant past messages        │
              │  • Memory retrieval instructions │
              └─────────────┬────────────────────┘
                            │
                            ▼
              ┌──────────────────────────────────┐
              │    AI generates response:        │
              │ "Your favorite color is blue,    │
              │  as you mentioned earlier!"      │
              └─────────────┬────────────────────┘
                            │
                            ▼
              ┌──────────────────────────────────┐
              │   AITutorMiddleware.             │
              │   processAIResponse()            │
              │   Validates response:            │
              │   ✅ Memory claim valid          │
              │   ✅ No math to validate         │
              │   ℹ️ Learning style detected     │
              └─────────────┬────────────────────┘
                            │
                            ▼
              ┌──────────────────────────────────┐
              │   Status badges added:           │
              │   ✅ Memory: PASSED              │
              │   ℹ️ Learning Style: 78%         │
              │                                  │
              │   Final response:                │
              │   "Your favorite color is blue,  │
              │    as you mentioned earlier!"    │
              └─────────────┬────────────────────┘
                            │
                            ▼
              ┌──────────────────────────────────┐
              │   Display to student             │
              │   SessionContext.addMessage()    │
              │   ✅ Stored (3/100)              │
              └──────────────────────────────────┘
```

---

## 🧩 Component Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                    EnhancedAITutorProvider                     │
│  (Main orchestrator)                                           │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │           Context Awareness Components                   │ │
│  │                                                          │ │
│  │  ┌─────────────────────────────────────────────────┐   │ │
│  │  │  _buildConversationHistory()                    │   │ │
│  │  │  • Gets last 20 messages from SessionContext    │   │ │
│  │  │  • Formats with roles & timestamps              │   │ │
│  │  │  • Adds topic summary                           │   │ │
│  │  │  Returns: "CONVERSATION HISTORY: ..."           │   │ │
│  │  └─────────────────────────────────────────────────┘   │ │
│  │                                                          │ │
│  │  ┌─────────────────────────────────────────────────┐   │ │
│  │  │  _findRelevantPastMessages(query)               │   │ │
│  │  │  • Extracts keywords from query                 │   │ │
│  │  │  • Scores all messages by relevance             │   │ │
│  │  │  • Applies recency weighting                    │   │ │
│  │  │  • Sorts and returns top 5 matches              │   │ │
│  │  │  Returns: List<ChatMessage>                     │   │ │
│  │  └─────────────────────────────────────────────────┘   │ │
│  │                                                          │ │
│  │  ┌─────────────────────────────────────────────────┐   │ │
│  │  │  _buildRelevantContext(query)                   │   │ │
│  │  │  • Detects memory queries                       │   │ │
│  │  │  • Calls _findRelevantPastMessages()            │   │ │
│  │  │  • Formats as context section                   │   │ │
│  │  │  Returns: "RELEVANT PAST CONTEXT: ..."          │   │ │
│  │  └─────────────────────────────────────────────────┘   │ │
│  │                                                          │ │
│  │  ┌─────────────────────────────────────────────────┐   │ │
│  │  │  _extractRelevantKeywords(text)                 │   │ │
│  │  │  • Removes stop words                           │   │ │
│  │  │  • Filters by length (> 2 chars)                │   │ │
│  │  │  • Returns unique keywords                      │   │ │
│  │  │  Returns: List<String>                          │   │ │
│  │  └─────────────────────────────────────────────────┘   │ │
│  │                                                          │ │
│  │  ┌─────────────────────────────────────────────────┐   │ │
│  │  │  _formatTimestamp(DateTime)                     │   │ │
│  │  │  • Calculates time difference                   │   │ │
│  │  │  • Returns human-readable format                │   │ │
│  │  │  Returns: "5m ago", "2h ago", etc.              │   │ │
│  │  └─────────────────────────────────────────────────┘   │ │
│  └──────────────────────────────────────────────────────────┘ │
└───────────────────┬────────────────────────────────────────────┘
                    │
                    │ Uses
                    ▼
┌────────────────────────────────────────────────────────────────┐
│                      SessionContext                            │
│  (Ephemeral conversation storage)                              │
│                                                                │
│  Properties:                                                   │
│  • userId: String                                              │
│  • _messages: List<ChatMessage> (max 100)                      │
│  • _topics: Map<String, ConversationTopic>                     │
│  • _sessionStart: DateTime                                     │
│                                                                │
│  Methods:                                                      │
│  • addMessage(ChatMessage)                                     │
│  • getAllMessages() → List<ChatMessage>                        │
│  • getRecentMessages(limit: 10) → List<ChatMessage>            │
│  • getRecentTopics(topK: 10) → List<ConversationTopic>         │
│  • hasDiscussedTopic(topic) → bool                             │
│  • clear()                                                     │
└────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow for Memory Queries

```
┌─────────────┐
│   Student   │
└──────┬──────┘
       │
       │ "My favorite color is blue"
       ▼
┌─────────────────────┐
│  SessionContext     │
│  Messages: [        │
│    {                │
│      type: user,    │
│      content: "My   │
│      favorite color │
│      is blue",      │
│      timestamp: T1  │
│    }                │
│  ]                  │
└─────────────────────┘
       │
       │ AI responds
       ▼
┌─────────────────────┐
│  SessionContext     │
│  Messages: [        │
│    { user, ... },   │
│    {                │
│      type: ai,      │
│      content: "Great│
│      I'll remember" │
│      timestamp: T2  │
│    }                │
│  ]                  │
└─────────────────────┘
       │
       │ Student asks: "What's my favorite color?"
       ▼
┌────────────────────────────────────────┐
│  Query Analysis                        │
│  • Keywords: ["favorite", "color"]     │
│  • Intent: confirmatory/factual        │
│  • Memory query: TRUE ✅               │
└──────────────┬─────────────────────────┘
               │
               ├─────────────────┐
               │                 │
               ▼                 ▼
   ┌───────────────────┐  ┌────────────────────┐
   │ Conversation      │  │ Semantic Search    │
   │ History Builder   │  │ Engine             │
   │                   │  │                    │
   │ Gets messages:    │  │ 1. Extract:        │
   │ [user msg T1,     │  │    ["favorite",    │
   │  ai msg T2,       │  │     "color"]       │
   │  user msg T3]     │  │                    │
   │                   │  │ 2. Score:          │
   │ Formats:          │  │    Msg T1: 2.8 ⭐  │
   │ "[STUDENT - 2m]:  │  │    Msg T2: 1.5     │
   │  My favorite      │  │    Msg T3: 0.9     │
   │  color is blue"   │  │                    │
   │                   │  │ 3. Return:         │
   │                   │  │    [Msg T1]        │
   └─────────┬─────────┘  └─────────┬──────────┘
             │                      │
             │                      │
             └──────────┬───────────┘
                        │
                        ▼
            ┌─────────────────────────┐
            │   Prompt Constructor    │
            │                         │
            │   CONVERSATION HISTORY: │
            │   [Full context]        │
            │                         │
            │   RELEVANT PAST:        │
            │   [Semantic matches]    │
            │                         │
            │   CRITICAL:             │
            │   Use context to answer │
            └────────┬────────────────┘
                     │
                     ▼
            ┌─────────────────────────┐
            │      AI Model           │
            │   Reads both sections   │
            │   Finds "blue" in T1    │
            │   Generates answer      │
            └────────┬────────────────┘
                     │
                     ▼
            ┌─────────────────────────┐
            │   Response:             │
            │ "Your favorite color is │
            │  blue, as you mentioned │
            │  earlier!"              │
            └─────────────────────────┘
```

---

## 🎯 Semantic Search Scoring Algorithm

```
For each message in SessionContext:

  score = 0
  
  ┌─────────────────────────────────────────┐
  │ Step 1: Keyword Matching                │
  │                                         │
  │ For each query keyword:                 │
  │   If keyword in message.content:        │
  │     score += 1.0                        │
  │                                         │
  │   If exact word match (not substring):  │
  │     score += 0.5 (bonus)                │
  └─────────────────────────────────────────┘
            │
            ▼
  ┌─────────────────────────────────────────┐
  │ Step 2: Recency Weighting               │
  │                                         │
  │ age = now - message.timestamp           │
  │ recency_bonus = 1.0 / (1.0 + age/60)    │
  │ score += recency_bonus * 0.3            │
  │                                         │
  │ Examples:                               │
  │ • Just now: +0.30                       │
  │ • 1 hour ago: +0.15                     │
  │ • 5 hours ago: +0.05                    │
  └─────────────────────────────────────────┘
            │
            ▼
  ┌─────────────────────────────────────────┐
  │ Step 3: Sorting & Selection             │
  │                                         │
  │ Sort all messages by score (descending) │
  │ Take top 5 results                      │
  │ Return as List<ChatMessage>             │
  └─────────────────────────────────────────┘

Example Scoring:
─────────────────────────────────────────────────────
Message                           | Score  | Selected
─────────────────────────────────────────────────────
"My favorite color is blue"       | 2.8    | ✅ Rank 1
"I like blue and green"           | 1.4    | ✅ Rank 2  
"What's your favorite animal?"    | 1.2    | ✅ Rank 3
"Blue is a nice color"            | 1.1    | ✅ Rank 4
"Tell me about colors"            | 1.0    | ✅ Rank 5
"Can you help with math?"         | 0.3    | ❌ Too low
─────────────────────────────────────────────────────
```

---

## 📦 Storage Architecture

```
┌───────────────────────────────────────────────────┐
│              EPHEMERAL STORAGE                    │
│          (Clears on app restart)                  │
│                                                   │
│  ┌─────────────────────────────────────────────┐ │
│  │         SessionContext (Memory)             │ │
│  │                                             │ │
│  │  Max Capacity: 100 messages                 │ │
│  │  Current Usage: 23/100                      │ │
│  │                                             │ │
│  │  Messages Array:                            │ │
│  │  ┌─────────────────────────────────────┐   │ │
│  │  │ [0] ChatMessage {                   │   │ │
│  │  │       type: user,                   │   │ │
│  │  │       content: "Help with math",    │   │ │
│  │  │       timestamp: 2024-10-01 14:23   │   │ │
│  │  │     }                               │   │ │
│  │  │ [1] ChatMessage { ... }             │   │ │
│  │  │ [2] ChatMessage { ... }             │   │ │
│  │  │ ...                                 │   │ │
│  │  │ [22] ChatMessage {                  │   │ │
│  │  │       type: user,                   │   │ │
│  │  │       content: "What's my favorite" │   │ │
│  │  │       timestamp: 2024-10-01 14:45   │   │ │
│  │  │      }                              │   │ │
│  │  └─────────────────────────────────────┘   │ │
│  │                                             │ │
│  │  Topics Map:                                │ │
│  │  ┌─────────────────────────────────────┐   │ │
│  │  │ "algebra": ConversationTopic {      │   │ │
│  │  │   topic: "algebra",                 │   │ │
│  │  │   score: 0.85,                      │   │ │
│  │  │   mentionCount: 4,                  │   │ │
│  │  │   lastMention: 2024-10-01 14:30     │   │ │
│  │  │ }                                   │   │ │
│  │  │ "color": ConversationTopic { ... }  │   │ │
│  │  │ "favorite": ConversationTopic {...} │   │ │
│  │  └─────────────────────────────────────┘   │ │
│  └─────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────┐
│           PERSISTENT STORAGE (Optional)           │
│         (Survives app restart - future)           │
│                                                   │
│  ┌─────────────────────────────────────────────┐ │
│  │        UserProfileStore (Firestore)         │ │
│  │                                             │ │
│  │  Could store:                               │ │
│  │  • Learning preferences                     │ │
│  │  • Important facts (with consent)           │ │
│  │  • Topic progress                           │ │
│  │  • Study goals                              │ │
│  │                                             │ │
│  │  NOT currently used for conversation        │ │
│  │  history (privacy-first design)             │ │
│  └─────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────┘
```

---

## 🔄 Message Lifecycle

```
┌──────────────┐
│  User types  │
│   message    │
└──────┬───────┘
       │
       ▼
┌─────────────────────────┐
│  ChatMessage created:   │
│  {                      │
│    type: user,          │
│    content: "...",      │
│    timestamp: now,      │
│    id: uuid             │
│  }                      │
└──────┬──────────────────┘
       │
       ▼
┌─────────────────────────┐
│ SessionContext.         │
│ addMessage()            │
│                         │
│ • Appends to _messages  │
│ • Extracts topics       │
│ • Trims if > 100        │
└──────┬──────────────────┘
       │
       ▼
┌─────────────────────────┐
│  AI processes with      │
│  full context           │
└──────┬──────────────────┘
       │
       ▼
┌─────────────────────────┐
│  ChatMessage created:   │
│  {                      │
│    type: ai,            │
│    content: "...",      │
│    timestamp: now,      │
│    id: uuid             │
│  }                      │
└──────┬──────────────────┘
       │
       ▼
┌─────────────────────────┐
│ Middleware validation   │
│ (badges added)          │
└──────┬──────────────────┘
       │
       ▼
┌─────────────────────────┐
│ SessionContext.         │
│ addMessage()            │
│                         │
│ • Appends to _messages  │
│ • Updates topics        │
└──────┬──────────────────┘
       │
       ▼
┌─────────────────────────┐
│  Display to user        │
│  with badges            │
└─────────────────────────┘

Retention:
• Messages: Until app restart or 100 limit
• Topics: Continuously updated with recency weighting
• Context: Available for all future queries in session
```

---

## 🎨 Visual Comparison

### Without Context Awareness ❌
```
User: "My favorite is blue"
         ↓
      [Store in DB?]
         ↓
        [Lost]
         ↓
User: "What's my favorite?"
         ↓
      [No context]
         ↓
AI: "I don't know. Please tell me."
```

### With Context Awareness ✅
```
User: "My favorite is blue"
         ↓
   [SessionContext]
    📝 Message #1
         ↓
User: "What's my favorite?"
         ↓
   [Semantic Search]
    🔍 Found: #1
         ↓
   [Prompt includes]
    📋 Full history
         ↓
AI: "Your favorite is blue!"
```

---

*Visual architecture guide for ChatGPT-level context awareness*  
*Version 2.0 - October 1, 2025*
