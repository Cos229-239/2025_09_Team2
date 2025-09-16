# StudyPals Development Branch Guide

## 🌳 Branch Structure

### 📦 **main** (Production)
- **Purpose**: Stable, production-ready code
- **Protection**: Only merge tested, complete features
- **Deployment**: This branch gets deployed to production
- **Commits**: Only via pull requests from feature branches

### 🎨 **ui-improvements** (UI Development)
- **Purpose**: User interface enhancements and design work
- **Focus Areas**:
  - Theme improvements
  - Component styling
  - Layout optimizations
  - Responsive design
  - Animation and transitions
  - User experience improvements

### ⚙️ **backend-features** (Backend Development)  
- **Purpose**: Server-side functionality and data management
- **Focus Areas**:
  - Database enhancements
  - API integrations
  - Authentication improvements
  - Data models and services
  - Performance optimizations
  - AI service improvements

## 🔄 Workflow Commands

### Switch Between Branches
```bash
# Switch to main (stable)
git checkout main

# Switch to UI work
git checkout ui-improvements

# Switch to backend work  
git checkout backend-features
```

### Work on Features
```bash
# Start UI work
git checkout ui-improvements
# Make changes...
git add .
git commit -m "UI: Add new dashboard theme"
git push origin ui-improvements

# Start backend work
git checkout backend-features  
# Make changes...
git add .
git commit -m "Backend: Improve database performance"
git push origin backend-features
```

### Merge to Main (When Ready)
```bash
# Option 1: Via GitHub Pull Request (Recommended)
# 1. Go to GitHub.com
# 2. Create pull request from feature branch to main
# 3. Review and merge

# Option 2: Direct merge (if working alone)
git checkout main
git merge ui-improvements
git push origin main
```

## 📋 Development Guidelines

### Commit Message Format
- **UI**: `UI: Add responsive navigation menu`
- **Backend**: `Backend: Implement user analytics API`
- **Fix**: `Fix: Resolve login authentication bug`
- **Feature**: `Feature: Add AI flashcard generator`

### Before Merging to Main
- [ ] Test thoroughly
- [ ] No console errors
- [ ] All features working
- [ ] Code reviewed
- [ ] Documentation updated

## 🚀 Current Status

- **main**: ✅ AI integration complete, production ready
- **ui-improvements**: 🎨 Ready for UI development
- **backend-features**: ⚙️ Ready for backend development

## 🎯 Recommended Workflow

1. **Daily Development**: Work on feature branches
2. **Testing**: Test changes before committing
3. **Regular Commits**: Commit small, logical changes
4. **Pull Requests**: Use GitHub PRs for code review
5. **Clean Main**: Keep main branch stable and deployable

---
*Created: September 6, 2025*  
*Repository: 2025_09_Team2*  
*Team: Cos229-239*
