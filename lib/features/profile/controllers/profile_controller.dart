import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Controller for the Profile feature.
///
/// Manages the user's profile picture selection from camera or gallery.
/// Holds the local [File] reference so the avatar can display the chosen image.
/// All existing mock user data (name, university, etc.) remains in [AuthController].
class ProfileController extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();

  File? _profileImage;

  /// The currently selected profile image file, or null if none selected.
  File? get profileImage => _profileImage;

  bool _isPickingImage = false;

  /// Whether an image pick/capture operation is in progress.
  bool get isPickingImage => _isPickingImage;

  String? _errorMessage;

  /// Error message from the last failed operation.
  String? get errorMessage => _errorMessage;

  /// Picks an image from the device gallery.
  Future<bool> pickFromGallery() async {
    return _pickImage(ImageSource.gallery);
  }

  /// Captures a new photo using the device camera.
  Future<bool> pickFromCamera() async {
    return _pickImage(ImageSource.camera);
  }

  /// Internal method that handles image picking from the given [source].
  Future<bool> _pickImage(ImageSource source) async {
    _isPickingImage = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _profileImage = File(pickedFile.path);
        _isPickingImage = false;
        notifyListeners();
        return true;
      } else {
        // User cancelled the picker
        _isPickingImage = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to pick image. Please try again.';
      _isPickingImage = false;
      notifyListeners();
      return false;
    }
  }

  /// Clears the currently selected profile image.
  void clearProfileImage() {
    _profileImage = null;
    notifyListeners();
  }
}
