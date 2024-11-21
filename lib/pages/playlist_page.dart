import 'package:authentification/components/my_drawer.dart';
import 'package:authentification/models/playlist_provider.dart';
import 'package:authentification/pages/song_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({super.key});

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  late final PlaylistProvider playlistProvider;

  @override
  void initState() {
    super.initState();
    playlistProvider = Provider.of<PlaylistProvider>(context, listen: false);
  }

  void _showEditPlaylistDialog(Playlist playlist) {
    final newPlaylistNameController =
        TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Playlist'),
          content: TextField(
            controller: newPlaylistNameController,
            decoration: const InputDecoration(
              hintText: 'Enter new playlist name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newPlaylistName = newPlaylistNameController.text.trim();
                if (newPlaylistName.isNotEmpty) {
                  playlistProvider.updatePlaylistName(
                      playlist, newPlaylistName);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showDeletePlaylistDialog(Playlist playlist) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Playlist'),
          content: Text('Are you sure you want to delete "${playlist.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                playlistProvider.deletePlaylist(playlist);
                Navigator.pop(context);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToPlaylistSongs(Playlist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistSongsPage(playlist: playlist),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Saved Playlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showEditPlaylistDialog(Playlist(id: 0, name: '', songs: []));
            },
          ),
        ],
      ),
      drawer: const MyDrawer(),
      body: Consumer<PlaylistProvider>(
        builder: (context, provider, child) {
          final playlists = provider.playlists;
          return ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return ListTile(
                title: Text(playlist.name),
                subtitle: Text('${playlist.songs.length} songs'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _showEditPlaylistDialog(playlist);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        _showDeletePlaylistDialog(playlist);
                      },
                    ),
                  ],
                ),
                onTap: () => _navigateToPlaylistSongs(playlist),
              );
            },
          );
        },
      ),
    );
  }
}

class PlaylistSongsPage extends StatelessWidget {
  final Playlist playlist;

  const PlaylistSongsPage({super.key, required this.playlist});

  void _playSongFromPlaylist(
      BuildContext context, Song song, List<Song> playlistSongs) {
    final playlistProvider =
        Provider.of<PlaylistProvider>(context, listen: false);

    // Update the main playlist and current song index
    // playlistProvider.playlist = playlistSongs;
    playlistProvider.currentSongIndex = playlistSongs.indexOf(song);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SongPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
      ),
      body: ListView.builder(
        itemCount: playlist.songs.length,
        itemBuilder: (context, index) {
          final song = playlist.songs[index];
          return ListTile(
            title: Text(song.songName),
            subtitle: Text(song.artistName),
            onTap: () => _playSongFromPlaylist(context, song, playlist.songs),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete),
                      SizedBox(width: 8),
                      Text('Remove from Playlist'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'remove') {
                  final provider =
                      Provider.of<PlaylistProvider>(context, listen: false);
                  provider.removeSongFromPlaylist(playlist, song);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
