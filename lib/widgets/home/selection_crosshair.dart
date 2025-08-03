import 'package:flutter/material.dart';
import 'package:rapiruta_app/models/selection_mode.dart';

class SelectionCrosshair extends StatelessWidget {
  final SelectionMode selectionMode;

  const SelectionCrosshair({super.key, required this.selectionMode});

  @override
  Widget build(BuildContext context) {
    if (selectionMode == SelectionMode.none) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color:
                (selectionMode == SelectionMode.origin
                        ? Colors.green
                        : Colors.red)
                    .withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: selectionMode == SelectionMode.origin
                  ? Colors.green
                  : Colors.red,
              width: 3,
            ),
          ),
          child: Icon(
            Icons.add,
            color: selectionMode == SelectionMode.origin
                ? Colors.green
                : Colors.red,
            size: 20,
          ),
        ),
      ),
    );
  }
}
