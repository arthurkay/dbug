import 'package:freezed_annotation/freezed_annotation.dart';

part 'environment_model.freezed.dart';
part 'environment_model.g.dart';

@freezed
class Environment with _$Environment {
  const Environment._();

  const factory Environment({
    required String id,
    required String name,
    @Default({}) Map<String, String> variables,
    @Default(false) bool isActive,
    @Default('user') String sourceType,
    String? sourceSpecId,
  }) = _Environment;

  factory Environment.fromJson(Map<String, dynamic> json) =>
      _$EnvironmentFromJson(json);

  bool get isUserDefined => sourceType == 'user';
  bool get isOpenApiDefined => sourceType == 'openapi';
}
