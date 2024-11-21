import 'package:authentification/components/my_drawer.dart';
import 'package:authentification/components/mini_player.dart';
import 'package:authentification/models/playlist_provider.dart';
import 'package:authentification/pages/song_page.dart';
import 'package:authentification/pages/playlist_page.dart';
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
  TextEditingController searchController = TextEditingController();
  List<Song> filteredPlaylist = [];

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
    setState(() {
      isLoading = false;
      filteredPlaylist = playlistProvider.playlist;
    });
  }

  void _filterSongs(String query) {
    setState(() {
      filteredPlaylist = playlistProvider.playlist
          .where((song) =>
              song.songName.toLowerCase().contains(query.toLowerCase()) ||
              song.artistName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
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

  void goToPlaylist() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlaylistPage(),
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

  // New method to show search bottom sheet
  void _showSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search songs...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          _filterSongs('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: _filterSongs,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        ),
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
          // Search button added here
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchBottomSheet,
          ),
          // Existing Playlist and Refresh buttons
          IconButton(
            icon: const Icon(Icons.playlist_add),
            onPressed: goToPlaylist,
          ),
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

                if (filteredPlaylist.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No songs found',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            searchController.clear();
                            _filterSongs('');
                          },
                          child: const Text('Reset Search'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredPlaylist.length,
                  itemBuilder: (context, index) {
                    final Song song = filteredPlaylist[index];

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
                      onTap: () =>
                          goToSong(playlistProvider.playlist.indexOf(song)),
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
                          const PopupMenuItem(
                            value: 'add_to_playlist',
                            child: Row(
                              children: [
                                Icon(Icons.playlist_add),
                                SizedBox(width: 8),
                                Text('Add to Playlist'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'play') {
                            goToSong(playlistProvider.playlist.indexOf(song));
                          } else if (value == 'details') {
                            _showSongDetails(context, song);
                          } else if (value == 'add_to_playlist') {
                            _showAddToPlaylistDialog(context, song);
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

  void _showAddToPlaylistDialog(BuildContext context, Song song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Playlist'),
        content: Consumer<PlaylistProvider>(
          builder: (context, provider, child) {
            final playlists = provider.playlists;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final playlist in playlists)
                  CheckboxListTile(
                    title: Text(playlist.name),
                    value: playlist.songs.contains(song),
                    onChanged: (value) {
                      if (value!) {
                        provider.addSongToPlaylist(playlist, song);
                      } else {
                        provider.removeSongFromPlaylist(playlist, song);
                      }
                    },
                  ),
              ],
            );
          },
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
