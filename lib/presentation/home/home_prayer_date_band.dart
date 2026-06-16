part of 'home_screen.dart';

class _PrayerDateBand extends StatelessWidget {
  final String label;

  const _PrayerDateBand({required this.label});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.black,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        );
    return Container(
      width: double.infinity,
      height: 34,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAF2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          textAlign: TextAlign.center,
          style: style,
        ),
      ),
    );
  }
}
