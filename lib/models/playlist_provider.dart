import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class Song {
  final String songName;
  final String artistName;
  final String? albumArtImagePath;
  final String audioPath;
  final File audioFile;

  Song({
    required this.songName,
    required this.artistName,
    this.albumArtImagePath,
    required this.audioPath,
    required this.audioFile,
  });
}

class PlaylistProvider extends ChangeNotifier {
  final List<Song> _playlist = [];
  int? _currentSongIndex;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _currentDuration = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;

  PlaylistProvider() {
    listenToDuration();
    initializePlaylist();
  }

  Future<void> initializePlaylist() async {
    if (await Permission.storage.request().isGranted) {
      await scanDeviceMusic();
    }
  }

  Future<void> scanDeviceMusic() async {
    try {
      List<Directory> musicDirs = [];

      if (Platform.isAndroid) {
        // Get the external storage directory
        List<Directory>? extDirs = await getExternalStorageDirectories();
        if (extDirs != null) {
          for (var dir in extDirs) {
            // Navigate up to the root of external storage
            String path = dir.path;
            final List<String> paths = path.split("/");
            int androidIndex = paths.indexOf("Android");
            if (androidIndex != -1) {
              path = paths.sublist(0, androidIndex).join("/");
              // Add common music directories
              final musicDir = Directory('$path/Music');
              if (await musicDir.exists()) musicDirs.add(musicDir);
            }
          }
        }
      } else if (Platform.isIOS) {
        // For iOS, we'll use the documents directory as a base
        final Directory docDir = await getApplicationDocumentsDirectory();
        musicDirs.add(docDir);
      }

      // Clear existing playlist
      _playlist.clear();

      // Scan directories for music files
      for (Directory dir in musicDirs) {
        await for (FileSystemEntity entity in dir.list(recursive: true)) {
          if (entity is File) {
            String extension = entity.path.toLowerCase().split('.').last;
            if (['mp3', 'm4a', 'aac', 'wav'].contains(extension)) {
              try {
                String fileName = entity.path.split('/').last;
                String songName = fileName.split('.').first;

                // Create song without metadata
                _playlist.add(Song(
                  songName: songName,
                  artistName: 'Unknown Artist',
                  albumArtImagePath: null,
                  audioPath: entity.path,
                  audioFile: entity,
                ));
              } catch (e) {
                print('Error processing file ${entity.path}: $e');
              }
            }
          }
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error scanning music: $e');
    }
  }

  // Rest of your methods remain the same
  void play() async {
    if (currentSongIndex == null || _playlist.isEmpty) return;

    final String filePath = _playlist[currentSongIndex!].audioPath;
    await _audioPlayer.stop();
    await _audioPlayer.play(DeviceFileSource(filePath));
    _isPlaying = true;
    notifyListeners();
  }

  void pause() async {
    await _audioPlayer.pause();
    _isPlaying = false;
    notifyListeners();
  }

  void resume() async {
    await _audioPlayer.resume();
    _isPlaying = true;
    notifyListeners();
  }

  void pauseOrResume() async {
    if (_isPlaying) {
      pause();
    } else {
      resume();
    }
    notifyListeners();
  }

  void seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void playNextSong() {
    if (_currentSongIndex != null) {
      if (_currentSongIndex! < _playlist.length - 1) {
        currentSongIndex = _currentSongIndex! + 1;
      } else {
        currentSongIndex = 0;
      }
    }
  }

  void playPreviousSong() {
    if (_currentDuration.inSeconds > 2) {
      seek(Duration.zero);
    } else {
      if (currentSongIndex! > 0) {
        currentSongIndex = _currentSongIndex! - 1;
      } else {
        currentSongIndex = _playlist.length - 1;
      }
    }
  }

  void listenToDuration() {
    _audioPlayer.onDurationChanged.listen((newDuration) {
      _totalDuration = newDuration;
      notifyListeners();
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      _currentDuration = newPosition;
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      playNextSong();
    });
  }

  List<Song> get playlist => _playlist;
  int? get currentSongIndex => _currentSongIndex;
  bool get isPlaying => _isPlaying;
  Duration get currentDuration => _currentDuration;
  Duration get totalDuration => _totalDuration;

  set currentSongIndex(int? newIndex) {
    _currentSongIndex = newIndex;
    if (newIndex != null) {
      play();
    }
    notifyListeners();
  }
}
