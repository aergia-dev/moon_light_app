import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';

class Moon3D extends StatefulWidget {
  const Moon3D({super.key});

  @override
  Moon3DState createState() => Moon3DState();
}

class Moon3DState extends State<Moon3D> with SingleTickerProviderStateMixin {
  late Object moon;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _controller.addListener(() {
      setState(() {
        if (mounted) {
          moon.rotation.y += 360 / (60 * 60);
          moon.updateTransform();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Cube(
      onSceneCreated: (Scene scene) {
        moon = Object(fileName: 'assets/moon.obj', isAsset: true);
        moon.scale.setValues(2.0, 2.0, 2.0);
        scene.world.add(moon);

        scene.camera.zoom = 5;
        scene.camera.target.setValues(0, 0, 0);
        scene.camera.position.setValues(0, 0, 10);

        scene.camera.viewportWidth = MediaQuery.of(context).size.width;
        scene.camera.viewportHeight = MediaQuery.of(context).size.height;

        scene.update();
      },
      interactive: false,
    );
  }
}
