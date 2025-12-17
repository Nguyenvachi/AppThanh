import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app_colors.dart';

class StopwatchScreen extends StatefulWidget {
  const StopwatchScreen({super.key});

  @override
  _StopwatchScreenState createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  final List<String> _laps = [];

  // Voice control
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  String _voiceText = '';
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speechToText.stop();
    super.dispose();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) return;

    if (!_speechEnabled) return;

    await _speechToText.listen(
      localeId: 'vi_VN',
      onResult: (result) {
        setState(() => _voiceText = result.recognizedWords.toLowerCase());
        if (result.finalResult) _processVoiceCommand(_voiceText);
      },
    );

    setState(() => _isListening = true);
  }

  void _stopListeningVoice() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  void _processVoiceCommand(String command) {
    if (command.contains("bắt đầu") || command.contains("start")) {
      if (!_stopwatch.isRunning) _startStopwatch();
      return;
    }

    if (command.contains("dừng") || command.contains("tạm dừng")) {
      if (_stopwatch.isRunning) _stopStopwatch();
      return;
    }

    if (command.contains("vòng") || command.contains("lap")) {
      if (_stopwatch.isRunning) _recordLap();
      return;
    }

    if (command.contains("reset") || command.contains("đặt lại")) {
      _resetStopwatch();
      return;
    }
  }

  void _startStopwatch() {
    setState(() {
      _stopwatch.start();
      _timer = Timer.periodic(
        const Duration(milliseconds: 30),
        (_) => setState(() {}),
      );
    });
  }

  void _stopStopwatch() {
    setState(() {
      _stopwatch.stop();
      _timer?.cancel();
    });
  }

  void _resetStopwatch() {
    setState(() {
      _stopwatch.reset();
      _timer?.cancel();
      _laps.clear();
    });
  }

  void _recordLap() {
    if (_stopwatch.isRunning) {
      setState(() {
        _laps.insert(
          0,
          "Vòng ${_laps.length + 1}: ${_formatTime(_stopwatch.elapsed)}",
        );
      });
    }
  }

  String _formatTime(Duration duration) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(duration.inMinutes.remainder(60))}:${two(duration.inSeconds.remainder(60))}.${(duration.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final displayTime = _formatTime(_stopwatch.elapsed);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Bấm Giờ",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // -------------------------
            // VÒNG TRÒN THỜI GIAN TỐI GIẢN
            // -------------------------
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 3),
              ),
              child: Center(
                child: Text(
                  displayTime,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // -------------------------
            // NÚT VOICE CONTROL TỐI GIẢN
            // -------------------------
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isListening
                            ? "Đang nghe..."
                            : "Điều khiển bằng giọng nói",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  if (_voiceText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '"$_voiceText"',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],

                  const SizedBox(height: 12),
                  SizedBox(
                    width: 180,
                    child: OutlinedButton.icon(
                      onPressed: _isListening
                          ? _stopListeningVoice
                          : _startListening,
                      icon: Icon(_isListening ? Icons.stop : Icons.mic),
                      label: Text(_isListening ? "Dừng nghe" : "Nhấn để nói"),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'Nói: "Bắt đầu", "Dừng", "Vòng", "Đặt lại"',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // -------------------------
            // NÚT ĐIỀU KHIỂN CHÍNH
            // -------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCircleButton(
                  icon: _stopwatch.isRunning ? Icons.pause : Icons.play_arrow,
                  color: Colors.black,
                  onPressed: _stopwatch.isRunning
                      ? _stopStopwatch
                      : _startStopwatch,
                ),
                _buildCircleButton(
                  icon: Icons.flag,
                  color: Colors.black87,
                  onPressed: _stopwatch.isRunning ? _recordLap : null,
                ),
                _buildCircleButton(
                  icon: Icons.refresh,
                  color: Colors.black87,
                  onPressed: _resetStopwatch,
                ),
              ],
            ),

            const SizedBox(height: 30),

            // -------------------------
            // DANH SÁCH VÒNG
            // -------------------------
            if (_laps.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Các vòng",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _laps.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: Colors.grey.shade300),
                      itemBuilder: (context, index) {
                        return Row(
                          children: [
                            Text(
                              "${_laps.length - index}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _laps[index],
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              )
            else
              Text(
                "Chưa ghi vòng nào",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // NÚT TRÒN TỐI GIẢN
  // -------------------------
  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: 75,
      height: 75,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black87, width: 2),
      ),
      child: IconButton(
        icon: Icon(icon, size: 32, color: Colors.black87),
        onPressed: onPressed,
      ),
    );
  }
}
