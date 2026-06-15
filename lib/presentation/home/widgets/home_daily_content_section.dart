import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _dailyContentSectionArabicLocale = Locale('ar');
const _dailyContentSectionBasmalaAsset = 'img/Besmele.svg';

class DailyContentSection extends StatefulWidget {
  final String title;
  final String arabicTitle;
  final String latinTitle;
  final String displayText;
  final bool isRtl;
  final String reference;
  final String bookReference;
  final Color cizgiColor;
  final Color contentColor;
  final Color referenceColor;
  final bool showBasmala;
  final double topContentInset;
  final String infoText;
  final VoidCallback? onReadTap;

  const DailyContentSection({
    super.key,
    required this.title,
    this.arabicTitle = '',
    this.latinTitle = '',
    required this.displayText,
    required this.isRtl,
    required this.reference,
    this.bookReference = '',
    required this.cizgiColor,
    required this.contentColor,
    required this.referenceColor,
    this.showBasmala = false,
    this.topContentInset = 0,
    this.infoText = '',
    this.onReadTap,
  });

  @override
  State<DailyContentSection> createState() => _DailyContentSectionState();
}

class _DailyContentSectionState extends State<DailyContentSection> {
  bool _isInfoOpen = false;
  final GlobalKey _sectionKey = GlobalKey();
  OverlayEntry? _infoOverlayEntry;

  @override
  void dispose() {
    _removeInfoOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final refStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: widget.referenceColor,
      fontWeight: FontWeight.w600,
      fontSize: 17,
    );
    final double refFontSize = refStyle?.fontSize ?? 17;
    final hasReadAction = widget.onReadTap != null;
    final infoTextTrimmed = widget.infoText.trim();
    final hasInfoAction = infoTextTrimmed.isNotEmpty;
    final textTrimmed = widget.displayText.trim();
    final isArabic = widget.isRtl && _hasArabic(textTrimmed);
    final titleTrimmed = widget.title.trim();
    final arabicTitleTrimmed = widget.arabicTitle.trim();
    final latinTitleTrimmed = widget.latinTitle.trim();
    final referenceTrimmed = widget.reference.trim();
    final bookReferenceTrimmed = widget.bookReference.trim();
    final hasReference =
        referenceTrimmed.isNotEmpty || bookReferenceTrimmed.isNotEmpty;
    final hasActions = hasInfoAction || hasReadAction;
    final showBasmalaHeader = widget.showBasmala && textTrimmed.isNotEmpty;
    final basmalaAfterGap = arabicTitleTrimmed.isNotEmpty ? 20.0 : 12.0;

    final TextStyle displayStyle;
    if (widget.isRtl) {
      displayStyle =
          Theme.of(context).textTheme.bodySmall?.copyWith(
            color: widget.cizgiColor.withValues(alpha: 0.9),
            fontFamily: 'Mirza',
            fontFamilyFallback: const <String>[
              'Lateef',
              'NotoNaskhArabic',
              'Amiri',
              'Arial',
            ],
            fontSize: 22,
            height: 1.45,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ) ??
          TextStyle(
            color: widget.cizgiColor.withValues(alpha: 0.9),
            fontSize: 22,
          );
    } else {
      displayStyle =
          Theme.of(context).textTheme.bodySmall?.copyWith(
            color: widget.cizgiColor.withValues(alpha: 0.85),
            height: 1.4,
            fontSize: 18,
            fontStyle: FontStyle.normal,
          ) ??
          const TextStyle(fontSize: 18);
    }

