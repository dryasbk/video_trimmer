import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:tmp_path/tmp_path.dart';
import 'package:path/path.dart' as p;
import 'package:transparent_image/transparent_image.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';

class FixedThumbnailViewer extends StatelessWidget {
  final File videoFile;
  final int videoDuration;
  final double thumbnailHeight;
  final BoxFit fit;
  final int numberOfThumbnails;
  final VoidCallback onThumbnailLoadingComplete;
  final int quality;

  /// For showing the thumbnails generated from the video,
  /// like a frame by frame preview
  const FixedThumbnailViewer({
    super.key,
    required this.videoFile,
    required this.videoDuration,
    required this.thumbnailHeight,
    required this.numberOfThumbnails,
    required this.fit,
    required this.onThumbnailLoadingComplete,
    this.quality = 75,
  });

  Stream<List<Uint8List?>> generateThumbnail() async* {
    final String videoPath = videoFile.path;
    double eachPart = videoDuration / numberOfThumbnails;
    List<Uint8List?> byteList = [];

// Future<void> run() async {
//       try {
//         var plugin = FcNativeVideoThumbnail();
//         final destFile = tmpPath() + p.extension(videoPath);
//         await plugin.getVideoThumbnail(
//             srcFile: videoPath,
//             destFile: destFile,
//             width: 50 * 8,
//             height: 50 ,
//             quality: quality,
//             // srcFileUri: isSrcUri,
//             format: 'jpeg');
//         if (await File(destFile).exists()) {
//           var imageFile = File(destFile);
//           // var decodedImage =
//           //     await decodeImageFromList(imageFile.readAsBytesSync());
//         //  final destImgSize =
//         //       'Decoded size: ${decodedImage.width}x${decodedImage.height}';

//         // } else {
//         //   error = 'No thumbnail extracted';
//         }
//       } catch (err) {
//         print( err.toString());
//       }
//     }

// //
    // the cache of last thumbnail
    Uint8List? lastBytes;
    for (int i = 1; i <= numberOfThumbnails; i++) {
      Uint8List? bytes;
      try {
        var plugin = FcNativeVideoThumbnail();
        final destFile = tmpPath() + p.extension(videoPath);
        await plugin.getVideoThumbnail(
            srcFile: videoPath,
            destFile: destFile,
            width: 50 * 8,
            height: 50,
            quality: quality,
            // srcFileUri: isSrcUri,
            format: 'jpeg');
        if (await File(destFile).exists()) {
          var imageFile = File(destFile);
          bytes = imageFile.readAsBytesSync();
          //   var decodedImage =
          //       await decodeImageFromList(imageFile.readAsBytesSync());
          //  final destImgSize =
          //       'Decoded size: ${decodedImage.width}x${decodedImage.height}';
        }
      } catch (e) {
        debugPrint('ERROR: Couldn\'t generate thumbnails: $e');
      }
      // if current thumbnail is null use the last thumbnail
      if (bytes != null) {
        lastBytes = bytes;
      } else {
        bytes = lastBytes;
      }
      byteList.add(bytes);
      if (byteList.length == numberOfThumbnails) {
        onThumbnailLoadingComplete();
      }
      yield byteList;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Uint8List?>>(
      stream: generateThumbnail(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Uint8List?> imageBytes = snapshot.data!;
          return Row(
            mainAxisSize: MainAxisSize.max,
            children: List.generate(
              numberOfThumbnails,
              (index) => SizedBox(
                height: thumbnailHeight,
                width: thumbnailHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: 0.2,
                      child: Image.memory(
                        imageBytes[0] ?? kTransparentImage,
                        fit: fit,
                      ),
                    ),
                    index < imageBytes.length
                        ? FadeInImage(
                            placeholder: MemoryImage(kTransparentImage),
                            image: MemoryImage(imageBytes[index]!),
                            fit: fit,
                          )
                        : const SizedBox(),
                  ],
                ),
              ),
            ),
          );
        } else {
          return Container(
            color: Colors.grey[900],
            height: thumbnailHeight,
            width: double.maxFinite,
          );
        }
      },
    );
  }
}
