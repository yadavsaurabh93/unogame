import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExitButton extends StatelessWidget {
  final VoidCallback? onTap;
  const ExitButton({super.key, this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        SystemSound.play(SystemSoundType.click);
        onTap != null ? onTap!() : Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.all(10),
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        child: const Icon(Icons.close, color: Colors.white70, size: 26),
      ),
    );
  }
}
