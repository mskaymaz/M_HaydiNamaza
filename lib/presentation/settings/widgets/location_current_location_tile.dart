import 'package:flutter/material.dart';

class LocationCurrentLocationTile extends StatelessWidget {
  final bool useCurrentLocation;
  final bool locating;
  final ValueChanged<bool?> onChanged;

  const LocationCurrentLocationTile({
    super.key,
    required this.useCurrentLocation,
    required this.locating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: useCurrentLocation,
      onChanged: locating ? null : onChanged,
      title: const Text('Mevcut Konumu Al'),
      controlAffinity: ListTileControlAffinity.leading,
      secondary: locating
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location_outlined),
      contentPadding: EdgeInsets.zero,
    );
  }
}
