import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/src/database/others/image.dart';
import 'package:fomo_connect/src/modal/post_modal.dart';
import 'package:fomo_connect/src/widgets/video_player_screen/video_player_mini.dart';

Future<ui.Image> _getImageSize(String url) async {
  final completer = Completer<ui.Image>();
  final image = NetworkImage(url);
  image
      .resolve(const ImageConfiguration())
      .addListener(
        ImageStreamListener((ImageInfo info, bool _) {
          completer.complete(info.image);
        }),
      );
  return completer.future;
}

Future<ui.Image> _getMediaSize(Map<String, dynamic> mediaItem) async {
  final type = mediaItem['type'] as String? ?? 'image';
  final url = mediaItem['url'] as String? ?? '';
  if (type == 'image') {
    return _getImageSize(url);
  } else if (type == 'video') {
    final uint8list = await getVideoThumbnail(url);
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(uint8list!, (img) => completer.complete(img));
    return completer.future;
  }
  throw Exception('Unknown media type');
}

void _openFullScreenImage(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    builder: (context) => GestureDetector(
      onTap: () => Navigator.of(context).pop(), // tap to close
      child: Container(
        color: Colors.black.withOpacity(0.8),
        alignment: Alignment.center,
        child: Hero(
          tag:
              imageUrl, // optional: for smooth transition if using Hero elsewhere
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
          ),
        ),
      ),
    ),
  );
}

Widget buildMedia(PostModal post) {
  if (post.media.isEmpty) return SizedBox.shrink();

  final List<String> mediaUrl = [];
  final List<String> mediaTypes = [];

  final mediaPost = post.media[0];
  final media = mediaPost.keys.toList();

  for (var stuff in media) {
    final urls = mediaPost[stuff]['url'] as String;
    final types = mediaPost[stuff]['type'] as String;

    mediaUrl.add(urls);
    mediaTypes.add(types);
  }

  if (media.isEmpty) {
    return SizedBox.shrink();
  }

  return FutureBuilder<ui.Image>(
    future: _getMediaSize(mediaPost["media_0"]), // first image decides ratio
    builder: (context, snapshot) {
      return snapshot.hasData
          ? LayoutBuilder(
              builder: (context, constraints) {
                final size = snapshot.data!;
                final aspectRatio = size.width / size.height;

                return SizedBox(
                  width: constraints.maxWidth,
                  height:
                      constraints.maxWidth /
                      aspectRatio, // enforce aspect ratio
                  child: CarouselSlider.builder(
                    itemCount: media.length,
                    options: CarouselOptions(
                      viewportFraction: 1.0,
                      enableInfiniteScroll: false,
                      enlargeCenterPage: false,
                      height:
                          constraints.maxWidth / aspectRatio, // enforce height
                    ),
                    itemBuilder: (context, index, realIdx) {
                      final url = mediaUrl[index];
                      final type = mediaTypes[index];
                      final isVideo = type == 'video';

                      if (isVideo) {
                        return VideoPlayerMini(isUrl: true, url: url);
                      } else {
                        return GestureDetector(
                          onTap: () => _openFullScreenImage(context, url),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (context, url) =>
                                Icon(Icons.image_not_supported_outlined),
                            errorWidget: (context, url, error) =>
                                Center(child: Icon(Icons.error)),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            )
          : Center(child: CircularProgressIndicator());
    },
  );
}
