part of 'home_screen.dart';

extension _HomePrayerTableInfoPanel on _HomeScreenState {
  Widget _buildInfoPanels({
    required _HomeData data,
    required Color cizgiColor,
    required Color panelColor,
    required double maxHeight,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FutureBuilder<DailyContentSelectionResult>(
          future: _dailyContentFuture,
          builder: (context, snapshot) {
            return HomeDailyContentPanel(
              result: snapshot.data,
              isLoading: snapshot.connectionState == ConnectionState.waiting,
              hasError: snapshot.hasError,
              cizgiColor: cizgiColor,
              panelColor: panelColor,
              maxHeight: maxHeight,
              onCycleContentTap: _cycleDailyContent,
            );
          },
        ),
        const SizedBox(height: 8),
        _PrayerTimesTablePanel(
          mode: _prayerTableMode,
          range: _prayerTableRange,
          future: _prayerTableFuture,
          cizgiColor: cizgiColor,
          panelColor: panelColor,
          onWeek: () => _loadWeeklyPrayerTable(data),
          onThirtyDays: () => _loadThirtyDayPrayerTable(data),
          onRange: () => _pickPrayerTableRange(data),
        ),
      ],
    );
  }
}

class _PrayerTimesTablePanel extends StatelessWidget {
  final _PrayerTableMode mode;
  final DateTimeRange? range;
  final Future<List<_PrayerTableDay>>? future;
  final Color cizgiColor;
  final Color panelColor;
  final VoidCallback onWeek;
  final VoidCallback onThirtyDays;
  final VoidCallback onRange;

  const _PrayerTimesTablePanel({
    required this.mode,
    required this.range,
    required this.future,
    required this.cizgiColor,
    required this.panelColor,
    required this.onWeek,
    required this.onThirtyDays,
    required this.onRange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 310),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
      decoration: BoxDecoration(
        color: panelColor.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cizgiColor.withValues(alpha: 0.18)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PrayerTableHeader(
            mode: mode,
            range: range,
            onWeek: onWeek,
            onThirtyDays: onThirtyDays,
            onRange: onRange,
          ),
          const SizedBox(height: 8),
          Flexible(child: _PrayerTableBody(future: future)),
        ],
      ),
    );
  }
}

class _PrayerTableHeader extends StatelessWidget {
  final _PrayerTableMode mode;
  final DateTimeRange? range;
  final VoidCallback onWeek;
  final VoidCallback onThirtyDays;
  final VoidCallback onRange;

  const _PrayerTableHeader({
    required this.mode,
    required this.range,
    required this.onWeek,
    required this.onThirtyDays,
    required this.onRange,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1B5E20),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Vakit Tablosu', style: titleStyle)),
            if (range != null)
              Text(
                _rangeLabel(range!),
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _PrayerTableButton(
              label: 'Haftalık',
              selected: mode == _PrayerTableMode.week,
              onPressed: onWeek,
            ),
            _PrayerTableButton(
              label: '30 Günlük',
              selected: mode == _PrayerTableMode.thirtyDays,
              onPressed: onThirtyDays,
            ),
            _PrayerTableButton(
              label: 'Aralık',
              selected: mode == _PrayerTableMode.range,
              onPressed: onRange,
            ),
          ],
        ),
      ],
    );
  }

  String _rangeLabel(DateTimeRange range) {
    return '${range.start.day}.${range.start.month} - '
        '${range.end.day}.${range.end.month}';
  }
}

class _PrayerTableButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _PrayerTableButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        backgroundColor: selected ? const Color(0xFFDDEFD9) : null,
      ),
      child: Text(label),
    );
  }
}

class _PrayerTableBody extends StatelessWidget {
  final Future<List<_PrayerTableDay>>? future;

  const _PrayerTableBody({required this.future});

  @override
  Widget build(BuildContext context) {
    final activeFuture = future;
    if (activeFuture == null) {
      return const Text(
        'Haftalık, 30 günlük veya aralık seçerek vakitleri tablo halinde getirin.',
      );
    }
    return FutureBuilder<List<_PrayerTableDay>>(
      future: activeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Text('Vakit tablosu getirilemedi.');
        }
        final rows = snapshot.data ?? const <_PrayerTableDay>[];
        if (rows.isEmpty) return const Text('Gösterilecek vakit yok.');
        return _PrayerTableRows(rows: rows);
      },
    );
  }
}

class _PrayerTableRows extends StatelessWidget {
  final List<_PrayerTableDay> rows;

  const _PrayerTableRows({required this.rows});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF111111),
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        );
    final headerStyle = textStyle?.copyWith(
      color: const Color(0xFF0F3D1D),
      fontSize: 14.5,
      fontWeight: FontWeight.w800,
    );
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder.all(color: const Color(0x33000000)),
          children: [
            _row(
              ['Gün', 'İmsak', 'Güneş', 'Öğle', 'İkindi', 'Akşam', 'Yatsı'],
              headerStyle,
              isHeader: true,
            ),
            for (final row in rows)
              _row(
                [
                  _dateLabel(row.date),
                  homeFormatTime(row.times.fajr),
                  homeFormatTime(row.times.sunrise),
                  homeFormatTime(row.times.dhuhr),
                  homeFormatTime(row.times.asr),
                  homeFormatTime(row.times.maghrib),
                  homeFormatTime(row.times.isha),
                ],
                textStyle,
              ),
          ],
        ),
      ),
    );
  }

  TableRow _row(
    List<String> values,
    TextStyle? style, {
    bool isHeader = false,
  }) {
    return TableRow(
      decoration: BoxDecoration(
        color: isHeader ? const Color(0xFFE8F4E3) : const Color(0xFFFDFDF9),
      ),
      children: [
        for (final value in values)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            child: Text(value, maxLines: 1, style: style),
          ),
      ],
    );
  }

  String _dateLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}';
  }
}
