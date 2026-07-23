/// YouTube video recommendation model.
class YouTubeVideo {
  final String videoId;
  final String title;
  final String thumbnailUrl;
  final String channelName;
  final String videoUrl;

  const YouTubeVideo({
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    required this.channelName,
    required this.videoUrl,
  });
}
