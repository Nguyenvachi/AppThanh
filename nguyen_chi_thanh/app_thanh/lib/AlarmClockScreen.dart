import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app_colors.dart';

class AlarmClockScreen extends StatefulWidget {
  const AlarmClockScreen({super.key});

  @override
  _AlarmClockScreenState createState() => _AlarmClockScreenState();
}

class _AlarmClockScreenState extends State<AlarmClockScreen> {
  TimeOfDay? _selectedTime;
  DateTime? _alarmTime;
  Timer? _timer;
  String _currentTime = '';
  bool _isAlarmSet = false;
  bool _isAlarmRinging = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _alarmMessage;
  final TextEditingController _messageController = TextEditingController();

  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  String _voiceText = '';
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _updateCurrentTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCurrentTime();
      _checkAlarm();
    });
    _initSpeech();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (error) => debugPrint('Speech error: $error'),
      onStatus: (status) => debugPrint('Speech status: $status'),
    );
    setState(() {});
  }

  void _startListening() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cần cấp quyền microphone')));
      return;
    }

    if (!_speechEnabled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Không khả dụng')));
      return;
    }

    await _speechToText.listen(
      onResult: (result) {
        setState(() => _voiceText = result.recognizedWords.toLowerCase());
        if (result.finalResult) _processVoiceCommand(_voiceText);
      },
      localeId: 'vi_VN',
    );

    setState(() => _isListening = true);
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  void _processVoiceCommand(String command) {
    if (command.contains('hủy') || command.contains('tắt báo thức')) {
      if (_isAlarmSet) _cancelAlarm();
      return;
    }

    bool isSet =
        command.contains('đặt') ||
        command.contains('hẹn') ||
        command.contains('báo thức');

    final r1 = RegExp(r'(\d+)\s*giờ\s*(\d*)');
    final r2 = RegExp(r'(\d+):(\d+)');

    int? h, m;
    var m1 = r1.firstMatch(command);
    var m2 = r2.firstMatch(command);

    if (m1 != null) {
      h = int.parse(m1.group(1)!);
      m = m1.group(2)!.isNotEmpty ? int.parse(m1.group(2)!) : 0;
    } else if (m2 != null) {
      h = int.parse(m2.group(1)!);
      m = int.parse(m2.group(2)!);
    }

    if (h != null && m != null) {
      setState(() => _selectedTime = TimeOfDay(hour: h!, minute: m!));
      if (isSet) _setAlarm();
    }
  }

  void _updateCurrentTime() {
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
    });
  }

  void _checkAlarm() {
    if (_isAlarmSet && _alarmTime != null && !_isAlarmRinging) {
      final now = DateTime.now();
      if (now.hour == _alarmTime!.hour && now.minute == _alarmTime!.minute) {
        _triggerAlarm();
      }
    }
  }

  Future<void> _triggerAlarm() async {
    setState(() => _isAlarmRinging = true);

    try {
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (_) {
      await _audioPlayer.play(
        UrlSource('https://www.soundjay.com/misc/sounds/bell-ringing-05.mp3'),
      );
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    }

    if (mounted) _showAlarmDialog();
  }

  void _showAlarmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('BÁO THỨC'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_alarmMessage ?? 'Đến giờ!'),
            const SizedBox(height: 8),
            Text(
              DateFormat('HH:mm').format(DateTime.now()),
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: _stopAlarm, child: const Text('Tắt báo thức')),
        ],
      ),
    );
  }

  void _stopAlarm() {
    _audioPlayer.stop();
    setState(() {
      _isAlarmRinging = false;
      _isAlarmSet = false;
      _alarmTime = null;
      _selectedTime = null;
      _alarmMessage = null;
    });
    Navigator.of(context).pop();
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _setAlarm() {
    if (_selectedTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Chưa chọn giờ")));
      return;
    }

    final now = DateTime.now();
    DateTime alarm = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (alarm.isBefore(now)) {
      alarm = alarm.add(const Duration(days: 1));
    }

    setState(() {
      _alarmTime = alarm;
      _isAlarmSet = true;
      _alarmMessage = _messageController.text.isEmpty
          ? null
          : _messageController.text;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Đã đặt báo thức")));
  }

  void _cancelAlarm() {
    setState(() {
      _isAlarmSet = false;
      _alarmTime = null;
      _selectedTime = null;
      _alarmMessage = null;
      _messageController.clear();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Đã hủy báo thức")));
  }

  // ---------------------------
  // UI TỐI GIẢN (Minimalist)
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Đồng Hồ Báo Thức"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCurrentTime(),
            const SizedBox(height: 20),
            _buildVoiceBox(),
            const SizedBox(height: 20),
            _buildAlarmSetter(),
            const SizedBox(height: 20),
            _buildGuide(),
          ],
        ),
      ),
    );
  }

  // Hiển thị giờ hiện tại tối giản
  Widget _buildCurrentTime() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Icon(Icons.access_time, size: 40),
          const SizedBox(height: 10),
          Text(
            _currentTime,
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          if (_isAlarmSet && _alarmTime != null) ...[
            const SizedBox(height: 8),
            Text(
              "Báo thức: ${DateFormat('HH:mm').format(_alarmTime!)}",
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ],
      ),
    );
  }

  // Voice control – phiên bản tối giản
  Widget _buildVoiceBox() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_isListening ? Icons.mic : Icons.mic_none),
              const SizedBox(width: 8),
              Text(
                _isListening ? "Đang nghe..." : "Điều khiển bằng giọng nói",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (_voiceText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '"$_voiceText"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _isListening ? _stopListening : _startListening,
            icon: Icon(_isListening ? Icons.stop : Icons.mic),
            label: Text(_isListening ? "Dừng" : "Nhấn để nói"),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
            ),
          ),
        ],
      ),
    );
  }

  // Card đặt báo thức tối giản
  Widget _buildAlarmSetter() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.alarm),
              SizedBox(width: 8),
              Text(
                "Đặt báo thức",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              _selectedTime == null ? "--:--" : _selectedTime!.format(context),
              style: TextStyle(
                fontSize: 42,
                color: _selectedTime == null ? Colors.grey : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tin nhắn
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: "Tin nhắn (tùy chọn)",
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),

          const SizedBox(height: 16),

          // Chọn giờ
          OutlinedButton.icon(
            onPressed: _isAlarmSet ? null : _selectTime,
            icon: const Icon(Icons.schedule),
            label: const Text("Chọn giờ"),
          ),
          const SizedBox(height: 10),

          // Đặt hoặc hủy báo thức
          _isAlarmSet
              ? OutlinedButton.icon(
                  onPressed: _cancelAlarm,
                  icon: const Icon(Icons.alarm_off),
                  label: const Text("Hủy báo thức"),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                )
              : ElevatedButton.icon(
                  onPressed: _setAlarm,
                  icon: const Icon(Icons.alarm_on),
                  label: const Text("Đặt báo thức"),
                ),
        ],
      ),
    );
  }

  // Hướng dẫn tối giản
  Widget _buildGuide() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline),
              SizedBox(width: 8),
              Text(
                "Hướng dẫn",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            "1. Nhấn 'Chọn giờ' để đặt thời gian\n"
            "2. Nhập tin nhắn tùy chọn\n"
            "3. Nhấn 'Đặt báo thức' để kích hoạt\n"
            "4. Báo thức sẽ kêu khi đến giờ\n"
            "5. Nhấn 'Tắt báo thức' trong hộp thoại để dừng",
            style: TextStyle(height: 1.4),
          ),
        ],
      ),
    );
  }
}
