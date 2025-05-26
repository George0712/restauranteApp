import 'package:flutter/material.dart';

Widget navbarItem(IconData icon, bool isActive, BuildContext context) {
  return Container(
    decoration: isActive
        ? BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).secondaryHeaderColor,
                width: 3,
              ),
            ),
          )
        : null,
    child: IconButton(
      onPressed: () {},
      icon: Icon(
        icon,
        color: isActive
            ? Theme.of(context).secondaryHeaderColor
            : Colors.white.withOpacity(0.6),
        size: 28,
      ),
    ),
  );
}
