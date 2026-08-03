import 'package:freezed_annotation/freezed_annotation.dart';

part 'environment_model.freezed.dart';
part 'environment_model.g.dart';

@freezed
class Environment with _$Environment {
  const factory Environment({
    required String id,
    required String name,
    @Default({}) Map<String, String> variables,
    @Default(false) bool isActive,
  }) = _Environment;

  factory Environment.fromJson(Map<String, dynamic> json) =>
      _$EnvironmentFromJson(json);
}
