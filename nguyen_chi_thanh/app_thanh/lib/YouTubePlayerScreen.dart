import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_colors.dart';

class YouTubePlayerScreen extends StatefulWidget {
  const YouTubePlayerScreen({super.key});

  @override
  State<YouTubePlayerScreen> createState() => _YouTubePlayerScreenState();
}

class _YouTubePlayerScreenState extends State<YouTubePlayerScreen> {
  final TextEditingController _urlController = TextEditingController();
  YoutubePlayerController? _controller;

  String? _error;
  String? _currentVideoId;
  bool _isReady = false;

  @override
  void dispose() {
    _controller?.dispose();
    _urlController.dispose();
    super.dispose();
  }

  // Load video từ URL
  void _loadVideo() {
    final url = _urlController.text.trim();
    setState(() => _error = null);

    if (url.isEmpty) {
      _error = "Vui lòng nhập link YouTube";
      return;
    }

    final videoId = YoutubePlayer.convertUrlToId(url);

    if (videoId == null) {
      _error = "Link YouTube không hợp lệ";
      return;
    }

    _currentVideoId = videoId;

    _controller?.dispose();
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        controlsVisibleAtStart: true,
      ),
    );

    setState(() => _isReady = true);
  }

  // Xóa video
  void _clearVideo() {
    _controller?.dispose();
    setState(() {
      _controller = null;
      _currentVideoId = null;
      _isReady = false;
      _urlController.clear();
      _error = null;
    });
  }

  // Mở video bằng app YouTube
  Future<void> _openInYouTube() async {
    if (_currentVideoId == null) return;

    final url = Uri.parse("https://www.youtube.com/watch?v=$_currentVideoId");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Không thể mở YouTube"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "YouTube Player",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          if (_isReady)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: _openInYouTube,
            ),
        ],
      ),

      // BODY
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // INPUT BOX
            TextField(
              controller: _urlController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: "Link YouTube",
                prefixIcon: const Icon(Icons.link),
                hintText: "https://youtube.com/watch?v=...",
                errorText: _error,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _urlController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _urlController.clear();
                            _error = null;
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() => _error = null),
            ),

            const SizedBox(height: 16),

            // BUTTONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _loadVideo,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      "Phát video",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (_isReady) ...[
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                    ),
                    onPressed: _clearVideo,
                    child: const Icon(Icons.stop),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // VIDEO PLAYER AREA
            if (_isReady && _controller != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: YoutubePlayer(
                  controller: _controller!,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: Colors.red,
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Nhập link rồi nhấn "Phát video"',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // HƯỚNG DẪN
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "Hướng dẫn:\n"
                "1. Sao chép link từ YouTube\n"
                "2. Dán vào ô nhập\n"
                "3. Nhấn 'Phát video'\n"
                "\nHỗ trợ các định dạng:\n"
                "• youtube.com/watch?v=ID\n"
                "• youtu.be/ID\n"
                "• youtube.com/embed/ID",
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
