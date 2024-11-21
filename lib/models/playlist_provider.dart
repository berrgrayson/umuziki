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
  }

  Future<void> _initializeDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    _database = await openDatabase(
      '${directory.path}/music_database.db',
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
    await _loadAllData();
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE playlists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE playlist_songs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_id INTEGER,
        song_path TEXT,
        song_name TEXT,
        artist_name TEXT,
        album_art_path TEXT,
        FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _upgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE playlist_songs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          playlist_id INTEGER,
          song_path TEXT,
          song_name TEXT,
          artist_name TEXT,
          album_art_path TEXT,
          FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  Future<void> _loadAllData() async {
    await _loadPlaylists();
    await scanDeviceMusic();
  }

  Future<void> _loadPlaylists() async {
    if (_database == null) return;

    final playlistsData = await _database!.query('playlists');
    _playlists.clear();

    for (final row in playlistsData) {
      final playlistId = row['id'] as int;
      final playlistName = row['name'] as String;
      final playlistSongs = await _loadSongsForPlaylist(playlistId);

      _playlists.add(
          Playlist(id: playlistId, name: playlistName, songs: playlistSongs));
    }

    notifyListeners();
  }

  Future<List<Song>> _loadSongsForPlaylist(int playlistId) async {
    if (_database == null) return [];

    final songsData = await _database!.query('playlist_songs',
        where: 'playlist_id = ?', whereArgs: [playlistId]);

    return songsData.map((songRow) {
      final audioFile = File(songRow['song_path'] as String);
      return Song(
        songName: songRow['song_name'] as String,
        artistName: songRow['artist_name'] as String,
        albumArtImagePath: songRow['album_art_path'] as String?,
        audioPath: songRow['song_path'] as String,
        audioFile: audioFile,
        playlistId: playlistId,
      );
    }).toList();
  }

  Future<void> createPlaylist(String name) async {
    if (_database == null) return;

    final playlistId = await _database!.insert('playlists', {'name': name});
    final newPlaylist = Playlist(id: playlistId, name: name, songs: []);
    _playlists.add(newPlaylist);
    notifyListeners();
  }

  Future<void> deletePlaylist(Playlist playlist) async {
    if (_database == null) return;

    // Delete songs in the playlist first
    await _database!.delete('playlist_songs',
        where: 'playlist_id = ?', whereArgs: [playlist.id]);

    // Then delete the playlist
    await _database!
        .delete('playlists', where: 'id = ?', whereArgs: [playlist.id]);

    _playlists.remove(playlist);
    notifyListeners();
  }

  Future<void> updatePlaylistName(Playlist playlist, String newName) async {
    if (_database == null) return;

    await _database!.update('playlists', {'name': newName},
        where: 'id = ?', whereArgs: [playlist.id]);

    playlist.name = newName;
    notifyListeners();
  }

  Future<void> addSongToPlaylist(Playlist playlist, Song song) async {
    if (_database == null) return;

    // Insert song into playlist_songs table
    await _database!.insert('playlist_songs', {
      'playlist_id': playlist.id,
      'song_path': song.audioPath,
      'song_name': song.songName,
      'artist_name': song.artistName,
      'album_art_path': song.albumArtImagePath,
    });

    song.playlistId = playlist.id;
    playlist.songs.add(song);
    notifyListeners();
  }

  Future<void> removeSongFromPlaylist(Playlist playlist, Song song) async {
    if (_database == null) return;

    // Remove song from playlist_songs table
    await _database!.delete('playlist_songs',
        where: 'playlist_id = ? AND song_path = ?',
        whereArgs: [playlist.id, song.audioPath]);

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
        // Add multiple common music directories
        final List<String> commonMusicPaths = [
          '/storage/emulated/0/Music',
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Songs',
          '/storage/emulated/0/Xender',
          '/storage/emulated/0/',
          '/storage/external_primary/'
        ];

        // Get external storage directories
        List<Directory>? extDirs = await getExternalStorageDirectories(
          type: StorageDirectory.music,
        );

        if (extDirs != null) {
          for (var dir in extDirs) {
            musicDirs.add(dir);
          }
        }

        // Add common music paths that might exist
        for (String path in commonMusicPaths) {
          final musicDir = Directory(path);
          if (await musicDir.exists()) {
            musicDirs.add(musicDir);
          }
        }
      }

      // Clear existing playlist
      _playlist.clear();

      // Scan directories for music files with improved error handling
      for (Directory dir in musicDirs) {
        try {
          await for (FileSystemEntity entity in dir.list(recursive: true)) {
            if (entity is File) {
              String extension = entity.path.toLowerCase().split('.').last;
              if (['mp3', 'm4a', 'aac', 'wav', 'flac', 'ogg']
                  .contains(extension)) {
                try {
                  String fileName = entity.path.split('/').last;
                  String songName = fileName.split('.').first;

                  // Optional: Add file size check to filter out very small files
                  int fileSize = await entity.length();
                  if (fileSize > 1024 * 100) {
                    // Minimum 100KB
                    _playlist.add(Song(
                      songName: songName,
                      artistName: 'Unknown Artist',
                      albumArtImagePath: null,
                      audioPath: entity.path,
                      audioFile: entity,
                    ));
                  }
                } catch (e) {
                  print('Error processing individual file ${entity.path}: $e');
                }
              }
            }
          }
        } catch (dirScanError) {
          print('Error scanning directory ${dir.path}: $dirScanError');
        }
      }

      // Optional: Add logging for debugging
      print('Total songs found: ${_playlist.length}');

      notifyListeners();
    } catch (e) {
      print('Critical error scanning music: $e');
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
