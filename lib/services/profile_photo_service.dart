import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePhotoService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery or camera
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      return File(pickedFile.path);
    } catch (e) {
      print('[ProfilePhotoService] Error picking image: $e');
      rethrow;
    }
  }

  /// Upload profile photo to Supabase storage
  Future<String> uploadProfilePhoto(String userId, File imageFile) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$userId\_$timestamp.jpg';
      final filePath = 'profile-photos/$fileName';

      // Upload to Supabase storage
      await _supabase.storage
          .from('profiles')
          .upload(filePath, imageFile);

      // Get public URL
      final publicUrl = _supabase.storage
          .from('profiles')
          .getPublicUrl(filePath);

      print('[ProfilePhotoService] Upload success: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('[ProfilePhotoService] Upload error: $e');
      rethrow;
    }
  }

  /// Delete old profile photo from storage
  Future<void> deleteProfilePhoto(String photoUrl) async {
    try {
      // Extract file path from URL
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;

      // Find the index of 'profiles' bucket
      final profilesIndex = pathSegments.indexOf('profiles');
      if (profilesIndex == -1) return;

      // Get file path after bucket name
      final filePath = pathSegments.sublist(profilesIndex + 1).join('/');

      await _supabase.storage
          .from('profiles')
          .remove([filePath]);

      print('[ProfilePhotoService] Deleted old photo: $filePath');
    } catch (e) {
      print('[ProfilePhotoService] Delete error: $e');
      // Don't rethrow - deletion errors shouldn't block upload
    }
  }

  /// Update user profile with photo URL
  Future<void> updateUserPhotoUrl(String userId, String photoUrl) async {
    try {
      await _supabase
          .from('user_profiles')
          .update({'photo_url': photoUrl})
          .eq('id', userId);

      print('[ProfilePhotoService] Updated user profile with photo URL');
    } catch (e) {
      print('[ProfilePhotoService] Update error: $e');
      rethrow;
    }
  }

  /// Full workflow: pick, upload, and save photo URL
  Future<String?> pickAndUploadPhoto(String userId, {String? oldPhotoUrl}) async {
    try {
      // Pick image
      final imageFile = await pickImage();
      if (imageFile == null) return null;

      // Delete old photo if exists
      if (oldPhotoUrl != null && oldPhotoUrl.isNotEmpty) {
        await deleteProfilePhoto(oldPhotoUrl);
      }

      // Upload new photo
      final photoUrl = await uploadProfilePhoto(userId, imageFile);

      // Update database
      await updateUserPhotoUrl(userId, photoUrl);

      return photoUrl;
    } catch (e) {
      print('[ProfilePhotoService] Full workflow error: $e');
      rethrow;
    }
  }
}
