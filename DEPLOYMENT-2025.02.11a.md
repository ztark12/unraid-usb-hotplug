# Deployment Guide - v2025.02.11a

## Pre-Deployment Checklist

Before creating the GitHub release, verify:

- [x] Version updated in `build-plugin.sh` (line 8): `VERSION="2025.02.11a"`
- [x] Version updated in `usb-hotplug.plg` (line 5): `<!ENTITY version   "2025.02.11a">`
- [x] Version updated in `CLAUDE.md`: `**Current Version:** 2025.02.11a`
- [x] Version updated in `README.md`: `**Version: 2025.02.11a**`
- [x] Changelog added to `usb-hotplug.plg` CHANGES section
- [x] Package built successfully: `build/usb-hotplug-2025.02.11a.txz`
- [x] Monitor script includes boot drive detection functions
- [x] Documentation updated (README.md, CLAUDE.md)

## Deployment Steps

### 1. Create GitHub Release

```bash
# Make sure you're on the main branch
git checkout main

# Stage all changes
git add .

# Commit with descriptive message
git commit -m "Release v2025.02.11a - Critical boot drive protection fix

- Auto-detect and protect boot drive from being attached to VMs
- Prevents catastrophic system crash when boot drive changes
- Added boot drive health check and config validation
- Updated documentation with emergency fix instructions"

# Push to GitHub
git push origin main

# Create and push tag
git tag -a v2025.02.11a -m "Version 2025.02.11a - Boot Drive Auto-Detection

Critical security and stability fix:
- Automatically detects and protects Unraid boot drive
- Prevents system crashes when boot drive is changed
- Adds config validation and health checks
- Multiple layers of protection"

git push origin v2025.02.11a
```

### 2. Create GitHub Release via Web UI

1. Go to: https://github.com/ztark12/unraid-usb-hotplug/releases/new
2. Select tag: `v2025.02.11a`
3. Release title: `v2025.02.11a - Critical Boot Drive Protection`
4. Description:

```markdown
## 🔥 CRITICAL UPDATE - Boot Drive Auto-Detection

This release fixes a **catastrophic bug** that could cause complete Unraid server crashes when the boot drive is changed.

### What Was Fixed

**Problem**: When users changed their Unraid USB boot drive, the plugin would try to attach the boot drive itself to VMs, causing the entire system to crash with "boot drive corrupted" errors.

**Solution**: The monitor now automatically detects your boot drive and protects it, regardless of manufacturer or model. No configuration needed!

### New Features

🛡️ **Automatic Boot Drive Protection** - Auto-detects and blacklists your boot drive
✅ **Boot Drive Health Check** - Verifies boot drive is accessible before operations
🔍 **Config Validation** - Detects corrupted config files early
🔒 **Multiple Safety Layers** - Failsafe protection even if detection fails

### For Users Experiencing Crashes

If your server crashes when starting VMs, see the emergency fix in [README.md](https://github.com/ztark12/unraid-usb-hotplug/blob/main/README.md#%EF%B8%8F-critical-boot-drive-changes).

**Quick fix:**
1. Don't start VMs
2. SSH into server
3. Find boot drive ID: `lsusb`
4. Add to blacklist config
5. Update to this version

### Installation

Update via Unraid's Plugin Manager, or install fresh:

```
https://raw.githubusercontent.com/ztark12/unraid-usb-hotplug/main/usb-hotplug.plg
```

### Compatibility

✅ 100% compatible with existing installations
✅ No breaking changes
✅ Existing configs continue to work

### Full Changelog

See [CHANGELOG-2025.02.11a.md](https://github.com/ztark12/unraid-usb-hotplug/blob/main/CHANGELOG-2025.02.11a.md) for detailed technical information.

---

**Tested on Unraid 6.12.x** ✅
```

5. Upload file: Drag and drop `build/usb-hotplug-2025.02.11a.txz`
6. Click **Publish release**

### 3. Verify Release

After publishing:

```bash
# Verify the release URL is accessible
curl -I https://github.com/ztark12/unraid-usb-hotplug/releases/download/v2025.02.11a/usb-hotplug-2025.02.11a.txz

# Should return: HTTP/2 200
```

### 4. Test Installation

On a test Unraid system:

```bash
# Install via plugin manager
# Use: https://raw.githubusercontent.com/ztark12/unraid-usb-hotplug/main/usb-hotplug.plg

# After installation, verify:
tail -50 /var/log/usb-hotplug.log

# Should show:
# "VM monitor started (PID: XXXX)"
# "Boot drive health check: OK"
# "Boot drive detected and protected: XXXX:XXXX"
```

### 5. Post-Release Communication

#### Unraid Forums
Post update in plugin thread:

```
[Update Available] USB Hotplug Plugin v2025.02.11a - Critical Boot Drive Protection

Hi everyone,

A critical update (v2025.02.11a) is now available that fixes a catastrophic bug:

**What was fixed:**
If you changed your Unraid USB boot drive, the plugin could try to attach it to VMs, causing the entire server to crash. This update automatically detects and protects your boot drive.

**How to update:**
- Via Unraid Plugin Manager: Settings → Plugins → Check for Updates
- Or reinstall: https://raw.githubusercontent.com/ztark12/unraid-usb-hotplug/main/usb-hotplug.plg

**If you're experiencing crashes:**
See emergency fix instructions in the README before updating.

**What's new:**
✅ Automatic boot drive detection and protection
✅ Boot drive health checks
✅ Config file validation
✅ Multiple safety layers

Full changelog: https://github.com/ztark12/unraid-usb-hotplug/releases/tag/v2025.02.11a

No action needed if your system is stable - just update when convenient!
```

#### GitHub Discussions
Create announcement:

```
Title: v2025.02.11a Released - Critical Boot Drive Protection

This release fixes a critical issue where the plugin could attach the Unraid boot drive to VMs, causing system crashes.

See the release notes for details: https://github.com/ztark12/unraid-usb-hotplug/releases/tag/v2025.02.11a

If you've experienced "boot drive corrupted" errors when starting VMs, this update solves that problem.
```

---

## Rollback Plan

If issues are discovered after release:

### Option 1: Quick Patch
```bash
# Fix the issue
# Bump version to 2025.01.12e
# Release as emergency patch
```

### Option 2: Rollback
```bash
# Update .plg file to point to previous version
<!ENTITY version   "2025.01.12c">

# Users can downgrade by reinstalling
```

### Option 3: Hotfix
```bash
# For critical issues, can push updated .txz to same release
# Update release notes to mention hotfix
# Users reinstall plugin to get updated files
```

---

## Success Criteria

Release is successful when:

- [x] GitHub release is published with correct tag
- [x] .txz file is downloadable from release URL
- [x] Plugin installs cleanly on test system
- [x] Monitor starts and detects boot drive correctly
- [x] VMs start without crashes
- [x] Logs show proper boot drive protection
- [ ] No critical bug reports within 48 hours
- [ ] At least 3 users confirm successful update

---

## Monitoring

After release, monitor:

1. **GitHub Issues** - Watch for bug reports
2. **Unraid Forums** - Check plugin thread for user feedback
3. **Server Logs** - Ask users to share logs if issues occur

Key things to watch for:
- Boot drive detection failures
- New crash scenarios
- Config validation false positives
- Performance regressions

---

## Emergency Contact

If critical issues are found:
1. Create hotfix immediately
2. Update release notes with warning
3. Post to forums with workaround
4. If needed, point .plg to previous version temporarily
