import '../models/qr_scan_payload.dart';
import '../models/qr_url_assessment.dart';

class QrUrlInspector {
  static const Set<String> _shortenerHosts = {
    'bit.ly',
    'cutt.ly',
    'is.gd',
    'rb.gy',
    'rebrand.ly',
    'shorturl.at',
    't.co',
    'tiny.cc',
    'tinyurl.com',
  };

  static const Set<String> _sensitiveQueryNames = {
    'access_token',
    'api_key',
    'apikey',
    'auth',
    'authorization',
    'code',
    'email',
    'key',
    'otp',
    'password',
    'passwd',
    'pin',
    'pwd',
    'secret',
    'session',
    'sessionid',
    'token',
  };

  static const Set<String> _redirectQueryNames = {
    'continue',
    'dest',
    'destination',
    'next',
    'redirect',
    'redirect_uri',
    'return',
    'return_to',
    'target',
    'url',
  };

  static const Set<String> _authenticationPathMarkers = {
    'access-token',
    'auth',
    'code',
    'confirm',
    'invite',
    'magic-link',
    'oauth',
    'password-reset',
    'recover',
    'recovery',
    'reset',
    'reset-password',
    'session',
    'token',
    'verify',
    'verification',
  };

  QrUrlAssessment inspect(String rawValue) {
    final signals = <QrUrlSignal>[];
    final parsed = Uri.tryParse(rawValue);
    if (parsed == null) {
      return _invalid(rawValue, QrUrlSignal.invalidStructure, 'invalid_url');
    }
    if (RegExp(r'%(?![0-9a-fA-F]{2})').hasMatch(rawValue)) {
      return _invalid(
        rawValue,
        QrUrlSignal.invalidStructure,
        'invalid_encoding',
      );
    }

    final scheme = parsed.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return _invalid(
        rawValue,
        QrUrlSignal.unsupportedScheme,
        'unsupported_scheme',
      );
    }
    if (parsed.host.isEmpty || !parsed.hasAuthority) {
      return _invalid(rawValue, QrUrlSignal.invalidStructure, 'missing_host');
    }
    if (_hasControlCharacters(rawValue)) {
      return _invalid(
        rawValue,
        QrUrlSignal.controlCharacters,
        'control_characters',
      );
    }

    final host = parsed.host.toLowerCase();
    if (_hasInvalidHostname(host)) {
      return _invalid(
        rawValue,
        QrUrlSignal.invalidStructure,
        'invalid_authority',
      );
    }
    final idn = _idnDisplay(host);
    if (_hasInvalidAsciiHostname(idn.asciiHost) ||
        _hasInvalidPunycodeLabel(host)) {
      return _invalid(rawValue, QrUrlSignal.invalidStructure, 'invalid_idn');
    }
    if (idn.asciiHost.split('.').any((label) => label.startsWith('xn--'))) {
      signals.add(QrUrlSignal.punycode);
    }
    if (_hasMixedScripts(idn.unicodeHost)) {
      signals.add(QrUrlSignal.mixedScripts);
    }
    if (scheme == 'http') signals.add(QrUrlSignal.insecureHttp);

    if (parsed.userInfo.isNotEmpty || parsed.authority.contains('@')) {
      signals.add(QrUrlSignal.embeddedCredentials);
    }

    final defaultPort = scheme == 'https' ? 443 : 80;
    if (_hasExplicitPort(parsed.authority) && parsed.port != defaultPort) {
      signals.add(QrUrlSignal.unusualPort);
    }

    if (_isNonPublicHost(host)) {
      signals.add(QrUrlSignal.localOrNonPublicHost);
    }
    if (_shortenerHosts.contains(host)) {
      signals.add(QrUrlSignal.knownShortener);
    }
    if (parsed.hasFragment) signals.add(QrUrlSignal.fragmentPresent);

