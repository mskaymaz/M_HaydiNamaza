part of 'home_daily_content_section.dart';

class _InfoOverlayPanel extends StatelessWidget {
  final String message;
  final bool isRtl;
  final Color cizgiColor;
  final Color contentColor;
  final double maxHeight;

  const _InfoOverlayPanel({
    required this.message,
    required this.isRtl,
    required this.cizgiColor,
    required this.contentColor,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Material(
          color: Color.lerp(contentColor, Colors.black, 0.12) ?? contentColor,
          borderRadius: BorderRadius.circular(10),
          elevation: 0,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cizgiColor.withValues(alpha: 0.28)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Directionality(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: Text(
                  _formatInfoMessage(message),
                  locale: isRtl ? _dailyContentSectionArabicLocale : null,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontSize: isRtl ? 20 : 18,
                    height: 1.3,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _formatInfoMessage(String message) {
  if (message.contains('\n')) return message;
  final splitIndex = message.indexOf('. ');
  if (splitIndex == -1) return message;
  return '${message.substring(0, splitIndex + 1)}\n\n'
      '${message.substring(splitIndex + 2)}';
}

double _maxDouble(double first, double second) {
  return first > second ? first : second;
}

class _BasmalaHeader extends StatelessWidget {
  final bool hasInfoAction;
  final bool hasReadAction;
  final VoidCallback onInfoTap;
  final VoidCallback? onReadTap;

  const _BasmalaHeader({
    required this.hasInfoAction,
    required this.hasReadAction,
    required this.onInfoTap,
    required this.onReadTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 34,
          height: 34,
          child: hasInfoAction
              ? _OverlayIconButton(
                  icon: Icons.info_outline_rounded,
                  tooltip: 'Bilgi',
                  onTap: onInfoTap,
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 4),
            child: _BasmalaMark(),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 34,
          height: 34,
          child: hasReadAction && onReadTap != null
              ? _OverlayIconButton(
                  icon: Icons.volume_up_rounded,
                  tooltip: 'Oku',
                  onTap: onReadTap!,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _OverlayIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.14),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 22, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _BasmalaMark extends StatelessWidget {
  const _BasmalaMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 30,
      child: SvgPicture.asset(
        _dailyContentSectionBasmalaAsset,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }
}
