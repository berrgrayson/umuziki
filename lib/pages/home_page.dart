import 'package:authentification/components/my_drawer.dart';
import 'package:authentification/components/mini_player.dart';
import 'package:authentification/models/playlist_provider.dart';
import 'package:authentification/pages/song_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = FirebaseAuth.instance.currentUser!;
  late final PlaylistProvider playlistProvider;
  bool isLoading = true;

  // sign user out method
  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  void initState() {
    super.initState();
    playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
    _initializeMusic();
  }

  Future<void> _initializeMusic() async {
    setState(() => isLoading = true);
    await playlistProvider.initializePlaylist();
    setState(() => isLoading = false);
  }

  void goToSong(int songIndex) {
    playlistProvider.currentSongIndex = songIndex;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SongPage(),
      ),
    );
  }

  Widget _buildAlbumArt(Song song) {
    if (song.albumArtImagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          File(song.albumArtImagePath!),
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholderArt(),
        ),
      );
    }
    return _buildPlaceholderArt();
  }

  Widget _buildPlaceholderArt() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(
        Icons.music_note,
        color: Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("P L A Y L I S T"),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeMusic,
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: Column(
        children: [
          Expanded(
            child: Consumer<PlaylistProvider>(
              builder: (context, value, child) {
                if (isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final List<Song> playlist = value.playlist;

                if (playlist.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.music_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No music files found',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _initializeMusic,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Scan for Music'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: playlist.length,
                  itemBuilder: (context, index) {
                    final Song song = playlist[index];

                    return ListTile(
                      title: Text(
                        song.songName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        song.artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      leading: _buildAlbumArt(song),
                      onTap: () => goToSong(index),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'play',
                            child: Row(
                              children: [
                                Icon(Icons.play_arrow),
                                SizedBox(width: 8),
                                Text('Play'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'details',
                            child: Row(
                              children: [
                                Icon(Icons.info),
                                SizedBox(width: 8),
                                Text('Details'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'play') {
                            goToSong(index);
                          } else if (value == 'details') {
                            _showSongDetails(context, song);
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Consumer<PlaylistProvider>(
            builder: (context, value, child) {
              final currentSong = value.currentSong;
              if (currentSong != null) {
                return MiniPlayer(
                  song: currentSong,
                  isPlaying: value.isPlaying,
                  onPlayPausePressed: value.pauseOrResume,
                  onNextPressed: value.playNextSong,
                  onPreviousPressed: value.playPreviousSong,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SongPage(),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  void _showSongDetails(BuildContext context, Song song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Song Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${song.songName}'),
            const SizedBox(height: 8),
            Text('Artist: ${song.artistName}'),
            const SizedBox(height: 8),
            Text(
              'Path: ${song.audioPath}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