    late final bool hasSensitiveQuery;
    late final bool hasSensitivePath;
    late final bool hasIdentifiableRedirect;
    try {
      hasSensitiveQuery = parsed.queryParametersAll.keys.any(
        (key) => _isSensitiveQueryName(key),
      );
      hasSensitivePath = _hasSensitiveAuthenticationPath(parsed.pathSegments);
      hasIdentifiableRedirect = _hasIdentifiableRedirect(parsed);
    } on FormatException {
      return _invalid(
        rawValue,
        QrUrlSignal.invalidStructure,
        'invalid_encoding',
      );
    }
    if (hasIdentifiableRedirect) signals.add(QrUrlSignal.identifiableRedirect);
    if (hasSensitiveQuery) signals.add(QrUrlSignal.sensitiveQuery);
    if (hasSensitivePath) signals.add(QrUrlSignal.sensitivePath);

    final displayValue = _redactedDisplay(
      rawValue,
      parsed,
      hidePath: hasSensitivePath,
    );
    final isStructurallyBlocked = signals.any(
      (signal) => const {
        QrUrlSignal.embeddedCredentials,
        QrUrlSignal.localOrNonPublicHost,
        QrUrlSignal.sensitiveQuery,
        QrUrlSignal.sensitivePath,
        QrUrlSignal.unusualPort,
      }.contains(signal),
    );

