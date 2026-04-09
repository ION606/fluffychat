import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:fluffychat/utils/url_preview_data.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class UrlPreviewCard extends StatefulWidget {
  final Event event;
  final Color textColor;
  final Color linkColor;

  const UrlPreviewCard({
    required this.event,
    required this.textColor,
    required this.linkColor,
    super.key,
  });

  @override
  State<UrlPreviewCard> createState() => _UrlPreviewCardState();
}

class _UrlPreviewCardState extends State<UrlPreviewCard> {
  UrlPreviewData? _preview;
  String? _url;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _url = UrlPreviewService.extractFirstUrl(widget.event.body);
    if (_url != null) {
      _fetchPreview();
    }
  }

  Future<void> _fetchPreview() async {
    final client = Matrix.of(context).client;
    final data = await UrlPreviewService.getPreview(client, _url!);
    if (!mounted) return;
    setState(() {
      _preview = data;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final url = _url;
    final preview = _preview;
    if (url == null || !_loaded || preview == null || !preview.hasContent) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final fontSize =
        AppConfig.messageFontSize * AppSettings.fontSizeFactor.value;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 8),
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppConfig.borderRadius / 2),
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () => UrlLauncher(context, url).launchUrl(),
          borderRadius: BorderRadius.circular(AppConfig.borderRadius / 2),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: widget.linkColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (preview.title != null)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 10,
                            right: 10,
                            top: 8,
                            bottom: 2,
                          ),
                          child: Text(
                            preview.title!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize * 0.9,
                              color: widget.linkColor,
                            ),
                          ),
                        ),
                      if (preview.description != null)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 10,
                            right: 10,
                            top: 2,
                            bottom: 8,
                          ),
                          child: Text(
                            preview.description!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: fontSize * 0.85,
                              color: widget.textColor.withAlpha(200),
                            ),
                          ),
                        ),
                      if (preview.imageUri != null)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 150),
                          child: MxcImage(
                            uri: preview.imageUri,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            client: Matrix.of(context).client,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
