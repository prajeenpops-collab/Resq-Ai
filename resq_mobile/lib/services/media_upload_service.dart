import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class MediaUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFile(File file, String folder) async {
    final ext = file.path.split('.').last;
    final fileName = '${const Uuid().v4()}.$ext';
    final ref = _storage.ref().child('$folder/$fileName');
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }
}