    return QrUrlAssessment(
      originalValue: rawValue,
      parsedUri: parsed,
      displayValue: displayValue,
      host: host,
      unicodeHost: idn.unicodeHost,
      asciiHost: idn.asciiHost,
      signals: List.unmodifiable(signals),
      isEligibleForReputation: !isStructurallyBlocked,
      canOpenExternally: !isStructurallyBlocked,
      fragmentOmittedFromReputation: parsed.hasFragment,
      blockReasonCode: isStructurallyBlocked ? _reasonFor(signals) : null,
    );
  }

  QrUrlAssessment _invalid(
    String rawValue,
    QrUrlSignal signal,
    String reasonCode,
  ) {
    return QrUrlAssessment(
      originalValue: rawValue,
      parsedUri: null,
      displayValue: escapeControlCharacters(rawValue),
      host: '',
      unicodeHost: '',
      asciiHost: '',
      signals: [signal],
      isEligibleForReputation: false,
      canOpenExternally: false,
      fragmentOmittedFromReputation: false,
      blockReasonCode: reasonCode,
    );
  }

  String _reasonFor(List<QrUrlSignal> signals) {
    if (signals.contains(QrUrlSignal.embeddedCredentials)) {
      return 'embedded_credentials';
    }
    if (signals.contains(QrUrlSignal.localOrNonPublicHost)) {
      return 'non_public_host';
    }
    if (signals.contains(QrUrlSignal.sensitiveQuery)) return 'sensitive_query';
    if (signals.contains(QrUrlSignal.sensitivePath)) return 'sensitive_path';
    if (signals.contains(QrUrlSignal.unusualPort)) return 'unusual_port';
    return 'local_policy';
  }

  bool _hasIdentifiableRedirect(Uri uri) {
    for (final entry in uri.queryParametersAll.entries) {
      final normalizedName = entry.key.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9_-]'),
        '',
      );
      final canonicalName = normalizedName.replaceAll('-', '_');
      if (!_redirectQueryNames.contains(canonicalName)) continue;
      if (entry.value.any((value) {
        final destination = value.trimLeft().toLowerCase();
        return destination.startsWith('http://') ||
            destination.startsWith('https://') ||
            destination.startsWith('//');
      })) {
        return true;
      }
    }
    return false;
  }

  bool _hasSensitiveAuthenticationPath(List<String> pathSegments) {
    for (var index = 0; index < pathSegments.length; index++) {
      final marker = pathSegments[index]
          .toLowerCase()
          .replaceAll('_', '-')
          .replaceAll(RegExp(r'[^a-z0-9-]'), '');
      if (!_authenticationPathMarkers.contains(marker) ||
          index + 1 >= pathSegments.length) {
        continue;
      }
      final candidate = pathSegments[index + 1];
      if (candidate.length >= 16 &&
          RegExp(r'^[a-zA-Z0-9._~-]+$').hasMatch(candidate)) {
        return true;
      }
    }
    return false;
  }

  String _redactedDisplay(String rawValue, Uri uri, {required bool hidePath}) {
    var visible = rawValue;
    final fragmentIndex = visible.indexOf('#');
    if (fragmentIndex >= 0) visible = visible.substring(0, fragmentIndex);

    final authorityMarker = visible.indexOf('://');
    if (authorityMarker >= 0) {
      final authorityStart = authorityMarker + 3;
      var authorityEnd = visible.length;
      for (final delimiter in ['/', '?', '#']) {
        final index = visible.indexOf(delimiter, authorityStart);
        if (index >= 0 && index < authorityEnd) authorityEnd = index;
      }
      final authority = visible.substring(authorityStart, authorityEnd);
      final credentialsSeparator = authority.lastIndexOf('@');
      if (credentialsSeparator >= 0) {
        visible = visible.replaceRange(
          authorityStart,
          authorityEnd,
          '[credenciales ocultas]@${authority.substring(credentialsSeparator + 1)}',
        );
      }
    }

    if (hidePath) {
      final authorityMarker = visible.indexOf('://');
      if (authorityMarker >= 0) {
        final authorityStart = authorityMarker + 3;
        var pathStart = visible.length;
        for (final delimiter in ['/', '?', '#']) {
          final index = visible.indexOf(delimiter, authorityStart);
          if (index >= 0 && index < pathStart) pathStart = index;
        }
        final queryStart = visible.indexOf('?');
        final pathEnd = queryStart >= pathStart ? queryStart : visible.length;
        if (pathStart < pathEnd && visible[pathStart] == '/') {
          visible =
              '${visible.substring(0, pathStart)}/[ruta potencialmente sensible]'
              '${visible.substring(pathEnd)}';
        }
      }
    }

    final queryStart = visible.indexOf('?');
    if (queryStart >= 0) {
      final prefix = visible.substring(0, queryStart + 1);
      final rawQuery = visible.substring(queryStart + 1);
      final redactedParts = rawQuery
          .split('&')
          .map((part) {
            final equals = part.indexOf('=');
            final rawName = equals < 0 ? part : part.substring(0, equals);
            var decodedName = rawName;
            try {
              decodedName = Uri.decodeQueryComponent(rawName);
            } on FormatException {
              // Hide values with malformed keys rather than risk exposing a secret.
              if (equals >= 0) return '$rawName=[oculto]';
            }
            if (!_isSensitiveQueryName(decodedName)) return part;
            return '$rawName=[oculto]';
          })
          .join('&');
      visible = '$prefix$redactedParts';
    }

    // `uri` is parsed before display; keeping it in this method makes that
    // precondition explicit and avoids a second, potentially different parse.
    assert(uri.hasAuthority);
    return escapeControlCharacters(visible);
  }

  bool _isSensitiveQueryName(String name) {
    final key = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return _sensitiveQueryNames.contains(key) ||
        key.endsWith('token') ||
        key.endsWith('password') ||
        key.endsWith('secret');
  }

  bool _hasControlCharacters(String value) =>
      hasControlOrFormattingCharacters(value);

  bool _hasInvalidHostname(String host) {
    if (host.trim() != host ||
        !RegExp(r'^[\p{L}\p{M}\p{N}.-]+$', unicode: true).hasMatch(host)) {
      return true;
    }
    final normalized = host.replaceFirst(RegExp(r'\.$'), '');
    final labels = normalized.split('.');
    return normalized.isEmpty ||
        normalized.runes.length > 253 ||
        labels.any(
          (label) =>
              label.isEmpty ||
              label.runes.length > 63 ||
              label.startsWith('-') ||
              label.endsWith('-'),
        );
  }

  bool _hasInvalidAsciiHostname(String host) {
    final normalized = host.replaceFirst(RegExp(r'\.$'), '');
    if (normalized.isEmpty || normalized.length > 253) return true;
    return normalized
        .split('.')
        .any(
          (label) =>
              label.isEmpty ||
              label.length > 63 ||
              label.startsWith('-') ||
              label.endsWith('-') ||
              !RegExp(r'^[a-z0-9-]+$').hasMatch(label),
        );
  }

  bool _hasInvalidPunycodeLabel(String host) => host.split('.').any((label) {
    if (!label.startsWith('xn--')) return false;
    final decoded = _Punycode.decode(label.substring(4));
    if (decoded == null ||
        decoded.isEmpty ||
        decoded.contains('.') ||
        decoded.startsWith('-') ||
        decoded.endsWith('-')) {
      return true;
    }
    return !RegExp(r'^[\p{L}\p{M}\p{N}-]+$', unicode: true).hasMatch(decoded);
  });

  bool _hasExplicitPort(String authority) {
    final hostAuthority = authority.substring(authority.lastIndexOf('@') + 1);
    if (hostAuthority.startsWith('[')) {
      final closeBracket = hostAuthority.indexOf(']');
      return closeBracket >= 0 && closeBracket + 1 < hostAuthority.length;
    }
    return hostAuthority.contains(':');
  }

  bool _isNonPublicHost(String host) {
    final normalized = host.toLowerCase().replaceFirst(RegExp(r'\.$'), '');
    if (normalized.isEmpty || normalized.contains(':')) return true;
    if (_looksLikeIpv4(normalized) || _looksLikeNumericAddress(normalized)) {
      return true;
    }
    if (!normalized.contains('.')) return true;
    const localSuffixes = {
      'localhost',
      'local',
      'internal',
      'test',
      'invalid',
      'example',
      'arpa',
    };
    return localSuffixes.any(
      (suffix) => normalized == suffix || normalized.endsWith('.$suffix'),
    );
  }

  bool _looksLikeIpv4(String host) {
    final parts = host.split('.');
    if (parts.length != 4) return false;
    return parts.every((part) {
      final value = int.tryParse(part);
      return value != null && value >= 0 && value <= 255;
    });
  }

  bool _looksLikeNumericAddress(String host) {
    final labels = host.split('.');
    return labels.every(
      (label) => RegExp(
        r'^(?:[0-9]+|0x[0-9a-f]+)$',
        caseSensitive: false,
      ).hasMatch(label),
    );
  }

  bool _hasMixedScripts(String host) {
    for (final label in host.split('.')) {
      final scripts = <String>{};
      for (final rune in label.runes) {
        if ((rune >= 0x0041 && rune <= 0x024f) ||
            (rune >= 0x1e00 && rune <= 0x1eff)) {
          scripts.add('latin');
        } else if (rune >= 0x0370 && rune <= 0x03ff) {
          scripts.add('greek');
        } else if (rune >= 0x0400 && rune <= 0x052f) {
          scripts.add('cyrillic');
        } else if (rune >= 0x0590 && rune <= 0x08ff) {
          scripts.add('right_to_left');
        } else if (rune >= 0x3040 && rune <= 0x30ff) {
          scripts.add('japanese');
        } else if (rune >= 0x3400 && rune <= 0x9fff) {
          scripts.add('cjk');
        }
      }
      if (scripts.length > 1) return true;
    }
    return false;
  }

  _IdnHost _idnDisplay(String host) {
    final unicodeLabels = <String>[];
    final asciiLabels = <String>[];
    for (final label in host.split('.')) {
      if (label.startsWith('xn--')) {
        final decoded = _Punycode.decode(label.substring(4));
        unicodeLabels.add(decoded ?? label);
        asciiLabels.add(label);
      } else if (label.runes.any((rune) => rune > 0x7f)) {
        unicodeLabels.add(label);
        final encoded = _Punycode.encode(label);
        asciiLabels.add(encoded == null ? label : 'xn--$encoded');
      } else {
        unicodeLabels.add(label);
        asciiLabels.add(label);
      }
    }
    return _IdnHost(unicodeLabels.join('.'), asciiLabels.join('.'));
  }
}

