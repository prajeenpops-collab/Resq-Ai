import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import '../../core/theme.dart';
import '../../services/location_service.dart';
import '../../services/api_service.dart';
import '../../services/media_upload_service.dart';
import '../../services/protocol_service.dart';
import '../protocols/protocol_execution_screen.dart';

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
  final _protocolService = ProtocolService();
  final _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  String? _recordedPath;
  File? _pickedImage;
  bool _submitting = false;
  String _detectedLat = 'Reading...';
  String _detectedLng = 'Reading...';

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final pos = await _locationService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() {
        _detectedLat = pos.latitude.toStringAsFixed(4);
        _detectedLng = pos.longitude.toStringAsFixed(4);
      });
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordedPath = path;
      });
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
        const SnackBar(
          content: Text('Please add text, voice, or an image before submitting.'),
          backgroundColor: AppTheme.warningAmber,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final position = await _locationService.getCurrentLocation();
      final lat = position?.latitude ?? 37.7749;
      final lng = position?.longitude ?? -122.4194;

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
        lat: lat,
        lng: lng,
      );

      // Auto-trigger automated protocol execution
      final execution = await _protocolService.triggerProtocolExecution(reportId: report.reportId);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ProtocolExecutionScreen(
            reportId: report.reportId,
            initialExecution: execution,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
            backgroundColor: AppTheme.criticalRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DETAILED EMERGENCY REPORT')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // GPS Location Badge Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cyberCyan.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location_rounded, color: AppTheme.cyberCyan, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GPS Telemetry Locked', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                        Text('Lat: $_detectedLat • Lng: $_detectedLng', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle_rounded, color: AppTheme.safeGreen, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Text Input Card
            TextField(
              controller: _textController,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Describe the emergency (e.g. Severe car crash on 5th main street with injury...)',
              ),
            ),
            const SizedBox(height: 16),

            // Media attachment controls
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _toggleRecording,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: _isRecording ? AppTheme.emergencyRed : const Color(0xFF475569),
                        width: _isRecording ? 2 : 1,
                      ),
                    ),
                    icon: Icon(
                      _isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded,
                      color: _isRecording ? AppTheme.emergencyRed : AppTheme.neonAlert,
                    ),
                    label: Text(_isRecording ? 'STOP RECORDING' : 'VOICE REPORT'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt_rounded, color: AppTheme.cyberCyan),
                    label: const Text('ADD PHOTO'),
                  ),
                ),
              ],
            ),

            if (_isRecording) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.emergencyRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.emergencyRed),
                    ),
                    SizedBox(width: 10),
                    Text('Recording voice stream... Gemini AI will transcribe audio.', style: TextStyle(color: AppTheme.emergencyRed, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],

            if (_recordedPath != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.safeGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppTheme.safeGreen, size: 18),
                    SizedBox(width: 8),
                    Text('Voice recording attached.', style: TextStyle(color: AppTheme.safeGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ],

            if (_pickedImage != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_pickedImage!, height: 180, fit: BoxFit.cover),
              ),
            ],

            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.bolt_rounded),
                label: Text(_submitting ? 'DISPATCHING AUTOMATED PROTOCOL...' : 'SUBMIT REPORT & LAUNCH PROTOCOL'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
