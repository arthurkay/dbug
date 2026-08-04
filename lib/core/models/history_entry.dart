import 'package:freezed_annotation/freezed_annotation.dart';

part 'history_entry.freezed.dart';
part 'history_entry.g.dart';

@freezed
class HistoryEntry with _$HistoryEntry {
  const factory HistoryEntry({
    required String id,
    String? requestId,
    required String method,
    required String url,
    int? statusCode,
    int? responseTimeMs,
    int? responseSize,
    String? responseBody,
    required DateTime sentAt,
    String? requestName,
    String? collectionId,
    @Default('{}') String headers,
    @Default('{}') String collectionHeaders,
    String? body,
    String? bodyType,
    @Default('{}') String queryParams,
    @Default('none') String authType,
    @Default('{}') String authData,
  }) = _HistoryEntry;

  factory HistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$HistoryEntryFromJson(json);
}
