import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../features/shared_settings/shared_settings_app_config.dart';
import '../../../../features/shared_settings/shared_settings_message_service.dart';
import '../../../../features/shared_settings/shared_settings_models.dart';
import 'shared_settings_section_styles.dart';

class SettingsSharedContactSection extends StatefulWidget {
  const SettingsSharedContactSection({super.key});

  @override
  State<SettingsSharedContactSection> createState() =>
      _SettingsSharedContactSectionState();
}

class _SettingsSharedContactSectionState
    extends State<SettingsSharedContactSection> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final SharedSettingsMessageService _messageService =
      SharedSettingsMessageService();
  bool _sending = false;
  bool _awaitingReply = false;
  late String _selectedTopic;

  @override
  void initState() {
    super.initState();
    _selectedTopic = _topics.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  List<String> get _topics {
    final topics = kSharedSettingsAppConfig.contact.topics
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return topics.isNotEmpty
        ? topics
        : const <String>[
            'Oneri / Geri Bildirim',
            'Hata Bildirimi',
            'Talepler',
            'Diger',
          ];
  }

  @override
  Widget build(BuildContext context) {
    final config = kSharedSettingsAppConfig;
    return SharedSettingsSectionCard(
      title: 'Bize Ulasin',
      headerColor: sharedSettingsContactHeader,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 14, 15, 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedTopic,
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'Konu',
                        border: OutlineInputBorder(),
                      ),
                      items: _topics
                          .map(
                            (topic) => DropdownMenuItem<String>(
                              value: topic,
                              child: Text(topic),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedTopic = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() => _awaitingReply = !_awaitingReply);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: _awaitingReply,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: (value) {
                            setState(() => _awaitingReply = value ?? true);
                          },
                        ),
                        const Text('Cevap bekliyorum'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Isim *',
                  border: OutlineInputBorder(),
                  isDense: true,
                  counterText: '',
                ),
                validator: _validateName,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                maxLength: 254,
                decoration: const InputDecoration(
                  labelText: 'E-posta *',
                  border: OutlineInputBorder(),
                  isDense: true,
                  counterText: '',
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _messageController,
                minLines: 4,
                maxLines: 6,
                maxLength: 300,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                inputFormatters: [LengthLimitingTextInputFormatter(300)],
                decoration: const InputDecoration(
                  labelText: 'Mesajiniz *',
                  helperText: 'En az 10 karakter',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: _validateMessage,
              ),
              const SizedBox(height: 8),
              Text(config.contact.responsePolicyText),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openUrl(
                      _mailtoUrl(config),
                      failMessage: 'E-posta uygulamasi acilamadi.',
                    ),
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('E-posta Gonder'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _openUrl(
                      config.contact.supportFormUrl,
                      failMessage: 'Destek formu acilamadi.',
                    ),
                    icon: const Icon(Icons.forum_outlined),
                    label: const Text('Destek Formu'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_sending ? 'Gonderiliyor...' : 'Gonder'),
                ),
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              StreamBuilder<List<SharedSettingsUserMessage>>(
                stream: _messageService.watchRecentMessages(),
                builder: (context, snapshot) {
                  final messages =
                      snapshot.data ?? const <SharedSettingsUserMessage>[];
                  final loading =
                      snapshot.connectionState == ConnectionState.waiting;
                  if (loading && messages.isEmpty) {
                    return const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  if (messages.isEmpty) {
                    return const Text(
                      'Henuz gonderilmis mesaj yok.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    );
                  }
                  return _RecentMessagesList(messages: messages);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _mailtoUrl(SharedSettingsAppConfig config) {
    final subject = Uri.encodeComponent(
      '${config.appName} - ${config.contact.supportFormTopic}',
    );
    final body = Uri.encodeComponent(config.contact.supportFormMessage);
    return 'mailto:${config.contact.email}?subject=$subject&body=$body';
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);

    final packageInfo = await PackageInfo.fromPlatform();
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString('anonymous_device_id');
    if (deviceId == null || deviceId.trim().isEmpty) {
      deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('anonymous_device_id', deviceId);
    }

    final result = await _messageService.sendMessage(
      topic: _selectedTopic,
      senderName: _nameController.text.trim(),
      senderEmail: _emailController.text.trim().toLowerCase(),
      message: _messageController.text.trim(),
      replyContact: _emailController.text.trim().toLowerCase(),
      awaitingReply: _awaitingReply,
      appVersion: packageInfo.version,
      anonymousDeviceId: deviceId,
      isTestDevice: false,
      technicalSummary: <String, dynamic>{},
    );

    if (!mounted) return;
    setState(() => _sending = false);

    if (!result.success) {
      _showSnack(
        result.errorMessage?.trim().isNotEmpty == true
            ? result.errorMessage!
            : 'Mesaj gonderilemedi.',
      );
      return;
    }

    _nameController.clear();
    _emailController.clear();
    _messageController.clear();
    _showSnack('Gonderildi');
  }

  String? _validateName(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < 2) return 'Isim en az 2 karakter olmali.';
    if (text.length > 80) return 'Isim en fazla 80 karakter olabilir.';
    return null;
  }

  String? _validateEmail(String? value) {
    final text = value?.trim().toLowerCase() ?? '';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
    if (!valid) return 'Gecerli bir e-posta girin.';
    if (text.length > 254) return 'E-posta en fazla 254 karakter olabilir.';
    return null;
  }

  String? _validateMessage(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < 10) return 'Mesaj en az 10 karakter olmali.';
    if (text.length > 300) return 'Mesaj en fazla 300 karakter olabilir.';
    return null;
  }

  Future<void> _openUrl(String rawUrl, {required String failMessage}) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) {
      _showSnack(failMessage);
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      _showSnack(failMessage);
    }
  }

  void _showSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RecentMessagesList extends StatelessWidget {
  final List<SharedSettingsUserMessage> messages;

  const _RecentMessagesList({required this.messages});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Gonderdiginiz Mesajlar',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _RecentMessageCard(message: messages[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentMessageCard extends StatelessWidget {
  final SharedSettingsUserMessage message;

  const _RecentMessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final createdAt = message.createdAt;
    final dateText = createdAt == null
        ? ''
        : '${createdAt.day.toString().padLeft(2, '0')}.${createdAt.month.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    final seen = message.adminSeen || message.status != 'new';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD8D8D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  message.topic,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (message.awaitingReply) ...[
                const SizedBox(width: 8),
                const Text(
                  'Cevap bekleniyor',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
              const SizedBox(width: 8),
              Icon(
                seen ? Icons.done_all_rounded : Icons.done_rounded,
                size: 16,
                color: seen ? const Color(0xFF2E7D32) : Colors.black45,
              ),
              const SizedBox(width: 3),
              Text(
                seen ? 'Goruldu' : 'Iletildi',
                style: TextStyle(
                  fontSize: 12,
                  color: seen ? const Color(0xFF2E7D32) : Colors.black54,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateText,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(message.message, maxLines: 2, overflow: TextOverflow.ellipsis),
          if (message.adminReply != null &&
              message.adminReply!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3EA),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Cevap: ${message.adminReply}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

