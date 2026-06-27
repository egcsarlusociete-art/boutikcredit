import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../models/video_model.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';

final bcVideosProvider = StreamProvider<List<VideoModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('bc_videos')
      .orderBy('publishedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(VideoModel.fromFirestore).toList());
});

class VideoScreen extends ConsumerStatefulWidget {
  const VideoScreen({super.key});
  @override
  ConsumerState<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends ConsumerState<VideoScreen> {
  YoutubePlayerController? _controller;
  String? _activeVideoId;
  String? _activeDocId;

  void _playVideo(VideoModel v) {
    _controller?.dispose();
    setState(() {
      _activeVideoId = v.youtubeId;
      _activeDocId = v.id;
      _controller = YoutubePlayerController(
        initialVideoId: v.youtubeId,
        flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
      );
    });
    FirebaseFirestore.instance.collection('bc_videos').doc(v.id).update({'views': FieldValue.increment(1)});
  }

  @override
  void dispose() { _controller?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final videosAsync = ref.watch(bcVideosProvider);
    return Scaffold(
      backgroundColor: EgcColors.bg,
      appBar: AppBar(
        title: const Text('Vidéos EGC-SARLU'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: videosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: EgcColors.primary)),
        error: (e, _) => const Center(child: Text('Erreur de chargement')),
        data: (videos) {
          if (videos.isEmpty) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('🎬', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text('Aucune vidéo disponible', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EgcColors.ink)),
            SizedBox(height: 8),
            Text('Revenez bientôt !', style: TextStyle(color: EgcColors.ink3)),
          ]));
          return ListView.builder(
            itemCount: videos.length,
            itemBuilder: (ctx, i) {
              final v = videos[i];
              final isActive = _activeDocId == v.id;
              return Column(children: [
                // Lecteur YouTube si actif
                if (isActive && _controller != null)
                  YoutubePlayer(controller: _controller!, showVideoProgressIndicator: true,
                    progressIndicatorColor: EgcColors.primary),
                // Carte vidéo
                GestureDetector(
                  onTap: () => _playVideo(v),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    decoration: BoxDecoration(color: EgcColors.bg2, borderRadius: EgcRadius.mdBorder, border: Border.all(color: isActive ? EgcColors.primary : EgcColors.line, width: isActive ? 2 : 1.5)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Thumbnail
                      if (!isActive) Stack(children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: EgcRadius.md),
                          child: Image.network(
                            'https://img.youtube.com/vi/${v.youtubeId}/hqdefault.jpg',
                            width: double.infinity, height: 180, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(height: 180, color: EgcColors.bg3, child: const Icon(Icons.play_circle_outline, size: 64, color: EgcColors.ink3)),
                          ),
                        ),
                        Positioned.fill(child: Center(child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                        ))),
                        if (v.isNew) Positioned(top: 8, left: 8, child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: EgcColors.primary, borderRadius: EgcRadius.pill),
                          child: const Text('NOUVEAU', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                        )),
                      ]),
                      // Infos
                      Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(v.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: EgcColors.ink), maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (v.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(v.description, style: const TextStyle(fontSize: 12, color: EgcColors.ink3, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                        const SizedBox(height: 8),
                        Row(children: [
                          const Icon(Icons.remove_red_eye_outlined, size: 14, color: EgcColors.ink3),
                          const SizedBox(width: 4),
                          Text('${v.views}', style: const TextStyle(fontSize: 12, color: EgcColors.ink3)),
                          const SizedBox(width: 12),
                          _LikeButton(videoId: v.id, likes: v.likes),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.share_outlined, size: 18, color: EgcColors.ink3),
                            onPressed: () => Share.share('Regardez cette vidéo EGC-SARLU : https://youtu.be/${v.youtubeId}'),
                            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.comment_outlined, size: 18, color: EgcColors.ink3),
                            onPressed: () => _showComments(context, v.id, v.title),
                            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 4),
                          Text('${v.comments}', style: const TextStyle(fontSize: 12, color: EgcColors.ink3)),
                        ]),
                        if (v.publishedAt != null) Text(fmtDate(v.publishedAt), style: const TextStyle(fontSize: 11, color: EgcColors.ink3)),
                      ])),
                    ]),
                  ),
                ),
              ]);
            },
          );
        },
      ),
    );
  }

  void _showComments(BuildContext context, String videoId, String title) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: EgcRadius.lg)),
      builder: (_) => CommentsSheet(videoId: videoId, title: title),
    );
  }
}

// Bouton Like
class _LikeButton extends StatefulWidget {
  final String videoId;
  final int likes;
  const _LikeButton({required this.videoId, required this.likes});
  @override
  State<_LikeButton> createState() => _LikeButtonState();
}
class _LikeButtonState extends State<_LikeButton> {
  bool _liked = false;
  late int _count;
  @override
  void initState() { super.initState(); _count = widget.likes; _checkLiked(); }

  Future<void> _checkLiked() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snap = await FirebaseFirestore.instance.collection('bc_video_likes').doc('${widget.videoId}_$uid').get();
    if (mounted) setState(() => _liked = snap.exists);
  }

  Future<void> _toggle() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ref = FirebaseFirestore.instance.collection('bc_video_likes').doc('${widget.videoId}_$uid');
    final videoRef = FirebaseFirestore.instance.collection('bc_videos').doc(widget.videoId);
    if (_liked) {
      await ref.delete();
      await videoRef.update({'likes': FieldValue.increment(-1)});
      setState(() { _liked = false; _count--; });
    } else {
      await ref.set({'userId': uid, 'videoId': widget.videoId, 'createdAt': FieldValue.serverTimestamp()});
      await videoRef.update({'likes': FieldValue.increment(1)});
      setState(() { _liked = true; _count++; });
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _toggle,
    child: Row(children: [
      Icon(_liked ? Icons.favorite : Icons.favorite_border, size: 16, color: _liked ? EgcColors.err : EgcColors.ink3),
      const SizedBox(width: 4),
      Text('$_count', style: TextStyle(fontSize: 12, color: _liked ? EgcColors.err : EgcColors.ink3)),
    ]),
  );
}

