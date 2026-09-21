import 'package:flutter/material.dart';
import '../../core/common/core.dart';
import '../services/api_service.dart';

/// Shared "Server Address" dialog — lets the user view/edit/test the
/// backend URL at runtime (persisted via ApiService), without a rebuild.
/// Reachable both pre-login (Welcome/Security screens) and post-login
/// (Privacy Settings), since a bad address can strike before login too.
void showServerSettingsDialog(BuildContext context) {
  final controller = TextEditingController(text: ApiService.currentBaseUrl);
  bool testing = false;
  String? resultMessage;
  bool? resultOk;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: const Text('Server Address'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Point the app at your backend, e.g. http://192.168.1.23:3000. '
                  'Saved on this device so it survives your PC\'s Wi-Fi IP '
                  'changing — no rebuild needed.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textGrey,
                    fontSize: 11.sp,
                  ),
                ),
                12.verticalSpace,
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    hintText: 'https://backend-mu-tawny-16.vercel.app',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    isDense: true,
                  ),
                ),
                if (resultMessage != null) ...[
                  8.verticalSpace,
                  Text(
                    resultMessage!,
                    style: AppTextStyles.caption.copyWith(
                      color: resultOk == true
                          ? Colors.green
                          : AppColors.errorRed,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: testing
                    ? null
                    : () async {
                        setDialogState(() {
                          testing = true;
                          resultMessage = null;
                        });
                        final ok = await ApiService.testConnection(
                          url: controller.text.trim(),
                        );
                        setDialogState(() {
                          testing = false;
                          resultOk = ok;
                          resultMessage = ok
                              ? 'Connected successfully ✅'
                              : 'Could not reach that address ❌';
                        });
                      },
                child: Text(testing ? 'Testing…' : 'Test Connection'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final url = controller.text.trim();
                  if (url.isEmpty) return;
                  await ApiService.setBaseUrl(url);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}
