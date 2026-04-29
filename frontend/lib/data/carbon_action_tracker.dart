import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CarbonActionItem {
  final String id;
  final String businessType;
  final String actionText;
  final String stepNumber;
  bool isCompleted;
  DateTime? completedAt;
  String? userNote;

  CarbonActionItem({
    required this.id,
    required this.businessType,
    required this.actionText,
    required this.stepNumber,
    this.isCompleted = false,
    this.completedAt,
    this.userNote,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'businessType': businessType,
    'actionText': actionText,
    'stepNumber': stepNumber,
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
    'userNote': userNote,
  };

  factory CarbonActionItem.fromJson(Map<String, dynamic> json) => CarbonActionItem(
    id: json['id'],
    businessType: json['businessType'],
    actionText: json['actionText'],
    stepNumber: json['stepNumber'],
    isCompleted: json['isCompleted'] ?? false,
    completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    userNote: json['userNote'],
  );
}

class CarbonActionTracker {
  static const String _storageKey = 'carbon_action_items';

  Future<void> saveActions(List<CarbonActionItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final existingItems = await _getAllItems();
    
    // Merge existing states if IDs match
    for (var newItem in items) {
      final existingIndex = existingItems.indexWhere((e) => e.id == newItem.id);
      if (existingIndex != -1) {
        newItem.isCompleted = existingItems[existingIndex].isCompleted;
        newItem.completedAt = existingItems[existingIndex].completedAt;
        newItem.userNote = existingItems[existingIndex].userNote;
        existingItems[existingIndex] = newItem;
      } else {
        existingItems.add(newItem);
      }
    }

    final encoded = jsonEncode(existingItems.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> markComplete(String id, {String? note}) async {
    final items = await _getAllItems();
    final index = items.indexWhere((e) => e.id == id);
    if (index != -1) {
      items[index].isCompleted = true;
      items[index].completedAt = DateTime.now();
      if (note != null) items[index].userNote = note;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(items.map((e) => e.toJson()).toList()));
    }
  }

  Future<void> markIncomplete(String id) async {
    final items = await _getAllItems();
    final index = items.indexWhere((e) => e.id == id);
    if (index != -1) {
      items[index].isCompleted = false;
      items[index].completedAt = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(items.map((e) => e.toJson()).toList()));
    }
  }

  Future<void> updateNote(String id, String note) async {
    final items = await _getAllItems();
    final index = items.indexWhere((e) => e.id == id);
    if (index != -1) {
      items[index].userNote = note;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(items.map((e) => e.toJson()).toList()));
    }
  }

  Future<List<CarbonActionItem>> getActionsForSector(String sector) async {
    final items = await _getAllItems();
    return items.where((e) => e.businessType == sector).toList();
  }

  Future<double> calculateCompletionRate(String sector) async {
    final items = await getActionsForSector(sector);
    if (items.isEmpty) return 0.0;
    
    int completed = items.where((e) => e.isCompleted).length;
    return completed / items.length;
  }

  Future<void> resetPlan(String sector) async {
    final items = await _getAllItems();
    bool modified = false;
    for (var i = 0; i < items.length; i++) {
      if (items[i].businessType == sector) {
        items[i].isCompleted = false;
        items[i].completedAt = null;
        items[i].userNote = null;
        modified = true;
      }
    }
    
    if (modified) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(items.map((e) => e.toJson()).toList()));
    }
  }

  Future<List<CarbonActionItem>> _getAllItems() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => CarbonActionItem.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }
}
