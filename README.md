# messenger_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# messenger-app

## ADB Wireless Connection

Connect your phone to your computer wirelessly using ADB:

### Prerequisites
- Phone and computer on the same network
- USB debugging enabled on phone
- ADB installed on computer

### Steps

1. **Connect via USB first:**
   ```bash
   adb devices
   ```

2. **Set device to listen on TCP port 5555:**
   ```bash
   adb tcpip 5555
   ```

3. **Find your device's IP address** (Settings > About > IP address)

4. **Connect wirelessly:**
   ```bash
   adb connect <DEVICE_IP>:5555
   ```

5. **Verify connection:**
   ```bash
   adb devices
   ```

6. **To disconnect:**
   ```bash
   adb disconnect <DEVICE_IP>:5555
   ```


