import 'shared_settings_models.dart';

class SharedSettingsMessageService {
  bool get isReady => false;

  Future<SharedSettingsSendMessageResult> sendMessage({
    required String topic,
    required String senderName,
    required String senderEmail,
    required String message,
    required String replyContact,
    required bool awaitingReply,
    required String appVersion,
    required String anonymousDeviceId,
    required bool isTestDevice,
    required Map<String, dynamic> technicalSummary,
  }) async {
    return const SharedSettingsSendMessageResult(
      success: false,
      errorMessage: 'Uygulama ici mesaj gonderimi su an aktif degil.',
    );
  }

  Stream<List<SharedSettingsUserMessage>> watchRecentMessages({
    int limit = 5,
  }) async* {
    yield const <SharedSettingsUserMessage>[];
  }
}
