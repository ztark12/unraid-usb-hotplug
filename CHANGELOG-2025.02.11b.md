# Changelog - Version 2025.02.11b

## Release Date
2025-02-11

## Summary
Updated USB Hotplug configuration page with improved Unraid-native styling, fixed character encoding issues, and updated version numbering.

## Changes Made

### 1. Version Update (2025.02.11a → 2025.02.11b)
**Files updated:**
- `build-plugin.sh` - Line 8: Updated VERSION variable
- `usb-hotplug.plg` - Line 5: Updated version entity
- `CLAUDE.md` - Line 9: Updated current version reference

**Added to CLAUDE.md:**
- Documented version naming convention (YYYY.MM.DD[a-z])
- Clarified when to increment letter vs date
- Updated from 2 to 3 places to update version (added CLAUDE.md)

### 2. Character Encoding Fixes
**Problem:** Unicode checkmarks (✓, ✕) displayed as garbled text ("âœ•", "âœ")

**Solution:** Replaced with HTML entities
- `✓` → `&check;` (checkmark)
- `✕` → `&times;` (multiplication sign/cross)

**Files affected:**
- `USBHotplug.page` - 5 occurrences fixed (success messages + remove button)

**Locations fixed:**
- Monitor restart success message
- Monitor stop success message
- Log clear success message
- Device remove button label
- JavaScript auto-save success messages (2 places)

### 3. CSS Improvements - Unraid Design System Compliance

**Design Philosophy:**
- Matched Unraid's dark theme aesthetic
- Used subtle backgrounds and borders for visual hierarchy
- Maintained #ff8c00 (orange) as primary accent color
- Improved readability with better contrast ratios

**Specific CSS Changes:**

#### Status Box
- Reduced background opacity (0.2 → 0.15)
- Reduced border opacity (solid → rgba 0.5)
- Added font-weight: 500

#### Messages (Success/Error)
- Matched status box styling for consistency
- Increased padding (10px → 12px 15px)

#### Device Management Section
- Added dark background: rgba(0, 0, 0, 0.15)
- Added subtle border: 1px solid rgba(255, 255, 255, 0.1)
- Increased border-radius (5px → 4px for consistency)

#### Device List Container
- Darker background: rgba(0, 0, 0, 0.2)
- Even more subtle border: rgba(255, 255, 255, 0.08)
- Added overflow: hidden for clean edges

#### Device Rows
- Increased padding (12px → 14px 16px)
- More subtle borders: rgba(255, 255, 255, 0.08)
- Hover effect: Orange tint rgba(255, 140, 0, 0.08)
- Protected rows: Darker background on hover
- Smoother transitions (0.2s → 0.15s ease)

#### Checkboxes
- Defined size: 16x16px
- Reduced disabled opacity (0.5 → 0.4)

#### Device Info
- Improved typography with Consolas fallback
- Better font weights (device ID now 500)
- More spacing (margin-left: 12px)

#### Badges
- Uppercase text with letter-spacing
- Refined padding (2px 8px → 3px 10px)
- Smaller font (11px → 10px)
- Added font-weight: 600
- Protection badge: Pure white text (#fff)
- Disconnected badge: Semi-transparent gray background

#### Remove Button
- Semi-transparent initial state: rgba(220, 53, 69, 0.8)
- Solid on hover: #dc3545
- Larger padding (4px 8px → 6px 10px)
- Bigger text (16px → 18px)
- Better line-height

#### Save Indicator
- Increased opacity (0.9 → 0.95)
- Added box-shadow for depth
- Better padding (10px 20px → 12px 20px)
- Reduced font-weight (bold → 500)

#### Log Viewer
- Darker background: rgba(0, 0, 0, 0.4)
- Added subtle border
- Improved line-height: 1.5
- Consistent border-radius: 4px

## Files Modified
1. `build-plugin.sh` - Version update
2. `usb-hotplug.plg` - Version update
3. `CLAUDE.md` - Version update + documentation
4. `USBHotplug.page` - Character encoding + CSS improvements
5. `test-ui-preview.html` - Updated to match new styling

## Testing
- ✅ Plugin builds successfully
- ✅ Package contains updated files
- ✅ HTML entities verified in package
- ✅ New CSS verified in package
- ✅ Static preview updated and functional
- ⏳ Runtime testing pending (requires Unraid installation)

## Breaking Changes
None - All changes are cosmetic/presentational

## Upgrade Notes
- No configuration changes required
- Existing blacklist files fully compatible
- No changes to monitor or hotplug scripts
- UI improvements only

## Known Issues
None

## Next Steps
1. Upload `build/usb-hotplug-2025.02.11b.txz` to GitHub releases
2. Test installation on Unraid system
3. Verify UI appearance in both light and dark themes
4. Test auto-save functionality
5. Confirm character encoding displays correctly

---
*Generated: 2025-02-11*
