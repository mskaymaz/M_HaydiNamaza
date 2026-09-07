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
            unawaited(_refreshNativeWidgetScheduleFromHomeData(data, times));
          });

          final items = _buildItems(l10n, displayTimes);
          final active = _prayerDayOffset == 0
              ? _activePrayer(displayTimes, _now)
              : Prayer.none;
          final next = _nextPrayer(times, _now, l10n);
          final countdown = _formatCountdown(_now, next.time);
          final nextTime = homeFormatTime(next.time);
          final isKerahatActive = _checkIsKerahatActive(displayTimes, _now);
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
                          final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
                          final stablePanelHeight = isLandscape ? math.max(constraints.maxHeight, constraints.maxWidth) : constraints.maxHeight;
                          final drawerLayout = _computeDrawerLayout(
                            locationTextSize: ui.typography.locationSize,
                            nextTimeTextSize: ui.typography.nextTimeSize,
                            nextLabelTextSize: ui.typography.nextLabelSize,
                            topPanelVerticalPadding:
                                ui.topPanelPadding.vertical,
                            constraintsMaxHeight: stablePanelHeight,
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
                            stablePanelHeight -
                                infoPanelTop -
                                infoPanelBottomPadding +
                                infoPanelBottomOverflow,
                          );
                          final panelWidthFactor = isLandscape
                              ? (_isLandscapePanelsExpanded ? 0.9 : 0.72)
                              : 1.0;
                          final prayerTablePanelHeight =
                              _prayerTableFuture == null ? 112.0 : 310.0;
                          final infoPanelEstimatedHeight =
                              infoPanelMaxHeight + 8.0 + prayerTablePanelHeight;
                          final scrollContentHeight = math.max(
                            constraints.maxHeight,
                            infoPanelTop +
                                infoPanelEstimatedHeight +
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
                                                                      false,
                                                                  showAzanIcon:
                                                                      _reminderSettings
                                                                          .showAzanIcon,
                                                                  showVibrationIcon:
                                                                      _reminderSettings
                                                                          .showVibrationIcon,
                                                                  showSilentIcon:
                                                                      _reminderSettings
                                                                          .prayerSilenceEnabled,
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
                                                      Positioned(
                                                        top: 8,
                                                        left: 8,
                                                        child: AppHelpTooltip(
                                                          visible: _reminderSettings
                                                              .showHelpBalloons,
                                                          title: _showPrayerControlPanel
                                                              ? 'Vakit paneli ayarlar\u0131'
                                                              : 'Vakit paneli',
                                                          message: _showPrayerControlPanel
                                                              ? 'Bu g\u00f6r\u00fcn\u00fcmde her vakit i\u00e7in sesli hat\u0131rlatma, ezan, titre\u015fim ve sessiz kal se\u00e7eneklerini sat\u0131r sat\u0131r d\u00fczenleyebilirsiniz. Sessiz kal ikonu, Ayarlar/Hat\u0131rlatma Ayarlar\u0131 b\u00f6l\u00fcm\u00fcndeki ana ayar etkinse ilgili vakitten \u00f6nce telefonu sessize al\u0131r ve s\u00fcre sonunda \u00f6nceki ayarlar\u0131na d\u00f6ner. \u2715 simgesine bast\u0131\u011f\u0131n\u0131zda normal vakit listesine d\u00f6nersiniz.'
                                                              : 'Vakitler paneli sa\u011fdan sola kayd\u0131r\u0131ld\u0131\u011f\u0131nda se\u00e7ili konum i\u00e7in yaln\u0131zca s\u0131radaki 7 g\u00fcn\u00fcn vakitleri g\u00f6sterilir.\n\nAlarm/hat\u0131rlatma yap\u0131s\u0131: \u{1F514} simgesine bast\u0131\u011f\u0131n\u0131zda vakit ayarlar\u0131 a\u00e7\u0131l\u0131r. Buradan her vakit i\u00e7in sesli hat\u0131rlatma, ezan ve titre\u015fim se\u00e7eneklerini ayr\u0131 ayr\u0131 etkinle\u015ftirip pasifle\u015ftirebilirsiniz.\n\nSessiz kal yap\u0131s\u0131: [[inline_icon]] simgesine bast\u0131\u011f\u0131n\u0131zda o vakit i\u00e7in sessize alma etkinle\u015ftirilir veya pasifle\u015ftirilir. Kullanabilmek i\u00e7in Ayarlar/Hat\u0131rlatma Ayarlar\u0131 b\u00f6l\u00fcm\u00fcnden ana ayar\u0131 etkinle\u015ftirin. Belirlenen s\u00fcre sonunda telefon \u00f6nceki ayarlar\u0131na d\u00f6ner.\n\nYatay ekranda panele \u00e7ift dokunarak panel geni\u015fli\u011fini de\u011fi\u015ftirebilirsiniz.',
                                                          inlineIconBuilder: (_) => SvgPicture.asset(
                                                            'assets/icons/volume_off.svg',
                                                            width: 18,
                                                            height: 18,
                                                            colorFilter: const ColorFilter.mode(
                                                              Color(0xFF1F1F1F),
                                                              BlendMode.srcIn,
                                                            ),
                                                          ),
                                                          iconSize: 19,
                                                          tapSize: 32,
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
                                      showHelpBalloons:
                                          _reminderSettings.showHelpBalloons,
                                      isKerahatActive: isKerahatActive,
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
                                            child: _buildInfoPanels(
                                              data: data,
                                              cizgiColor: palette.cizgiColor,
                                              panelColor: palette.zeminColor,
                                              maxHeight: infoPanelMaxHeight,
                                              showHelpBalloons:
                                                  _reminderSettings.showHelpBalloons,
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
                  if (_voiceLoopUntil != null)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: SafeArea(
                        top: false,
                        child: HomeActiveReminderPanel(
                          voicePrayerLabel: _voiceLoopPrayerLabel,
                          onCloseVoice: _dismissVoiceReminder,
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

  bool _checkIsKerahatActive(PrayerTimes times, DateTime now) {
    if (!_kerahatSettings.enabled || _prayerDayOffset != 0) return false;
    final sunriseStart = times.sunrise;
    final sunriseEnd = sunriseStart.add(
      Duration(minutes: _kerahatSettings.sunriseMinutes.clamp(0, 120)),
    );
    if (!now.isBefore(sunriseStart) && now.isBefore(sunriseEnd)) return true;

    final dhuhrStart = times.dhuhr.subtract(
      Duration(minutes: _kerahatSettings.dhuhrMinutes.clamp(0, 120)),
    );
    final dhuhrEnd = times.dhuhr;
    if (!now.isBefore(dhuhrStart) && now.isBefore(dhuhrEnd)) return true;

    final maghribStart = times.maghrib.subtract(
      Duration(minutes: _kerahatSettings.maghribMinutes.clamp(0, 120)),
    );
    final maghribEnd = times.maghrib;
    if (!now.isBefore(maghribStart) && now.isBefore(maghribEnd)) return true;

    return false;
  }
}
