import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

part 'home_daily_content_section_widgets.dart';

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
  final VoidCallback? onPreviousPageTap;
  final VoidCallback? onNextPageTap;

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
    this.onPreviousPageTap,
    this.onNextPageTap,
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
                    onPreviousPageTap: widget.onPreviousPageTap,
                    onNextPageTap: widget.onNextPageTap,
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
    const screenEdgeGap = 12.0;
    const horizontalPanelInset = 20.0;
    final overlayObject = overlay.context.findRenderObject();
    final overlayHeight = overlayObject is RenderBox && overlayObject.hasSize
        ? overlayObject.size.height
        : MediaQuery.sizeOf(context).height;
    final maxPanelHeight = _maxDouble(0, overlayHeight - (screenEdgeGap * 2));
    final targetTop = offset.dy.clamp(screenEdgeGap, overlayHeight).toDouble();
    final targetLeft = offset.dx + horizontalPanelInset;
    final targetWidth = _maxDouble(0, size.width - (horizontalPanelInset * 2));

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
              left: targetLeft,
              top: targetTop,
              width: targetWidth,
              child: _InfoOverlayPanel(
                message: trimmedMessage,
                isRtl: widget.isRtl,
                cizgiColor: widget.cizgiColor,
                contentColor: widget.contentColor,
                maxHeight: maxPanelHeight,
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

