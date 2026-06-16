part of 'home_screen.dart';

extension _HomeCustomPrayerRowsController on _HomeScreenState {
  void _addCustomPrayerRow() {
    final label = 'Nafile ${_nextAvailableNafileIndex()}';
    final row = _CustomPrayerDraft(
      id: 'nafile_${_customPrayerSeed++}',
      labelController: TextEditingController(text: label),
      reminderController: TextEditingController(text: '15'),
      settings: const _PrayerRowSettings(reminderMinutes: 15),
      timeRule: const _CustomPrayerTimeRule(
        mode: _CustomPrayerTimeMode.manual,
        manualTime: null,
      ),
    );
    _setHomeState(() {
      _customPrayerRows.add(row);
    });
    _scrollPrayerListToBottom();
    unawaited(_persistCustomPrayerRows());
  }

  void _scrollPrayerListToBottom([int attempt = 0]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_prayerListScrollController.hasClients) {
        if (attempt < 4) {
          Future<void>.delayed(
            const Duration(milliseconds: 120),
            () => _scrollPrayerListToBottom(attempt + 1),
          );
        }
        return;
      }
      final maxScrollExtent =
          _prayerListScrollController.position.maxScrollExtent;
      _prayerListScrollController.animateTo(
        maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  int _nextAvailableNafileIndex({String? excludingId}) {
    final used = <int>{};
    final pattern = RegExp(r'^Nafile (\d+)$');
    for (final row in _customPrayerRows) {
      if (row.id == excludingId) continue;
      final match = pattern.firstMatch(row.labelController.text.trim());
      if (match != null) {
        used.add(int.parse(match.group(1)!));
      }
    }
    var candidate = 1;
    while (used.contains(candidate)) {
      candidate++;
    }
    return candidate;
  }

  void _setCustomPrayerLabel(_CustomPrayerDraft row, String value) {
    _setHomeState(() {});
    unawaited(_persistCustomPrayerRows());
  }

  void _normalizeCustomPrayerLabel(_CustomPrayerDraft row) {
    if (row.labelController.text.trim().isNotEmpty) return;
    final label = 'Nafile ${_nextAvailableNafileIndex(excludingId: row.id)}';
    row.labelController.text = label;
    row.labelController.selection = TextSelection.collapsed(
      offset: row.labelController.text.length,
    );
    _setHomeState(() {});
    unawaited(_persistCustomPrayerRows());
  }

  void _setCustomReminderMinutes(_CustomPrayerDraft row, String value) {
    final minutes = int.tryParse(value) ?? 0;
    _setHomeState(() {
      row.settings = row.settings.copyWith(reminderMinutes: minutes);
    });
    unawaited(_persistCustomPrayerRows());
  }

  void _toggleCustomVoice(_CustomPrayerDraft row) {
    _setHomeState(() {
      row.settings = row.settings.copyWith(
        voiceEnabled: !row.settings.voiceEnabled,
      );
    });
    unawaited(_persistCustomPrayerRows());
  }

  void _toggleCustomVisual(_CustomPrayerDraft row) {
    _setHomeState(() {
      row.settings = row.settings.copyWith(
        visualEnabled: !row.settings.visualEnabled,
      );
    });
    unawaited(_persistCustomPrayerRows());
  }

  void _toggleCustomAzan(_CustomPrayerDraft row) {
    _setHomeState(() {
      row.settings = row.settings.copyWith(
        azanEnabled: !row.settings.azanEnabled,
      );
    });
    unawaited(_persistCustomPrayerRows());
  }

  void _toggleCustomVibration(_CustomPrayerDraft row) {
    _setHomeState(() {
      row.settings = row.settings.copyWith(
        vibrationEnabled: !row.settings.vibrationEnabled,
      );
    });
    unawaited(_persistCustomPrayerRows());
  }

  void _removeCustomPrayerRow(_CustomPrayerDraft row) {
    _setHomeState(() {
      _customPrayerRows.removeWhere((entry) => entry.id == row.id);
    });
    row.labelController.dispose();
    row.reminderController.dispose();
    unawaited(_persistCustomPrayerRows());
  }

  Future<void> _openCustomTimeEditor(
    _CustomPrayerDraft row,
    AppLocalizations l10n,
  ) async {
    final savedRule = await showModalBottomSheet<_CustomPrayerTimeRule>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _HomeCustomTimeEditorSheet(
          l10n: l10n,
          initialRule: row.timeRule,
        );
      },
    );
    if (savedRule == null) return;
    _setHomeState(() {
      row.timeRule = savedRule;
    });
    unawaited(_persistCustomPrayerRows());
  }

  List<HomePrayerListItem> _buildItems(
    AppLocalizations l10n,
    PrayerTimes times,
  ) {
    HomePrayerListItem itemFor(Prayer prayer, String label, DateTime time) {
      final settings = _settingsFor(prayer);
      return HomePrayerListItem(
        id: prayer.name,
        prayer: prayer,
        label: label,
        sortTime: time,
        timeLabel: homeFormatTime(time),
        reminderController: _controllerFor(prayer),
        onReminderChanged: (value) => _setReminderMinutes(prayer, value),
        onReminderTap: () => _editReminderMinutes(
          controller: _controllerFor(prayer),
          onChanged: (value) => _setReminderMinutes(prayer, value),
        ),
        voiceEnabled: settings.voiceEnabled,
        visualEnabled: settings.visualEnabled,
        azanEnabled: settings.azanEnabled,
        vibrationEnabled: settings.vibrationEnabled,
        onVoiceToggle: () => _toggleVoiceReminder(prayer),
        onVisualToggle: () => _toggleVisualReminder(prayer),
        onAzanToggle: () => _toggleAzanReminder(prayer),
        onVibrationToggle: () => _toggleVibrationReminder(prayer),
      );
    }

    final items = [
      itemFor(Prayer.fajr, l10n.prayerFajr, times.fajr),
      itemFor(Prayer.sunrise, l10n.prayerSunrise, times.sunrise),
      itemFor(Prayer.dhuhr, l10n.prayerDhuhr, times.dhuhr),
      itemFor(Prayer.asr, l10n.prayerAsr, times.asr),
      itemFor(Prayer.maghrib, l10n.prayerMaghrib, times.maghrib),
      itemFor(Prayer.isha, l10n.prayerIsha, times.isha),
    ];

    for (final row in _customPrayerRows) {
      final resolvedTime = _resolveCustomPrayerTime(row.timeRule, times);
      items.add(
        HomePrayerListItem(
          id: row.id,
          prayer: null,
          label: row.labelController.text.trim(),
          sortTime: resolvedTime,
          labelController: row.labelController,
          onLabelChanged: (value) => _setCustomPrayerLabel(row, value),
          onLabelEditingComplete: () => _normalizeCustomPrayerLabel(row),
          timeLabel: resolvedTime == null
              ? '--:--'
              : homeFormatTime(resolvedTime),
          onTimeTap: () => _openCustomTimeEditor(row, l10n),
          reminderController: row.reminderController,
          onReminderChanged: (value) => _setCustomReminderMinutes(row, value),
          onReminderTap: () => _editReminderMinutes(
            controller: row.reminderController,
            onChanged: (value) => _setCustomReminderMinutes(row, value),
          ),
          voiceEnabled: row.settings.voiceEnabled,
          visualEnabled: row.settings.visualEnabled,
          azanEnabled: row.settings.azanEnabled,
          vibrationEnabled: row.settings.vibrationEnabled,
          onVoiceToggle: () => _toggleCustomVoice(row),
          onVisualToggle: () => _toggleCustomVisual(row),
          onAzanToggle: () => _toggleCustomAzan(row),
          onVibrationToggle: () => _toggleCustomVibration(row),
          onDelete: () => _removeCustomPrayerRow(row),
        ),
      );
    }

    if (!_reminderSettings.sortCustomPrayersByTime) {
      return items;
    }

    final ordered = List<HomePrayerListItem>.from(items);
    ordered.sort((a, b) {
      final aTime = a.sortTime;
      final bTime = b.sortTime;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      final compare = aTime.compareTo(bTime);
      if (compare != 0) return compare;
      if (a.prayer != null && b.prayer == null) return -1;
      if (a.prayer == null && b.prayer != null) return 1;
      return a.label.compareTo(b.label);
    });
    return ordered;
  }
}
