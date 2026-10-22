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
    } catch (_)
