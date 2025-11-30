# Mooves for F-Droid

## App Information

- **Name**: Mooves
- **Package ID**: `com.mooves.app`
- **Version**: 1.0.2
- **License**: MIT
- **Source Code**: https://github.com/yourusername/mooves
- **Website**: https://mooves.app

## F-Droid Compatibility

✅ **F-Droid Compatible**: This app is designed to work with F-Droid and uses only F-Droid-compatible dependencies.

### Payment Methods
- **Stripe**: Credit card and bank transfer payments
- **Bitcoin**: Cryptocurrency payments
- **No Google Play Billing**: Automatically disabled on F-Droid

### Dependencies
All dependencies are F-Droid-compatible:
- `flutter` (3.16.9)
- `http` (1.1.0)
- `shared_preferences` (2.2.2)
- `image_picker` (1.0.7)
- `provider` (6.1.1)
- `flutter_local_notifications` (19.3.0)
- `socket_io_client` (3.1.2)
- `geolocator` (14.0.1)
- `permission_handler` (12.0.0+1)
- `package_info_plus` (8.0.2)

## Build Instructions

### Prerequisites
- Flutter SDK 3.16.9 or later
- Android SDK
- F-Droid build environment

### Build Steps
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/mooves.git
   cd mooves/dating_app
   ```

2. Build for F-Droid:
   ```bash
   ./scripts/build-fdroid.sh
   ```

3. The APK will be created at: `build/fdroid/fdroid-v1.0.2-106.apk`

## F-Droid Metadata

The `fdroid-metadata.yml` file contains all necessary metadata for F-Droid inclusion:

```yaml
Categories:
  - Dating
  - Social
  - Internet

License: MIT
WebSite: https://mooves.app
SourceCode: https://github.com/yourusername/mooves
IssueTracker: https://github.com/yourusername/mooves/issues

Builds:
  - versionName: '1.0.2'
    versionCode: 106
    commit: v1.0.2
    subdir: dating_app
    gradle:
      - yes
```

## Features

- **Privacy-focused**: No tracking or data selling
- **Open source**: Full source code available
- **F-Droid compatible**: No proprietary dependencies
- **Multiple payment options**: Stripe and Bitcoin
- **Cross-platform**: Works on all Android devices

## Support

- **Issues**: https://github.com/yourusername/mooves/issues
- **Documentation**: https://mooves.app/docs
- **Privacy Policy**: https://mooves.app/privacy

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 