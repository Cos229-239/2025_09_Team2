# 🚀 How to Test the AI Tutor Middleware

## The Simplest Way to Test (5 Minutes)

### Step 1: Make Sure It's Integrated
Check that you've added the middleware to your code (see `QUICK_START_CHECKLIST.md`).

### Step 2: Run Your App
```powershell
flutter run -d edge
```

### Step 3: Open Browser Console
- Press `F12` in Edge/Chrome
- Click the **Console** tab

### Step 4: Test in AI Tutor Chat

Try these 4 quick tests:

#### ✅ Test 1: False Memory Detection
**Type**: "Do you remember what we discussed yesterday?"  
**Expected**: AI says it doesn't remember (not claiming false memory)  
**What this tests**: Memory claim validation

#### ✅ Test 2: Math Validation  
**Type**: "What is 5 + 7?"  
**Expected**: Correct answer (12)  
**What this tests**: Math engine

#### ✅ Test 3: Learning Style
**Type**: "Can you show me a visual diagram?"  
**Expected**: Console shows learning style detection logs  
**What this tests**: Learning style detector

#### ✅ Test 4: Session Memory
**Type**: "Explain photosynthesis"  
**Wait for response**, then type: "What did we just discuss?"  
**Expected**: AI correctly recalls photosynthesis discussion  
**What this tests**: SessionContext tracking

### Step 5: Check Console Logs

You should see logs like:
```
[AITutorMiddleware] Pre-processing message for user: ...
[LearningStyleDetector] Detected style: Visual: 0.60...
[AITutorMiddleware] Post-processing complete. Memory valid: true, Math valid: true
```

## ✅ If You See These Logs → It's Working!

---

## 🐛 Not Working?

### No middleware logs appearing?

1. **Check integration**: Did you add the 3 lines to `enhanced_ai_tutor_provider.dart`?
2. **Check feature flags**: Add `FeatureFlags.setDevelopmentMode();` in `main.dart`
3. **Check imports**: Make sure you imported the middleware classes

### Still stuck?

See detailed troubleshooting in `TESTING_GUIDE.md`

---

## 📋 Success Checklist

- [ ] Console shows middleware logs
- [ ] False memory test passes
- [ ] Math validation test passes
- [ ] Learning style detection test passes
- [ ] Session memory test passes
- [ ] No crashes or errors

---

## Next: Production Rollout

Once all tests pass:
1. Follow the 4-week rollout plan in `AI_TUTOR_INTEGRATION_PLAN.md`
2. Start with internal team (Week 1)
3. Gradually expand to all users

**Total testing time**: ~5-10 minutes  
**Difficulty**: Easy ⭐  
**Tools needed**: Just your browser

That's it! 🎉
