import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import '../../services/location_service.dart';
import '../../services/api_service.dart';
import '../../services/media_upload_service.dart';
import 'report_result_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _textController = TextEditingController();
  final _locationService = LocationService();
  final _apiService = ApiService();
  final _mediaUploadService = MediaUploadService();
  final _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  String? _recordedPath;
  File? _pickedImage;
  bool _submitting = false;

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() { _isRecording = false; _recordedPath = path; });
    } else {
      if (await _audioRecorder.hasPermission()) {
        final dir = Directory.systemTemp;
        final path = '${dir.path}/resq_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() => _isRecording = true);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (file != null) {
      setState(() => _pickedImage = File(file.path));
    }
  }

  Future<void> _submit() async {
    if (_textController.text.trim().isEmpty && _recordedPath == null && _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add text, voice, or an image before submitting.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        throw Exception('Location permission required.');
      }

      String type = 'text';
      String? mediaUrl;

      if (_pickedImage != null) {
        type = 'image';
        mediaUrl = await _mediaUploadService.uploadFile(_pickedImage!, 'reports/images');
      } else if (_recordedPath != null) {
        type = 'voice';
        mediaUrl = await _mediaUploadService.uploadFile(File(_recordedPath!), 'reports/voice');
      }

      final report = await _apiService.submitReport(
        type: type,
        rawText: _textController.text.trim().isEmpty ? null : _textController.text.trim(),
        mediaUrl: mediaUrl,
        lat: position.latitude,
        lng: position.longitude,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ReportResultScreen(report: report)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Emergency')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Describe the emergency',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _toggleRecording,
                    icon: Icon(_isRecording ? Icons.stop_circle : Icons.mic),
                    label: Text(_isRecording ? 'Stop' : 'Record Voice'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Add Photo'),
                  ),
                ),
              ],
            ),
            if (_recordedPath != null) ...[
              const SizedBox(height: 8),
              const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 18),
                  SizedBox(width: 6), Text('Voice recorded')]),
            ],
            if (_pickedImage != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_pickedImage!, height: 160, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }
}
