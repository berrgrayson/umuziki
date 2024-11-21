import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';

class Song {
  final String songName;
  final String artistName;
  final String? albumArtImagePath;
  final String audioPath;
  final File audioFile;
  int? playlistId;

  Song({
    required this.songName,
    required this.artistName,
    this.albumArtImagePath,
    required this.audioPath,
    required this.audioFile,
    this.playlistId,
  });
}

class Playlist {
  final int id;
  String name;
  final List<Song> songs;

  Playlist({
    required this.id,
    required this.name,
    required this.songs,
  });
}

class PlaylistProvider extends ChangeNotifier {
  final List<Song> _playlist = [];
  final List<Playlist> _playlists = [];
  int? _currentSongIndex;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _currentDuration = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  Database? _database;

  PlaylistProvider() {
    listenToDuration();
    initializePlaylist();
    _initializeDatabase();
    _loadPlaylists();
  }

  Future<void> _initializeDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    _database = await openDatabase(
      '${directory.path}/playlists.db',
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          '''
          CREATE TABLE playlists (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT
          )
        ''',
        );
      },
    );
  }

  Future<void> _loadPlaylists() async {
    if (_database == null) return;

    final playlistsData = await _database!.query('playlists');
    _playlists.clear();

    for (final row in playlistsData) {
      final playlistId = row['id'] as int;
      final playlistName = row['name'] as String;
      final playlistSongs = await _getSongsForPlaylist(playlistId);
      _playlists.add(
          Playlist(id: playlistId, name: playlistName, songs: playlistSongs));
    }

    notifyListeners();
  }

  Future<List<Song>> _getSongsForPlaylist(int playlistId) async {
    final songsList = <Song>[];
    for (final song in _playlist) {
      if (song.playlistId == playlistId) {
        songsList.add(song);
      }
    }
    return songsList;
  }

  Future<void> createPlaylist(String name) async {
    if (_database == null) return;

    final playlistId = await _database!.insert('playlists', {'name': name});
    _playlists.add(Playlist(id: playlistId, name: name, songs: []));
    notifyListeners();
  }

  void deletePlaylist(Playlist playlist) async {
    if (_database == null) return;

    await _database!
        .delete('playlists', where: 'id = ?', whereArgs: [playlist.id]);
    _playlists.remove(playlist);
    notifyListeners();
  }

  void updatePlaylistName(Playlist playlist, String newName) async {
    if (_database == null) return;

    await _database!.update('playlists', {'name': newName},
        where: 'id = ?', whereArgs: [playlist.id]);
    playlist.name = newName;
    notifyListeners();
  }

  void addSongToPlaylist(Playlist playlist, Song song) {
    song.playlistId = playlist.id;
    playlist.songs.add(song);
    notifyListeners();
  }

  void removeSongFromPlaylist(Playlist playlist, Song song) {
    song.playlistId = null;
    playlist.songs.remove(song);
    notifyListeners();
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
  Song? get currentSong => _currentSongIndex != null && _playlist.isNotEmpty
      ? _playlist[_currentSongIndex!]
      : null;
  List<Playlist> get playlists => _playlists;

  set currentSongIndex(int? newIndex) {
    _currentSongIndex = newIndex;
    if (newIndex != null) {
      play();
    }
    notifyListeners();
  }
}
