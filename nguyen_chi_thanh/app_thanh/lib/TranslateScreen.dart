import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

import 'RealtimeTranslateScreen.dart';
import 'ImageTranslateOverlayScreen.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final TextEditingController _textController = TextEditingController();
  late stt.SpeechToText _speech;

  String _translatedText = '';
  bool _isListening = false;
  bool _isTranslating = false;
  bool _isRecognizing = false;
  bool _isDownloading = false;

  OnDeviceTranslator? _translator;
  final ImagePicker _picker = ImagePicker();
  final OnDeviceTranslatorModelManager _modelMgr =
      OnDeviceTranslatorModelManager();

  TranslateLanguage _source = TranslateLanguage.vietnamese;
  TranslateLanguage _target = TranslateLanguage.english;

  final Map<TranslateLanguage, String> _langs = {
    TranslateLanguage.vietnamese: "Tiếng Việt",
    TranslateLanguage.english: "English",
    TranslateLanguage.chinese: "中文",
    TranslateLanguage.japanese: "日本語",
    TranslateLanguage.korean: "한국어",
    TranslateLanguage.french: "Français",
    TranslateLanguage.german: "Deutsch",
    TranslateLanguage.spanish: "Español",
    TranslateLanguage.thai: "ไทย",
  };

  final Map<TranslateLanguage, String> _locales = {
    TranslateLanguage.vietnamese: 'vi_VN',
    TranslateLanguage.english: 'en_US',
    TranslateLanguage.chinese: 'zh_CN',
    TranslateLanguage.japanese: 'ja_JP',
    TranslateLanguage.korean: 'ko_KR',
    TranslateLanguage.french: 'fr_FR',
    TranslateLanguage.german: 'de_DE',
    TranslateLanguage.spanish: 'es_ES',
    TranslateLanguage.thai: 'th_TH',
  };

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
    _initTranslator();
  }

  Future<void> _initSpeech() async {
    await _speech.initialize(
      onError: (e) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.errorMsg))),
      onStatus: (s) => setState(() => _isListening = (s == "listening")),
    );
  }

  void _initTranslator() {
    _translator = OnDeviceTranslator(
      sourceLanguage: _source,
      targetLanguage: _target,
    );
  }

  Future<void> _startVoice() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cần quyền microphone")));
      return;
    }

    if (!_isListening) {
      await _speech.listen(
        localeId: _locales[_source],
        onResult: (res) {
          setState(() => _textController.text = res.recognizedWords);
        },
      );
    } else {
      await _speech.stop();
    }

    setState(() {});
  }

  Future<void> _translateText() async {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Nhập văn bản cần dịch")));
      return;
    }

    setState(() {
      _isTranslating = true;
      _translatedText = '';
    });

    final ok = await _ensureModels();
    if (!ok) {
      setState(() => _isTranslating = false);
      return;
    }

    await _translator?.close();
    _initTranslator();

    try {
      final result = await _translator!.translateText(_textController.text);
      if (mounted) {
        setState(() {
          _translatedText = result;
          _isTranslating = false;
        });
      }
    } catch (e) {
      setState(() => _isTranslating = false);
    }
  }

  Future<bool> _ensureModels() async {
    try {
      setState(() => _isDownloading = true);

      final src = _source.bcpCode;
      final tgt = _target.bcpCode;

      if (!await _modelMgr.isModelDownloaded(src)) {
        await _modelMgr.downloadModel(src);
      }
      if (!await _modelMgr.isModelDownloaded(tgt)) {
        await _modelMgr.downloadModel(tgt);
      }

      return true;
    } catch (_) {
      return false;
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  void _swap() {
    setState(() {
      final temp = _source;
      _source = _target;
      _target = temp;

      final t = _textController.text;
      _textController.text = _translatedText;
      _translatedText = t;
    });
  }

  Future<void> _pickImage(ImageSource src) async {
    setState(() => _isRecognizing = true);
    final file = await _picker.pickImage(source: src);
    setState(() => _isRecognizing = false);

    if (file != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImageTranslateOverlayScreen(
            imagePath: file.path,
            sourceLanguage: _source,
            targetLanguage: _target,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _translator?.close();
    _speech.stop();
    _textController.dispose();
    super.dispose();
  }

  // ============================================
  // UI TỐI GIẢN
  // ============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          "Dịch Văn Bản",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RealtimeTranslateScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildLangDropdown(
                    _source,
                    (v) => setState(() => _source = v!),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz, size: 30),
                  onPressed: _swap,
                ),
                Expanded(
                  child: _buildLangDropdown(
                    _target,
                    (v) => setState(() => _target = v!),
                  ),
                ),
              ],
            ),

            if (_isDownloading) ...[
              const SizedBox(height: 10),
              const Text("Đang tải model dịch…"),
              const SizedBox(height: 10),
            ],

            const SizedBox(height: 20),

            _buildCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Văn bản gốc",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _textController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Nhập văn bản…",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.black),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      _iconBtn(
                        Icons.mic,
                        active: _isListening,
                        onTap: _startVoice,
                      ),
                      const SizedBox(width: 10),
                      _iconBtn(
                        Icons.camera_alt_outlined,
                        onTap: () {
                          _showImageSource();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _isTranslating ? null : _translateText,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black, width: 2),
                ),
                child: _isTranslating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Dịch", style: TextStyle(fontSize: 18)),
              ),
            ),

            const SizedBox(height: 24),

            if (_translatedText.isNotEmpty)
              _buildCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Kết quả",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    SelectableText(
                      _translatedText,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ----------------- UI helpers -----------------

  Widget _buildLangDropdown(
    TranslateLanguage val,
    Function(TranslateLanguage?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TranslateLanguage>(
          value: val,
          items: _langs.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: onChanged,
          isExpanded: true,
        ),
      ),
    );
  }

  Widget _buildCard(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _iconBtn(IconData icon, {bool active = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1.3),
          borderRadius: BorderRadius.circular(10),
          color: active ? Colors.red.shade100 : Colors.white,
        ),
        child: Icon(icon, size: 22),
      ),
    );
  }

  void _showImageSource() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Chụp ảnh"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Chọn từ thư viện"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
