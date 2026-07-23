import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:ai_study_companion/models/youtube_video.dart';

/// Service that searches YouTube for educational videos related to a query.
///
/// Uses `youtube_explode_dart` so no Google Cloud API key is needed.
class YouTubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  /// Searches YouTube for the top [maxResults] videos matching [query].
  ///
  /// Appends "lecture tutorial" to bias results toward educational content.
  Future<List<YouTubeVideo>> searchVideos(
    String query, {
    int maxResults = 5,
  }) async {
    try {
      final searchQuery = '$query lecture tutorial';
      final searchList = await _yt.search.search(searchQuery);

      final results = <YouTubeVideo>[];
      for (final item in searchList.take(maxResults)) {
        results.add(YouTubeVideo(
          videoId: item.id.value,
          title: item.title,
          thumbnailUrl: item.thumbnails.mediumResUrl,
          channelName: item.author,
          videoUrl: 'https://www.youtube.com/watch?v=${item.id.value}',
        ));
      }

      return results;
    } catch (e) {
      debugPrint('YouTubeService.searchVideos error: $e');
      return [];
    }
  }

  /// Closes the underlying HTTP client.
  void dispose() {
    _yt.close();
  }
}
