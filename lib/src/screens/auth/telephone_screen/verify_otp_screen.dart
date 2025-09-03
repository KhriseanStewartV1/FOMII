import 'package:flutter/material.dart';
import 'package:fomo_connect/src/database/auth/auth_service.dart';
import 'package:fomo_connect/src/widgets/misc.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String telephone;
  final String verificationId;

  const VerifyOtpScreen({
    super.key,
    required this.telephone,
    required this.verificationId,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _loading = false;

  Future<void> _verifyCode() async {
    if (_otpController.text.length != 6) return;
    setState(() => _loading = true);

    final cred = await AuthService().verifyTelephone(
      context,
      widget.verificationId,
      _otpController.text.trim(),
      widget.telephone,
    );

    setState(() => _loading = false);

    if (cred != null) {
      Navigator.pop(context); // close OTP screen
      displayRoundedSnackBar(context, "Phone Verified ✅");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text("Verify Code")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Enter the 6-digit code sent to ${widget.telephone}",
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            PinCodeTextField(
              appContext: context,
              length: 6,
              controller: _otpController,
              keyboardType: TextInputType.number,
              animationType: AnimationType.fade,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(8),
                fieldHeight: 50,
                fieldWidth: 45,
                activeFillColor: Colors.white,
                inactiveFillColor: Colors.grey.shade200,
                selectedFillColor: Colors.grey.shade100,
                activeColor: Colors.blue,
                inactiveColor: Colors.grey,
                selectedColor: Colors.blueAccent,
              ),
              animationDuration: const Duration(milliseconds: 300),
              enableActiveFill: true,
              onChanged: (value) {},
            ),
            const SizedBox(height: 30),
            _loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _verifyCode,
                      child: const Text("Verify"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
