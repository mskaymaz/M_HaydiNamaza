import 'package:flutter_test/flutter_test.dart';
import 'package:mhaydinamaza/features/shared_settings/shared_settings_parser.dart';

void main() {
  group('SharedSettingsParser.parseCatalogPayload', () {
    test('parses map root with apps list', () {
      const payload = '''
      {
        "apps": [
          {
            "app_id": "haydi_namaza",
            "name": "Haydi Namaza",
            "description": "desc",
            "url": "https://example.com/app",
            "active": true,
            "order": 2,
            "target_apps": ["*"]
          }
        ]
      }
      ''';

      final items = SharedSettingsParser.parseCatalogPayload(payload);

      expect(items, hasLength(1));
      expect(items.first.appId, 'haydi_namaza');
      expect(items.first.name, 'Haydi Namaza');
    });

    test('ignores invalid rows', () {
      const payload = '''
      {
        "apps": [
          {
            "app_id": "",
            "name": "Broken",
            "description": "desc",
            "url": "not-url",
            "active": true,
            "order": 1,
            "target_apps": []
          }
        ]
      }
      ''';

      final items = SharedSettingsParser.parseCatalogPayload(payload);

      expect(items, isEmpty);
    });
  });

  group('SharedSettingsParser.parseUpdatePayload', () {
    test('parses valid update payload', () {
      const payload = '''
      {
        "version": "1.2.3",
        "build_number": 4,
        "url": "https://example.com/release",
        "force_update": true,
        "notes": "Important"
      }
      ''';

      final manifest = SharedSettingsParser.parseUpdatePayload(payload);

      expect(manifest, isNotNull);
      expect(manifest!.buildNumber, 4);
      expect(manifest.forceUpdate, isTrue);
    });

    test('returns null for invalid payload', () {
      const payload = '''
      {
        "version": "",
        "build_number": 0,
        "url": "",
        "force_update": false
      }
      ''';

      final manifest = SharedSettingsParser.parseUpdatePayload(payload);

      expect(manifest, isNull);
    });
  });
}
