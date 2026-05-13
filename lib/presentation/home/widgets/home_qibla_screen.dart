import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

import '../../../app/location_storage.dart';
import '../../../features/qibla/qibla_bearing_calculator.dart';
import '../../../features/qibla/qibla_constants.dart';

class HomeQiblaScreen extends StatefulWidget {
  final LocationData? location;

  const HomeQiblaScreen({super.key, required this.location});

  @override
  State<HomeQiblaScreen> createState() => _HomeQiblaScreenState();
}

class _HomeQiblaScreenState extends State<HomeQiblaScreen> {
  final QiblaBearingCalculator _bearingCalculator = const QiblaBearingCalculator();

  double? _deviceLatitude;
  double? _deviceLongitude;
  bool _checkingDeviceLocation = false;
  bool _locationPermissionUnavailable = false;

  double? _previousHeading;
  int _unstableHeadingScore = 0;

  @override
  void initState() {
    super.initState();
    _resolveDeviceLocationIfNeeded();
  }

  double? _parse(String? value) => double.tryParse((value ?? '').trim());

  Future<void> _resolveDeviceLocationIfNeeded() async {
    final selectedLatitude = _parse(widget.location?.latitude);
    final selectedLongitude = _parse(widget.location?.longitude);
    if (selectedLatitude != null && selectedLongitude != null) {
      return;
    }

    setState(() {
      _checkingDeviceLocation = true;
      _locationPermissionUnavailable = false;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _locationPermissionUnavailable = true;
          _checkingDeviceLocation = false;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationPermissionUnavailable = true;
          _checkingDeviceLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _deviceLatitude = position.latitude;
        _deviceLongitude = position.longitude;
        _checkingDeviceLocation = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationPermissionUnavailable = true;
        _checkingDeviceLocation = false;
      });
    }
  }

  bool _isHeadingUnstable(double heading, double? accuracy) {
    if (_previousHeading == null) {
      _previousHeading = heading;
      return false;
    }

    final rawDelta = (heading - _previousHeading!).abs();
    final normalizedDelta = rawDelta > 180 ? 360 - rawDelta : rawDelta;
    _previousHeading = heading;

    if (normalizedDelta > 15) {
      _unstableHeadingScore = (_unstableHeadingScore + 1).clamp(0, 6);
    } else {
      _unstableHeadingScore = (_unstableHeadingScore - 1).clamp(0, 6);
    }

    final unstableByDelta = _unstableHeadingScore >= 3;
    final unstableByAccuracy = accuracy != null && accuracy > 20;
    return unstableByDelta || unstableByAccuracy;
  }

  @override
  Widget build(BuildContext context) {
    final selectedLatitude = _parse(widget.location?.latitude);
    final selectedLongitude = _parse(widget.location?.longitude);
    final latitude = selectedLatitude ?? _deviceLatitude;
    final longitude = selectedLongitude ?? _deviceLongitude;

    final hasLocation = latitude != null && longitude != null;
    final qiblaBearing = hasLocation
        ? _bearingCalculator.calculateInitialBearing(
            latitude: latitude,
            longitude: longitude,
          )
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Kible Yonu')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: StreamBuilder<CompassEvent>(
              stream: FlutterCompass.events,
              builder: (context, snapshot) {
                final heading = snapshot.data?.heading;
                final accuracy = snapshot.data?.accuracy;
                final modeLabel = hasLocation
                    ? QiblaConstants.locationModeLabel
                    : QiblaConstants.sensorFallbackModeLabel;

                if (heading == null) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        modeLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      if (_checkingDeviceLocation)
                        const Text(
                          'Konum izni kontrol ediliyor...',
                          textAlign: TextAlign.center,
                        )
                      else
                        const Text(
                          'Pusula verisi bekleniyor.',
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 10),
                      if (!hasLocation)
                        Text(
                          QiblaConstants.enableLocationGuidance,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      const SizedBox(height: 8),
                      Text(
                        QiblaConstants.calibrationGuidance,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  );
                }

                final rotation = hasLocation
                    ? ((qiblaBearing! - heading) * math.pi) / 180
                    : ((0 - heading) * math.pi) / 180;
                final showUnstableWarning = _isHeadingUnstable(heading, accuracy);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      modeLabel,
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    if (!hasLocation) ...[
                      const SizedBox(height: 6),
                      Text(
                        QiblaConstants.enableLocationGuidance,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF5F0E6),
                        border: Border.all(
                          color: const Color(0xFF1F7A3E).withValues(alpha: 0.22),
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
                          Positioned(
                            bottom: 22,
                            child: Text(
                              hasLocation ? 'Kabe' : 'Kuzey',
                              style: const TextStyle(
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
                      hasLocation
                          ? 'Kible acisi: ${qiblaBearing!.toStringAsFixed(1)} deg'
                          : 'Pusula acisi: ${heading.toStringAsFixed(1)} deg',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasLocation
                          ? 'Telefonu duz tutup yesil oku takip edin.'
                          : 'Konum yokken sadece sensor referansi gosterilir.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      QiblaConstants.calibrationGuidance,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    if (showUnstableWarning) ...[
                      const SizedBox(height: 8),
                      Text(
                        QiblaConstants.unstableAccuracyWarning,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_locationPermissionUnavailable && !hasLocation) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Konum izni kapali oldugu icin yaklasik sensor modu kullaniliyor.',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      QiblaConstants.noPerfectAccuracyNote,
                      style: Theme.of(context).textTheme.bodySmall,
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