    return Container(
      key: _sectionKey,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 1, 10, 8),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: widget.contentColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.cizgiColor.withValues(alpha: 0.12)),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.topContentInset > 0 && !showBasmalaHeader)
                  SizedBox(height: widget.topContentInset),
                if (showBasmalaHeader) ...[
                  _BasmalaHeader(
                    hasInfoAction: hasInfoAction,
                    hasReadAction: hasReadAction,
                    onInfoTap: () => _openInfoPanel(infoTextTrimmed),
                    onReadTap: widget.onReadTap,
                  ),
                  SizedBox(height: basmalaAfterGap),
                ],
                if (arabicTitleTrimmed.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      arabicTitleTrimmed,
                      locale: _dailyContentSectionArabicLocale,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: widget.cizgiColor.withValues(alpha: 0.9),
                            fontFamily: 'Amiri',
                            fontFamilyFallback: const <String>[
                              'NotoNaskhArabic',
                              'Lateef',
                              'Mirza',
                              'Arial',
                            ],
                            fontSize: 32,
                            height: 1.1,
                            fontWeight: FontWeight.normal,
                            letterSpacing: 0,
                          ) ??
                          TextStyle(
                            color: widget.cizgiColor.withValues(alpha: 0.9),
                            fontFamily: 'Amiri',
                            fontSize: 32,
                            height: 1.1,
                            fontWeight: FontWeight.normal,
                          ),
                    ),
                  ),
                  if (latinTitleTrimmed.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        latinTitleTrimmed,
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: widget.cizgiColor.withValues(alpha: 0.85),
                              fontSize: 20,
                              fontWeight: FontWeight.normal,
                            ) ??
                            TextStyle(
                              color: widget.cizgiColor.withValues(alpha: 0.85),
                              fontSize: 20,
                              fontWeight: FontWeight.normal,
                            ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                ] else if (titleTrimmed.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      titleTrimmed,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: widget.cizgiColor.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                if (textTrimmed.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      textTrimmed,
                      locale: widget.isRtl
                          ? _dailyContentSectionArabicLocale
                          : null,
                      style: displayStyle,
                      textAlign: TextAlign.center,
                      textDirection: isArabic
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      softWrap: true,
                    ),
                  ),
                ],
                if (hasReference) ...[
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (referenceTrimmed.isNotEmpty)
                          Text(
                            referenceTrimmed,
                            style: refStyle,
                            textAlign: TextAlign.center,
                            textDirection: widget.isRtl
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                          ),
                        if (bookReferenceTrimmed.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            bookReferenceTrimmed,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: (refFontSize - 2),
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            textDirection: widget.isRtl
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (hasActions && !showBasmalaHeader) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: 34,
                        height: 34,
                        child: hasInfoAction
                            ? _OverlayIconButton(
                                icon: Icons.info_outline_rounded,
                                tooltip: 'Bilgi',
                                onTap: () => _openInfoPanel(infoTextTrimmed),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 34,
                        height: 34,
                        child: hasReadAction
                            ? _OverlayIconButton(
                                icon: Icons.volume_up_rounded,
                                tooltip: 'Oku',
                                onTap: widget.onReadTap!,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openInfoPanel(String message) {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) return;
    if (_isInfoOpen) return;
    _removeInfoOverlay();
    final renderObject = _sectionKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final overlay = Overlay.of(context);
    final offset = renderObject.localToGlobal(Offset.zero);
    final size = renderObject.size;

    _infoOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _closeInfoPanel,
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              left: offset.dx,
              top: offset.dy,
              width: size.width,
              height: size.height,
              child: _InfoOverlayPanel(
                message: trimmedMessage,
                isRtl: widget.isRtl,
                cizgiColor: widget.cizgiColor,
                contentColor: widget.contentColor,
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_infoOverlayEntry!);
    if (mounted) setState(() => _isInfoOpen = true);
  }

  void _closeInfoPanel() {
    _removeInfoOverlay();
    if (mounted) setState(() => _isInfoOpen = false);
  }

  void _removeInfoOverlay() {
    _infoOverlayEntry?.remove();
    _infoOverlayEntry = null;
  }

  bool _hasArabic(String value) {
    return RegExp(
      r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
    ).hasMatch(value);
  }
}

class _InfoOverlayPanel extends StatelessWidget {
  final String message;
  final bool isRtl;
  final Color cizgiColor;
  final Color contentColor;

  const _InfoOverlayPanel({
    required this.message,
    required this.isRtl,
    required this.cizgiColor,
    required this.contentColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final panelHeight = maxHeight <= 0
            ? 120.0
            : (maxHeight * 0.5).clamp(120.0, 200.0).toDouble();
        return Align(
          alignment: Alignment.center,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: SizedBox(
              width: double.infinity,
              height: panelHeight,
              child: Material(
                color: Color.lerp(contentColor, Colors.black, 0.12) ??
                    contentColor,
                borderRadius: BorderRadius.circular(10),
                elevation: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: cizgiColor.withValues(alpha: 0.28),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Directionality(
                    textDirection: isRtl
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
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
