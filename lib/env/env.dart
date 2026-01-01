import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'GOOGLE_FORM_URL', obfuscate: true)
  static final String googleFormUrl = _Env.googleFormUrl;

  @EnviedField(varName: 'ENTRY_QUESTION_ID', obfuscate: true)
  static final String entryQuestionId = _Env.entryQuestionId;

  @EnviedField(varName: 'ENTRY_COMMENT', obfuscate: true)
  static final String entryComment = _Env.entryComment;
}
