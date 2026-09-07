import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Pray'**
  String get appTitle;

  /// No description provided for @homePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Prayer times will appear here soon.'**
  String get homePlaceholder;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get languageTurkish;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @calculationMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Prayer time method'**
  String get calculationMethodLabel;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @locationNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get locationNotSet;

  /// No description provided for @locationEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationEditTitle;

  /// No description provided for @locationCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get locationCountryLabel;

  /// No description provided for @locationCityLabel.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get locationCityLabel;

  /// No description provided for @locationUseList.
  ///
  /// In en, this message translates to:
  /// **'Select from list'**
  String get locationUseList;

  /// No description provided for @locationFavoritesLabel.
  ///
  /// In en, this message translates to:
  /// **'Favorite locations'**
  String get locationFavoritesLabel;

  /// No description provided for @locationSelectLabel.
  ///
  /// In en, this message translates to:
  /// **'Select location'**
  String get locationSelectLabel;

  /// No description provided for @locationAddFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get locationAddFavorite;

  /// No description provided for @locationDistrictLabel.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get locationDistrictLabel;

  /// No description provided for @locationLatitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get locationLatitudeLabel;

  /// No description provided for @locationLongitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get locationLongitudeLabel;

  /// No description provided for @locationSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get locationSave;

  /// No description provided for @locationFillAll.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields.'**
  String get locationFillAll;

  /// No description provided for @locationFavoriteAdded.
  ///
  /// In en, this message translates to:
  /// **'Location added to favorites.'**
  String get locationFavoriteAdded;

  /// No description provided for @locationFavoriteExists.
  ///
  /// In en, this message translates to:
  /// **'This location is already in favorites.'**
  String get locationFavoriteExists;

  /// No description provided for @locationFavoriteRemoved.
  ///
  /// In en, this message translates to:
  /// **'Favorite location removed.'**
  String get locationFavoriteRemoved;

  /// No description provided for @locationFavoriteApplied.
  ///
  /// In en, this message translates to:
  /// **'Favorite location applied.'**
  String get locationFavoriteApplied;

  /// No description provided for @locationFavoriteApplyLabel.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get locationFavoriteApplyLabel;

  /// No description provided for @locationFavoriteUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This favorite has no coordinates.'**
  String get locationFavoriteUnavailable;

  /// No description provided for @locationFavoriteRemoveLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove favorite'**
  String get locationFavoriteRemoveLabel;

  /// No description provided for @methodNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get methodNotSet;

  /// No description provided for @methodEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer time method'**
  String get methodEditTitle;

  /// No description provided for @methodSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get methodSave;

  /// No description provided for @methodTurkey.
  ///
  /// In en, this message translates to:
  /// **'Turkey calculation method'**
  String get methodTurkey;

  /// No description provided for @methodAladhan.
  ///
  /// In en, this message translates to:
  /// **'Aladhan'**
  String get methodAladhan;

  /// No description provided for @methodMuslimWorldLeague.
  ///
  /// In en, this message translates to:
  /// **'Muslim World League'**
  String get methodMuslimWorldLeague;

  /// No description provided for @methodUmmAlQura.
  ///
  /// In en, this message translates to:
  /// **'Umm Al-Qura'**
  String get methodUmmAlQura;

  /// No description provided for @methodMoonsighting.
  ///
  /// In en, this message translates to:
  /// **'Moonsighting Committee'**
  String get methodMoonsighting;

  /// No description provided for @methodNorthAmerica.
  ///
  /// In en, this message translates to:
  /// **'North America (ISNA)'**
  String get methodNorthAmerica;

  /// No description provided for @prayerFajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get prayerFajr;

  /// No description provided for @prayerSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get prayerSunrise;

  /// No description provided for @prayerDhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get prayerDhuhr;

  /// No description provided for @prayerAsr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerAsr;

  /// No description provided for @prayerMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get prayerMaghrib;

  /// No description provided for @prayerIsha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get prayerIsha;

  /// No description provided for @kerahatWarning.
  ///
  /// In en, this message translates to:
  /// **'KERAHAT TIME'**
  String get kerahatWarning;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
