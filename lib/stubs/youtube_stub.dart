// Stub youtube_player_flutter pour le web
import 'package:flutter/material.dart';

class YoutubePlayerController {
  YoutubePlayerController({required String initialVideoId, dynamic flags});
  void dispose() {}
  void load(String videoId) {}
  void pause() {}
}
class YoutubePlayerFlags {
  const YoutubePlayerFlags({bool? autoPlay, bool? mute, bool? disableDragSeek, bool? loop, bool? isLive, bool? forceHD, bool? enableCaption});
}
class YoutubePlayer extends StatelessWidget {
  const YoutubePlayer({super.key, required dynamic controller, bool? showVideoProgressIndicator, Color? progressIndicatorColor});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
class YoutubePlayerBuilder extends StatelessWidget {
  final YoutubePlayer player;
  final Widget Function(BuildContext, Widget) builder;
  const YoutubePlayerBuilder({super.key, required this.player, required this.builder});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
class YoutubeMetaData {
  final String title;
  const YoutubeMetaData({this.title = ''});
}
