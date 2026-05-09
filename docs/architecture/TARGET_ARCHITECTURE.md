# Target Architecture

## Flutter structure

```text
lib/
  app/
    app.dart
    app_config.dart
    routing/
    theme/
  core/
    constants/
    errors/
    logging/
    platform/
    storage/
    utils/
    widgets/
  features/
    prayer_times/
      data/
      domain/
      presentation/
    qibla/
      data/
      domain/
      presentation/
    daily_content/
      data/
      domain/
      presentation/
    shared_settings/
      data/
      domain/
      presentation/
    location/
      data/
      domain/
      presentation/
    notifications/
      data/
      domain/
      presentation/
assets/
  data/
    daily_content/
      draft/
      approved/
      archive/
    prayer_times/
docs/
  architecture/
test/
```

## Feature responsibilities

### prayer_times
- Source strategy
- Calculation/cache/domain models
- Data-source labels
- Prayer-time panel presentation

### qibla
- Kaaba bearing calculation
- Sensor fallback
- Permission guidance
- Calibration/accuracy messages

### daily_content
- Approved ayah/hadith JSON loading
- Daily random pick
- Repeat prevention until cycle completion
- Prayer-times-adjacent panel presentation

### shared_settings
- Contact
- App info and update
- Other apps catalog
- Support
- About

### location
- Permission state
- Coordinate resolution
- User guidance

### notifications
- Prayer reminders
- Local notification scheduling
- Safe fallback behavior

## Non-negotiable boundaries
- UI should not calculate prayer times or qibla bearing directly.
- Domain logic must be testable without Flutter widgets.
- Religious content must include source metadata and approval status.
- Prayer-time source must be transparent to the user.

