import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a CheapShark redirect URL in the device's default browser.
Future<bool> openDealUrl(BuildContext context, String url) async {
  if (url.isEmpty) return false;

  final uri = Uri.tryParse(url);
  if (uri == null) {
    _showError(context, 'Invalid deal link.');
    return false;
  }

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _showError(context, 'Could not open the store page.');
    }
    return launched;
  } catch (_) {
    if (context.mounted) {
      _showError(context, 'Could not open the store page.');
    }
    return false;
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade700,
    ),
  );
}