// Section Commentaires
class CommentsSheet extends StatefulWidget {
  final String videoId;
  final String title;
  const CommentsSheet({super.key, required this.videoId, required this.title});
  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}
class _CommentsSheetState extends State<CommentsSheet> {
  final _commentC = TextEditingController();
  String? _replyToId;
  String? _replyToName;
  bool _sending = false;

  Stream<List<VideoComment>> get _comments => FirebaseFirestore.instance
      .collection('bc_video_comments')
      .where('videoId', isEqualTo: widget.videoId)
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((s) => s.docs.map(VideoComment.fromFirestore).toList());

  Future<void> _send() async {
    final text = _commentC.text.trim();
    if (text.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { showSnack(context, 'Connectez-vous pour commenter', isError: true); return; }
    setState(() => _sending = true);
    try {
      await FirebaseFirestore.instance.collection('bc_video_comments').add({
        'videoId': widget.videoId, 'userId': user.uid,
        'userName': user.displayName ?? user.email ?? 'Utilisateur',
        'text': text, 'likes': 0,
        'parentId': _replyToId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('bc_videos').doc(widget.videoId)
          .update({'comments': FieldValue.increment(1)});
      _commentC.clear();
      setState(() { _replyToId = null; _replyToName = null; });
    } catch (e) {
      if (mounted) showSnack(context, 'Erreur envoi', isError: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(VideoComment c) async {
    await FirebaseFirestore.instance.collection('bc_video_comments').doc(c.id).delete();
    await FirebaseFirestore.instance.collection('bc_videos').doc(widget.videoId)
        .update({'comments': FieldValue.increment(-1)});
  }

  @override
  void dispose() { _commentC.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return DraggableScrollableSheet(
      initialChildSize: 0.75, maxChildSize: 0.95, minChildSize: 0.4, expand: false,
      builder: (_, sc) => Column(children: [
        Container(height: 4, width: 40, margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: EgcColors.line2, borderRadius: EgcRadius.pill)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(widget.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
        const Divider(),
        Expanded(child: StreamBuilder<List<VideoComment>>(
          stream: _comments,
          builder: (_, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: EgcColors.primary));
            final comments = snap.data!.where((c) => c.parentId == null).toList();
            final replies = snap.data!.where((c) => c.parentId != null).toList();
            if (comments.isEmpty) return const Center(child: Text('Soyez le premier à commenter !', style: TextStyle(color: EgcColors.ink3)));
            return ListView.builder(
              controller: sc,
              itemCount: comments.length,
              itemBuilder: (_, i) {
                final c = comments[i];
                final cReplies = replies.where((r) => r.parentId == c.id).toList();
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _CommentTile(comment: c, uid: uid, onReply: () => setState(() { _replyToId = c.id; _replyToName = c.userName; }), onDelete: () => _delete(c)),
                  ...cReplies.map((r) => Padding(padding: const EdgeInsets.only(left: 40),
                    child: _CommentTile(comment: r, uid: uid, onReply: null, onDelete: () => _delete(r)))),
                ]);
              },
            );
          },
        )),
        if (_replyToName != null) Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: EgcColors.primaryBg,
          child: Row(children: [
            Text('Répondre à $_replyToName', style: const TextStyle(fontSize: 12, color: EgcColors.primary, fontWeight: FontWeight.w600)),
            const Spacer(),
            GestureDetector(onTap: () => setState(() { _replyToId = null; _replyToName = null; }), child: const Icon(Icons.close, size: 16, color: EgcColors.primary)),
          ]),
        ),
        SafeArea(child: Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 8, top: 8),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _commentC,
              decoration: InputDecoration(hintText: 'Écrire un commentaire...', filled: true, fillColor: EgcColors.bg, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none)),
              maxLines: null, textInputAction: TextInputAction.send, onSubmitted: (_) => _send(),
            )),
            const SizedBox(width: 8),
            GestureDetector(onTap: _sending ? null : _send,
              child: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: EgcColors.primary, shape: BoxShape.circle),
                child: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send, color: Colors.white, size: 20))),
          ]),
        )),
      ]),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final VideoComment comment;
  final String? uid;
  final VoidCallback? onReply;
  final VoidCallback onDelete;
  const _CommentTile({required this.comment, required this.uid, required this.onReply, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isOwn = comment.userId == uid;
    return Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CircleAvatar(radius: 16, backgroundColor: EgcColors.primaryMid,
        child: Text(comment.userName.isNotEmpty ? comment.userName[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EgcColors.primary))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(comment.userName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: EgcColors.ink)),
          const SizedBox(width: 6),
          Text(fmtDate(comment.createdAt), style: const TextStyle(fontSize: 10, color: EgcColors.ink3)),
        ]),
        const SizedBox(height: 2),
        Text(comment.text, style: const TextStyle(fontSize: 13, color: EgcColors.ink2, height: 1.4)),
        const SizedBox(height: 4),
        Row(children: [
          if (onReply != null) GestureDetector(onTap: onReply, child: const Text('Répondre', style: TextStyle(fontSize: 11, color: EgcColors.primary, fontWeight: FontWeight.w600))),
          if (isOwn) ...[const SizedBox(width: 12), GestureDetector(onTap: onDelete, child: const Text('Supprimer', style: TextStyle(fontSize: 11, color: EgcColors.err, fontWeight: FontWeight.w600)))],
        ]),
      ])),
    ]));
  }
}
