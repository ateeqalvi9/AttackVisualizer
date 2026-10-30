/// Storage Repository for History Records and Graph Sessions
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryRecord {
  final String id;
  final String type; // 'calculator' | 'matrix' | 'solver' | 'calculus'
  final String expression;
  final String result;
  final Map<String, double>? variables;
  final DateTime timestamp;

  HistoryRecord({
    required this.id,
    required this.type,
    required this.expression,
    required this.result,
    this.variables,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'expression': expression,
        'result': result,
        'variables': variables,
        'timestamp': timestamp.toIso8601String(),
      };

  factory HistoryRecord.fromJson(Map<String, dynamic> json) => HistoryRecord(
        id: json['id'] as String,
        type: json['type'] as String,
        expression: json['expression'] as String,
        result: json['result'] as String,
        variables: (json['variables'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class GraphSession {
  final String id;
  final String name;
  final String type; // '2d' | '3d'
  final List<String> formulas;
  final Map<String, dynamic> config;
  final DateTime timestamp;

  GraphSession({
    required this.id,
    required this.name,
    required this.type,
    required this.formulas,
    required this.config,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'formulas': formulas,
        'config': config,
        'timestamp': timestamp.toIso8601String(),
      };

  factory GraphSession.fromJson(Map<String, dynamic> json) => GraphSession(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        formulas: List<String>.from(json['formulas'] as List),
        config: Map<String, dynamic>.from(json['config'] as Map),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class HistoryRepository {
  static const _historyKey = 'cas_history_records_v1';
  static const _graphsKey = 'cas_graphs_sessions_v1';

  static Future<List<HistoryRecord>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List;
      final records = list
          .map((e) => HistoryRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return records;
    } catch (_) {
      return [];
    }
  }

  static Future<HistoryRecord> insertHistory({
    required String type,
    required String expression,
    required String result,
    Map<String, double>? variables,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getHistory();

    final newRecord = HistoryRecord(
      id: 'hist_${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      expression: expression,
      result: result,
      variables: variables,
      timestamp: DateTime.now(),
    );

    // Keep at most 200 recent history records to preserve storage on low-spec phones
    records.insert(0, newRecord);
    if (records.length > 200) {
      records.removeRange(200, records.length);
    }

    final encoded = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_historyKey, encoded);
    return newRecord;
  }

  static Future<void> deleteHistory(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getHistory();
    records.removeWhere((r) => r.id == id);
    final encoded = jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_historyKey, encoded);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  static Future<List<GraphSession>> getGraphs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_graphsKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List;
      final sessions = list
          .map((e) => GraphSession.fromJson(e as Map<String, dynamic>))
          .toList();
      sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return sessions;
    } catch (_) {
      return [];
    }
  }

  static Future<GraphSession> insertGraph({
    required String name,
    required String type,
    required List<String> formulas,
    required Map<String, dynamic> config,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await getGraphs();

    final newSession = GraphSession(
      id: 'graph_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      type: type,
      formulas: formulas,
      config: config,
      timestamp: DateTime.now(),
    );

    sessions.insert(0, newSession);
    final encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_graphsKey, encoded);
    return newSession;
  }

  static Future<void> deleteGraph(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await getGraphs();
    sessions.removeWhere((s) => s.id == id);
    final encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString(_graphsKey, encoded);
  }
}
