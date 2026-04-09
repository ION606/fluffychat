import 'dart:convert';

import 'package:fluffychat/config/setting_keys.dart';
import 'package:http/http.dart' as http;
import 'package:linkify/linkify.dart';
import 'package:matrix/matrix.dart';

class UrlPreviewData {
  final String? title;
  final String? description;
  final Uri? imageUri;
  final int? imageSize;

  const UrlPreviewData({
    this.title,
    this.description,
    this.imageUri,
    this.imageSize,
  });

  bool get hasContent => title != null || description != null;

  static const _empty = UrlPreviewData();
}

class UrlPreviewService {
  static const _maxCacheSize = 200;
  static final Map<String, UrlPreviewData> _cache = {};
  static final List<String> _cacheOrder = [];

  static String? extractFirstUrl(String text) {
    final elements = linkify(
      text,
      options: const LinkifyOptions(humanize: false),
      linkifiers: const [UrlLinkifier()],
    );
    for (final element in elements) {
      if (element is UrlElement) {
        final url = element.url;
        if (url.contains('matrix.to') || url.startsWith('mxc://')) continue;
        final uri = Uri.tryParse(url);
        if (uri != null &&
            (uri.scheme == 'http' || uri.scheme == 'https') &&
            uri.host.isNotEmpty) {
          return url;
        }
      }
    }
    return null;
  }

  static Future<UrlPreviewData?> getPreview(
    Client client,
    String url,
  ) async {
    if (_cache.containsKey(url)) {
      return _cache[url];
    }

    try {
      final proxyUrl = AppSettings.linkPreviewProxy.value;

      final http.StreamedResponse response;
      if (proxyUrl.isNotEmpty) {
        final proxyUri = Uri.parse(proxyUrl).replace(
          queryParameters: {
            ...Uri.parse(proxyUrl).queryParameters,
            'url': url,
          },
        );
        final request = http.Request('GET', proxyUri);
        response = await client.httpClient.send(request);
      } else {
        final useAuthed = await client.authenticatedMediaSupported();
        final path = useAuthed
            ? '_matrix/client/v1/media/preview_url'
            : '_matrix/media/v3/preview_url';
        final requestUri = Uri(
          path: path,
          queryParameters: {'url': url},
        );
        final request = http.Request(
          'GET',
          client.baseUri!.resolveUri(requestUri),
        );
        request.headers['authorization'] = 'Bearer ${client.bearerToken!}';
        response = await client.httpClient.send(request);
      }

      final responseBody = await response.stream.toBytes();
      if (response.statusCode != 200) {
        _putCache(url, UrlPreviewData._empty);
        return null;
      }

      final json =
          jsonDecode(utf8.decode(responseBody)) as Map<String, Object?>;
      final data = UrlPreviewData(
        title: json['og:title'] as String?,
        description: json['og:description'] as String?,
        imageUri: json['og:image'] != null
            ? Uri.tryParse(json['og:image'] as String)
            : null,
        imageSize: json['matrix:image:size'] as int?,
      );

      _putCache(url, data);
      return data;
    } catch (_) {
      _putCache(url, UrlPreviewData._empty);
      return null;
    }
  }

  static void _putCache(String url, UrlPreviewData data) {
    if (_cache.length >= _maxCacheSize) {
      final oldest = _cacheOrder.removeAt(0);
      _cache.remove(oldest);
    }
    _cache[url] = data;
    _cacheOrder.remove(url);
    _cacheOrder.add(url);
  }

  static void clearCache() {
    _cache.clear();
    _cacheOrder.clear();
  }
}
