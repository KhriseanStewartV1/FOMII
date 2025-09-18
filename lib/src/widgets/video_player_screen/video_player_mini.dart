import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

// ignore: must_be_immutable
class VideoPlayerMini extends StatefulWidget {
  bool isUrl;
  File? file;
  String? url;
  double? aspectRatio;
  VideoPlayerMini({
    super.key,
    this.file,
    this.url,
    this.aspectRatio,
    required this.isUrl,
  });

  @override
  State<VideoPlayerMini> createState() => _VideoPlayerMiniState();
}

class _VideoPlayerMiniState extends State<VideoPlayerMini> {
  late VideoPlayerController _controller;
  ChewieController? _chewieController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = widget.isUrl
        ? VideoPlayerController.network(widget.url!)
        : VideoPlayerController.file(widget.file!);

    _controller
        .initialize()
        .then((_) {
          _chewieController = ChewieController(
            videoPlayerController: _controller,
            autoPlay: true,
            looping: false,
            aspectRatio: widget.aspectRatio,
          );

          if (mounted) {
            setState(() => _isLoading = false);
          }
        })
        .catchError((e) {
          debugPrint("Video initialization error: $e");
          if (mounted) setState(() => _isLoading = false);
        });
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Center(
      child: _isLoading
          ? const CircularProgressIndicator()
          : Chewie(controller: _chewieController!),
    );
  }
}
