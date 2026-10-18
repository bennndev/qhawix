/// One phone number chosen from the system contacts UI.
class PickedPhoneContact {
  const PickedPhoneContact({required this.name, required this.phone});

  final String name;
  final String phone;
}

/// Opens the OS contact picker. The app must not hold READ_CONTACTS.
abstract interface class ContactPickerPort {
  /// Null when the person cancels.
  Future<PickedPhoneContact?> pickPhoneContact();
}
