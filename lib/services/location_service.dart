import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<String> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return "Dhaka";

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return "Dhaka";
      }

      if (permission == LocationPermission.deniedForever) return "Dhaka";

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(const Duration(seconds: 5));

      return "${position.latitude},${position.longitude}";
    } catch (e) {
      return "Dhaka";
    }
  }
}
