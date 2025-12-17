import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart'
    as mlkit_translation;

class ImageTranslateOverlayScreen extends StatefulWidget {
  final String imagePath;
  final TranslateLanguage sourceLanguage;
  final TranslateLanguage targetLanguage;

  const ImageTranslateOverlayScreen({
    super.key,
    required this.imagePath,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  @override
  State<ImageTranslateOverlayScreen> createState() =>
      _ImageTranslateOverlayScreenState();
}

class TextBlockTranslation {
  final Rect boundingBox;
  final String originalText;
  final String translatedText;

  TextBlockTranslation({
    required this.boundingBox,
    required this.originalText,
    required this.translatedText,
  });
}

class _ImageTranslateOverlayScreenState
    extends State<ImageTranslateOverlayScreen> {
  bool _isProcessing = true;
  OnDeviceTranslator? _translator;
  List<TextBlockTranslation> _textBlocks = [];
  Size _imageSize = Size.zero;
  bool _isDownloadingModels = false;

  final mlkit_translation.OnDeviceTranslatorModelManager _modelManager =
      mlkit_translation.OnDeviceTranslatorModelManager();

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    setState(() => _isProcessing = true);

    try {
      if (!await _ensureModels()) {
        setState(() => _isProcessing = false);
        return;
      }

      // Lấy kích thước thực tế của ảnh
      final imageFile = File(widget.imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      _imageSize = Size(
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      );
      print('Kích thước ảnh thực tế: $_imageSize');

      final inputImage = InputImage.fromFilePath(widget.imagePath);

      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      if (recognizedText.blocks.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không phát hiện được văn bản trong ảnh'),
              backgroundColor: Colors.black87,
            ),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      _translator = OnDeviceTranslator(
        sourceLanguage: widget.sourceLanguage,
        targetLanguage: widget.targetLanguage,
      );

      final translatedBlocks = <TextBlockTranslation>[];

      print('Số block text phát hiện: ${recognizedText.blocks.length}');

      for (final block in recognizedText.blocks) {
        try {
          print('Đang dịch: ${block.text}');
          final translated = await _translator!.translateText(block.text);
          print('Đã dịch: $translated');

          translatedBlocks.add(
            TextBlockTranslation(
              boundingBox: block.boundingBox,
              originalText: block.text,
              translatedText: translated,
            ),
          );
        } catch (e) {
          print('Lỗi dịch block: $e');
          // Thêm block gốc nếu dịch lỗi
          translatedBlocks.add(
            TextBlockTranslation(
              boundingBox: block.boundingBox,
              originalText: block.text,
              translatedText: block.text,
            ),
          );
        }
      }

      print('Tổng số block đã dịch: ${translatedBlocks.length}');

      if (mounted) {
        setState(() {
          _textBlocks = translatedBlocks;
          _isProcessing = false;
        });
        print('Đã setState với ${_textBlocks.length} blocks');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.black87),
        );
      }
    }
  }

  Future<bool> _ensureModels() async {
    try {
      setState(() => _isDownloadingModels = true);

      final src = widget.sourceLanguage.bcpCode;
      final tgt = widget.targetLanguage.bcpCode;

      if (!await _modelManager.isModelDownloaded(src)) {
        await _modelManager.downloadModel(src);
      }
      if (!await _modelManager.isModelDownloaded(tgt)) {
        await _modelManager.downloadModel(tgt);
      }

      return true;
    } catch (_) {
      return false;
    } finally {
      if (mounted) setState(() => _isDownloadingModels = false);
    }
  }

  @override
  void dispose() {
    _translator?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // ----------------------------
      // TỐI GIẢN APPBAR
      // ----------------------------
      appBar: AppBar(
        title: const Text(
          "Dịch từ ảnh",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      body: _isProcessing ? _buildLoading() : _buildImageWithOverlays(),
    );
  }

  // ----------------------------
  // LOADING TỐI GIẢN
  // ----------------------------
  Widget _buildLoading() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 32),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 18),
            Text(
              _isDownloadingModels
                  ? 'Đang tải mô hình dịch...'
                  : 'Đang xử lý ảnh...',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------
  // HIỂN THỊ ẢNH + OVERLAY
  // ----------------------------
  Widget _buildImageWithOverlays() {
    return Stack(
      children: [
        Center(child: Image.file(File(widget.imagePath), fit: BoxFit.contain)),
        if (_textBlocks.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                size: Size(constraints.maxWidth, constraints.maxHeight),
                painter: TranslationOverlayPainter(
                  textBlocks: _textBlocks,
                  imageSize: _imageSize,
                  containerSize: Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

// -------------------------------------------------------
// PAINTER — GIỮ LOGIC, TỐI GIẢN MÀU
// -------------------------------------------------------
class TranslationOverlayPainter extends CustomPainter {
  final List<TextBlockTranslation> textBlocks;
  final Size imageSize;
  final Size containerSize;

  TranslationOverlayPainter({
    required this.textBlocks,
    required this.imageSize,
    required this.containerSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.width <= 0 || imageSize.height <= 0) {
      print('Image size invalid: $imageSize');
      return;
    }

    print('Painting ${textBlocks.length} blocks');
    print('Image size: $imageSize');
    print('Container size: $containerSize');

    final double scaleX = containerSize.width / imageSize.width;
    final double scaleY = containerSize.height / imageSize.height;
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    final double scaledWidth = imageSize.width * scale;
    final double scaledHeight = imageSize.height * scale;

    final double offsetX = (containerSize.width - scaledWidth) / 2;
    final double offsetY = (containerSize.height - scaledHeight) / 2;

    for (var block in textBlocks) {
      final rect = Rect.fromLTWH(
        offsetX + block.boundingBox.left * scale,
        offsetY + block.boundingBox.top * scale,
        block.boundingBox.width * scale,
        block.boundingBox.height * scale,
      );

      // Nền bán trong suốt
      final bg = Paint()
        ..color = Colors.black.withOpacity(0.65)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, bg);

      // Border tối giản
      final border = Paint()
        ..color = Colors.white.withOpacity(0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawRect(rect, border);

      // Vẽ chữ
      final tp = TextPainter(
        text: TextSpan(
          text: block.translatedText,
          style: TextStyle(
            color: Colors.white,
            fontSize: _fontSize(rect.height),
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 10,
      );

      tp.layout(maxWidth: rect.width - 8);

      tp.paint(
        canvas,
        Offset(rect.left + 4, rect.top + (rect.height - tp.height) / 2),
      );
    }
  }

  double _fontSize(double h) {
    if (h < 28) return 10;
    if (h < 50) return 12;
    if (h < 80) return 14;
    if (h < 120) return 16;
    return 18;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
