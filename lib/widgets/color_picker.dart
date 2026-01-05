import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/uno_card.dart';

class ColorPicker extends StatelessWidget {
  const ColorPicker({super.key});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [const BoxShadow(color: Colors.white24, blurRadius: 20)],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "PICK A COLOR",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close,
                          color: Colors.redAccent, size: 30),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 20,
                  runSpacing: 20,
                  children: CardColor.values
                      .where((c) => c != CardColor.black)
                      .map((c) => GestureDetector(
                            onTap: () => Navigator.pop(context, c),
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                  color: UnoCard(
                                          id: "",
                                          color: c,
                                          value: CardValue.zero)
                                      .colorHex,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: UnoCard(
                                                id: "",
                                                color: c,
                                                value: CardValue.zero)
                                            .colorHex,
                                        blurRadius: 15)
                                  ]),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
