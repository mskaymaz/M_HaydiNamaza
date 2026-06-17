part of 'home_screen.dart';

class _HomeCustomTimeEditorSheet extends StatefulWidget {
  final AppLocalizations l10n;
  final _CustomPrayerTimeRule initialRule;

  const _HomeCustomTimeEditorSheet({
    required this.l10n,
    required this.initialRule,
  });

  @override
  State<_HomeCustomTimeEditorSheet> createState() =>
      _HomeCustomTimeEditorSheetState();
}

class _HomeCustomTimeEditorSheetState extends State<_HomeCustomTimeEditorSheet> {
  late _CustomPrayerTimeMode _mode;
  late Prayer _anchorPrayer;
  late TextEditingController _offsetController;
  late TextEditingController _hourController;
  late TextEditingController _minuteController;

  List<MapEntry<Prayer, String>> get _prayerOptions => <MapEntry<Prayer, String>>[
        MapEntry(Prayer.fajr, widget.l10n.prayerFajr),
        MapEntry(Prayer.sunrise, widget.l10n.prayerSunrise),
        MapEntry(Prayer.dhuhr, widget.l10n.prayerDhuhr),
        MapEntry(Prayer.asr, widget.l10n.prayerAsr),
        MapEntry(Prayer.maghrib, widget.l10n.prayerMaghrib),
        MapEntry(Prayer.isha, widget.l10n.prayerIsha),
      ];

  @override
  void initState() {
    super.initState();
    _mode = widget.initialRule.mode;
    _anchorPrayer = widget.initialRule.anchorPrayer ?? Prayer.fajr;
    _offsetController = TextEditingController(
      text: widget.initialRule.offsetMinutes.toString(),
    );
    _hourController = TextEditingController(
      text: widget.initialRule.manualTime == null
          ? ''
          : widget.initialRule.manualTime!.hour.toString().padLeft(2, '0'),
    );
    _minuteController = TextEditingController(
      text: widget.initialRule.manualTime == null
          ? ''
          : widget.initialRule.manualTime!.minute.toString().padLeft(2, '0'),
    );
  }

  @override
  void dispose() {
    _offsetController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  TimeOfDay? _readManualTime() {
    final hour = int.tryParse(_hourController.text.trim());
    final minute = int.tryParse(_minuteController.text.trim());
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23) return null;
    if (minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  void _save() {
    final offsetMinutes = int.tryParse(_offsetController.text.trim()) ?? 0;
    final rule = _CustomPrayerTimeRule(
      mode: _mode,
      anchorPrayer: _mode == _CustomPrayerTimeMode.manual ? null : _anchorPrayer,
      offsetMinutes: offsetMinutes,
      manualTime: _mode == _CustomPrayerTimeMode.manual ? _readManualTime() : null,
    );
    Navigator.of(context).pop(rule);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vakit zamani',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Sabit saat'),
                selected: _mode == _CustomPrayerTimeMode.manual,
                onSelected: (_) {
                  setState(() {
                    _mode = _CustomPrayerTimeMode.manual;
                  });
                },
              ),
              ChoiceChip(
                label: const Text('Vakitten once'),
                selected: _mode == _CustomPrayerTimeMode.beforePrayer,
                onSelected: (_) {
                  setState(() {
                    _mode = _CustomPrayerTimeMode.beforePrayer;
                  });
                },
              ),
              ChoiceChip(
                label: const Text('Vakitten sonra'),
                selected: _mode == _CustomPrayerTimeMode.afterPrayer,
                onSelected: (_) {
                  setState(() {
                    _mode = _CustomPrayerTimeMode.afterPrayer;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_mode == _CustomPrayerTimeMode.manual)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hourController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Saat',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _minuteController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Dakika',
                    ),
                  ),
                ),
              ],
            )
          else ...[
            Text(
              'Referans vakit',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in _prayerOptions)
                  ChoiceChip(
                    label: Text(option.value),
                    selected: _anchorPrayer == option.key,
                    onSelected: (_) {
                      setState(() {
                        _anchorPrayer = option.key;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _offsetController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Dakika'),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(52, 28),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: _save,
              child: const Text('Kaydet'),
            ),
          ),
        ],
      ),
    );
  }
}
