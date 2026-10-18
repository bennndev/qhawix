import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';

import '../domain/contact_picker_port.dart';

/// System contact picker. Declares no READ_CONTACTS permission.
class NativeContactPicker implements ContactPickerPort {
  NativeContactPicker({FlutterNativeContactPicker? picker})
      : _picker = picker ?? FlutterNativeContactPicker();

  final FlutterNativeContactPicker _picker;

  @override
  Future<PickedPhoneContact?> pickPhoneContact() async {
    final picked = await _picker.selectPhoneNumber();
    if (picked == null) return null;
    final phone = picked.selectedPhoneNumber?.trim() ?? '';
    final name = picked.fullName?.trim() ?? '';
    if (phone.isEmpty) return null;
    return PickedPhoneContact(
      name: name.isEmpty ? phone : name,
      phone: phone,
    );
  }
}