class _IdnHost {
  const _IdnHost(this.unicodeHost, this.asciiHost);

  final String unicodeHost;
  final String asciiHost;
}

class _Punycode {
  static const int _base = 36;
  static const int _tMin = 1;
  static const int _tMax = 26;
  static const int _skew = 38;
  static const int _damp = 700;
  static const int _initialBias = 72;
  static const int _initialN = 128;

  static String? encode(String input) {
    final codePoints = input.toLowerCase().runes.toList();
    final output = StringBuffer();
    var basicCount = 0;
    for (final point in codePoints) {
      if (point < 0x80) {
        output.writeCharCode(point);
        basicCount++;
      }
    }

    var handled = basicCount;
    if (basicCount > 0 && handled < codePoints.length) output.write('-');
    var n = _initialN;
    var delta = 0;
    var bias = _initialBias;

    while (handled < codePoints.length) {
      var next = 0x7fffffff;
      for (final point in codePoints) {
        if (point >= n && point < next) next = point;
      }
      if (next == 0x7fffffff) return null;
      final advance = (next - n) * (handled + 1);
      if (advance > 0x7fffffff - delta) return null;
      delta += advance;
      n = next;

      for (final point in codePoints) {
        if (point < n) {
          delta++;
          if (delta < 0) return null;
        } else if (point == n) {
          var q = delta;
          for (var k = _base; ; k += _base) {
            final threshold = _threshold(k, bias);
            if (q < threshold) break;
            final code = threshold + ((q - threshold) % (_base - threshold));
            output.write(_digit(code));
            q = (q - threshold) ~/ (_base - threshold);
          }
          output.write(_digit(q));
          bias = _adapt(delta, handled + 1, handled == basicCount);
          delta = 0;
          handled++;
        }
      }
      delta++;
      n++;
    }
    return output.toString();
  }

