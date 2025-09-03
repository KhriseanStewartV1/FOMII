import 'dart:async';
import 'dart:io';

import 'package:deepar_flutter_plus/deepar_flutter_plus.dart';
import 'package:flutter/material.dart';
import 'package:fomo_connect/src/screens/camera_screen/filter_data.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}


class _CameraScreenState extends State<CameraScreen> {


final _controllerPlus = DeepArControllerPlus();
Future<void> init () async {
  final result = await _controllerPlus.initialize(androidLicenseKey: "9306a430517468330a3aad09e93d57be8cc9d4bc7ad8b1ad4831160314df89ca69de2e7825b6d9ff", iosLicenseKey: "2b150a2226b8db4a863493fb21e05c5f10526dc91d1cbd15f60e625456d3945d75a605c5ff562519");
  if(result.success){
    print("Initalization Successful: ${result.message} ");
   if (Platform.isIOS) {
    // Check initialization status periodically
    Timer.periodic(Duration(milliseconds: 500), (timer) {
   if (_controllerPlus.isInitialized) {
        print('iOS view is now fully initialized');
        setState(() {
          // Update your UI to show the camera preview
        });
        timer.cancel();
      } else if (timer.tick > 20) {
        // Timeout after 10 seconds
        print('Timeout waiting for iOS view initialization');
        timer.cancel();
      }
  });
   }
  }else {
  // Initialization failed
  print("Initialization failed: ${result.message}");
}
}
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: init(),
      builder: (context, snapshot) {
        if(snapshot.connectionState == ConnectionState.done){
          return Stack(
            children: [
              buildCameraPrev(),
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: buildFilters(),
                ),
                Positioned(
                  bottom: 30,
                  left: 20,
                  right: 20,
                  child: buildButtons(),
                ),
            ],
          );
        } else {return Center(child: Text("Loading Preview"),);}
      }
    );
  }

  Widget buildCameraPrev () {
    return SizedBox( child: Transform.scale(scale: 1.5, child: DeepArPreviewPlus(_controllerPlus),),);
  }

  Widget buildButtons () {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      IconButton(onPressed: _controllerPlus.flipCamera, icon: Icon(Icons.flip_camera_android_rounded)),
      IconButton(onPressed: _controllerPlus.takeScreenshot, icon: Icon(Icons.camera)),
      IconButton(onPressed: _controllerPlus.toggleFlash, icon: Icon(Icons.flash_on)),
    ],);
  }
  Widget buildFilters () {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.1,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
        final filter = filters[index];
        final effectFile = File("${filter.imagePath}${filter.filterPath}").path;
        print(filter.imagePath);
        return InkWell(
          onTap: () => _controllerPlus.switchEffect("assets/filters/Devil_Neon_Horns/Neon_Devil_Horns.deepar"),
          child: Padding(padding: const EdgeInsets.all(8.0),
          child: Container(width: 40, decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(
    image: AssetImage("${filter.imagePath}${filter.imageName}"),
    fit: BoxFit.cover,
  ),)),),
        );
      },),
    );
  }
}