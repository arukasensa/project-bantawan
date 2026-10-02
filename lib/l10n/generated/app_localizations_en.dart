// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SOS Premier';

  @override
  String get sos => 'SOS';

  @override
  String get profile => 'Profile';

  @override
  String get navHome => 'Home';

  @override
  String get navMap => 'Map';

  @override
  String get navSOS => 'SOS';

  @override
  String get navProfile => 'Profile';

  @override
  String get greetingAfternoon => 'Good Afternoon,';

  @override
  String get safetyStatusNormal => 'Safety system working normally';

  @override
  String get loadingWeather => 'Loading weather data...';

  @override
  String get retryHint => 'If it stuck for too long, please tap to retry';

  @override
  String get locationNotFound => 'Location not found';

  @override
  String get tapToRetry => 'Tap to retry';

  @override
  String get emergencyHotlines => 'Emergency Hotlines';

  @override
  String get seeAll => 'See All';

  @override
  String get hospitals => 'Hospitals';

  @override
  String get firstAidGuide => 'First Aid Guide';

  @override
  String get survivalTools => 'Survival Tools';

  @override
  String get emergencyContacts => 'Emergency Contacts';

  @override
  String get medicalHistory => 'Medical History';

  @override
  String get medicalId => 'Medical Identification';

  @override
  String get bloodType => 'Blood Type';

  @override
  String get nearestHospital => 'Nearest Hospital';

  @override
  String get survivalTitle => 'Survival Tools';

  @override
  String get compass => 'Digital Compass';

  @override
  String get flashlight => 'Emergency Strobe';

  @override
  String get siren => 'SOS Siren';

  @override
  String get nearbyNetwork => 'Nearby Emergency Network';

  @override
  String get startNetwork => 'Start Identification System';

  @override
  String get stopNetwork => 'Stop Identification System';

  @override
  String get enterChat => 'Enter Nearby Chat';

  @override
  String get offlineChatTitle => 'Offline Mesh Chat';

  @override
  String get searchingPeers => 'Searching for nearby people...';

  @override
  String connectedDevices(int count) {
    return 'Connected $count devices';
  }

  @override
  String get noMessages =>
      'No messages yet\nSend SOS or greet people around you';

  @override
  String get typeEmergencyMsg => 'Type emergency message...';

  @override
  String get myLocation => 'My Location';

  @override
  String get viewInMap => 'View in Map';

  @override
  String get locationError => 'Cannot get location';

  @override
  String get medicalEmergency => 'Medical Emergency';

  @override
  String get police => 'Police';

  @override
  String get fire => 'Fire Department';

  @override
  String get tourist => 'Tourist Police';

  @override
  String get rescue => 'Rescue Support';

  @override
  String get mentalHealth => 'Mental Health';

  @override
  String get sosButtonHint => 'Press for immediate assistance';

  @override
  String get signalAccuracy => 'Signal Accuracy';

  @override
  String get searchingSignal => 'Searching for signal...';

  @override
  String get meters => 'meters';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get altitude => 'Altitude';

  @override
  String get heading => 'Heading';

  @override
  String get copyCoordsForRescue => 'Copy Coordinates for Rescue';

  @override
  String get readyForWifiRadio => 'Ready for radio communication';

  @override
  String get startingSystem => 'Starting System...';

  @override
  String get identifiableByOthers => 'Others can see you now';

  @override
  String get startOfflineSearch => 'Start searching offline';

  @override
  String sendMsgToDevices(int count) {
    return 'Send message to $count nearby devices';
  }

  @override
  String get coordsCopied => 'Coordinates copied to clipboard';

  @override
  String get mapTitle => 'Nearby Medical Facilities';

  @override
  String get mapSubtitle => 'Find the nearest help point';

  @override
  String mapPoints(int count) {
    return '$count points';
  }

  @override
  String get filterAll => 'All';

  @override
  String get filterHospitals => 'Hospitals';

  @override
  String get filterClinics => 'Clinics';

  @override
  String get searchRadius => 'Search Radius';

  @override
  String get mapStyle => 'Map Style';

  @override
  String get kmUnit => 'km';

  @override
  String etaLabel(String eta) {
    return 'Arrives in $eta';
  }

  @override
  String get minutes => 'mins';

  @override
  String get sosInitialMsg => 'Emergency help requested! Please stay calm.';

  @override
  String sosCountdown(int count) {
    return 'Sending alert in $count...';
  }

  @override
  String get sosSent => 'SOS Alert Sent';

  @override
  String get sosActive => 'SOS ACTIVE';

  @override
  String get cancelSos => 'CANCEL SOS';

  @override
  String get nearbyUsers => 'Nearby Users';

  @override
  String distUnit(String dist) {
    return '$dist km';
  }

  @override
  String get sosHoldCancelHelp => 'Release to cancel | Hold to confirm';

  @override
  String get sosCanceledNotify => 'SOS Canceled';

  @override
  String get sosLoggingLocation => 'Current location is being recorded';

  @override
  String get sosSendingMedicalData => 'Your medical info will be sent as well';

  @override
  String get sosSentDetail =>
      'We have sent an SMS and your location to your emergency contacts. You can call them now.';

  @override
  String get finishButton => 'Finished';

  @override
  String get okButton => 'OK';

  @override
  String get noEmergencyContacts => 'No Emergency Contacts Found';

  @override
  String get addEmergencyContactsHint =>
      'Please add emergency contacts before using SOS';

  @override
  String get error => 'Error';

  @override
  String get smsAppOpened => 'SMS App Opened';

  @override
  String get distance => 'Distance';

  @override
  String get medicalIDHeader => 'Medical Identification';

  @override
  String get conditionsLabel => 'Medical Conditions';

  @override
  String get allergiesLabel => 'Allergies';

  @override
  String get hospitalPrefLabel => 'Preferred Hospital';

  @override
  String get insuranceLabel => 'Insurance Provider';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get bodyCompHeader => 'Body Composition';

  @override
  String get weightLabel => 'WEIGHT';

  @override
  String get heightLabel => 'HEIGHT';

  @override
  String get bmiLabel => 'BMI';

  @override
  String get appSettingsHeader => 'App Global Settings';

  @override
  String get appLanguageLabel => 'App Language';

  @override
  String get securityHeader => 'Security & Account';

  @override
  String get deleteAccountLabel => 'Delete Account';

  @override
  String get logoutLabel => 'Logout';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get guestUser => 'Guest User';

  @override
  String get ageLabel => 'Age';

  @override
  String get bloodTypeShort => 'Blood';

  @override
  String smsConfirmHint(int count) {
    return 'Please confirm sending the message in your SMS app.\n\nSent to: $count people';
  }

  @override
  String get cancelButton => 'Cancel Now';

  @override
  String get filterPharmacies => 'Pharmacies';

  @override
  String get openingHours => 'Opening Hours';

  @override
  String get openNow => 'Open Now';

  @override
  String get closed => 'Closed';

  @override
  String get sosConfirmSend =>
      'Please confirm sending the message in the SMS app immediately';

  @override
  String get sosHaveYouSent => 'Have you confirmed the sending?';

  @override
  String get yesAlreadySent => 'Yes, already sent';

  @override
  String get reSendLimit => 'Send again';
}
