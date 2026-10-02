import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('en'),
    Locale('th'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SOS Premier'**
  String get appTitle;

  /// No description provided for @sos.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sos;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navSOS.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get navSOS;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon,'**
  String get greetingAfternoon;

  /// No description provided for @safetyStatusNormal.
  ///
  /// In en, this message translates to:
  /// **'Safety system working normally'**
  String get safetyStatusNormal;

  /// No description provided for @loadingWeather.
  ///
  /// In en, this message translates to:
  /// **'Loading weather data...'**
  String get loadingWeather;

  /// No description provided for @retryHint.
  ///
  /// In en, this message translates to:
  /// **'If it stuck for too long, please tap to retry'**
  String get retryHint;

  /// No description provided for @locationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Location not found'**
  String get locationNotFound;

  /// No description provided for @tapToRetry.
  ///
  /// In en, this message translates to:
  /// **'Tap to retry'**
  String get tapToRetry;

  /// No description provided for @emergencyHotlines.
  ///
  /// In en, this message translates to:
  /// **'Emergency Hotlines'**
  String get emergencyHotlines;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @hospitals.
  ///
  /// In en, this message translates to:
  /// **'Hospitals'**
  String get hospitals;

  /// No description provided for @firstAidGuide.
  ///
  /// In en, this message translates to:
  /// **'First Aid Guide'**
  String get firstAidGuide;

  /// No description provided for @survivalTools.
  ///
  /// In en, this message translates to:
  /// **'Survival Tools'**
  String get survivalTools;

  /// No description provided for @emergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get emergencyContacts;

  /// No description provided for @medicalHistory.
  ///
  /// In en, this message translates to:
  /// **'Medical History'**
  String get medicalHistory;

  /// No description provided for @medicalId.
  ///
  /// In en, this message translates to:
  /// **'Medical Identification'**
  String get medicalId;

  /// No description provided for @bloodType.
  ///
  /// In en, this message translates to:
  /// **'Blood Type'**
  String get bloodType;

  /// No description provided for @nearestHospital.
  ///
  /// In en, this message translates to:
  /// **'Nearest Hospital'**
  String get nearestHospital;

  /// No description provided for @survivalTitle.
  ///
  /// In en, this message translates to:
  /// **'Survival Tools'**
  String get survivalTitle;

  /// No description provided for @compass.
  ///
  /// In en, this message translates to:
  /// **'Digital Compass'**
  String get compass;

  /// No description provided for @flashlight.
  ///
  /// In en, this message translates to:
  /// **'Emergency Strobe'**
  String get flashlight;

  /// No description provided for @siren.
  ///
  /// In en, this message translates to:
  /// **'SOS Siren'**
  String get siren;

  /// No description provided for @nearbyNetwork.
  ///
  /// In en, this message translates to:
  /// **'Nearby Emergency Network'**
  String get nearbyNetwork;

  /// No description provided for @startNetwork.
  ///
  /// In en, this message translates to:
  /// **'Start Identification System'**
  String get startNetwork;

  /// No description provided for @stopNetwork.
  ///
  /// In en, this message translates to:
  /// **'Stop Identification System'**
  String get stopNetwork;

  /// No description provided for @enterChat.
  ///
  /// In en, this message translates to:
  /// **'Enter Nearby Chat'**
  String get enterChat;

  /// No description provided for @offlineChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline Mesh Chat'**
  String get offlineChatTitle;

  /// No description provided for @searchingPeers.
  ///
  /// In en, this message translates to:
  /// **'Searching for nearby people...'**
  String get searchingPeers;

  /// No description provided for @connectedDevices.
  ///
  /// In en, this message translates to:
  /// **'Connected {count} devices'**
  String connectedDevices(int count);

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet\nSend SOS or greet people around you'**
  String get noMessages;

  /// No description provided for @typeEmergencyMsg.
  ///
  /// In en, this message translates to:
  /// **'Type emergency message...'**
  String get typeEmergencyMsg;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My Location'**
  String get myLocation;

  /// No description provided for @viewInMap.
  ///
  /// In en, this message translates to:
  /// **'View in Map'**
  String get viewInMap;

  /// No description provided for @locationError.
  ///
  /// In en, this message translates to:
  /// **'Cannot get location'**
  String get locationError;

  /// No description provided for @medicalEmergency.
  ///
  /// In en, this message translates to:
  /// **'Medical Emergency'**
  String get medicalEmergency;

  /// No description provided for @police.
  ///
  /// In en, this message translates to:
  /// **'Police'**
  String get police;

  /// No description provided for @fire.
  ///
  /// In en, this message translates to:
  /// **'Fire Department'**
  String get fire;

  /// No description provided for @tourist.
  ///
  /// In en, this message translates to:
  /// **'Tourist Police'**
  String get tourist;

  /// No description provided for @rescue.
  ///
  /// In en, this message translates to:
  /// **'Rescue Support'**
  String get rescue;

  /// No description provided for @mentalHealth.
  ///
  /// In en, this message translates to:
  /// **'Mental Health'**
  String get mentalHealth;

  /// No description provided for @sosButtonHint.
  ///
  /// In en, this message translates to:
  /// **'Press for immediate assistance'**
  String get sosButtonHint;

  /// No description provided for @signalAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Signal Accuracy'**
  String get signalAccuracy;

  /// No description provided for @searchingSignal.
  ///
  /// In en, this message translates to:
  /// **'Searching for signal...'**
  String get searchingSignal;

  /// No description provided for @meters.
  ///
  /// In en, this message translates to:
  /// **'meters'**
  String get meters;

  /// No description provided for @latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitude;

  /// No description provided for @longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitude;

  /// No description provided for @altitude.
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get altitude;

  /// No description provided for @heading.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get heading;

  /// No description provided for @copyCoordsForRescue.
  ///
  /// In en, this message translates to:
  /// **'Copy Coordinates for Rescue'**
  String get copyCoordsForRescue;

  /// No description provided for @readyForWifiRadio.
  ///
  /// In en, this message translates to:
  /// **'Ready for radio communication'**
  String get readyForWifiRadio;

  /// No description provided for @startingSystem.
  ///
  /// In en, this message translates to:
  /// **'Starting System...'**
  String get startingSystem;

  /// No description provided for @identifiableByOthers.
  ///
  /// In en, this message translates to:
  /// **'Others can see you now'**
  String get identifiableByOthers;

  /// No description provided for @startOfflineSearch.
  ///
  /// In en, this message translates to:
  /// **'Start searching offline'**
  String get startOfflineSearch;

  /// No description provided for @sendMsgToDevices.
  ///
  /// In en, this message translates to:
  /// **'Send message to {count} nearby devices'**
  String sendMsgToDevices(int count);

  /// No description provided for @coordsCopied.
  ///
  /// In en, this message translates to:
  /// **'Coordinates copied to clipboard'**
  String get coordsCopied;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby Medical Facilities'**
  String get mapTitle;

  /// No description provided for @mapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find the nearest help point'**
  String get mapSubtitle;

  /// No description provided for @mapPoints.
  ///
  /// In en, this message translates to:
  /// **'{count} points'**
  String mapPoints(int count);

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterHospitals.
  ///
  /// In en, this message translates to:
  /// **'Hospitals'**
  String get filterHospitals;

  /// No description provided for @filterClinics.
  ///
  /// In en, this message translates to:
  /// **'Clinics'**
  String get filterClinics;

  /// No description provided for @searchRadius.
  ///
  /// In en, this message translates to:
  /// **'Search Radius'**
  String get searchRadius;

  /// No description provided for @mapStyle.
  ///
  /// In en, this message translates to:
  /// **'Map Style'**
  String get mapStyle;

  /// No description provided for @kmUnit.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get kmUnit;

  /// No description provided for @etaLabel.
  ///
  /// In en, this message translates to:
  /// **'Arrives in {eta}'**
  String etaLabel(String eta);

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'mins'**
  String get minutes;

  /// No description provided for @sosInitialMsg.
  ///
  /// In en, this message translates to:
  /// **'Emergency help requested! Please stay calm.'**
  String get sosInitialMsg;

  /// No description provided for @sosCountdown.
  ///
  /// In en, this message translates to:
  /// **'Sending alert in {count}...'**
  String sosCountdown(int count);

  /// No description provided for @sosSent.
  ///
  /// In en, this message translates to:
  /// **'SOS Alert Sent'**
  String get sosSent;

  /// No description provided for @sosActive.
  ///
  /// In en, this message translates to:
  /// **'SOS ACTIVE'**
  String get sosActive;

  /// No description provided for @cancelSos.
  ///
  /// In en, this message translates to:
  /// **'CANCEL SOS'**
  String get cancelSos;

  /// No description provided for @nearbyUsers.
  ///
  /// In en, this message translates to:
  /// **'Nearby Users'**
  String get nearbyUsers;

  /// No description provided for @distUnit.
  ///
  /// In en, this message translates to:
  /// **'{dist} km'**
  String distUnit(String dist);

  /// No description provided for @sosHoldCancelHelp.
  ///
  /// In en, this message translates to:
  /// **'Release to cancel | Hold to confirm'**
  String get sosHoldCancelHelp;

  /// No description provided for @sosCanceledNotify.
  ///
  /// In en, this message translates to:
  /// **'SOS Canceled'**
  String get sosCanceledNotify;

  /// No description provided for @sosLoggingLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location is being recorded'**
  String get sosLoggingLocation;

  /// No description provided for @sosSendingMedicalData.
  ///
  /// In en, this message translates to:
  /// **'Your medical info will be sent as well'**
  String get sosSendingMedicalData;

  /// No description provided for @sosSentDetail.
  ///
  /// In en, this message translates to:
  /// **'We have sent an SMS and your location to your emergency contacts. You can call them now.'**
  String get sosSentDetail;

  /// No description provided for @finishButton.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finishButton;

  /// No description provided for @okButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okButton;

  /// No description provided for @noEmergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'No Emergency Contacts Found'**
  String get noEmergencyContacts;

  /// No description provided for @addEmergencyContactsHint.
  ///
  /// In en, this message translates to:
  /// **'Please add emergency contacts before using SOS'**
  String get addEmergencyContactsHint;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @smsAppOpened.
  ///
  /// In en, this message translates to:
  /// **'SMS App Opened'**
  String get smsAppOpened;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @medicalIDHeader.
  ///
  /// In en, this message translates to:
  /// **'Medical Identification'**
  String get medicalIDHeader;

  /// No description provided for @conditionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Medical Conditions'**
  String get conditionsLabel;

  /// No description provided for @allergiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get allergiesLabel;

  /// No description provided for @hospitalPrefLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred Hospital'**
  String get hospitalPrefLabel;

  /// No description provided for @insuranceLabel.
  ///
  /// In en, this message translates to:
  /// **'Insurance Provider'**
  String get insuranceLabel;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @bodyCompHeader.
  ///
  /// In en, this message translates to:
  /// **'Body Composition'**
  String get bodyCompHeader;

  /// No description provided for @weightLabel.
  ///
  /// In en, this message translates to:
  /// **'WEIGHT'**
  String get weightLabel;

  /// No description provided for @heightLabel.
  ///
  /// In en, this message translates to:
  /// **'HEIGHT'**
  String get heightLabel;

  /// No description provided for @bmiLabel.
  ///
  /// In en, this message translates to:
  /// **'BMI'**
  String get bmiLabel;

  /// No description provided for @appSettingsHeader.
  ///
  /// In en, this message translates to:
  /// **'App Global Settings'**
  String get appSettingsHeader;

  /// No description provided for @appLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguageLabel;

  /// No description provided for @securityHeader.
  ///
  /// In en, this message translates to:
  /// **'Security & Account'**
  String get securityHeader;

  /// No description provided for @deleteAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountLabel;

  /// No description provided for @logoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutLabel;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @guestUser.
  ///
  /// In en, this message translates to:
  /// **'Guest User'**
  String get guestUser;

  /// No description provided for @ageLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ageLabel;

  /// No description provided for @bloodTypeShort.
  ///
  /// In en, this message translates to:
  /// **'Blood'**
  String get bloodTypeShort;

  /// No description provided for @smsConfirmHint.
  ///
  /// In en, this message translates to:
  /// **'Please confirm sending the message in your SMS app.\n\nSent to: {count} people'**
  String smsConfirmHint(int count);

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel Now'**
  String get cancelButton;

  /// No description provided for @filterPharmacies.
  ///
  /// In en, this message translates to:
  /// **'Pharmacies'**
  String get filterPharmacies;

  /// No description provided for @openingHours.
  ///
  /// In en, this message translates to:
  /// **'Opening Hours'**
  String get openingHours;

  /// No description provided for @openNow.
  ///
  /// In en, this message translates to:
  /// **'Open Now'**
  String get openNow;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @sosConfirmSend.
  ///
  /// In en, this message translates to:
  /// **'Please confirm sending the message in the SMS app immediately'**
  String get sosConfirmSend;

  /// No description provided for @sosHaveYouSent.
  ///
  /// In en, this message translates to:
  /// **'Have you confirmed the sending?'**
  String get sosHaveYouSent;

  /// No description provided for @yesAlreadySent.
  ///
  /// In en, this message translates to:
  /// **'Yes, already sent'**
  String get yesAlreadySent;

  /// No description provided for @reSendLimit.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get reSendLimit;
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
      <String>['en', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
