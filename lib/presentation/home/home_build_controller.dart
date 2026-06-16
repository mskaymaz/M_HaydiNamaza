part of 'home_screen.dart';

extension _HomeBuildController on _HomeScreenState {
  Widget _buildHomeScaffold(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: FutureBuilder<_HomeData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          if (data.location == null) {
            return HomeMissingLocationPanel(
              message: l10n.locationNotSet,
              settingsLabel: l10n.settingsTitle,
              onOpenSettings: _openSettings,
            );
          }

          if (data.error == 'invalid_location') {
            return HomeInvalidLocationPanel(
              message: l10n.locationFillAll,
              settingsLabel: l10n.settingsTitle,
              onOpenSettings: _openSettings,
            );
          }

          final times = data.times;
          final displayTimes = data.displayTimes ?? times;
          if (times == null || displayTimes == null) {
            return HomePrayerTimesUnavailablePanel(message: l10n.comingSoon);
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            unawaited(_checkAndTriggerReminders(times, l10n));
          });

          final items = _buildItems(l10n, displayTimes);
          final active = _prayerDayOffset == 0
              ? _activePrayer(displayTimes, _now)
              : Prayer.none;
          final next = _nextPrayer(times, _now, l10n);
          final countdown = _formatCountdown(_now, next.time);
          final nextTime = homeFormatTime(next.time);
          final location = data.location!;
          final provinceLabel = homeTitleCase(
            location.province,
            l10n.localeName,
          );
          final districtLabel = homeTitleCase(
            location.district,
            l10n.localeName,
          );
          final displayDate = data.displayDate ?? _now;
          final dateLabel = _combinedDateLabel(displayDate, l10n);
          final palette = widget.uiPaletteController.value;
          final ui = ConfigRegistry.mainUiFor(palette);
          final mediaPadding = MediaQuery.of(context).padding;
          final statusBarHeight = mediaPadding.top;
          final bottomSafePadding = mediaPadding.bottom;
          final statusBarColor =
              Color.lerp(palette.zeminColor, Colors.white, 0.5) ??
              palette.zeminColor;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            child: ColoredBox(
              color: palette.backgroundZeminColor,
              child: Stack(
                children: [
                  if (statusBarHeight > 0)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: statusBarHeight,
                      child: ColoredBox(color: statusBarColor),
                    ),
                  SafeArea(
                    child: Padding(
                      padding: ui.screenPadding,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final drawerLayout = _computeDrawerLayout(
                            locationTextSize: ui.typography.locationSize,
                            nextTimeTextSize: ui.typography.nextTimeSize,
                            nextLabelTextSize: ui.typography.nextLabelSize,
                            topPanelVerticalPadding:
                                ui.topPanelPadding.vertical,
                            constraintsMaxHeight: constraints.maxHeight,
                            drawerProgress: 1.0,
                          );
                          const infoPanelGap = 3.0;
                          const infoPanelBottomPadding = 8.0;
                          final infoPanelBottomOverflow = bottomSafePadding;
                          final drawerBottom =
                              drawerLayout.drawerTop +
                              drawerLayout.drawerHeight;
                          final infoPanelTop = drawerBottom + infoPanelGap;
                          final infoPanelMaxHeight = math.max(
                            140.0,
                            constraints.maxHeight -
                                infoPanelTop -
                                infoPanelBottomPadding +
                                infoPanelBottomOverflow,
                          );
                          final isLandscape =
                              MediaQuery.of(context).orientation ==
                              Orientation.landscape;
                          final panelWidthFactor = isLandscape
                              ? (_isLandscapePanelsExpanded ? 0.9 : 0.72)
                              : 1.0;
                          final scrollContentHeight = math.max(
                            constraints.maxHeight,
                            infoPanelTop +
                                infoPanelMaxHeight +
                                infoPanelBottomPadding,
                          );

                          return SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: scrollContentHeight,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    top: drawerLayout.drawerTop,
                                    left: 0,
                                    right: 0,
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: FractionallySizedBox(
                                        widthFactor: panelWidthFactor,
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 220,
                                          ),
                                          curve: Curves.easeOutCubic,
                                          height: drawerLayout.drawerHeight,
                                          decoration: BoxDecoration(
                                            color: ui.listPanel.color,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x22000000),
                                                blurRadius: 12,
                                                offset: Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: Column(
                                            children: [
                                              _PrayerDateBand(label: dateLabel),
                                              Expanded(
                                                child: GestureDetector(
                                                  behavior: HitTestBehavior
                                                      .translucent,
                                                  onTap: () {
                                                    if (!_showPrayerControlPanel) {
                                                      return;
                                                    }
                                                    _setHomeState(
                                                      () => _showPanelAddButton =
                                                          !_showPanelAddButton,
                                                    );
                                                  },
                                                  onHorizontalDragEnd:
                                                      _onPrayerPanelHorizontalDragEnd,
                                                  onHorizontalDragStart:
                                                      _onPrayerPanelHorizontalDragStart,
                                                  onHorizontalDragUpdate:
                                                      _onPrayerPanelHorizontalDragUpdate,
                                                  onDoubleTap: () {
                                                    if (!isLandscape) return;
                                                    _setHomeState(() {
                                                      _isLandscapePanelsExpanded =
                                                          !_isLandscapePanelsExpanded;
                                                    });
                                                  },
                                                  child: Stack(
                                                    children: [
                                                      Positioned.fill(
                                                        child: AnimatedSwitcher(
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    220,
                                                              ),
                                                          transitionBuilder: (child, animation) {
                                                            final curved = CurvedAnimation(
                                                              parent: animation,
                                                              curve: Curves.easeOutCubic,
                                                            );
                                                            return FadeTransition(
                                                              opacity: curved,
                                                              child: SlideTransition(
                                                                position: Tween<Offset>(
                                                                  begin: Offset(
                                                                    0.28 * _prayerPanelTransitionDirection,
                                                                    0,
                                                                  ),
                                                                  end: Offset.zero,
                                                                ).animate(curved),
                                                                child: child,
                                                              ),
                                                            );
                                                          },
                                                          child:
                                                              _showPrayerControlPanel
                                                              ? HomePrayerList(
                                                                  key: ValueKey('prayer_controls_$_prayerDayOffset'),
                                                                  controller:
                                                                      _prayerListScrollController,
                                                                  items: items,
                                                                  active:
                                                                      active,
                                                                  style: ui
                                                                      .listPanel,
                                                                  listPadding: ui
                                                                      .listPadding,
                                                                  rowGap:
                                                                      ui.rowGap,
                                                                  iconStyle: ui
                                                                      .iconToggle,
                                                                  chipStyle: ui
                                                                      .reminderChip,
                                                                  typography: ui
                                                                      .typography,
                                                                  cizgiColor:
                                                                      palette
                                                                          .cizgiColor,
                                                                  activeColor:
                                                                      palette
                                                                          .zeminColor,
                                                                  customPrayerLabelColor:
                                                                      palette
                                                                          .customPrayerLabelColor,
                                                                  showVoiceIcon:
                                                                      _reminderSettings
                                                                          .showVoiceIcon,
                                                                  showVisualIcon:
                                                                      _reminderSettings
                                                                          .showVisualIcon,
                                                                  showAzanIcon:
                                                                      _reminderSettings
                                                                          .showAzanIcon,
                                                                  showVibrationIcon:
                                                                      _reminderSettings
                                                                          .showVibrationIcon,
                                                                )
                                                              : HomePrayerSummaryList(
                                                                  key: ValueKey('prayer_summary_$_prayerDayOffset'),
                                                                  controller:
                                                                      _prayerListScrollController,
                                                                  items: items,
                                                                  active:
                                                                      active,
                                                                  listPadding: ui
                                                                      .listPadding,
                                                                  cizgiColor:
                                                                      palette
                                                                          .cizgiColor,
                                                                  activeColor:
                                                                      palette
                                                                          .zeminColor,
                                                                  customPrayerLabelColor:
                                                                      palette
                                                                          .customPrayerLabelColor,
                                                                  onOpenControls:
                                                                      _showPrayerControls,
                                                                ),
                                                        ),
                                                      ),
                                                      if (_showPrayerControlPanel)
                                                        Positioned(
                                                          top: 8,
                                                          right: 8,
                                                          child: InkWell(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  999,
                                                                ),
                                                            onTap:
                                                                _hidePrayerControls,
                                                            child: Container(
                                                              width: 34,
                                                              height: 34,
                                                              decoration: BoxDecoration(
                                                                color: Colors
                                                                    .white
                                                                    .withValues(
                                                                      alpha:
                                                                          0.92,
                                                                    ),
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                              child: const Icon(
                                                                Icons
                                                                    .close_rounded,
                                                                color: Color(
                                                                  0xFF1B5E20,
                                                                ),
                                                                size: 20,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      if (_showPrayerControlPanel &&
                                                          _showPanelAddButton)
                                                        Positioned(
                                                          left: 12,
                                                          bottom: 12,
                                                          child: InkWell(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  999,
                                                                ),
                                                            onTap:
                                                                _addCustomPrayerRow,
                                                            child: Container(
                                                              width: 36,
                                                              height: 36,
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    const Color(
                                                                      0xFFFFEB3B,
                                                                    ),
                                                                shape: BoxShape
                                                                    .circle,
                                                                border: Border.all(
                                                                  color: palette
                                                                      .cizgiColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.25,
                                                                      ),
                                                                ),
                                                              ),
                                                              child: const Icon(
                                                                Icons.add,
                                                                color: Color(
                                                                  0xFF1B5E20,
                                                                ),
                                                                size: 19.5,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: HomeTopPanel(
                                      provinceLabel: provinceLabel,
                                      districtLabel: districtLabel,
                                      nextLabel: next.label,
                                      nextTime: nextTime,
                                      countdown: countdown,
                                      onLocationTap: () =>
                                          _openLocationSettings(location),
                                      onQibla: () => _openQibla(location),
                                      onSettings: _openSettings,
                                      style: ui.topPanel,
                                      padding: ui.topPanelPadding,
                                      settingsIconSize: ui.settingsIconSize,
                                      settingsIconBoxSize:
                                          ui.settingsIconBoxSize,
                                      settingsIconOpacity:
                                          ui.settingsIconOpacity,
                                      typography: ui.typography,
                                      cizgiColor: palette.cizgiColor,
                                    ),
                                  ),
                                  Positioned(
                                    top: infoPanelTop,
                                    left: 0,
                                    right: 0,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        0,
                                        0,
                                        0,
                                        infoPanelBottomPadding,
                                      ),
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onDoubleTap: () {
                                          if (!isLandscape) return;
                                          _setHomeState(() {
                                            _isLandscapePanelsExpanded =
                                                !_isLandscapePanelsExpanded;
                                          });
                                        },
                                        child: Align(
                                          alignment: Alignment.topCenter,
                                          child: FractionallySizedBox(
                                            widthFactor: panelWidthFactor,
                                            child:
                                                FutureBuilder<
                                                  DailyContentSelectionResult
                                                >(
                                                  future: _dailyContentFuture,
                                                  builder: (context, snapshot) {
                                                    return HomeDailyContentPanel(
                                                      result: snapshot.data,
                                                      isLoading:
                                                          snapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting,
                                                      hasError:
                                                          snapshot.hasError,
                                                      cizgiColor:
                                                          palette.cizgiColor,
                                                      panelColor:
                                                          palette.zeminColor,
                                                      maxHeight:
                                                          infoPanelMaxHeight,
                                                      onCycleContentTap:
                                                          _cycleDailyContent,
                                                    );
                                                  },
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (_voiceLoopUntil != null || _visualLoopUntil != null)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: SafeArea(
                        top: false,
                        child: HomeActiveReminderPanel(
                          voicePrayerLabel: _voiceLoopPrayerLabel,
                          visualPrayerLabel: _visualLoopPrayerLabel,
                          visualMessage: _visualLoopMessage,
                          showVisualCard: _showVisualOverlay,
                          onCloseVoice: _dismissVoiceReminder,
                          onCloseVisual: _dismissVisualReminder,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
