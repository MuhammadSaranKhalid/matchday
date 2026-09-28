import 'package:geolocator/geolocator.dart';

import '../../../../core/error/exceptions.dart';

/// Reads the device's current coordinates, handling the permission/service
/// dance. Throws [PermissionException] when access is denied or location
/// services are off; the repository maps that to a PermissionFailure.
class DeviceLocationDataSource {
  const DeviceLocationDataSource();

  Future<({double latitude, double longitude})> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw PermissionException('Location services are turned off');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw PermissionException('Location permission was denied');
    }
    if (permission == LocationPermission.deniedForever) {
      throw PermissionException(
        'Location permission is permanently denied — enable it in Settings',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    );
    return (latitude: position.latitude, longitude: position.longitude);
  }
}
