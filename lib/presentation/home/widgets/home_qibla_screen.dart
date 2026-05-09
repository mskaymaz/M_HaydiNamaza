import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../../../app/location_storage.dart';

class HomeQiblaScreen extends StatelessWidget {
  static const double _kaabaLatitude = 21.4225;
  static const double _kaabaLongitude = 39.8262;

  final LocationData? location;

  const HomeQiblaScreen({super.key, required this.location});

  double? _parse(String? value) => double.tryParse((value ?? '').trim());

  double _bearingToKaaba(double latitude, double longitude) {
    final lat1 = _degToRad(latitude);
    final lon1 = _degToRad(longitude);
    final lat2 = _degToRad(_kaabaLatitude);
    final lon2 = _degToRad(_kaabaLongitude);
    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (_radToDeg(math.atan2(y, x)) + 360) % 360;
  }

  double _degToRad(double deg) => deg * math.pi / 180;
  double _radToDeg(double rad) => rad * 180 / math.pi;

  @override
  Widget build(BuildContext context) {
    final latitude = _parse(location?.latitude);
    final longitude = _parse(location?.longitude);
    final hasLocation = latitude != null && longitude != null;
    final qiblaBearing = hasLocation
        ? _bearingToKaaba(latitude, longitude)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Kıble Yönü')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: !hasLocation
                ? const Text(
                    'Kıble yönü için önce konum seçin.',
                    textAlign: TextAlign.center,
                  )
                : StreamBuilder<CompassEvent>(
                    stream: FlutterCompass.events,
                    builder: (context, snapshot) {
                      final heading = snapshot.data?.heading;
                      if (heading == null) {
                        return const Text(
                          'Pusula verisi bekleniyor.',
                          textAlign: TextAlign.center,
                        );
                      }
                      final rotation =
                          ((qiblaBearing! - heading) * math.pi) / 180;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 280,
                            height: 280,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF5F0E6),
                              border: Border.all(
                                color: const Color(
                                  0xFF1F7A3E,
                                ).withValues(alpha: 0.22),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x16000000),
                                  blurRadius: 16,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Text(
                                  'N',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Transform.rotate(
                                  angle: rotation,
                                  child: const Icon(
                                    Icons.navigation_rounded,
                                    size: 120,
                                    color: Color(0xFF1F7A3E),
                                  ),
                                ),
                                const Positioned(
                                  bottom: 22,
                                  child: Text(
                                    'Kâbe',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Kıble açısı: ${qiblaBearing.toStringAsFixed(1)}°',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Telefonu düz tutup yeşil oku takip edin.',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
