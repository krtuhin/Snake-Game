import 'package:flutter/material.dart';

class BlankPixel extends StatelessWidget {
  const BlankPixel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0.3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
