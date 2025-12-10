import 'package:flutter/material.dart';
import 'package:frontend_flutter/consts.dart';

class BaseCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Function()? action;

  BaseCard({required this.child, this.action, this.color});

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: () => action?.call(),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: EdgeInsets.zero,
        foregroundColor: Colors.white,
        iconColor: Colors.white,
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardBorderRadius),
        ),
      ),
      child: child,
    );

    return Container(
      margin: const EdgeInsets.all(5),
      child: Card(
        color: color,
        child: action != null ? button : child,
      ),
    );
  }
}
