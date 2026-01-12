# Deployment Guide - Publishing Your Plugin

Follow these steps to publish your USB Hotplug plugin for Unraid.

## Step 1: Prepare Your Files

You should have these files ready:
- `usb-hotplug.plg` - Main plugin file
- `build-plugin.sh` - Build script
- `qemu-vm-monitor.sh` - Updated monitor script
- `USBHotplug.page` - Web UI page
- `README.md` - Documentation

## Step 2: Create GitHub Repository

1. Go to https://github.com and create a new repository
2. Repository name: `unraid-usb-hotplug` (or your preferred name)
3. Make it public
4. Initialize with a README (you can replace it later)

## Step 3: Build the Plugin Package

On your local machine (or Unraid server):

```bash
# Make sure you're in the directory with all the files
chmod +x build-plugin.sh
./build-plugin.sh
```

This creates: `build/usb-hotplug-2025.01.12.txz`

## Step 4: Create GitHub Release

1. Go to your repository on GitHub
2. Click **Releases** → **Create a new release**
3. Tag version: `v2025.01.12`
4. Release title: `USB Hotplug v2025.01.12 - Initial Release`
5. Description:
   ```
   Initial release of USB Hotplug plugin for Unraid
   
   Features:
   - Automatic USB device attachment on VM startup
   - Real-time hotplug support
   - Web-based blacklist configuration
   - Crash protection and error recovery
   
   Installation: See README.md
   ```
6. **Upload the .txz file**: `usb-hotplug-2025.01.12.txz`
7. Click **Publish release**

## Step 5: Update Plugin File

Edit `usb-hotplug.plg` and replace `YOUR_USERNAME` with your actual GitHub username:

```xml
<!ENTITY gitURL    "https://raw.githubusercontent.com/YOUR_USERNAME/unraid-usb-hotplug/master">
```

For example, if your GitHub username is `jesper123`:
```xml
<!ENTITY gitURL    "https://raw.githubusercontent.com/jesper123/unraid-usb-hotplug/master">
```

## Step 6: Commit Files to Repository

```bash
# Clone your repository
git clone https://github.com/YOUR_USERNAME/unraid-usb-hotplug.git
cd unraid-usb-hotplug

# Add your files
cp /path/to/usb-hotplug.plg .
cp /path/to/build-plugin.sh .
cp /path/to/qemu-vm-monitor.sh .
cp /path/to/USBHotplug.page .
cp /path/to/README.md .

# Create packages directory structure
mkdir -p packages

# Commit everything
git add .
git commit -m "Initial release of USB Hotplug plugin"
git push origin master
```

## Step 7: Test Installation

On your Unraid server:

1. Go to **Plugins** tab
2. At the bottom, paste:
   ```
   https://raw.githubusercontent.com/YOUR_USERNAME/unraid-usb-hotplug/master/usb-hotplug.plg
   ```
3. Click **Install**
4. Monitor the installation progress
5. Go to **Settings → USB Hotplug** to verify

## Step 8: Submit to Community Applications (Optional)

To make your plugin discoverable in the Unraid App Store:

1. Fork the Community Applications repository:
   https://github.com/Squidly271/AppFeed

2. Add your plugin XML to the appropriate folder

3. Create a pull request

4. Wait for review and approval

## Directory Structure

Your repository should look like this:

```
unraid-usb-hotplug/
├── README.md
├── usb-hotplug.plg
├── build-plugin.sh
├── qemu-vm-monitor.sh
├── USBHotplug.page
├── LICENSE (optional)
└── packages/
    └── (place built .txz files here for easier management)
```

## Updating the Plugin

When you make changes:

1. Update version number in `usb-hotplug.plg`:
   ```xml
   <!ENTITY version   "2025.01.13">
   ```

2. Update CHANGES section:
   ```xml
   <CHANGES>
   ###2025.01.13
   - Fixed: Issue with device detection
   - Added: New feature XYZ
   
   ###2025.01.12
   - Initial release
   </CHANGES>
   ```

3. Rebuild package:
   ```bash
   ./build-plugin.sh
   ```

4. Create new GitHub release with updated .txz

5. Commit and push changes to master branch

6. Users will be notified of the update in Unraid

## Plugin URL Format

Users will install your plugin using this URL:
```
https://raw.githubusercontent.com/YOUR_USERNAME/unraid-usb-hotplug/master/usb-hotplug.plg
```

## Troubleshooting Deployment

### "Could not download plugin"
- Check that usb-hotplug.plg is in the root of your repository
- Verify the repository is public
- Check the URL is correct

### "Package not found"
- Verify .txz file is uploaded to GitHub releases
- Check the version number matches in the .plg file and release tag
- Ensure URL in .plg points to correct location

### "Installation failed"
- Check the CHANGES section has proper XML syntax
- Verify all file paths in the .plg are correct
- Test the installation script sections manually

## Support Resources

- **Unraid Plugin Documentation**: https://wiki.unraid.net/UnRAID_Manual_6:Plugins
- **Community Applications**: https://forums.unraid.net/topic/38582-plug-in-community-applications/
- **Plugin Development Guide**: https://forums.unraid.net/forum/55-plugin-development/

## Security Considerations

- Never include sensitive information (passwords, API keys) in the plugin
- Test thoroughly before releasing to public
- Consider code signing for production releases
- Keep dependencies minimal and audited

## Best Practices

1. **Version numbering**: Use YYYY.MM.DD format for consistency
2. **Changelog**: Always update CHANGES section with each release
3. **Testing**: Test on fresh Unraid install before releasing
4. **Documentation**: Keep README.md updated with all features
5. **Support**: Monitor forum thread for user issues
6. **Backup**: Keep backups of all plugin versions

## Next Steps

After successful deployment:

1. Create a forum thread on Unraid forums
2. Update your README with the forum link
3. Monitor for user feedback and issues
4. Consider creating video tutorial
5. Submit to Community Applications for wider distribution

Good luck with your plugin! 🚀
