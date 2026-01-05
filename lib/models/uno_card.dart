import 'dart:math';
import 'package:flutter/material.dart';

enum CardColor { red, blue, green, yellow, black }

enum CardValue {
  zero,
  one,
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  skip,
  reverse,
  plusTwo,
  wild,
  wildFour
}

class UnoCard implements Comparable<UnoCard> {
  final String id;
  CardColor color;
  final CardValue value;

  UnoCard({required this.id, required this.color, required this.value});

  bool get isWild => color == CardColor.black;

  bool canPlayOn(UnoCard topCard) {
    if (color == CardColor.black) return true;
    if (color == topCard.color) return true;
    if (value == topCard.value) return true;
    return false;
  }

  String toData() => "${color.name}_${value.name}";

  static UnoCard fromData(String data) {
    try {
      if (!data.contains('_'))
        return UnoCard(id: "err", color: CardColor.red, value: CardValue.zero);
      var parts = data.split('_');
      var c = CardColor.values
          .firstWhere((e) => e.name == parts[0], orElse: () => CardColor.black);
      var v = CardValue.values
          .firstWhere((e) => e.name == parts[1], orElse: () => CardValue.wild);
      return UnoCard(
          id: Random().nextInt(99999).toString(), color: c, value: v);
    } catch (e) {
      return UnoCard(id: "err", color: CardColor.red, value: CardValue.zero);
    }
  }

  Color get colorHex {
    switch (color) {
      case CardColor.red:
        return const Color(0xFFFF0044);
      case CardColor.blue:
        return const Color(0xFF00C3FF);
      case CardColor.green:
        return const Color(0xFF00FF88);
      case CardColor.yellow:
        return const Color(0xFFFFEA00);
      case CardColor.black:
        return const Color(0xFF222222);
    }
  }

  String get symbol {
    switch (value) {
      case CardValue.skip:
        return "⊘";
      case CardValue.reverse:
        return "⇄";
      case CardValue.plusTwo:
        return "+2";
      case CardValue.wild:
        return "★";
      case CardValue.wildFour:
        return "+4";
      default:
        return (CardValue.values.indexOf(value)).toString();
    }
  }

  @override
  int compareTo(UnoCard other) {
    int colorComp = color.index.compareTo(other.color.index);
    if (colorComp != 0) return colorComp;
    return value.index.compareTo(other.value.index);
  }
}
