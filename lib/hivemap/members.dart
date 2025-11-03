import 'dart:convert';

import 'package:flutter/foundation.dart';

@immutable
class MemberRecord {
  final String name; // from A2-A400
  final String group; // BT1 | BT2 | BT3
  final int power; // from C2-C400

  const MemberRecord({
    required this.name,
    required this.group,
    required this.power,
  });

  MemberRecord copyWith({String? name, String? group, int? power}) =>
      MemberRecord(
        name: name ?? this.name,
        group: group ?? this.group,
        power: power ?? this.power,
      );

  Map<String, dynamic> toJson() => {'n': name, 'g': group, 'p': power};

  static MemberRecord fromJson(Map<String, dynamic> m) => MemberRecord(
    name: m['n'] as String? ?? '',
    group: m['g'] as String? ?? 'BT1',
    power: (m['p'] as num?)?.toInt() ?? 0,
  );
}

String encodeMembers(List<MemberRecord> list) =>
    jsonEncode(list.map((e) => e.toJson()).toList());

List<MemberRecord> decodeMembers(String s) {
  final d = jsonDecode(s);
  if (d is List) {
    return d
        .whereType<Map<String, dynamic>>()
        .map(MemberRecord.fromJson)
        .toList();
  }
  return const <MemberRecord>[];
}
