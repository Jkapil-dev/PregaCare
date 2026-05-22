import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';

class LocationProvider extends ChangeNotifier {
  bool _isLoading = false;
  Position? _currentPosition;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  Position? get currentPosition => _currentPosition;
  String? get errorMessage => _errorMessage;

  /// Fetch location safely, managing permissions and displaying contextual user messages
  Future<Position?> fetchLocation(BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _errorMessage = 'Location services are disabled. Please enable GPS.';
        _isLoading = false;
        notifyListeners();
        
        if (context.mounted) {
          _showDisabledGPSSnackbar(context);
        }
        return null;
      }

      // 2. Manage Location Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _errorMessage = 'Location permission was denied.';
          _isLoading = false;
          notifyListeners();
          
          if (context.mounted) {
            _showSnackbar(context, 'Location permission is required for sharing.');
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _errorMessage = 'Location permission permanently denied.';
        _isLoading = false;
        notifyListeners();
        
        if (context.mounted) {
          _showPermanentlyDeniedDialog(context);
        }
        return null;
      }

      // 3. Fetch current high-accuracy position
      // Using a short timeout (8 seconds) to prevent blocking the UI indefinitely
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      _currentPosition = position;
      _isLoading = false;
      notifyListeners();
      return position;
    } catch (e) {
      debugPrint('LocationProvider fetchLocation error: $e');
      _errorMessage = 'Failed to fetch GPS coordinates: $e';
      _isLoading = false;
      notifyListeners();
      
      if (context.mounted) {
        _showSnackbar(context, 'Failed to fetch GPS location. Please check your signal.');
      }
      return null;
    }
  }

  /// Share current location via SMS, WhatsApp, or native share sheet
  Future<void> shareLocation(BuildContext context) async {
    final pos = await fetchLocation(context);
    if (pos == null) return;

    final mapsUrl = 'https://maps.google.com/?q=${pos.latitude},${pos.longitude}';
    final message = 'Emergency! I may need help.\n\nMy current location:\n$mapsUrl';

    try {
      await Share.share(
        message, 
        subject: 'Materna Emergency Location Alert',
      );
    } catch (e) {
      debugPrint('LocationProvider native share error: $e');
      if (context.mounted) {
        _showSnackbar(context, 'Failed to open share sheet: $e');
      }
    }
  }

  // ==========================================
  // CONTEXT-AWARE DIALOGS & SNACKBARS
  // ==========================================

  void _showSnackbar(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: Colors.red[800],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDisabledGPSSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('GPS Location Services are turned off.'),
        backgroundColor: Colors.amber[900],
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'SETTINGS',
          textColor: Colors.white,
          onPressed: () async {
            if (!kIsWeb) {
              await Geolocator.openLocationSettings();
            }
          },
        ),
      ),
    );
  }

  void _showPermanentlyDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Location Permission'),
            ],
          ),
          content: const Text(
            'GPS permissions are permanently denied for Materna. Please enable location services inside the device system settings to use this feature.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                if (!kIsWeb) {
                  await Geolocator.openAppSettings();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Open Settings', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
