import 'dart:convert';

import 'package:flutter/foundation.dart';

@immutable
class MemberRecord {
  final String name; // from A2-A400
  final String group; // BT1 | BT2 | BT3
  final int power; // from C2-C400
  final int attendance; // attendance percentage 0-100

  const MemberRecord({
    required this.name,
    required this.group,
    required this.power,
    this.attendance = 100, // default 100%
  });

  MemberRecord copyWith({
    String? name,
    String? group,
    int? power,
    int? attendance,
  }) => MemberRecord(
    name: name ?? this.name,
    group: group ?? this.group,
    power: power ?? this.power,
    attendance: attendance ?? this.attendance,
  );

  // Calculate effective power based on attendance
  int get effectivePower {
    if (attendance == 100) {
      return power * 2; // 100% = double power
    } else {
      return (power * (attendance / 100)).round();
    }
  }

  Map<String, dynamic> toJson() => {
    'n': name,
    'g': group,
    'p': power,
    'a': attendance,
  };

  static MemberRecord fromJson(Map<String, dynamic> m) => MemberRecord(
    name: m['n'] as String? ?? '',
    group: m['g'] as String? ?? 'BT1',
    power: (m['p'] as num?)?.toInt() ?? 0,
    attendance: (m['a'] as num?)?.toInt() ?? 100,
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
