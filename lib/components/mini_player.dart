import 'dart:io';

import 'package:flutter/material.dart';
import 'package:authentification/components/neu_box.dart';
import 'package:authentification/models/playlist_provider.dart';

class MiniPlayer extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final VoidCallback onPlayPausePressed;
  final VoidCallback onNextPressed;
  final VoidCallback onPreviousPressed;
  final VoidCallback onTap;

  const MiniPlayer({
    super.key,
    required this.song,
    required this.isPlaying,
    required this.onPlayPausePressed,
    required this.onNextPressed,
    required this.onPreviousPressed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Album art
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: song.albumArtImagePath != null
                  ? Image.file(
                      File(song.albumArtImagePath!),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderArt(),
                    )
                  : _buildPlaceholderArt(),
            ),
            const SizedBox(width: 12),
            // Song info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.songName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    song.artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Controls
            NeuBox(
              child: IconButton(
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: onPlayPausePressed,
              ),
            ),
            const SizedBox(width: 8),
            NeuBox(
              child: IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: onPreviousPressed,
              ),
            ),
            const SizedBox(width: 8),
            NeuBox(
              child: IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: onNextPressed,
              ),
            ),
          ],
        ),
      ),
    );
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
}
