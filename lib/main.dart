import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

void main() {
  runApp(const CarrozzeriaDspApp());
}

class CarrozzeriaDspApp extends StatelessWidget {
  const CarrozzeriaDspApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carrozzeria DEQ-P999',
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
  String _selectedSection = 'All Songs';
  final OnAudioQuery _audioQuery = OnAudioQuery();
  List<SongModel> _playlist = [];
  List<AlbumModel> _albums = [];
  List<ArtistModel> _artists = [];
  List<GenreModel> _genres = [];
  List<PlaylistModel> _playlists = [];
  
  int _currentTrackIndex = -1;
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoadingLibrary = true;

  String _activeDspPreset = 'DSP: STADIUM';
  String _activeEqMode = 'EQ: HARDWARE';

  static const platform = MethodChannel('com.maudsp.player/audio_fx');
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
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

    _requestStorageAndScan();
  }

  @override
  void dispose() {
    _animController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _requestStorageAndScan() async {
    PermissionStatus status = await Permission.audio.request();
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    try {
      List<SongModel> songs = await _audioQuery.querySongs(
        uriType: UriType.EXTERNAL,
        orderType: OrderType.DEFAULT,
        sortType: SongSortType.TITLE,
        ignoreCase: true,
      );

      List<AlbumModel> albums = await _audioQuery.queryAlbums();
      List<ArtistModel> artists = await _audioQuery.queryArtists();
      List<GenreModel> genres = await _audioQuery.queryGenres();
      List<PlaylistModel> playlists = await _audioQuery.queryPlaylists();

      setState(() {
        _playlist = songs;
        _albums = albums;
        _artists = artists;
        _genres = genres;
        _playlists = playlists;
        _isLoadingLibrary = false;
      });
    } catch (_) {
      setState(() => _isLoadingLibrary = false);
    }
  }

  Future<void> _playTrack(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    try {
      _currentTrackIndex = index;
      final song = _playlist[index];
      
      await _audioPlayer.setFilePath(song.data);
      
      final int? sessionId = await _audioPlayer.androidAudioSessionId;
      if (sessionId != null) {
        await platform.invokeMethod('initEffects', {'sessionId': sessionId});
      }

      await _audioPlayer.play();
      setState(() {});
    } catch (_) {}
  }

  Future<void> _openDeviceEqualizer() async {
    try {
      final int? sessionId = await _audioPlayer.androidAudioSessionId;
      await platform.invokeMethod('openAudioEffects', {'sessionId': sessionId ?? 0});
    } catch (_) {}
  }

  void _togglePlay() async {
    if (_playlist.isEmpty) return;
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

  void _showDspDialog() {
    final dspOptions = ['DSP: HALL', 'DSP: STADIUM', 'DSP: LARGE ROOM'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF050B14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
        ),
        title: const Text('DEQ-P999 ACOUSTIC DSP', style: TextStyle(color: Color(0xFF00E5FF), fontFamily: 'monospace', fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: dspOptions.map((preset) => ListTile(
            title: Text(preset, style: const TextStyle(color: Colors.white, fontFamily: 'monospace')),
            trailing: _activeDspPreset == preset ? const Icon(Icons.check, color: Color(0xFF00E5FF)) : null,
            onTap: () {
              setState(() => _activeDspPreset = preset);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xFF00E5FF)),
        title: Text(
          _selectedSection.toUpperCase(),
          style: const TextStyle(color: Color(0xFF00E5FF), fontFamily: 'monospace', fontWeight: FontWeight.bold, letterSpacing: 2.0),
        ),
        centerTitle: true,
      ),
      drawer: _buildNavigationDrawer(),
      body: _getSelectedBodyView(),
    );
  }

  // Side Drawer mirroring your reference menu layout
  Widget _buildNavigationDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0C1017),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF03070E)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('CARROZZERIA', style: TextStyle(color: Color(0xFF00E5FF), fontFamily: 'monospace', fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
                SizedBox(height: 4),
                Text('DEQ-P999 Hi-Fi Audio', style: TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 12)),
              ],
            ),
          ),
          _drawerItem(Icons.play_arrow_rounded, 'Current'),
          _drawerItem(Icons.music_note_rounded, 'All Songs'),
          _drawerItem(Icons.album_rounded, 'Albums'),
          _drawerItem(Icons.mic_rounded, 'Artists'),
          _drawerItem(Icons.queue_music_rounded, 'Genres'),
          _drawerItem(Icons.playlist_play_rounded, 'Playlists'),
          _drawerItem(Icons.folder_rounded, 'Folders'),
          const Divider(color: Colors.grey, height: 20),
          _drawerItem(Icons.settings_rounded, 'Settings'),
          _drawerItem(Icons.equalizer_rounded, 'Equalizer'),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title) {
    bool isSelected = _selectedSection == title;
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF00E5FF) : Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF00E5FF) : Colors.white,
          fontFamily: 'monospace',
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // close drawer
        if (title == 'Equalizer') {
          _openDeviceEqualizer();
        } else {
          setState(() => _selectedSection = title);
        }
      },
    );
  }

  Widget _getSelectedBodyView() {
    if (_isLoadingLibrary) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
    }

    switch (_selectedSection) {
      case 'Current':
        return _buildPlayerTab();
      case 'Albums':
        return ListView.builder(
          itemCount: _albums.length,
          itemBuilder: (context, index) => ListTile(
            leading: const Icon(Icons.album, color: Color(0xFF00E5FF)),
            title: Text(_albums[index].album, style: const TextStyle(color: Colors.white, fontFamily: 'monospace')),
            subtitle: Text('${_albums[index].numOfSongs ?? 0} songs', style: const TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 11)),
          ),
        );
      case 'Artists':
        return ListView.builder(
          itemCount: _artists.length,
          itemBuilder: (context, index) => ListTile(
            leading: const Icon(Icons.mic, color: Color(0xFF00E5FF)),
            title: Text(_artists[index].artist, style: const TextStyle(color: Colors.white, fontFamily: 'monospace')),
            subtitle: Text('${_artists[index].numberOfTracks ?? 0} tracks', style: const TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 11)),
          ),
        );
      case 'Genres':
        return ListView.builder(
          itemCount: _genres.length,
          itemBuilder: (context, index) => ListTile(
            leading: const Icon(Icons.queue_music, color: Color(0xFF00E5FF)),
            title: Text(_genres[index].genre, style: const TextStyle(color: Colors.white, fontFamily: 'monospace')),
          ),
        );
      case 'Playlists':
        return ListView.builder(
          itemCount: _playlists.length,
          itemBuilder: (context, index) => ListTile(
            leading: const Icon(Icons.playlist_play, color: Color(0xFF00E5FF)),
            title: Text(_playlists[index].playlist, style: const TextStyle(color: Colors.white, fontFamily: 'monospace')),
          ),
        );
      case 'Folders':
        return const Center(
          child: Text('FOLDERS VIEW (AUTO-SYNCED)', style: TextStyle(color: Color(0xFF00E5FF), fontFamily: 'monospace')),
        );
      case 'Settings':
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('CARROZZERIA SYSTEM SETTINGS', style: TextStyle(color: Color(0xFF00E5FF), fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF050B14), foregroundColor: const Color(0xFF00E5FF)),
                  onPressed: _requestStorageAndScan,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Rescan Device Storage', style: TextStyle(fontFamily: 'monospace')),
                ),
              ],
            ),
          ),
        );
      case 'All Songs':
      default:
        return _buildAllSongsView();
    }
  }

  Widget _buildAllSongsView() {
    if (_playlist.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_off_rounded, size: 64, color: Color(0xFF00E5FF)),
            const SizedBox(height: 16),
            const Text('NO MUSIC FOUND', style: TextStyle(color: Color(0xFF00E5FF), fontFamily: 'monospace', fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF050B14), foregroundColor: const Color(0xFF00E5FF)),
              onPressed: _requestStorageAndScan,
              child: const Text('RESCAN', style: TextStyle(fontFamily: 'monospace')),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _playlist.length,
      itemBuilder: (context, index) {
        final song = _playlist[index];
        final isSelected = index == _currentTrackIndex;

        return ListTile(
          leading: Icon(isSelected ? Icons.graphic_eq_rounded : Icons.music_note_rounded, color: const Color(0xFF00E5FF)),
          title: Text(
            song.title,
            style: TextStyle(color: isSelected ? const Color(0xFF00E5FF) : Colors.white, fontFamily: 'monospace', fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(song.artist ?? '<unknown artist>', style: const TextStyle(color: Colors.grey, fontFamily: 'monospace', fontSize: 11)),
          onTap: () {
            _playTrack(index);
            setState(() => _selectedSection = 'Current');
          },
        );
      },
    );
  }

  Widget _buildPlayerTab() {
    final currentTrack = (_currentTrackIndex >= 0 && _currentTrackIndex < _playlist.length) ? _playlist[_currentTrackIndex] : null;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF03070E),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.6), width: 2),
              boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.3), blurRadius: 12, spreadRadius: 1)],
            ),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: ScanlinePainter())),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_activeEqMode, style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontFamily: 'monospace')),
                          const Text('FLAC/MP3 Hi-Fi', style: TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontFamily: 'monospace')),
                        ],
                      ),
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(24, (index) {
                              double heightFactor = _isPlaying
                                  ? (math.sin((_animController.value * math.pi * 4) + (index * 0.5)).abs() * 85 +
                                      math.cos((_animController.value * math.pi * 3) - (index * 0.3)).abs() * 45 + 15)
                                  : 10.0;
                              return Container(
                                width: 5,
                                height: heightFactor.clamp(8.0, 120.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E5FF),
                                  borderRadius: BorderRadius.circular(1),
                                  boxShadow: [BoxShadow(color: const Color(0xFF00E5FF), blurRadius: 4)],
                                ),
                              );
                            }),
                          );
                        },
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_activeDspPreset, style: const TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'monospace')),
                          const SizedBox(height: 2),
                          Text(
                            '>> ${currentTrack?.title ?? 'SELECT TRACK'}',
                            style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF050B14),
                    foregroundColor: const Color(0xFF00E5FF),
                    side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
                  ),
                  onPressed: _openDeviceEqualizer,
                  icon: const Icon(Icons.equalizer, size: 18),
                  label: const Text('EQ SETTINGS', style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF050B14),
                    foregroundColor: const Color(0xFF00E5FF),
                    side: const BorderSide(color: Color(0xFF00E5FF), width: 1.5),
                  ),
                  onPressed: _showDspDialog,
                  icon: const Icon(Icons.surround_sound, size: 18),
                  label: const Text('DSP REVERB', style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(icon: const Icon(Icons.fast_rewind_rounded, size: 36), color: const Color(0xFF00E5FF), onPressed: _prevTrack),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00E5FF), width: 2),
                  boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.3), blurRadius: 10)],
                ),
                child: IconButton(
                  icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 44),
                  color: const Color(0xFF00E5FF),
                  onPressed: _togglePlay,
                ),
              ),
              IconButton(icon: const Icon(Icons.fast_forward_rounded, size: 36), color: const Color(0xFF00E5FF), onPressed: _nextTrack),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class ScanlinePainter extends CustomPainter {
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.height; i += 4) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
}
