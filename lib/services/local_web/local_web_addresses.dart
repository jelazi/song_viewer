import 'dart:io';

/// One address the local web server can be reached at from another device.
class LocalWebAddress {
  final String interfaceName;
  final String host;

  const LocalWebAddress({required this.interfaceName, required this.host});

  String url(int port) => 'http://$host:$port';

  @override
  bool operator ==(Object other) => identical(this, other) || other is LocalWebAddress && other.interfaceName == interfaceName && other.host == host;

  @override
  int get hashCode => Object.hash(interfaceName, host);

  @override
  String toString() => '$interfaceName: $host';
}

/// Addresses of this machine that a phone on the same network can reach.
///
/// Only private IPv4 ranges are returned, in the order a home or church Wi-Fi
/// is most likely to use. Loopback is useless for a scanned QR code, and
/// 169.254/16 means DHCP failed — the interface is up but nothing can route to
/// it, so offering either would produce a QR code that silently does not work.
List<LocalWebAddress> rankAddresses(List<NetworkInterface> interfaces) {
  final addresses = <LocalWebAddress>[];

  for (final interface in interfaces) {
    for (final address in interface.addresses) {
      if (address.type != InternetAddressType.IPv4) continue;
      if (address.isLoopback) continue;
      if (!_isPrivateIPv4(address.address)) continue;
      addresses.add(LocalWebAddress(interfaceName: interface.name, host: address.address));
    }
  }

  addresses.sort((a, b) {
    final byRange = _rangeRank(a.host).compareTo(_rangeRank(b.host));
    if (byRange != 0) return byRange;
    return a.interfaceName.compareTo(b.interfaceName);
  });

  return addresses;
}

Future<List<LocalWebAddress>> listLocalAddresses() async {
  try {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
      includeLinkLocal: false,
    );
    return rankAddresses(interfaces);
  } on SocketException {
    return const [];
  }
}

bool _isPrivateIPv4(String host) {
  final parts = host.split('.');
  if (parts.length != 4) return false;
  final first = int.tryParse(parts[0]);
  final second = int.tryParse(parts[1]);
  if (first == null || second == null) return false;

  if (first == 10) return true;
  if (first == 192 && second == 168) return true;
  if (first == 172 && second >= 16 && second <= 31) return true;
  return false;
}

/// 192.168/16 first: it is what consumer routers hand out, so it is the address
/// a phone on the same Wi-Fi is most likely to reach.
int _rangeRank(String host) {
  if (host.startsWith('192.168.')) return 0;
  if (host.startsWith('10.')) return 1;
  return 2;
}
