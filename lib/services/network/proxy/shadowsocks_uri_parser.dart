import 'dart:convert';

import 'proxy_settings_service.dart';

class ShadowsocksUriConfig {
  const ShadowsocksUriConfig({
    required this.host,
    required this.port,
    required this.cipher,
    required this.password,
    this.remarks,
  });

  final String host;
  final int port;
  final String cipher;
  final String password;
  final String? remarks;
}

class ShadowsocksUriParser {
  const ShadowsocksUriParser._();

  static ShadowsocksUriConfig parse(String input) {
    final raw = input.trim();
    if (raw.isEmpty) {
      throw const FormatException('链接不能为空');
    }
    if (!raw.toLowerCase().startsWith('ss://')) {
      throw const FormatException('仅支持 ss:// 链接');
    }

    final payload = raw.substring(5);
    final hashIndex = payload.indexOf('#');
    final body = hashIndex >= 0 ? payload.substring(0, hashIndex) : payload;
    final remarks = hashIndex >= 0
        ? Uri.decodeComponent(payload.substring(hashIndex + 1))
        : null;

    final config = _parseBody(body);
    final cipher =
        ProxySettingsService.normalizeShadowsocksCipher(config.$1.trim());
    if (cipher.isEmpty) {
      throw FormatException(
        '当前版本仅支持 ${ProxySettingsService.supportedShadowsocksCiphers.join(' / ')}',
      );
    }

    return ShadowsocksUriConfig(
      host: config.$3,
      port: config.$4,
      cipher: cipher,
      password: config.$2,
      remarks: remarks,
    );
  }

  static (String, String, String, int) _parseBody(String body) {
    final cleaned = body.trim();
    if (cleaned.isEmpty) {
      throw const FormatException('ss:// 链接内容为空');
    }

    if (!cleaned.contains('@')) {
      final decoded = _decodeBase64Payload(cleaned);
      return _parseBody(decoded);
    }

    final atIndex = cleaned.lastIndexOf('@');
    final userInfoPart = cleaned.substring(0, atIndex);
    final hostPart = cleaned.substring(atIndex + 1).split('?').first;

    final userInfo = userInfoPart.contains(':')
        ? Uri.decodeComponent(userInfoPart)
        : _decodeBase64Payload(userInfoPart);

    final separatorIndex = userInfo.indexOf(':');
    if (separatorIndex <= 0) {
      throw const FormatException('无法解析加密算法和密码');
    }

    final cipher = userInfo.substring(0, separatorIndex);
    final password = userInfo.substring(separatorIndex + 1);
    final (host, port) = _parseHostPort(hostPart);
    return (cipher, password, host, port);
  }

  static String _decodeBase64Payload(String input) {
    final normalized = input.trim();
    try {
      return utf8.decode(base64Url.decode(base64Url.normalize(normalized)));
    } catch (_) {
      try {
        return utf8.decode(base64.decode(base64.normalize(normalized)));
      } catch (_) {
        throw const FormatException('ss:// 链接 Base64 解码失败');
      }
    }
  }

  static (String, int) _parseHostPort(String input) {
    final value = input.trim();
    if (value.isEmpty) {
      throw const FormatException('缺少服务器地址');
    }

    if (value.startsWith('[')) {
      final closing = value.indexOf(']');
      if (closing <= 0 || closing + 2 > value.length || value[closing + 1] != ':') {
        throw const FormatException('IPv6 地址格式无效');
      }
      final host = value.substring(1, closing);
      final port = int.tryParse(value.substring(closing + 2));
      if (port == null || port <= 0 || port > 65535) {
        throw const FormatException('端口无效');
      }
      return (host, port);
    }

    final colon = value.lastIndexOf(':');
    if (colon <= 0 || colon == value.length - 1) {
      throw const FormatException('缺少端口');
    }
    final host = value.substring(0, colon);
    final port = int.tryParse(value.substring(colon + 1));
    if (port == null || port <= 0 || port > 65535) {
      throw const FormatException('端口无效');
    }
    return (host, port);
  }
}
