import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:math' as math;

void main() {
  runApp(const CarrozzeriaDspApp());
}

class TrackItem {
  final String name;
  final String path;
  final String quality;

  TrackItem({required this.name, required this.path, required this.quality});
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
      home: const MainPlayerScreen(),
    );
  }
}

class MainPlayerScreen extends StatefulWidget {
  const MainPlayerScreen({super.key});

  @override
  State<MainPlayerScreen> createState() => _MainPlayerScreenState();
}

class _MainPlayerScreenState extends State<MainPlayerScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final List<TrackItem> _playlist = [];
  int _currentTrackIndex = -1;
  
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  
  String _activeDspPreset = 'DSP: STADIUM';
  String _activeEqMode = 'EQ > ROCK';

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat();

    _audioPlayer.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
        if (_isPlaying) {
          _animController.repeat();
        } else {
          _animController.stop();
        }
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _importSongs() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          for (var file in result.files) {
            if (file.path != null) {
              final name = file.name;
              final quality = name.toLowerCase().endsWith('.flac') ? 'FLAC 96kHz/24bit' : 'MP3 320kbps';
              if (!_playlist.any((t) => t.path == file.path)) {
                _playlist.add(TrackItem(name: name, path: file.path!, quality: quality));
              }
            }
          }
          if (_currentTrackIndex == -1 && _playlist.isNotEmpty) {
            _playTrack(0);
          }
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _playTrack(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    try {
      _currentTrackIndex = index;
      final track = _playlist[index];
      await _audioPlayer.setFilePath(track.path);
      await _audioPlayer.play();
      setState(() {});
    } catch (e) {
      // Handle error
    }
  }

  void _togglePlay() async {
    if (_playlist.isEmpty) {
      await _importSongs();
      return;
    }
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_currentTrackIndex == -1) {
        await _playTrack(0);
      } else {
        await _audioPlayer.play();
      }
    }
  }

  void _nextTrack() {
    if (_playlist.isEmpty) return;
    int next = (_currentTrackIndex + 1) % _playlist.length;
    _playTrack(next);
  }

  void _prevTrack() {
    if (_playlist.isEmpty) return;
    int prev = (_currentTrackIndex - 1 + _playlist.length) % _playlist.length;
    _playTrack(prev);
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF050B14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
        ),
        title: const Text(
          'DSP & EQUALIZER SETTINGS',
          style: TextStyle(color: Color(0xFF00E5FF), fontFamily: 'monospace', fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Reverb Preset', style: TextStyle(color: Colors.white, fontFamily: 'monospace')),
              subtitle: Text(_activeDspPreset, style: const TextStyle(color: Color(0xFF00E5FF), fontFamily: 'monospace')),
              trailing: const Icon(Icons.tune, color: Color(0xFF00E5FF)),
              onTap: () {
                setState(() {
                  if (_activeDspPreset == 'DSP: STADIUM') {
                    _activeDspPreset = 'DSP: HALL';
                  } else if (_activeDspPreset == 'DSP: HALL') {
                    _activeDspPreset = 'DSP: LARGE ROOM';
                  } else {
                    _activeDspPreset = 'DSP: STADIUM';
                  }
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Equalizer Mode', style: TextStyle(color: Colors.white, fontFamily: 'monospace')),
              subtitle: Text(_activeEqMode, style: const TextStyle(color: Color(0xFF00E5FF), fontFamily: 'monospace')),
              trailing: const Icon(Icons.equalizer, color: Color(0xFF00E5FF)),
              onTap: () {
                setState(() {
                  if (_activeEqMode == 'EQ > ROCK') {
                    _activeEqMode = 'EQ > BASS BOOST';
                  } else if (_activeEqMode == 'EQ > BASS BOOST') {
                    _activeEqMode = 'EQ > VOCAL CLEAR';
                  } else {
                    _activeEqMode = 'EQ > ROCK';
                  }
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildPlayerTab(),
      _buildPlaylistTab(),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          _currentIndex == 0 ? 'CARROZZERIA DSP' : 'LIBRARY & PLAYLIST',
          style: const TextStyle(
            color: Color(0xFF00E5FF),
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_suggest_rounded, color: Color(0xFF00E5FF)),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFF00E5FF),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_fill_rounded),
            label: 'Player',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music_rounded),
            label: 'Library',
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTab() {
    final currentTrack = (_currentTrackIndex >= 0 && _currentTrackIndex < _playlist.length)
        ? _playlist[_currentTrackIndex]
        : null;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            height: 220,
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
                          Text(
                            _activeEqMode,
                            style: const TextStyle(
                              color: Color(0xFF00E5FF),
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            currentTrack?.quality ?? 'FLAC 96kHz/24bit',
                            style: const TextStyle(
                              color: Color(0xFF00E5FF),
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(16, (index) {
                              double wave = _isPlaying
                                  ? math.sin((_animController.value * 2 * math.pi) + (index * 0.5)) * 45 + 65
                                  : 15.0;
                              return Container(
                                width: 8,
                                height: wave.abs(),
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
                          );
                        },
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _activeDspPreset,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '>> ${currentTrack?.name ?? 'NO TRACK LOADED'}',
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
            onPressed: _importSongs,
            icon: const Icon(Icons.library_add_rounded),
            label: const Text('IMPORT MUSIC FILES', style: TextStyle(fontFamily: 'monospace')),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.fast_rewind_rounded, size: 36),
                color: const Color(0xFF00E5FF),
                onPressed: _prevTrack,
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
                onPressed: _nextTrack,
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPlaylistTab() {
    if (_playlist.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_off_rounded, size: 64, color: Color(0xFF00E5FF)),
            const SizedBox(height: 16),
            const Text(
              'NO SONGS IN LIBRARY',
              style: TextStyle(color: Color(0xFF00E5FF), fontFamily: 'monospace', fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF050B14),
                foregroundColor: const Color(0xFF00E5FF),
                side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
              ),
              onPressed: _importSongs,
              icon: const Icon(Icons.add_rounded),
              label: const Text('ADD MUSIC', style: TextStyle(fontFamily: 'monospace')),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _playlist.length,
      itemBuilder: (context, index) {
        final track = _playlist[index];
        final isSelected = index == _currentTrackIndex;

        return ListTile(
          leading: Icon(
            isSelected ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
            color: const Color(0xFF00E5FF),
          ),
          title: Text(
            track.name,
            style: TextStyle(
              color: isSelected ? const Color(0xFF00E5FF) : Colors.white,
              fontFamily: 'monospace',
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            track.quality,
            style: const TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 11),
          ),
          trailing: isSelected && _isPlaying
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Color(0xFF00E5FF), strokeWidth: 2),
                )
              : null,
          onTap: () => _playTrack(index),
        );
      },
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
