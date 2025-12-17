import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:permission_handler/permission_handler.dart';

class RealtimeTranslateScreen extends StatefulWidget {
  const RealtimeTranslateScreen({super.key});

  @override
  State<RealtimeTranslateScreen> createState() =>
      _RealtimeTranslateScreenState();
}

class _RealtimeTranslateScreenState extends State<RealtimeTranslateScreen> {
  CameraController? _cameraController;
  bool _isDetecting = false;
  bool _isCameraInitialized = false;
  String _recognizedText = '';
  String _translatedText = '';
  bool _isTranslating = false;
  Timer? _translationTimer;

  TranslateLanguage _sourceLanguage = TranslateLanguage.english;
  TranslateLanguage _targetLanguage = TranslateLanguage.vietnamese;
  OnDeviceTranslator? _translator;

  List<CameraDescription> _cameras = [];
  CameraLensDirection _currentLens = CameraLensDirection.back;
  Timer? _frameTimer;

  final Map<TranslateLanguage, String> _languageNames = {
    TranslateLanguage.vietnamese: 'Tiếng Việt',
    TranslateLanguage.english: 'English',
    TranslateLanguage.chinese: '中文',
    TranslateLanguage.japanese: '日本語',
    TranslateLanguage.korean: '한국어',
    TranslateLanguage.french: 'Français',
    TranslateLanguage.german: 'Deutsch',
    TranslateLanguage.spanish: 'Español',
  };

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initTranslator();
  }

  Future<void> _initCamera({CameraLensDirection? lens}) async {
    try {
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
        if (!status.isGranted) return;
      }

      _frameTimer?.cancel();
      await _cameraController?.dispose();

      if (_cameras.isEmpty) _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      final desired = lens ?? _currentLens;
      final cam = _findCamera(desired) ?? _cameras.first;
      _currentLens = cam.lensDirection;

      _cameraController = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isCameraInitialized = true);
        _startImageStream();
      }
    } catch (_) {}
  }

  CameraDescription? _findCamera(CameraLensDirection dir) {
    for (final c in _cameras) {
      if (c.lensDirection == dir) return c;
    }
    return null;
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    final newDir = _currentLens == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    setState(() => _isCameraInitialized = false);
    await _initCamera(lens: newDir);
  }

  void _initTranslator() {
    _translator = OnDeviceTranslator(
      sourceLanguage: _sourceLanguage,
      targetLanguage: _targetLanguage,
    );
  }

  void _startImageStream() {
    _frameTimer?.cancel();
    _frameTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!_isDetecting && _isCameraInitialized) {
        await _captureAndDetectText();
      }
    });
  }

  Future<void> _captureAndDetectText() async {
    if (!_isCameraInitialized || _isDetecting) return;

    try {
      _isDetecting = true;
      final XFile imageFile = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(imageFile.path);

      final textRecognizer = GoogleMlKit.vision.textRecognizer();
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      if (recognizedText.text.isNotEmpty &&
          recognizedText.text != _recognizedText) {
        setState(() => _recognizedText = recognizedText.text);
        _translationTimer?.cancel();
        _translationTimer = Timer(
          const Duration(milliseconds: 800),
          () => _translateText(_recognizedText),
        );
      }
    } catch (_) {
    } finally {
      _isDetecting = false;
    }
  }

  Future<void> _translateText(String text) async {
    if (text.isEmpty || _isTranslating) return;

    setState(() => _isTranslating = true);

    try {
      final result = await _translator!.translateText(text);
      if (mounted) {
        setState(() {
          _translatedText = result;
          _isTranslating = false;
        });
      }
    } catch (_) {
      setState(() => _isTranslating = false);
    }
  }

  Future<void> _changeLanguages(
    TranslateLanguage? source,
    TranslateLanguage? target,
  ) async {
    if (source != null) _sourceLanguage = source;
    if (target != null) _targetLanguage = target;

    await _translator?.close();
    _translator = OnDeviceTranslator(
      sourceLanguage: _sourceLanguage,
      targetLanguage: _targetLanguage,
    );

    setState(() => _translatedText = '');
    if (_recognizedText.isNotEmpty) _translateText(_recognizedText);
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _translationTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // -----------------------------
      // APPBAR TỐI GIẢN
      // -----------------------------
      appBar: AppBar(
        title: const Text(
          'Dịch realtime',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _switchCamera,
            icon: const Icon(Icons.cameraswitch),
          ),
        ],
      ),

      body: !_isCameraInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // -----------------------------
                // DÒNG CHỌN NGÔN NGỮ TỐI GIẢN
                // -----------------------------
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildLanguageDropdown(
                          value: _sourceLanguage,
                          onChanged: (v) => _changeLanguages(v, null),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward),
                      ),
                      Expanded(
                        child: _buildLanguageDropdown(
                          value: _targetLanguage,
                          onChanged: (v) => _changeLanguages(null, v),
                        ),
                      ),
                    ],
                  ),
                ),

                // -----------------------------
                // CAMERA + OVERLAY TỐI GIẢN
                // -----------------------------
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: CameraPreview(_cameraController!)),

                      // Khung hướng dẫn
                      if (_recognizedText.isEmpty)
                        Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.85,
                            height: 140,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Đưa văn bản vào khung',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // OVERLAY DỊCH TỐI GIẢN
                      if (_recognizedText.isNotEmpty)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.45,
                            ),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Text gốc
                                  Text(
                                    _recognizedText,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Text dịch
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.translate,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Bản dịch",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (_isTranslating)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 10),
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  Text(
                                    _translatedText.isEmpty
                                        ? "Đang dịch..."
                                        : _translatedText,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      height: 1.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLanguageDropdown({
    required TranslateLanguage value,
    required ValueChanged<TranslateLanguage?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TranslateLanguage>(
          value: value,
          isExpanded: true,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          items: _languageNames.entries.map((e) {
            return DropdownMenuItem(value: e.key, child: Text(e.value));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
