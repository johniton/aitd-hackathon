import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisclaimerBanner extends StatefulWidget {
  final String disclaimerKey;
  const DisclaimerBanner({super.key, this.disclaimerKey = 'general_disclaimer_dismissed'});

  @override
  State<DisclaimerBanner> createState() => _DisclaimerBannerState();
}

class _DisclaimerBannerState extends State<DisclaimerBanner> {
  bool _dismissed = true; // Default true to avoid flash before load

  @override
  void initState() {
    super.initState();
    _checkDismissed();
  }

  Future<void> _checkDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dismissed = prefs.getBool(widget.disclaimerKey) ?? false;
    });
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(widget.disclaimerKey, true);
    setState(() {
      _dismissed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade900.withValues(alpha: 0.15),
        border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.amber.shade600, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "These figures are AI-generated estimates for awareness only. They are not audited, certified, or legally valid for compliance submissions, investor reporting, or government applications. Always consult a certified carbon consultant or MRV body before taking financial action.",
                  style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _dismiss,
                child: const Icon(Icons.close, color: Colors.white54, size: 18),
              )
            ],
          ),
        ],
      ),
    );
  }
}
