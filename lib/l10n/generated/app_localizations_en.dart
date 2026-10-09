// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'BANTAWAN';

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

  @override
  String get tabPublic => 'Public';

  @override
  String get tabPrivate => 'Private';

  @override
  String get onlinePeers => 'Nearby Nodes';

  @override
  String get meshRelayTitle => 'Mesh Relay & Bridging';

  @override
  String get meshRelayDesc =>
      'Multi-hop message and SOS forwarding across Bluetooth nodes';

  @override
  String get dataMuleTitle => 'Emergency Data Mule';

  @override
  String get dataMuleDesc =>
      'Store-carry-and-forward messages via passing peers when out of range';

  @override
  String get tacticalCallsign => 'Tactical Callsign';

  @override
  String get changeCallsign => 'Change Callsign';

  @override
  String get appLanguage => 'App Language';

  @override
  String get carrierBag => 'Courier Tactical Bag';

  @override
  String get selectCarrier => 'Select Carrier (Data Mule)';

  @override
  String get dispatchAllConnected => 'Dispatch to All Connected';

  @override
  String get autoPlayVoice => 'Auto-play Voice Messages';

  @override
  String get systemInfo => 'System Architecture & Info';

  @override
  String get settingsTab => 'Settings';

  @override
  String get infoTab => 'Info';

  @override
  String get sendSos => 'Send SOS';

  @override
  String get shareLocation => 'Share Location';

  @override
  String get recordVoice => 'Hold to record voice';

  @override
  String get offlineBagEmpty => 'Your tactical bag is currently empty';

  @override
  String get navFirstAid => 'First Aid';

  @override
  String get disasterInterface => 'TACTICAL DISASTER INTERFACE';

  @override
  String get disasterSub =>
      'Select a scenario to access offline survival tools and simulations';

  @override
  String get floodTitle => 'Flood Emergency';

  @override
  String get floodDesc => 'Flood evacuation & offline communication';

  @override
  String get fireTitle => 'Fire Hazard';

  @override
  String get fireDesc => 'Emergency strobe & siren distress signals';

  @override
  String get earthquakeTitle => 'Earthquake';

  @override
  String get earthquakeDesc => 'Initial distress signals & survival beacons';

  @override
  String get lostTitle => 'Lost in Wild';

  @override
  String get lostDesc => 'Digital compass & tactical position fix';

  @override
  String get flashlightTitle => 'Emergency Flashlight';

  @override
  String get flashlightSos => 'SOS Strobe (3 Short 3 Long 3 Short)';

  @override
  String get flashlightStrobe => 'Tactical Strobe Beacon';

  @override
  String strobeSpeed(String speed) {
    return 'Strobe Frequency: $speed Hz';
  }

  @override
  String get sirenTitle => 'Emergency Siren';

  @override
  String get sirenPolice => 'Police Siren';

  @override
  String get sirenAmbulance => 'Ambulance Siren';

  @override
  String get sirenTactical => 'Tactical Alarm';

  @override
  String get sirenStop => 'Stop Siren';

  @override
  String get compassTitle => 'Digital Compass & Position Fix';

  @override
  String get compassCalibrating => 'Calibrating compass...';

  @override
  String get compassUnavailable => 'Compass Unavailable';

  @override
  String get compassPermDenied =>
      'Please enable Location permission in app settings to use compass';

  @override
  String get compassSensorMissing => 'This device lacks a magnetometer sensor';

  @override
  String compassAccuracyLabel(String acc) {
    return 'Sensor Accuracy: $acc';
  }

  @override
  String get directionN => 'NORTH';

  @override
  String get directionS => 'SOUTH';

  @override
  String get directionE => 'EAST';

  @override
  String get directionW => 'WEST';

  @override
  String get copyCoordsSuccess => 'Map link and coordinates copied!';

  @override
  String get shareCoordsPrompt => 'Share Your Coordinates';

  @override
  String get coordCopiedClip => 'Coordinates copied to clipboard';

  @override
  String get meshOffline => '#mesh Offline';

  @override
  String get meshScanning => 'Scanning nodes...';

  @override
  String meshConnectedNodes(int count) {
    return '$count nodes connected';
  }

  @override
  String get disasterAlertTitle => 'Disaster Alert';

  @override
  String get noDisasterReport => 'No severe disaster reports in this area';

  @override
  String get offlineWeatherInfo => 'Offline Weather Telemetry';

  @override
  String get connectivityTitle => 'Connectivity Status';

  @override
  String get meshOfflineActive => 'Offline Mesh Mode Active (Zero Internet)';

  @override
  String get deviceHealthTitle => 'Device Health Telemetry';

  @override
  String get batteryLabel => 'Battery';

  @override
  String get storageLabel => 'Storage';

  @override
  String get sensorsLabel => 'Sensors';

  @override
  String get gettingLocation => 'Acquiring location...';

  @override
  String get identifyingLoc => 'Identifying...';

  @override
  String get openPermSettings => 'Open settings to grant permission';

  @override
  String get unknownStreet => 'Unknown Street';

  @override
  String medicalIdComplete(int percent) {
    return 'Medical ID $percent% Complete';
  }

  @override
  String get nearestHospitalTitle => 'Nearest Hospital';

  @override
  String get anonymousMode => 'Anonymous Mode (ANONYMOUS)';

  @override
  String get iceContact => 'ICE Contact (Emergency)';

  @override
  String get hikeElevation => 'ELEVATION';

  @override
  String get hikeDistance => 'DISTANCE';

  @override
  String get hikeDuration => 'DURATION';

  @override
  String get hikeSpeed => 'SPEED';

  @override
  String get hikePace => 'PACE';

  @override
  String get hikeAltitude => 'ALTITUDE';

  @override
  String get meterUnit => 'm';

  @override
  String get backtrackTitle => 'Backtrack Navigation';

  @override
  String backtrackDistanceLabel(String dist) {
    return 'Distance to trailhead: $dist';
  }

  @override
  String get backtrackArrived => 'Arrived at Starting Point!';

  @override
  String get endHikeTitle => 'Finish Hike Tracking?';

  @override
  String get endHikeConfirm =>
      'Your trail track will be securely stored offline on this device.';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get noticeBoardTitle => 'Notices @ #mesh';

  @override
  String get noticePostEmergency => 'Urgent Emergency Notice';

  @override
  String get noticeDurationLabel => 'Notice Expiration';

  @override
  String get duration1d => '1 Day';

  @override
  String get duration3d => '3 Days';

  @override
  String get duration7d => '7 Days';

  @override
  String get noticeDelete => 'Delete Notice';

  @override
  String get noticeEmpty => 'No active notices in this mesh sector';

  @override
  String get noticePostedUrgent =>
      '🚨 Urgent emergency notice broadcast to all mesh nodes';

  @override
  String get noticePostedNormal =>
      '📌 Notice posted successfully via Peer-to-Peer mesh';

  @override
  String get callsignDialogTitle => 'Change Callsign (@)';

  @override
  String get callsignDialogPrompt =>
      'This handle will identify you in the offline #mesh network:';

  @override
  String get saveAction => 'Save';

  @override
  String get deleteNoticeConfirm =>
      'Are you sure you want to delete this notice?';

  @override
  String get verifyPeerTitle => 'Peer Identity Verification';

  @override
  String get scanPeerQr => 'Scan QR Code to Verify';

  @override
  String get myQr => 'My QR Code';

  @override
  String get scanFriendQr => 'Scan Peer QR';

  @override
  String get qrInstruction =>
      'Ask your peer to scan this QR code to verify your public key, preventing MITM attacks.';

  @override
  String get verifiedStatus => 'Verified Identity';

  @override
  String get unverifiedStatus => 'Unverified Peer';

  @override
  String get keyChangedAlert => 'SECURITY WARNING: Peer key has changed!';

  @override
  String compareFingerprint(String name) {
    return 'Compare this security fingerprint with $name\'s screen';
  }

  @override
  String get safetyTitle => 'AUTO CHECK-IN';

  @override
  String get safetySubtitle => 'TACTICAL LIFELINE MONITOR';

  @override
  String get safetyStandby => 'STANDBY';

  @override
  String get safetyAlert => 'CRITICAL ALERT';

  @override
  String get safetyActive => 'ACTIVE MONITORING';

  @override
  String get safetyStandbyDesc =>
      'System Standby • Automatic Mesh Monitoring Ready';

  @override
  String get safetyActiveDesc =>
      'Active Lifeline • Tap dial or button to confirm safety';

  @override
  String get safetyCrisisDesc =>
      'CRISIS! Please confirm your safety to cancel outgoing SOS';

  @override
  String get checkInNow => 'Check-in Safety Now';

  @override
  String get recurringCheckin => 'Recurring Mode';

  @override
  String get facilitiesNearbyTitle => 'Medical Facilities Nearby';

  @override
  String get noFacilitiesFiltered =>
      'No medical facilities match active filter';

  @override
  String get openStatus => 'Open';

  @override
  String get closedStatus => 'Closed';

  @override
  String get navigateAction => 'Directions';

  @override
  String get callAction => 'Call';

  @override
  String get greetingMorning => 'Good Morning,';

  @override
  String get greetingEvening => 'Good Evening,';

  @override
  String get urgentNoticeAlert => '🚨 Urgent Notice';

  @override
  String get tapToOpenRadar => 'Tap to open radar';

  @override
  String get hikeFloatingActive => '🌲 Hike Active';

  @override
  String get hikeFloatingBacktrack => '🧭 Backtracking...';

  @override
  String get gpsSignalLabel => 'GPS Signal';

  @override
  String get gpsEnabled => 'Enabled';

  @override
  String get gpsDisabled => 'Disabled';

  @override
  String get gpsLockSuccess => 'Position Locked';

  @override
  String get gpsLockFail => 'No Fix';

  @override
  String get meshNodesLabel => 'Mesh Network';

  @override
  String get meshTapToChat => 'Tap to chat';

  @override
  String get meshNoConnection => 'No Connection';

  @override
  String get nodesUnit => 'Nodes';

  @override
  String get pleaseCharge => 'Please Charge';

  @override
  String get normalStatus => 'Normal';

  @override
  String get forecast24h7d => 'Forecast 24h & 7 Days';

  @override
  String get internetUnstable => 'Internet Unstable';

  @override
  String get offlineMapRecommend =>
      'Download offline map for safety before signal is lost';

  @override
  String get downloadMap => 'Download';

  @override
  String get startingDownloadMap => 'Starting offline map download...';

  @override
  String get checkInSystemWorking => 'Check-in System Active';

  @override
  String checkInTimeRemaining(String time) {
    return 'Time Remaining: $time';
  }

  @override
  String get checkInRecurringSuffix => ' (Recurring)';

  @override
  String get checkInAutoPrompt => 'Set timer for auto SOS if unresponsive';

  @override
  String get checkInWarningExpiring => 'Warning: Time almost up!';

  @override
  String get bloodTypePrefix => 'Blood Type - ';

  @override
  String get deactivateSystem => 'DEACTIVATE SYSTEM';

  @override
  String get iAmSafe => 'I AM SAFE';

  @override
  String get iAmSafeSubtitle => 'Tap to reset countdown for next cycle';

  @override
  String activateShield(int minutes) {
    return 'ACTIVATE SHIELD • $minutes MIN';
  }

  @override
  String get activateShieldSubtitle => 'Enable automatic safety monitoring';

  @override
  String get checkInDurationLabel => 'CHECK-IN DURATION';

  @override
  String get countingDown => 'Counting down';

  @override
  String get recurringModeTitle => 'Recurring Mode';

  @override
  String get recurringModeSubtitle =>
      'Automatically restart timer after checking in';

  @override
  String get systemArmed => 'SYSTEM ARMED';

  @override
  String get tapToArm => 'TAP TO ARM';

  @override
  String get urgentNoticeTitle => 'Urgent Alert';

  @override
  String get urgentNoticeDesc =>
      'System will broadcast emergency SOS with GPS coordinates soon';

  @override
  String get standbyNoticeTitle => 'Tactical Monitor';

  @override
  String get standbyNoticeDesc =>
      'If timer expires without response, emergency SOS will be sent via Mesh';

  @override
  String get endHikeBtn => 'End Hike';

  @override
  String get hikeResumeBtn => 'Continue Hike';

  @override
  String get hikeHoldToEnd => 'HOLD TO END';

  @override
  String backtrackDistanceRemaining(String dist) {
    return 'Remaining: $dist';
  }

  @override
  String get backtrackFollowArrow => 'Follow the arrow and trail back';

  @override
  String get backtrackBasecamp => 'Starting Point (Basecamp ⛳)';

  @override
  String get backtrackNavActive => 'Navigating back to start';

  @override
  String get hikeRecording => 'HIKE RECORDING';

  @override
  String get hikeRecordingTrail => 'Recording trail offline';

  @override
  String get hikeMinimizedBox => 'Minimize (Keep recording in background)';

  @override
  String get hikeExitDialogTitle => 'Exit Hike Tracking?';

  @override
  String get hikeExitDialogDesc =>
      'Hike activity is currently recording. What would you like to do?';

  @override
  String hikeTrailDistance(String dist, int points) {
    return '$dist km • $points pts';
  }

  @override
  String get shareSmsTitle => 'Send via SMS';

  @override
  String get shareSmsSubtitle => 'Send emergency rescue message now';

  @override
  String get copyLinkTitle => 'Copy Location Link';

  @override
  String get copyLinkSubtitle => 'Share coordinates as Google Maps Link';

  @override
  String get meshOfflineNetworkTitle => 'Offline Mesh Network';

  @override
  String get meshScanningSubtitle => 'Scanning for peers nearby...';

  @override
  String get meshOfflineDisabled => 'Offline mesh communication disabled';

  @override
  String get openChatRoom => 'Open Chat';

  @override
  String get localSosTitle => 'Emergency Local SOS';

  @override
  String get localSosSubtitle =>
      'Broadcast to peers within 100 meters (Offline)';

  @override
  String get sosTrappedRoof => 'Trapped on roof';

  @override
  String get sosNeedFoodWater => 'Need food/water';

  @override
  String get sosInjuredElderly => 'Injured/Elderly present';

  @override
  String get sosWaterRising => 'Water level rising';

  @override
  String sosSentBroadcast(String text) {
    return 'Signal sent: $text';
  }

  @override
  String get urgentSosTitle => 'Emergency SOS';

  @override
  String get fireService199 => 'Fire Dept (199)';

  @override
  String get medicalService1669 => 'Rescue (1669)';

  @override
  String get emergencySignalsTitle => 'Emergency Signals';

  @override
  String get flashlightSosOff => 'Stop SOS Flash';

  @override
  String get flashlightSosOn => 'Flashlight SOS';

  @override
  String get strobeOff => 'Turn Off Strobe';

  @override
  String get strobeOn => 'Strobe Beacon';

  @override
  String get sirenOff => 'Turn Off Siren';

  @override
  String get sirenOn => 'Siren';

  @override
  String get safetyCheckShortcutTitle => 'Auto Check-In (Safety Check)';

  @override
  String get safetyCheckShortcutSubtitle =>
      'Send SOS automatically if you lose contact';

  @override
  String get hikeActiveTitle => 'Hike Tracking Active';

  @override
  String get hikeStartTitle => 'Start Hike Mode';

  @override
  String get hikeActiveSubtitle => 'Trail recording active.. tap to stop';

  @override
  String get hikeStartSubtitle => 'Record trail track and mark starting point';

  @override
  String get hikeEndSnackbar => 'Hike tracking finished';

  @override
  String get hikePrepTitle => 'Preparing Hike Session';

  @override
  String get hikePrepDesc => 'Preparing hike area (10 sq km) & offline map';

  @override
  String get hikeStartAdventure => 'Start Adventure (Hike Mode)';

  @override
  String get unableToGetLocation => 'Unable to determine coordinates';

  @override
  String get openAppSettings => 'Open App Settings';

  @override
  String get headingDirectionLabel => 'Heading Direction';

  @override
  String get directionNE => 'Northeast (NE)';

  @override
  String get directionSE => 'Southeast (SE)';

  @override
  String get directionSW => 'Southwest (SW)';

  @override
  String get directionNW => 'Northwest (NW)';

  @override
  String get altitudeMsl => 'Altitude (MSL)';

  @override
  String get facilitiesNearbySubtitle => 'Nearby medical coordinates';

  @override
  String facilityUnitCount(int count) {
    return '$count places';
  }

  @override
  String get searchMedicalHint => 'Search hospital, clinic, pharmacy...';

  @override
  String get openNowFilter => 'Open Now';

  @override
  String get sortByNearest => 'Nearest';

  @override
  String get sortByName => 'Name A-Z';

  @override
  String get chipAll => 'All';

  @override
  String get chipHospital => '🏥 Hospital';

  @override
  String get chipClinic => '🩺 Clinic';

  @override
  String get chipPharmacy => '💊 Pharmacy';

  @override
  String get open24Hours => 'Open 24h';

  @override
  String get myFingerprintTitle => '📱 Your Device Fingerprint';

  @override
  String myFingerprintDesc(String peer) {
    return 'Have $peer verify this code on their device';
  }

  @override
  String peerFingerprintTitle(String peer) {
    return '🔑 Fingerprint of $peer';
  }

  @override
  String peerFingerprintDesc(String peer) {
    return 'Compare this security code with $peer\'s screen';
  }

  @override
  String get fingerprintCopied => 'Fingerprint copied to clipboard';

  @override
  String get noFingerprintData => 'No fingerprint data to copy';

  @override
  String get verifiedSuccess => 'Identity Verified';

  @override
  String get resetTrust => 'Reset Trust';

  @override
  String get resetTrustSuccess => 'Trust status reset successfully';

  @override
  String get scanQrForKeys => 'Scan QR Code for Keys';

  @override
  String get waitingForPublicKey =>
      'Waiting for public key from peer via mesh...';

  @override
  String get acceptNewKey => 'Accept New Key';

  @override
  String get markAsVerified => 'Mark as Verified';
}
