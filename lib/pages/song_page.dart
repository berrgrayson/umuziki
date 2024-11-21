import 'dart:io';

import 'package:flutter/material.dart';
import 'package:authentification/components/neu_box.dart';
import 'package:authentification/models/playlist_provider.dart';
import 'package:provider/provider.dart';

class SongPage extends StatelessWidget {
  const SongPage({super.key});

  // convert duration into min:sec
  String formatTime(Duration duration) {
    String twoDigitSeconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    String formattedTime = "${duration.inMinutes}:$twoDigitSeconds";
    return formattedTime;
  }

  void _showAddToPlaylistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Playlist'),
        content: Consumer<PlaylistProvider>(
          builder: (context, provider, child) {
            final playlists = provider.playlists;
            final currentSong = provider.currentSong;
            if (currentSong == null) return const SizedBox.shrink();
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final playlist in playlists)
                      CheckboxListTile(
                        title: Text(playlist.name),
                        value: playlist.songs.contains(currentSong),
                        onChanged: (value) {
                          if (value!) {
                            provider.addSongToPlaylist(playlist, currentSong);
                          } else {
                            provider.removeSongFromPlaylist(
                                playlist, currentSong);
                          }
                        },
                      ),
                  ],
                ),
              ),
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

  void _showCreatePlaylistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final newPlaylistNameController = TextEditingController();
        final provider = Provider.of<PlaylistProvider>(context, listen: false);
        final currentSong = provider.currentSong;
        if (currentSong == null) {
          return const AlertDialog(title: Text('No current song'));
        }
        return AlertDialog(
          title: const Text('Create Playlist'),
          content: TextField(
            controller: newPlaylistNameController,
            decoration: const InputDecoration(
              hintText: 'Enter playlist name',
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
                  provider.createPlaylist(newPlaylistName);
                  provider.addSongToPlaylist(
                    provider.playlists.last,
                    currentSong,
                  );
                  Navigator.pop(context);

                  // Show a snackbar to confirm playlist creation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Playlist "$newPlaylistName" created successfully'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaceholderArt() {
    return Container(
      width: 250,
      height: 250,
      color: Colors.grey[300],
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 80,
            color: Colors.grey,
          ),
          Text(
            'No Album Art',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, value, child) {
        // get playlist
        final playlist = value.playlist;

        // Check if playlist is empty or index is invalid
        if (playlist.isEmpty || value.currentSongIndex == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: const Center(
              child: Text("No songs found. Add some music to your device!"),
            ),
          );
        }

        // get current song
        final currentSong = playlist[value.currentSongIndex ?? 0];

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // app bar
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.arrow_back),
                                ),
                                const Text("P L A Y L I S T"),
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.menu),
                                ),
                              ],
                            ),

                            // album artwork with improved interaction
                            GestureDetector(
                              onDoubleTap: () =>
                                  _showAddToPlaylistDialog(context),
                              child: NeuBox(
                                child: Column(
                                  children: [
                                    // image with fallback
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child:
                                          currentSong.albumArtImagePath != null
                                              ? Image.file(
                                                  File(currentSong
                                                      .albumArtImagePath!),
                                                  width: 300,
                                                  height: 300,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      _buildPlaceholderArt(),
                                                )
                                              : _buildPlaceholderArt(),
                                    ),

                                    // song and artist name and icon
                                    Padding(
                                      padding: const EdgeInsets.all(15.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // song and artist name with ellipsis for long text
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  currentSong.songName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  currentSong.artistName,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Playlist actions with more intuitive icons
                                          Row(
                                            children: [
                                              IconButton(
                                                tooltip:
                                                    'Add to Existing Playlist',
                                                onPressed: () =>
                                                    _showAddToPlaylistDialog(
                                                        context),
                                                icon: const Icon(Icons
                                                    .playlist_add_check_rounded),
                                                color: Colors.green,
                                              ),
                                              IconButton(
                                                tooltip: 'Create New Playlist',
                                                onPressed: () =>
                                                    _showCreatePlaylistDialog(
                                                        context),
                                                icon: const Icon(Icons
                                                    .create_new_folder_outlined),
                                                color: Colors.green.shade500,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Enhanced Slider with Time Display
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formatTime(value.currentDuration),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withOpacity(0.7),
                                        ),
                                      ),
                                      Text(
                                        formatTime(value.totalDuration),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 5,
                                    thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 8),
                                    overlayShape: const RoundSliderOverlayShape(
                                        overlayRadius: 15),
                                    activeTrackColor: Colors.deepOrange,
                                    inactiveTrackColor:
                                        Colors.deepOrange.shade100,
                                    thumbColor: Colors.deepOrangeAccent,
                                  ),
                                  child: Slider(
                                    min: 0,
                                    max: value.totalDuration.inSeconds
                                        .toDouble(),
                                    value: value.currentDuration.inSeconds
                                        .toDouble(),
                                    onChanged: (double position) {
                                      value.seek(
                                          Duration(seconds: position.toInt()));
                                    },
                                  ),
                                ),
                              ],
                            ),

                            // Playback Controls with Improved Interaction
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: value.playPreviousSong,
                                    child: NeuBox(
                                      child: Icon(
                                        Icons.skip_previous_rounded,
                                        color:
                                            Theme.of(context).iconTheme.color,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  flex: 2,
                                  child: GestureDetector(
                                    onTap: value.pauseOrResume,
                                    child: NeuBox(
                                      child: Icon(
                                        value.isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color:
                                            Theme.of(context).iconTheme.color,
                                        size: 50,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: value.playNextSong,
                                    child: NeuBox(
                                      child: Icon(
                                        Icons.skip_next_rounded,
                                        color:
                                            Theme.of(context).iconTheme.color,
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
