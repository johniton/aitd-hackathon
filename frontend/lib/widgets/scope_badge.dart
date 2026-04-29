import 'package:flutter/material.dart';

enum EmissionScope { scope1, scope2, scope3 }

class ScopeBadge extends StatelessWidget {
  final EmissionScope scope;
  
  const ScopeBadge({super.key, required this.scope});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String text;

    switch (scope) {
      case EmissionScope.scope1:
        bgColor = Colors.grey.shade800;
        textColor = Colors.white;
        text = "S1 Direct";
        break;
      case EmissionScope.scope2:
        bgColor = Colors.blue.shade900.withValues(alpha: 0.6);
        textColor = Colors.blue.shade100;
        text = "S2 Energy";
        break;
      case EmissionScope.scope3:
        bgColor = Colors.orange.shade900.withValues(alpha: 0.6);
        textColor = Colors.orange.shade100;
        text = "S3 Value Chain ⚠️";
        break;
    }

    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(left: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.w600),
      ),
    );

    if (scope == EmissionScope.scope3) {
      return Tooltip(
        message: "Scope 3 emissions are from activities outside your direct control. You generally CANNOT generate carbon credits from Scope 3 reductions. These are included for your awareness only.",
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(12),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
        child: badge,
      );
    }

    return badge;
  }
}
