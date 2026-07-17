import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import '../theme/app_theme.dart';

/// Displays a module's icon fetched from `/api/modules/{id}/UI/icon`.
///
/// Two things make a plain `Image.network` unusable here:
///  - the endpoint is access-controlled, so the request must carry the Bearer
///    token (an anonymous request is rejected with 403); and
///  - the URL has no file extension and the module may declare a raster (PNG/
///    JPG) *or* a vector (SVG) icon, which need different widgets.
///
/// So we fetch the bytes once with the auth header, sniff SVG vs raster, and
/// render the matching widget. A missing/failed icon falls back to a neutral
/// placeholder rather than an error box.
class ModuleIcon extends StatefulWidget {
  final String url;
  final String token;
  final double size;

  const ModuleIcon({
    super.key,
    required this.url,
    required this.token,
    this.size = 32,
  });

  @override
  State<ModuleIcon> createState() => _ModuleIconState();
}

class _ModuleIconState extends State<ModuleIcon> {
  Uint8List? _bytes;
  bool _isSvg = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ModuleIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-fetch if the module (or the token, on re-login) changed under us.
    if (oldWidget.url != widget.url || oldWidget.token != widget.token) {
      _bytes = null;
      _isSvg = false;
      _failed = false;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final response = await http
          .get(Uri.parse(widget.url), headers: {'Authorization': 'Bearer ${widget.token}'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        if (mounted) setState(() => _failed = true);
        return;
      }
      final contentType = response.headers['content-type']?.toLowerCase() ?? '';
      final isSvg = contentType.contains('svg') || _looksLikeSvg(response.bodyBytes);
      if (!mounted) return;
      setState(() {
        _bytes = response.bodyBytes;
        _isSvg = isSvg;
      });
    } catch (_) {
      // Offline / unreachable / bad response - show the placeholder, never crash.
      if (mounted) setState(() => _failed = true);
    }
  }

  /// Sniffs the first bytes for an SVG/XML signature, as a backstop for servers
  /// that mislabel the content type (the URL itself carries no extension).
  static bool _looksLikeSvg(Uint8List bytes) {
    final head = String.fromCharCodes(bytes.take(256)).trimLeft().toLowerCase();
    return head.startsWith('<svg') || head.startsWith('<?xml') || head.contains('<svg');
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return _placeholder();

    final bytes = _bytes;
    if (bytes == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(
          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    if (_isSvg) {
      return SvgPicture.memory(
        bytes,
        width: widget.size,
        height: widget.size,
        placeholderBuilder: (_) => _placeholder(),
      );
    }

    return Image.memory(
      bytes,
      width: widget.size,
      height: widget.size,
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }

  Widget _placeholder() => Icon(Icons.widgets, size: widget.size, color: AppColors.faint(0.5));
}
