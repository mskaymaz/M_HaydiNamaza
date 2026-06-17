part of 'home_screen.dart';

extension _HomePrayerPanelController on _HomeScreenState {
  void _setReminderMinutes(Prayer prayer, String value) {
    final minutes = int.tryParse(value) ?? 0;
    _setHomeState(() {
      final current = _settingsFor(prayer);
      _rowSettings[prayer] = current.copyWith(reminderMinutes: minutes);
    });
    unawaited(_persistPrayerRowSettings());
  }

  Future<void> _editReminderMinutes({
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) async {
    final editController = TextEditingController(text: controller.text.trim());
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          constraints: const BoxConstraints(minWidth: 150, maxWidth: 150),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Hatırlatma Süresi'),
              const SizedBox(height: 6),
              SizedBox(
                width: 112,
                child: Center(
                  child: SizedBox(
                    width: 72,
                    child: TextField(
                      controller: editController,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Dakika',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Material(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Vazgeç',
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Material(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.14),
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: () =>
                          Navigator.of(context).pop(editController.text),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Tamam',
                      icon: const Icon(Icons.check_rounded),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (result == null) return;
    final value = result.trim();
    controller.text = value.isEmpty ? '0' : value;
    onChanged(controller.text);
  }

  void _toggleVoiceReminder(Prayer prayer) {
    _setHomeState(() {
      final current = _settingsFor(prayer);
      _rowSettings[prayer] = current.copyWith(
        voiceEnabled: !current.voiceEnabled,
      );
    });
    unawaited(_persistPrayerRowSettings());
  }

  void _toggleVisualReminder(Prayer prayer) {
    _setHomeState(() {
      final current = _settingsFor(prayer);
      _rowSettings[prayer] = current.copyWith(
        visualEnabled: !current.visualEnabled,
      );
    });
    unawaited(_persistPrayerRowSettings());
  }

  void _toggleAzanReminder(Prayer prayer) {
    _setHomeState(() {
      final current = _settingsFor(prayer);
      _rowSettings[prayer] = current.copyWith(
        azanEnabled: !current.azanEnabled,
      );
    });
    unawaited(_persistPrayerRowSettings());
  }

  void _toggleVibrationReminder(Prayer prayer) {
    _setHomeState(() {
      final current = _settingsFor(prayer);
      _rowSettings[prayer] = current.copyWith(
        vibrationEnabled: !current.vibrationEnabled,
      );
    });
    unawaited(_persistPrayerRowSettings());
  }

  void _onPrayerPanelHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final draggedDistance = _prayerPanelDragDx;
    _prayerPanelDragDx = 0;
    if (_showPrayerControlPanel) return;
    if (velocity.abs() < 140.0 && draggedDistance.abs() < 12.0) return;
    final direction = draggedDistance.abs() >= 12.0
        ? draggedDistance.sign
        : velocity.sign;
    final nextOffset = direction < 0
        ? (_prayerDayOffset + 1).clamp(0, 29)
        : (_prayerDayOffset - 1).clamp(0, 29);
    if (nextOffset == _prayerDayOffset) return;
    _setHomeState(() {
      _prayerPanelTransitionDirection = nextOffset > _prayerDayOffset ? 1 : -1;
      _prayerDayOffset = nextOffset;
      _future = _loadData();
    });
  }

  void _onPrayerPanelHorizontalDragStart(DragStartDetails details) {
    _prayerPanelDragDx = 0;
  }

  void _onPrayerPanelHorizontalDragUpdate(DragUpdateDetails details) {
    _prayerPanelDragDx += details.primaryDelta ?? details.delta.dx;
  }

  void _showPrayerControls() {
    if (_showPrayerControlPanel) return;
    _setHomeState(() {
      _showPrayerControlPanel = true;
      _showPanelAddButton = false;
    });
  }

  void _hidePrayerControls() {
    if (!_showPrayerControlPanel) return;
    _setHomeState(() {
      _showPrayerControlPanel = false;
      _showPanelAddButton = false;
    });
  }
}
