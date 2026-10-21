import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const CarrozzeriaDspApp());
}

class CarrozzeriaDspApp extends StatelessWidget {
  const CarrozzeriaDspApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carrozzeria DSP Player',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const CarrozzeriaVisualizerScreen(),
    );
  }
}

class CarrozzeriaVisualizerScreen extends StatefulWidget {
  const CarrozzeriaVisualizerScreen({super.key});

  @override
  State<CarrozzeriaVisualizerScreen> createState() => _CarrozzeriaVisualizerScreenState();
}

class _CarrozzeriaVisualizerScreenState extends State<CarrozzeriaVisualizerScreen> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  String _currentTrackName = 'SELECT LOCAL TRACK...';
  String _audioInfo = 'EQ > DSP ON';

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickAndPlayMusic() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;

        await _audioPlayer.setFilePath(filePath);
        await _audioPlayer.play();

        setState(() {
          _currentTrackName = fileName;
          _audioInfo = fileName.toLowerCase().endsWith('.flac') ? 'FLAC 96kHz/24bit' : 'MP3 LOCAL AUDIO';
        });
      } else {
        setState(() {
          _currentTrackName = 'SELECTION CANCELLED';
        });
      }
    } catch (e) {
      setState(() {
        _currentTrackName = 'ERROR LOADING FILE';
      });
    }
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_audioPlayer.processingState == ProcessingState.idle) {
        await _pickAndPlayMusic();
      } else {
        await _audioPlayer.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'CARROZZERIA DSP',
          style: TextStyle(
            color: Color(0xFF00E5FF),
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF050B14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.25),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: ScanlinePainter(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'EQ > DSP ON',
                              style: TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              _audioInfo,
                              style: const TextStyle(
                                color: Color(0xFF00E5FF),
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(16, (index) {
                            final heights = [
                              40.0, 70.0, 30.0, 90.0, 110.0, 85.0, 50.0, 65.0,
                              95.0, 120.0, 75.0, 45.0, 60.0, 100.0, 80.0, 55.0
                            ];
                            return Container(
                              width: 8,
                              height: _isPlaying ? heights[(index + DateTime.now().second) % heights.length] : 15.0,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E5FF),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                        Text(
                          '>> $_currentTrackName',
                          style: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF050B14),
                foregroundColor: const Color(0xFF00E5FF),
                side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
              ),
              onPressed: _pickAndPlayMusic,
              icon: const Icon(Icons.folder_open),
              label: const Text('SELECT AUDIO FILE', style: TextStyle(fontFamily: 'monospace')),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.fast_rewind_rounded, size: 36),
                  color: const Color(0xFF00E5FF),
                  onPressed: () {},
                ),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00E5FF), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 44),
                    color: const Color(0xFF00E5FF),
                    onPressed: _togglePlay,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.fast_forward_rounded, size: 36),
                  color: const Color(0xFF00E5FF),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.height; i += 4) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
