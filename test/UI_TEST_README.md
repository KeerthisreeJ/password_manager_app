# UI Usability Test - Combined File

## Overview
All usability tests have been combined into a single file: **`test_ui_usability.dart`**

This file contains **51 comprehensive test cases** covering all 6 usability user stories.

## File Structure

### `test_ui_usability.dart`
**Total: 51 test cases**

#### US 9: Light/Dark Mode Toggle (8 tests)
- Theme toggle visibility
- Theme switching functionality  
- Theme persistence
- MaterialApp theme matching
- Rapid toggle handling
- Accessibility labels

#### US 14: Better Loading Indicators (6 tests)
- Login loading state
- Immediate loading visibility (< 100ms)
- Register loading state
- Loading indicator styling
- No stacking indicators
- Button disabled during loading

#### US 15: Improved Error Messages (8 tests)
- Empty field validation
- Short password validation
- User-friendly messaging (no jargon)
- SnackBar visibility
- Error dismissal
- Distinguishable styling
- Actionable error content

#### US 10: Keyboard Navigation (9 tests)
- Tab navigation
- Enter key submission
- Keyboard types
- Text input actions
- Button accessibility
- Focus indicators
- Logical navigation order

#### US 11: Accessibility Labels (9 tests)
- Icon tooltips
- Form field labels
- Descriptive button text
- Semantic widgets
- Screen reader compatibility
- App title
- Password visibility toggle
- Clear, descriptive labels

#### US 7: Responsive Layout (11 tests)
- Multiple screen sizes (600x800 to 1920x1080)
- Login/register page responsiveness
- No horizontal overflow
- Minimum touch targets (40px)
- Text scaling (1.0x to 2.0x)
- Portrait/landscape orientation
- Flexible layout widgets

## Running the Tests

### Run the Combined UI Test File
```bash
cd "d:\SEM 6\Software Eng\Project\password_manager_app"
flutter test test/test_ui_usability.dart
```

### Run with Verbose Output
```bash
flutter test test/test_ui_usability.dart --reporter expanded
```

### Run All Tests
```bash
flutter test
```

## Advantages of Combined File

✅ **Single file** - Easy to run all usability tests at once  
✅ **Organized** - Clear sections for each user story  
✅ **51 tests** - Comprehensive coverage  
✅ **Similar to Python tests** - Follows the pattern of `test_audit.py` and `test_security.py`  
✅ **Easy to maintain** - One file to update  

## Test Output

Each test prints a success message:
```
✓ Test X.X PASSED: [Description]
```

Some tests may be skipped:
```
⚠ Test X.X SKIPPED: [Reason]
```

## Files Created

1. ✅ **`test/test_ui_usability.dart`** - Combined UI test file (51 tests)
2. ✅ `test/test_theme_toggle.dart` - Individual theme tests (8 tests)
3. ✅ `test/test_loading_indicators.dart` - Individual loading tests (6 tests)
4. ✅ `test/test_error_messages.dart` - Individual error tests (8 tests)
5. ✅ `test/test_keyboard_navigation.dart` - Individual keyboard tests (10 tests)
6. ✅ `test/test_accessibility.dart` - Individual accessibility tests (10 tests)
7. ✅ `test/test_responsive_layout.dart` - Individual responsive tests (15 tests)

You can use either the **combined file** or the **individual files** depending on your needs!
