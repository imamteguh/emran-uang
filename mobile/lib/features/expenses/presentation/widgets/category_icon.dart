import 'package:flutter/material.dart';

class CategoryIcon extends StatelessWidget {
  final String icon;
  final Color color;
  final double size;

  const CategoryIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    IconData? iconData;
    switch (icon.toLowerCase().trim()) {
      case 'restaurant':
      case 'food':
      case 'food & drinks':
        iconData = Icons.restaurant;
        break;
      case 'home':
      case 'housing':
        iconData = Icons.home;
        break;
      case 'directions_car':
      case 'transport':
      case 'car':
        iconData = Icons.directions_car;
        break;
      case 'shopping_cart':
      case 'groceries':
        iconData = Icons.shopping_cart;
        break;
      case 'lightbulb':
      case 'utilities':
        iconData = Icons.lightbulb;
        break;
      case 'movie':
      case 'entertainment':
        iconData = Icons.movie;
        break;
      case 'local_hospital':
      case 'healthcare':
      case 'health':
        iconData = Icons.local_hospital;
        break;
      case 'medication':
        iconData = Icons.medication;
        break;
      case 'shopping_bag':
      case 'shopping':
        iconData = Icons.shopping_bag;
        break;
      case 'school':
      case 'education':
        iconData = Icons.school;
        break;
      case 'flight':
      case 'travel':
        iconData = Icons.flight;
        break;
      case 'favorite':
      case 'date night':
      case 'date_night':
        iconData = Icons.favorite;
        break;
      case 'subscriptions':
        iconData = Icons.subscriptions;
        break;
      case 'pets':
        iconData = Icons.pets;
        break;
      case 'card_giftcard':
      case 'gifts':
        iconData = Icons.card_giftcard;
        break;
      case 'receipt_long':
        iconData = Icons.receipt_long;
        break;
      case 'more_horiz':
        iconData = Icons.more_horiz;
        break;
      case 'help_outline':
      case 'other':
      case 'help':
        iconData = Icons.help_outline;
        break;
      default:
        // If it starts with a high rune, it's likely an emoji or special character
        if (icon.isNotEmpty && icon.runes.first > 127) {
          return Text(
            icon,
            style: TextStyle(fontSize: size),
          );
        }
        iconData = Icons.category_outlined;
    }

    return Icon(
      iconData,
      color: color,
      size: size,
    );
  }
}
