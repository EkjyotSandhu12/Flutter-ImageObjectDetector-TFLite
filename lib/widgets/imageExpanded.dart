import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_downloader/image_downloader.dart';

class imageExpanded extends StatelessWidget {

  final String imgUrl;

  imageExpanded({required this.imgUrl});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Container(
        height: MediaQuery.of(context).size.width-100,
        width: MediaQuery.of(context).size.width-100,
        child: Image.network(imgUrl,
            fit: BoxFit.cover),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(onPressed: () async {
          Navigator.of(context).pop(context);
          try {
            // Saved with this method.
            var imageId = await ImageDownloader.downloadImage(imgUrl);
            if (imageId == null) {
              return;
            }
          print(imageId);
          } on PlatformException catch (error) {
            print(error);
          }

        }, child: Text("Download"))
      ],
    );
  }
}
