# Current Architecture (TASK-01)

Date: 2026-05-10  
Scope: Documentation audit only, no app-code changes.

## 1) Main app entry points
- `lib/main.dart`: Flutter bootstrap, runtime error hooks, startup performance timer, `runApp(const App())`.
- `lib/app/app.dart`: Root `MaterialApp`, locale + palette controllers, localization delegates, `home: HomeScreen(...)`.
- `lib/presentation/home/home_screen.dart`: Main runtime screen that loads location/prayer data, drives reminders, and opens settings/location/qibla flows.

## 2) Current major folders and responsibilities
- `lib/app/`: App-level services/controllers/storage adapters (prayer service, reminder audio/settings storage, location storage, locale/palette controllers, runtime monitor).
- `lib/core/prayer_engine/`: Prayer-time engine/domain math primitives (`CalculationMethod`, `PrayerTimes`, coordinate/time calculations).
- `lib/core/config/`: UI style config and external data-source config registry.
- `lib/presentation/home/`: Main prayer dashboard and reminder orchestration, plus extracted helper/widget files.
- `lib/presentation/settings/`: Settings, location selection, favorites, calculation method, reminder/color UI and helper widgets.
- `lib/presentation/reminders/`: Visual reminder card widgets.
- `lib/l10n/`: ARB and generated localization code.
- `assets/`: Adhan audio files (repo assets) and image assets used by UI.
- `docs/architecture/`: Architecture docs (`TARGET_ARCHITECTURE.md`, `CLEANUP_MAP.md`, this file).
- `test/`: Minimal widget smoke test.
- `testdata/`: Prayer-time comparison/reference JSON snapshots.
- `scripts/`, `tools/`: Utility scripts, not part of runtime app architecture.

## 3) Files over 600 lines (current audit)
Method: repository text-like files (`.dart`, `.md`, `.yaml`, `.json`, `.arb`, `.xml`, `.lock`, `.pbxproj`, `.txt`, scripts).

- `testdata/adhan/Singapore-Singapore.json` (~10616)
- `_archive_instruction_old_20260509_132105/hadisler.json` (~9547)
- `_archive_instruction_old_20260509_132105/ayetler.json` (~5721)
- `_archive_instruction_old_20260509_132105/ayetlerEski.json` (~1370)
- `lib/presentation/home/home_screen.dart` (~1316)
- `pubspec.lock` (~799)
- `testdata/adhan/Izmir-Diyanet.json` (~722)
- `testdata/adhan/Istanbul-Diyanet.json` (~722)
- `testdata/adhan/Konya-Diyanet.json` (~722)
- `testdata/adhan/Ankara-Turkey.json` (~698)
- `ios/Runner.xcodeproj/project.pbxproj` (~601)

Code-focused note: only one Dart file is above 600 lines: `lib/presentation/home/home_screen.dart`.

## 4) UI files still containing orchestration/business logic
- `lib/presentation/home/home_screen.dart`
- Owns reminder trigger logic, timer loops, vibration/audio loop scheduling, persistence writes, custom-prayer rule management, and navigation orchestration.
- `lib/presentation/settings/settings_screen.dart`
- Owns settings load/save orchestration, reminder snapshot persistence, voice-test execution, file-picker orchestration, and navigation orchestration.
- `lib/presentation/settings/location_screen.dart`
- Owns Diyanet list API loading, geolocator/geocoding permission/runtime flow, favorites apply/remove/save orchestration.
- `lib/presentation/settings/calculation_method_screen.dart`
- Owns advanced calculation settings load/save orchestration.
- `lib/presentation/home/widgets/home_qibla_screen.dart`
- Contains qibla bearing math directly in UI widget (domain logic is not yet extracted).

## 5) Services mixing unrelated responsibilities
- `lib/app/prayer_service.dart`
- Mixes multiple concerns: external HTTP clients (Diyanet + Aladhan), ID resolution for province/district, fallback strategy, local prayer-engine usage, caching (memory + shared preferences), settings adaptation, and runtime profiling/logging.

Secondary observation:
- `lib/app/reminder_audio_service.dart` combines TTS voice discovery/selection, file-audio playback, and alert sound triggering. All are audio-domain concerns, but still a broad responsibility surface.

## 6) Current feature flows
Prayer-time flow:
`HomeScreen._loadData()` -> `LocationStorage.read()` + `CalculationMethodStorage.readCode()` -> `PrayerService.calculateToday()` -> Diyanet/Aladhan/local-engine fallback + cache -> `PrayerTimes` rendered by home widgets.

Qibla flow:
Home top panel action -> `HomeScreen._openQibla()` -> `HomeQiblaScreen(location)` -> Kaaba bearing math + `FlutterCompass.events` heading stream -> directional UI arrow.

Settings flow:
Home action -> `SettingsScreen` -> load location/favorites/method/reminder text/voice options from storages/services -> persist updates via storage classes -> return to Home and refresh data.

Notification/reminder flow (current implementation):
In-app only (no OS scheduled local notifications layer).  
`HomeScreen` periodic ticker + `_checkAndTriggerReminders()` -> per-prayer stage trigger keys in `ReminderTriggerStorage` -> play TTS/file/alert via `ReminderAudioService` and vibration via `Vibration`.

Location flow:
`LocationScreen` loads country/state/district lists from Diyanet location APIs, optionally reads device GPS/geocoding, manages favorites, writes final selection via `LocationStorage`, and returns changed state to caller.

Daily content flow:
Not yet implemented as active runtime feature.  
No dedicated `daily_content` module in `lib/` and no approved-content runtime pipeline yet; this remains planned for later tasks.

## 7) Safe refactor order (for later tasks, without behavior change)
1. Extract Home reminder orchestration from `home_screen.dart` into dedicated reminder coordinator/service class while keeping current UI contracts.
2. Extract qibla bearing math from `home_qibla_screen.dart` into pure domain helper/use-case with unit-test entry points.
3. Split `PrayerService` into narrower units: data-source clients, id resolver, cache adapter, and orchestration facade.
4. Move location remote-loading and permission/runtime logic from `location_screen.dart` into a location service/controller layer.
5. Move settings persistence orchestration from `settings_screen.dart` into settings controller/use-case layer.
6. Introduce feature folders (`lib/features/...`) and migrate by slices after behavior is covered by tests.
7. Implement daily-content architecture only after source/approval contract is defined (TASK-05), not before.

## Architectural risks to carry forward
- Home orchestration remains high-coupling and state-heavy.
- Prayer-time source strategy is still unresolved for release quality.
- Notification behavior is in-app session-based; no durable OS scheduling layer yet.
- Some user-facing strings/encoding remain inconsistent in legacy text paths.
