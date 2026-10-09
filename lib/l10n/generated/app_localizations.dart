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
  /// **'BANTAWAN'**
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

  /// No description provided for @tabPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get tabPublic;

  /// No description provided for @tabPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get tabPrivate;

  /// No description provided for @onlinePeers.
  ///
  /// In en, this message translates to:
  /// **'Nearby Nodes'**
  String get onlinePeers;

  /// No description provided for @meshRelayTitle.
  ///
  /// In en, this message translates to:
  /// **'Mesh Relay & Bridging'**
  String get meshRelayTitle;

  /// No description provided for @meshRelayDesc.
  ///
  /// In en, this message translates to:
  /// **'Multi-hop message and SOS forwarding across Bluetooth nodes'**
  String get meshRelayDesc;

  /// No description provided for @dataMuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Data Mule'**
  String get dataMuleTitle;

  /// No description provided for @dataMuleDesc.
  ///
  /// In en, this message translates to:
  /// **'Store-carry-and-forward messages via passing peers when out of range'**
  String get dataMuleDesc;

  /// No description provided for @tacticalCallsign.
  ///
  /// In en, this message translates to:
  /// **'Tactical Callsign'**
  String get tacticalCallsign;

  /// No description provided for @changeCallsign.
  ///
  /// In en, this message translates to:
  /// **'Change Callsign'**
  String get changeCallsign;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @carrierBag.
  ///
  /// In en, this message translates to:
  /// **'Courier Tactical Bag'**
  String get carrierBag;

  /// No description provided for @selectCarrier.
  ///
  /// In en, this message translates to:
  /// **'Select Carrier (Data Mule)'**
  String get selectCarrier;

  /// No description provided for @dispatchAllConnected.
  ///
  /// In en, this message translates to:
  /// **'Dispatch to All Connected'**
  String get dispatchAllConnected;

  /// No description provided for @autoPlayVoice.
  ///
  /// In en, this message translates to:
  /// **'Auto-play Voice Messages'**
  String get autoPlayVoice;

  /// No description provided for @systemInfo.
  ///
  /// In en, this message translates to:
  /// **'System Architecture & Info'**
  String get systemInfo;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @infoTab.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get infoTab;

  /// No description provided for @sendSos.
  ///
  /// In en, this message translates to:
  /// **'Send SOS'**
  String get sendSos;

  /// No description provided for @shareLocation.
  ///
  /// In en, this message translates to:
  /// **'Share Location'**
  String get shareLocation;

  /// No description provided for @recordVoice.
  ///
  /// In en, this message translates to:
  /// **'Hold to record voice'**
  String get recordVoice;

  /// No description provided for @offlineBagEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your tactical bag is currently empty'**
  String get offlineBagEmpty;

  /// No description provided for @navFirstAid.
  ///
  /// In en, this message translates to:
  /// **'First Aid'**
  String get navFirstAid;

  /// No description provided for @disasterInterface.
  ///
  /// In en, this message translates to:
  /// **'TACTICAL DISASTER INTERFACE'**
  String get disasterInterface;

  /// No description provided for @disasterSub.
  ///
  /// In en, this message translates to:
  /// **'Select a scenario to access offline survival tools and simulations'**
  String get disasterSub;

  /// No description provided for @floodTitle.
  ///
  /// In en, this message translates to:
  /// **'Flood Emergency'**
  String get floodTitle;

  /// No description provided for @floodDesc.
  ///
  /// In en, this message translates to:
  /// **'Flood evacuation & offline communication'**
  String get floodDesc;

  /// No description provided for @fireTitle.
  ///
  /// In en, this message translates to:
  /// **'Fire Hazard'**
  String get fireTitle;

  /// No description provided for @fireDesc.
  ///
  /// In en, this message translates to:
  /// **'Emergency strobe & siren distress signals'**
  String get fireDesc;

  /// No description provided for @earthquakeTitle.
  ///
  /// In en, this message translates to:
  /// **'Earthquake'**
  String get earthquakeTitle;

  /// No description provided for @earthquakeDesc.
  ///
  /// In en, this message translates to:
  /// **'Initial distress signals & survival beacons'**
  String get earthquakeDesc;

  /// No description provided for @lostTitle.
  ///
  /// In en, this message translates to:
  /// **'Lost in Wild'**
  String get lostTitle;

  /// No description provided for @lostDesc.
  ///
  /// In en, this message translates to:
  /// **'Digital compass & tactical position fix'**
  String get lostDesc;

  /// No description provided for @flashlightTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Flashlight'**
  String get flashlightTitle;

  /// No description provided for @flashlightSos.
  ///
  /// In en, this message translates to:
  /// **'SOS Strobe (3 Short 3 Long 3 Short)'**
  String get flashlightSos;

  /// No description provided for @flashlightStrobe.
  ///
  /// In en, this message translates to:
  /// **'Tactical Strobe Beacon'**
  String get flashlightStrobe;

  /// No description provided for @strobeSpeed.
  ///
  /// In en, this message translates to:
  /// **'Strobe Frequency: {speed} Hz'**
  String strobeSpeed(String speed);

  /// No description provided for @sirenTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Siren'**
  String get sirenTitle;

  /// No description provided for @sirenPolice.
  ///
  /// In en, this message translates to:
  /// **'Police Siren'**
  String get sirenPolice;

  /// No description provided for @sirenAmbulance.
  ///
  /// In en, this message translates to:
  /// **'Ambulance Siren'**
  String get sirenAmbulance;

  /// No description provided for @sirenTactical.
  ///
  /// In en, this message translates to:
  /// **'Tactical Alarm'**
  String get sirenTactical;

  /// No description provided for @sirenStop.
  ///
  /// In en, this message translates to:
  /// **'Stop Siren'**
  String get sirenStop;

  /// No description provided for @compassTitle.
  ///
  /// In en, this message translates to:
  /// **'Digital Compass & Position Fix'**
  String get compassTitle;

  /// No description provided for @compassCalibrating.
  ///
  /// In en, this message translates to:
  /// **'Calibrating compass...'**
  String get compassCalibrating;

  /// No description provided for @compassUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Compass Unavailable'**
  String get compassUnavailable;

  /// No description provided for @compassPermDenied.
  ///
  /// In en, this message translates to:
  /// **'Please enable Location permission in app settings to use compass'**
  String get compassPermDenied;

  /// No description provided for @compassSensorMissing.
  ///
  /// In en, this message translates to:
  /// **'This device lacks a magnetometer sensor'**
  String get compassSensorMissing;

  /// No description provided for @compassAccuracyLabel.
  ///
  /// In en, this message translates to:
  /// **'Sensor Accuracy: {acc}'**
  String compassAccuracyLabel(String acc);

  /// No description provided for @directionN.
  ///
  /// In en, this message translates to:
  /// **'NORTH'**
  String get directionN;

  /// No description provided for @directionS.
  ///
  /// In en, this message translates to:
  /// **'SOUTH'**
  String get directionS;

  /// No description provided for @directionE.
  ///
  /// In en, this message translates to:
  /// **'EAST'**
  String get directionE;

  /// No description provided for @directionW.
  ///
  /// In en, this message translates to:
  /// **'WEST'**
  String get directionW;

  /// No description provided for @copyCoordsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Map link and coordinates copied!'**
  String get copyCoordsSuccess;

  /// No description provided for @shareCoordsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Share Your Coordinates'**
  String get shareCoordsPrompt;

  /// No description provided for @coordCopiedClip.
  ///
  /// In en, this message translates to:
  /// **'Coordinates copied to clipboard'**
  String get coordCopiedClip;

  /// No description provided for @meshOffline.
  ///
  /// In en, this message translates to:
  /// **'#mesh Offline'**
  String get meshOffline;

  /// No description provided for @meshScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning nodes...'**
  String get meshScanning;

  /// No description provided for @meshConnectedNodes.
  ///
  /// In en, this message translates to:
  /// **'{count} nodes connected'**
  String meshConnectedNodes(int count);

  /// No description provided for @disasterAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Disaster Alert'**
  String get disasterAlertTitle;

  /// No description provided for @noDisasterReport.
  ///
  /// In en, this message translates to:
  /// **'No severe disaster reports in this area'**
  String get noDisasterReport;

  /// No description provided for @offlineWeatherInfo.
  ///
  /// In en, this message translates to:
  /// **'Offline Weather Telemetry'**
  String get offlineWeatherInfo;

  /// No description provided for @connectivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Connectivity Status'**
  String get connectivityTitle;

  /// No description provided for @meshOfflineActive.
  ///
  /// In en, this message translates to:
  /// **'Offline Mesh Mode Active (Zero Internet)'**
  String get meshOfflineActive;

  /// No description provided for @deviceHealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Device Health Telemetry'**
  String get deviceHealthTitle;

  /// No description provided for @batteryLabel.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get batteryLabel;

  /// No description provided for @storageLabel.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storageLabel;

  /// No description provided for @sensorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sensors'**
  String get sensorsLabel;

  /// No description provided for @gettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Acquiring location...'**
  String get gettingLocation;

  /// No description provided for @identifyingLoc.
  ///
  /// In en, this message translates to:
  /// **'Identifying...'**
  String get identifyingLoc;

  /// No description provided for @openPermSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings to grant permission'**
  String get openPermSettings;

  /// No description provided for @unknownStreet.
  ///
  /// In en, this message translates to:
  /// **'Unknown Street'**
  String get unknownStreet;

  /// No description provided for @medicalIdComplete.
  ///
  /// In en, this message translates to:
  /// **'Medical ID {percent}% Complete'**
  String medicalIdComplete(int percent);

  /// No description provided for @nearestHospitalTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearest Hospital'**
  String get nearestHospitalTitle;

  /// No description provided for @anonymousMode.
  ///
  /// In en, this message translates to:
  /// **'Anonymous Mode (ANONYMOUS)'**
  String get anonymousMode;

  /// No description provided for @iceContact.
  ///
  /// In en, this message translates to:
  /// **'ICE Contact (Emergency)'**
  String get iceContact;

  /// No description provided for @hikeElevation.
  ///
  /// In en, this message translates to:
  /// **'ELEVATION'**
  String get hikeElevation;

  /// No description provided for @hikeDistance.
  ///
  /// In en, this message translates to:
  /// **'DISTANCE'**
  String get hikeDistance;

  /// No description provided for @hikeDuration.
  ///
  /// In en, this message translates to:
  /// **'DURATION'**
  String get hikeDuration;

  /// No description provided for @hikeSpeed.
  ///
  /// In en, this message translates to:
  /// **'SPEED'**
  String get hikeSpeed;

  /// No description provided for @hikePace.
  ///
  /// In en, this message translates to:
  /// **'PACE'**
  String get hikePace;

  /// No description provided for @hikeAltitude.
  ///
  /// In en, this message translates to:
  /// **'ALTITUDE'**
  String get hikeAltitude;

  /// No description provided for @meterUnit.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get meterUnit;

  /// No description provided for @backtrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Backtrack Navigation'**
  String get backtrackTitle;

  /// No description provided for @backtrackDistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance to trailhead: {dist}'**
  String backtrackDistanceLabel(String dist);

  /// No description provided for @backtrackArrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived at Starting Point!'**
  String get backtrackArrived;

  /// No description provided for @endHikeTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish Hike Tracking?'**
  String get endHikeTitle;

  /// No description provided for @endHikeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Your trail track will be securely stored offline on this device.'**
  String get endHikeConfirm;

  /// No description provided for @confirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @noticeBoardTitle.
  ///
  /// In en, this message translates to:
  /// **'Notices @ #mesh'**
  String get noticeBoardTitle;

  /// No description provided for @noticePostEmergency.
  ///
  /// In en, this message translates to:
  /// **'Urgent Emergency Notice'**
  String get noticePostEmergency;

  /// No description provided for @noticeDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Notice Expiration'**
  String get noticeDurationLabel;

  /// No description provided for @duration1d.
  ///
  /// In en, this message translates to:
  /// **'1 Day'**
  String get duration1d;

  /// No description provided for @duration3d.
  ///
  /// In en, this message translates to:
  /// **'3 Days'**
  String get duration3d;

  /// No description provided for @duration7d.
  ///
  /// In en, this message translates to:
  /// **'7 Days'**
  String get duration7d;

  /// No description provided for @noticeDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Notice'**
  String get noticeDelete;

  /// No description provided for @noticeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No active notices in this mesh sector'**
  String get noticeEmpty;

  /// No description provided for @noticePostedUrgent.
  ///
  /// In en, this message translates to:
  /// **'🚨 Urgent emergency notice broadcast to all mesh nodes'**
  String get noticePostedUrgent;

  /// No description provided for @noticePostedNormal.
  ///
  /// In en, this message translates to:
  /// **'📌 Notice posted successfully via Peer-to-Peer mesh'**
  String get noticePostedNormal;

  /// No description provided for @callsignDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Callsign (@)'**
  String get callsignDialogTitle;

  /// No description provided for @callsignDialogPrompt.
  ///
  /// In en, this message translates to:
  /// **'This handle will identify you in the offline #mesh network:'**
  String get callsignDialogPrompt;

  /// No description provided for @saveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveAction;

  /// No description provided for @deleteNoticeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this notice?'**
  String get deleteNoticeConfirm;

  /// No description provided for @verifyPeerTitle.
  ///
  /// In en, this message translates to:
  /// **'Peer Identity Verification'**
  String get verifyPeerTitle;

  /// No description provided for @scanPeerQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code to Verify'**
  String get scanPeerQr;

  /// No description provided for @myQr.
  ///
  /// In en, this message translates to:
  /// **'My QR Code'**
  String get myQr;

  /// No description provided for @scanFriendQr.
  ///
  /// In en, this message translates to:
  /// **'Scan Peer QR'**
  String get scanFriendQr;

  /// No description provided for @qrInstruction.
  ///
  /// In en, this message translates to:
  /// **'Ask your peer to scan this QR code to verify your public key, preventing MITM attacks.'**
  String get qrInstruction;

  /// No description provided for @verifiedStatus.
  ///
  /// In en, this message translates to:
  /// **'Verified Identity'**
  String get verifiedStatus;

  /// No description provided for @unverifiedStatus.
  ///
  /// In en, this message translates to:
  /// **'Unverified Peer'**
  String get unverifiedStatus;

  /// No description provided for @keyChangedAlert.
  ///
  /// In en, this message translates to:
  /// **'SECURITY WARNING: Peer key has changed!'**
  String get keyChangedAlert;

  /// No description provided for @compareFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Compare this security fingerprint with {name}\'s screen'**
  String compareFingerprint(String name);

  /// No description provided for @safetyTitle.
  ///
  /// In en, this message translates to:
  /// **'AUTO CHECK-IN'**
  String get safetyTitle;

  /// No description provided for @safetySubtitle.
  ///
  /// In en, this message translates to:
  /// **'TACTICAL LIFELINE MONITOR'**
  String get safetySubtitle;

  /// No description provided for @safetyStandby.
  ///
  /// In en, this message translates to:
  /// **'STANDBY'**
  String get safetyStandby;

  /// No description provided for @safetyAlert.
  ///
  /// In en, this message translates to:
  /// **'CRITICAL ALERT'**
  String get safetyAlert;

  /// No description provided for @safetyActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE MONITORING'**
  String get safetyActive;

  /// No description provided for @safetyStandbyDesc.
  ///
  /// In en, this message translates to:
  /// **'System Standby • Automatic Mesh Monitoring Ready'**
  String get safetyStandbyDesc;

  /// No description provided for @safetyActiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Active Lifeline • Tap dial or button to confirm safety'**
  String get safetyActiveDesc;

  /// No description provided for @safetyCrisisDesc.
  ///
  /// In en, this message translates to:
  /// **'CRISIS! Please confirm your safety to cancel outgoing SOS'**
  String get safetyCrisisDesc;

  /// No description provided for @checkInNow.
  ///
  /// In en, this message translates to:
  /// **'Check-in Safety Now'**
  String get checkInNow;

  /// No description provided for @recurringCheckin.
  ///
  /// In en, this message translates to:
  /// **'Recurring Mode'**
  String get recurringCheckin;

  /// No description provided for @facilitiesNearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical Facilities Nearby'**
  String get facilitiesNearbyTitle;

  /// No description provided for @noFacilitiesFiltered.
  ///
  /// In en, this message translates to:
  /// **'No medical facilities match active filter'**
  String get noFacilitiesFiltered;

  /// No description provided for @openStatus.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openStatus;

  /// No description provided for @closedStatus.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closedStatus;

  /// No description provided for @navigateAction.
  ///
  /// In en, this message translates to:
  /// **'Directions'**
  String get navigateAction;

  /// No description provided for @callAction.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callAction;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning,'**
  String get greetingMorning;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening,'**
  String get greetingEvening;

  /// No description provided for @urgentNoticeAlert.
  ///
  /// In en, this message translates to:
  /// **'🚨 Urgent Notice'**
  String get urgentNoticeAlert;

  /// No description provided for @tapToOpenRadar.
  ///
  /// In en, this message translates to:
  /// **'Tap to open radar'**
  String get tapToOpenRadar;

  /// No description provided for @hikeFloatingActive.
  ///
  /// In en, this message translates to:
  /// **'🌲 Hike Active'**
  String get hikeFloatingActive;

  /// No description provided for @hikeFloatingBacktrack.
  ///
  /// In en, this message translates to:
  /// **'🧭 Backtracking...'**
  String get hikeFloatingBacktrack;

  /// No description provided for @gpsSignalLabel.
  ///
  /// In en, this message translates to:
  /// **'GPS Signal'**
  String get gpsSignalLabel;

  /// No description provided for @gpsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get gpsEnabled;

  /// No description provided for @gpsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get gpsDisabled;

  /// No description provided for @gpsLockSuccess.
  ///
  /// In en, this message translates to:
  /// **'Position Locked'**
  String get gpsLockSuccess;

  /// No description provided for @gpsLockFail.
  ///
  /// In en, this message translates to:
  /// **'No Fix'**
  String get gpsLockFail;

  /// No description provided for @meshNodesLabel.
  ///
  /// In en, this message translates to:
  /// **'Mesh Network'**
  String get meshNodesLabel;

  /// No description provided for @meshTapToChat.
  ///
  /// In en, this message translates to:
  /// **'Tap to chat'**
  String get meshTapToChat;

  /// No description provided for @meshNoConnection.
  ///
  /// In en, this message translates to:
  /// **'No Connection'**
  String get meshNoConnection;

  /// No description provided for @nodesUnit.
  ///
  /// In en, this message translates to:
  /// **'Nodes'**
  String get nodesUnit;

  /// No description provided for @pleaseCharge.
  ///
  /// In en, this message translates to:
  /// **'Please Charge'**
  String get pleaseCharge;

  /// No description provided for @normalStatus.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normalStatus;

  /// No description provided for @forecast24h7d.
  ///
  /// In en, this message translates to:
  /// **'Forecast 24h & 7 Days'**
  String get forecast24h7d;

  /// No description provided for @internetUnstable.
  ///
  /// In en, this message translates to:
  /// **'Internet Unstable'**
  String get internetUnstable;

  /// No description provided for @offlineMapRecommend.
  ///
  /// In en, this message translates to:
  /// **'Download offline map for safety before signal is lost'**
  String get offlineMapRecommend;

  /// No description provided for @downloadMap.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadMap;

  /// No description provided for @startingDownloadMap.
  ///
  /// In en, this message translates to:
  /// **'Starting offline map download...'**
  String get startingDownloadMap;

  /// No description provided for @checkInSystemWorking.
  ///
  /// In en, this message translates to:
  /// **'Check-in System Active'**
  String get checkInSystemWorking;

  /// No description provided for @checkInTimeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time Remaining: {time}'**
  String checkInTimeRemaining(String time);

  /// No description provided for @checkInRecurringSuffix.
  ///
  /// In en, this message translates to:
  /// **' (Recurring)'**
  String get checkInRecurringSuffix;

  /// No description provided for @checkInAutoPrompt.
  ///
  /// In en, this message translates to:
  /// **'Set timer for auto SOS if unresponsive'**
  String get checkInAutoPrompt;

  /// No description provided for @checkInWarningExpiring.
  ///
  /// In en, this message translates to:
  /// **'Warning: Time almost up!'**
  String get checkInWarningExpiring;

  /// No description provided for @bloodTypePrefix.
  ///
  /// In en, this message translates to:
  /// **'Blood Type - '**
  String get bloodTypePrefix;

  /// No description provided for @deactivateSystem.
  ///
  /// In en, this message translates to:
  /// **'DEACTIVATE SYSTEM'**
  String get deactivateSystem;

  /// No description provided for @iAmSafe.
  ///
  /// In en, this message translates to:
  /// **'I AM SAFE'**
  String get iAmSafe;

  /// No description provided for @iAmSafeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to reset countdown for next cycle'**
  String get iAmSafeSubtitle;

  /// No description provided for @activateShield.
  ///
  /// In en, this message translates to:
  /// **'ACTIVATE SHIELD • {minutes} MIN'**
  String activateShield(int minutes);

  /// No description provided for @activateShieldSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable automatic safety monitoring'**
  String get activateShieldSubtitle;

  /// No description provided for @checkInDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'CHECK-IN DURATION'**
  String get checkInDurationLabel;

  /// No description provided for @countingDown.
  ///
  /// In en, this message translates to:
  /// **'Counting down'**
  String get countingDown;

  /// No description provided for @recurringModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring Mode'**
  String get recurringModeTitle;

  /// No description provided for @recurringModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically restart timer after checking in'**
  String get recurringModeSubtitle;

  /// No description provided for @systemArmed.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM ARMED'**
  String get systemArmed;

  /// No description provided for @tapToArm.
  ///
  /// In en, this message translates to:
  /// **'TAP TO ARM'**
  String get tapToArm;

  /// No description provided for @urgentNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Urgent Alert'**
  String get urgentNoticeTitle;

  /// No description provided for @urgentNoticeDesc.
  ///
  /// In en, this message translates to:
  /// **'System will broadcast emergency SOS with GPS coordinates soon'**
  String get urgentNoticeDesc;

  /// No description provided for @standbyNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Tactical Monitor'**
  String get standbyNoticeTitle;

  /// No description provided for @standbyNoticeDesc.
  ///
  /// In en, this message translates to:
  /// **'If timer expires without response, emergency SOS will be sent via Mesh'**
  String get standbyNoticeDesc;

  /// No description provided for @endHikeBtn.
  ///
  /// In en, this message translates to:
  /// **'End Hike'**
  String get endHikeBtn;

  /// No description provided for @hikeResumeBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue Hike'**
  String get hikeResumeBtn;

  /// No description provided for @hikeHoldToEnd.
  ///
  /// In en, this message translates to:
  /// **'HOLD TO END'**
  String get hikeHoldToEnd;

  /// No description provided for @backtrackDistanceRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {dist}'**
  String backtrackDistanceRemaining(String dist);

  /// No description provided for @backtrackFollowArrow.
  ///
  /// In en, this message translates to:
  /// **'Follow the arrow and trail back'**
  String get backtrackFollowArrow;

  /// No description provided for @backtrackBasecamp.
  ///
  /// In en, this message translates to:
  /// **'Starting Point (Basecamp ⛳)'**
  String get backtrackBasecamp;

  /// No description provided for @backtrackNavActive.
  ///
  /// In en, this message translates to:
  /// **'Navigating back to start'**
  String get backtrackNavActive;

  /// No description provided for @hikeRecording.
  ///
  /// In en, this message translates to:
  /// **'HIKE RECORDING'**
  String get hikeRecording;

  /// No description provided for @hikeRecordingTrail.
  ///
  /// In en, this message translates to:
  /// **'Recording trail offline'**
  String get hikeRecordingTrail;

  /// No description provided for @hikeMinimizedBox.
  ///
  /// In en, this message translates to:
  /// **'Minimize (Keep recording in background)'**
  String get hikeMinimizedBox;

  /// No description provided for @hikeExitDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit Hike Tracking?'**
  String get hikeExitDialogTitle;

  /// No description provided for @hikeExitDialogDesc.
  ///
  /// In en, this message translates to:
  /// **'Hike activity is currently recording. What would you like to do?'**
  String get hikeExitDialogDesc;

  /// No description provided for @hikeTrailDistance.
  ///
  /// In en, this message translates to:
  /// **'{dist} km • {points} pts'**
  String hikeTrailDistance(String dist, int points);

  /// No description provided for @shareSmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Send via SMS'**
  String get shareSmsTitle;

  /// No description provided for @shareSmsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send emergency rescue message now'**
  String get shareSmsSubtitle;

  /// No description provided for @copyLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy Location Link'**
  String get copyLinkTitle;

  /// No description provided for @copyLinkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share coordinates as Google Maps Link'**
  String get copyLinkSubtitle;

  /// No description provided for @meshOfflineNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline Mesh Network'**
  String get meshOfflineNetworkTitle;

  /// No description provided for @meshScanningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scanning for peers nearby...'**
  String get meshScanningSubtitle;

  /// No description provided for @meshOfflineDisabled.
  ///
  /// In en, this message translates to:
  /// **'Offline mesh communication disabled'**
  String get meshOfflineDisabled;

  /// No description provided for @openChatRoom.
  ///
  /// In en, this message translates to:
  /// **'Open Chat'**
  String get openChatRoom;

  /// No description provided for @localSosTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Local SOS'**
  String get localSosTitle;

  /// No description provided for @localSosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Broadcast to peers within 100 meters (Offline)'**
  String get localSosSubtitle;

  /// No description provided for @sosTrappedRoof.
  ///
  /// In en, this message translates to:
  /// **'Trapped on roof'**
  String get sosTrappedRoof;

  /// No description provided for @sosNeedFoodWater.
  ///
  /// In en, this message translates to:
  /// **'Need food/water'**
  String get sosNeedFoodWater;

  /// No description provided for @sosInjuredElderly.
  ///
  /// In en, this message translates to:
  /// **'Injured/Elderly present'**
  String get sosInjuredElderly;

  /// No description provided for @sosWaterRising.
  ///
  /// In en, this message translates to:
  /// **'Water level rising'**
  String get sosWaterRising;

  /// No description provided for @sosSentBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Signal sent: {text}'**
  String sosSentBroadcast(String text);

  /// No description provided for @urgentSosTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS'**
  String get urgentSosTitle;

  /// No description provided for @fireService199.
  ///
  /// In en, this message translates to:
  /// **'Fire Dept (199)'**
  String get fireService199;

  /// No description provided for @medicalService1669.
  ///
  /// In en, this message translates to:
  /// **'Rescue (1669)'**
  String get medicalService1669;

  /// No description provided for @emergencySignalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Signals'**
  String get emergencySignalsTitle;

  /// No description provided for @flashlightSosOff.
  ///
  /// In en, this message translates to:
  /// **'Stop SOS Flash'**
  String get flashlightSosOff;

  /// No description provided for @flashlightSosOn.
  ///
  /// In en, this message translates to:
  /// **'Flashlight SOS'**
  String get flashlightSosOn;

  /// No description provided for @strobeOff.
  ///
  /// In en, this message translates to:
  /// **'Turn Off Strobe'**
  String get strobeOff;

  /// No description provided for @strobeOn.
  ///
  /// In en, this message translates to:
  /// **'Strobe Beacon'**
  String get strobeOn;

  /// No description provided for @sirenOff.
  ///
  /// In en, this message translates to:
  /// **'Turn Off Siren'**
  String get sirenOff;

  /// No description provided for @sirenOn.
  ///
  /// In en, this message translates to:
  /// **'Siren'**
  String get sirenOn;

  /// No description provided for @safetyCheckShortcutTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto Check-In (Safety Check)'**
  String get safetyCheckShortcutTitle;

  /// No description provided for @safetyCheckShortcutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send SOS automatically if you lose contact'**
  String get safetyCheckShortcutSubtitle;

  /// No description provided for @hikeActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Hike Tracking Active'**
  String get hikeActiveTitle;

  /// No description provided for @hikeStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Start Hike Mode'**
  String get hikeStartTitle;

  /// No description provided for @hikeActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trail recording active.. tap to stop'**
  String get hikeActiveSubtitle;

  /// No description provided for @hikeStartSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record trail track and mark starting point'**
  String get hikeStartSubtitle;

  /// No description provided for @hikeEndSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Hike tracking finished'**
  String get hikeEndSnackbar;

  /// No description provided for @hikePrepTitle.
  ///
  /// In en, this message translates to:
  /// **'Preparing Hike Session'**
  String get hikePrepTitle;

  /// No description provided for @hikePrepDesc.
  ///
  /// In en, this message translates to:
  /// **'Preparing hike area (10 sq km) & offline map'**
  String get hikePrepDesc;

  /// No description provided for @hikeStartAdventure.
  ///
  /// In en, this message translates to:
  /// **'Start Adventure (Hike Mode)'**
  String get hikeStartAdventure;

  /// No description provided for @unableToGetLocation.
  ///
  /// In en, this message translates to:
  /// **'Unable to determine coordinates'**
  String get unableToGetLocation;

  /// No description provided for @openAppSettings.
  ///
  /// In en, this message translates to:
  /// **'Open App Settings'**
  String get openAppSettings;

  /// No description provided for @headingDirectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Heading Direction'**
  String get headingDirectionLabel;

  /// No description provided for @directionNE.
  ///
  /// In en, this message translates to:
  /// **'Northeast (NE)'**
  String get directionNE;

  /// No description provided for @directionSE.
  ///
  /// In en, this message translates to:
  /// **'Southeast (SE)'**
  String get directionSE;

  /// No description provided for @directionSW.
  ///
  /// In en, this message translates to:
  /// **'Southwest (SW)'**
  String get directionSW;

  /// No description provided for @directionNW.
  ///
  /// In en, this message translates to:
  /// **'Northwest (NW)'**
  String get directionNW;

  /// No description provided for @altitudeMsl.
  ///
  /// In en, this message translates to:
  /// **'Altitude (MSL)'**
  String get altitudeMsl;

  /// No description provided for @facilitiesNearbySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby medical coordinates'**
  String get facilitiesNearbySubtitle;

  /// No description provided for @facilityUnitCount.
  ///
  /// In en, this message translates to:
  /// **'{count} places'**
  String facilityUnitCount(int count);

  /// No description provided for @searchMedicalHint.
  ///
  /// In en, this message translates to:
  /// **'Search hospital, clinic, pharmacy...'**
  String get searchMedicalHint;

  /// No description provided for @openNowFilter.
  ///
  /// In en, this message translates to:
  /// **'Open Now'**
  String get openNowFilter;

  /// No description provided for @sortByNearest.
  ///
  /// In en, this message translates to:
  /// **'Nearest'**
  String get sortByNearest;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Name A-Z'**
  String get sortByName;

  /// No description provided for @chipAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get chipAll;

  /// No description provided for @chipHospital.
  ///
  /// In en, this message translates to:
  /// **'🏥 Hospital'**
  String get chipHospital;

  /// No description provided for @chipClinic.
  ///
  /// In en, this message translates to:
  /// **'🩺 Clinic'**
  String get chipClinic;

  /// No description provided for @chipPharmacy.
  ///
  /// In en, this message translates to:
  /// **'💊 Pharmacy'**
  String get chipPharmacy;

  /// No description provided for @open24Hours.
  ///
  /// In en, this message translates to:
  /// **'Open 24h'**
  String get open24Hours;

  /// No description provided for @myFingerprintTitle.
  ///
  /// In en, this message translates to:
  /// **'📱 Your Device Fingerprint'**
  String get myFingerprintTitle;

  /// No description provided for @myFingerprintDesc.
  ///
  /// In en, this message translates to:
  /// **'Have {peer} verify this code on their device'**
  String myFingerprintDesc(String peer);

  /// No description provided for @peerFingerprintTitle.
  ///
  /// In en, this message translates to:
  /// **'🔑 Fingerprint of {peer}'**
  String peerFingerprintTitle(String peer);

  /// No description provided for @peerFingerprintDesc.
  ///
  /// In en, this message translates to:
  /// **'Compare this security code with {peer}\'s screen'**
  String peerFingerprintDesc(String peer);

  /// No description provided for @fingerprintCopied.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint copied to clipboard'**
  String get fingerprintCopied;

  /// No description provided for @noFingerprintData.
  ///
  /// In en, this message translates to:
  /// **'No fingerprint data to copy'**
  String get noFingerprintData;

  /// No description provided for @verifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Identity Verified'**
  String get verifiedSuccess;

  /// No description provided for @resetTrust.
  ///
  /// In en, this message translates to:
  /// **'Reset Trust'**
  String get resetTrust;

  /// No description provided for @resetTrustSuccess.
  ///
  /// In en, this message translates to:
  /// **'Trust status reset successfully'**
  String get resetTrustSuccess;

  /// No description provided for @scanQrForKeys.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code for Keys'**
  String get scanQrForKeys;

  /// No description provided for @waitingForPublicKey.
  ///
  /// In en, this message translates to:
  /// **'Waiting for public key from peer via mesh...'**
  String get waitingForPublicKey;

  /// No description provided for @acceptNewKey.
  ///
  /// In en, this message translates to:
  /// **'Accept New Key'**
  String get acceptNewKey;

  /// No description provided for @markAsVerified.
  ///
  /// In en, this message translates to:
  /// **'Mark as Verified'**
  String get markAsVerified;
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
