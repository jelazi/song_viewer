import 'dart:io';

import 'package:song_viewer/services/local_web/local_web_addresses.dart';
import 'package:flutter_test/flutter_test.dart';

/// [NetworkInterface] cannot be constructed, so the ranking is exercised
/// through a stand-in with the same shape.
class _FakeInterface implements NetworkInterface {
  @override
  final String name;
  @override
  final List<InternetAddress> addresses;

  _FakeInterface(this.name, List<String> hosts) : addresses = hosts.map(InternetAddress.new).toList();

  @override
  int get index => 0;
}

void main() {
  group('rankAddresses', () {
    test('keeps only private IPv4 addresses', () {
      final ranked = rankAddresses([
        _FakeInterface('en0', ['192.168.1.20', '8.8.8.8', '169.254.10.1']),
      ]);

      expect(ranked.map((a) => a.host), ['192.168.1.20']);
    });

    test('drops loopback', () {
      final ranked = rankAddresses([
        _FakeInterface('lo0', ['127.0.0.1']),
      ]);

      expect(ranked, isEmpty);
    });

    test('192.168 wins over 10.x — it is what home routers hand out', () {
      final ranked = rankAddresses([
        _FakeInterface('utun0', ['10.8.0.3']),
        _FakeInterface('en0', ['192.168.0.50']),
      ]);

      expect(ranked.first.host, '192.168.0.50');
      expect(ranked.last.host, '10.8.0.3');
    });

    test('accepts the whole 172.16–172.31 block and nothing outside it', () {
      final ranked = rankAddresses([
        _FakeInterface('a', ['172.15.0.1', '172.16.0.1', '172.31.255.9', '172.32.0.1']),
      ]);

      expect(ranked.map((a) => a.host), ['172.16.0.1', '172.31.255.9']);
    });

    test('an interface with no usable address contributes nothing', () {
      final ranked = rankAddresses([
        _FakeInterface('en1', []),
        _FakeInterface('en0', ['192.168.4.4']),
      ]);

      expect(ranked, hasLength(1));
    });
  });

  group('LocalWebAddress', () {
    test('builds the url the QR code carries', () {
      const address = LocalWebAddress(interfaceName: 'en0', host: '192.168.1.20');

      expect(address.url(8080), 'http://192.168.1.20:8080');
    });
  });
}
