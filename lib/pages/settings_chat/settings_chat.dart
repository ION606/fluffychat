import 'package:fluffychat/config/setting_keys.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_ok_cancel_alert_dialog.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_text_input_dialog.dart';
import 'package:flutter/material.dart';

import 'settings_chat_view.dart';

class SettingsChat extends StatefulWidget {
  const SettingsChat({super.key});

  @override
  SettingsChatController createState() => SettingsChatController();
}

class SettingsChatController extends State<SettingsChat> {
  Future<void> toggleEncryptedPreviews(bool newValue) async {
    if (newValue) {
      final result = await showOkCancelAlertDialog(
        context: context,
        title: L10n.of(context).linkPreviewsInEncrypted,
        message: L10n.of(context).linkPreviewsInEncryptedWarning,
        isDestructive: true,
        okLabel: L10n.of(context).ok,
        cancelLabel: L10n.of(context).cancel,
      );
      if (result != OkCancelResult.ok) return;
    }
    await AppSettings.linkPreviewsInEncrypted.setItem(newValue);
    setState(() {});
  }

  Future<void> editProxyUrl() async {
    final currentProxy = AppSettings.linkPreviewProxy.value;
    final result = await showTextInputDialog(
      context: context,
      title: L10n.of(context).linkPreviewProxy,
      message: L10n.of(context).linkPreviewProxyDescription,
      hintText: 'https://proxy.example.com/preview',
      initialText: currentProxy.isEmpty ? null : currentProxy,
      keyboardType: TextInputType.url,
      autocorrect: false,
    );
    if (result == null) return;
    await AppSettings.linkPreviewProxy.setItem(result.trim());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => SettingsChatView(this);
}
