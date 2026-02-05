---
description: Run a full project health check and update indexing logs. Includes Deep Scan for code quality.
---

# Project Health Check (Deep Scan)

Use this workflow to perform a deep audit of the codebase against the "Gold Standard" rules defined in the `project-brain` skill.

## 🛠️ Automated Audit Steps

// turbo
1. **Static Analysis & Linting**
   Check for syntax errors, unused imports, and style violations.
   ```powershell
   flutter analyze
   ```

2. **Hardcoding & Magic Number Audit**
   Search for potential hardcoded strings or numbers that should be in `utils.dart`.
   ```powershell
   # Search for strings inside lib/ that might be hardcoded (ignoring imports/logs)
   grep -r "['\"][^'\"]*['\"]" lib/ | grep -v "import" | grep -v "print" | head -n 20
   ```

3. **Play Store Readiness Check**
   Verify versioning and critical Android permissions.
   ```powershell
   # Check version in pubspec
   cat pubspec.yaml | grep "version:"
   # Check for wallpaper permissions
   cat android/app/src/main/AndroidManifest.xml | grep "SET_WALLPAPER"
   ```

4. **Architectural Consistency**
   Ensure business logic isn't leaking into the `pages/` directory.
   ```powershell
   # Check if pages are directly calling rare APIs that should be in services
   grep -r "dart:io" lib/pages/
   grep -r "package:http" lib/pages/
   ```

5. **TODO & Debt Tracking**
   Identify all pending tasks.
   ```powershell
   grep -rn "TODO" lib/
   ```

## 📊 Final Assessment
After running the steps above:
- **High Health**: 0 errors, version updated, no hardcoding found.
- **Medium Health**: Linting warnings present, or minor hardcoding.
- **Low Health**: Missing permissions, analysis errors, or severe logic duplication.
