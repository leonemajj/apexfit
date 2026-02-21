import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUploadService {
  final SupabaseClient _client;
  final ImagePicker _picker = ImagePicker();

  ImageUploadService(this._client);

  Future<String?> pickAndUploadAvatar(String userId) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (image == null) return null;

    final file = File(image.path);
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _client.storage.from('avatars').upload(
      path,
      file,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
    );

    final url = _client.storage.from('avatars').getPublicUrl(path);
    await _client.from('users').update({'avatar_url': url, 'updated_at': DateTime.now().toIso8601String()}).eq('id', userId);
    return url;
  }
}