  static String? decode(String input) {
    final output = <int>[];
    final delimiter = input.lastIndexOf('-');
    var index = 0;
    if (delimiter >= 0) {
      for (final codeUnit in input.substring(0, delimiter).codeUnits) {
        if (codeUnit >= 0x80) return null;
        output.add(codeUnit);
      }
      index = delimiter + 1;
    }

    var n = _initialN;
    var i = 0;
    var bias = _initialBias;
    while (index < input.length) {
      final oldI = i;
      var weight = 1;
      for (var k = _base; ; k += _base) {
        if (index >= input.length) return null;
        final digit = _value(input.codeUnitAt(index++));
        if (digit < 0 || digit > (0x7fffffff - i) ~/ weight) return null;
        i += digit * weight;
        final threshold = _threshold(k, bias);
        if (digit < threshold) break;
        final factor = _base - threshold;
        if (weight > 0x7fffffff ~/ factor) return null;
        weight *= factor;
      }
      final count = output.length + 1;
      bias = _adapt(i - oldI, count, oldI == 0);
      final increment = i ~/ count;
      if (increment > 0x10ffff - n) return null;
      n += increment;
      if (n >= 0xd800 && n <= 0xdfff) return null;
      i %= count;
      output.insert(i, n);
      i++;
    }
    return String.fromCharCodes(output);
  }

  static int _threshold(int k, int bias) {
    if (k <= bias + _tMin) return _tMin;
    if (k >= bias + _tMax) return _tMax;
    return k - bias;
  }

  static int _adapt(int delta, int numberOfPoints, bool firstTime) {
    var value = firstTime ? delta ~/ _damp : delta ~/ 2;
    value += value ~/ numberOfPoints;
    var k = 0;
    final limit = ((_base - _tMin) * _tMax) ~/ 2;
    while (value > limit) {
      value ~/= _base - _tMin;
      k += _base;
    }
    return k + (((_base - _tMin + 1) * value) ~/ (value + _skew));
  }

  static int _value(int codeUnit) {
    if (codeUnit >= 0x61 && codeUnit <= 0x7a) return codeUnit - 0x61;
    if (codeUnit >= 0x41 && codeUnit <= 0x5a) return codeUnit - 0x41;
    if (codeUnit >= 0x30 && codeUnit <= 0x39) return codeUnit - 0x30 + 26;
    return -1;
  }

  static String _digit(int value) =>
      String.fromCharCode(value < 26 ? value + 0x61 : value - 26 + 0x30);
}
