import 'package:flutter/material.dart';
import 'package:fomo_connect/src/database/auth/auth_service.dart';

class TelephoneScreen extends StatefulWidget {
  const TelephoneScreen({super.key});

  @override
  State<TelephoneScreen> createState() => _TelephoneScreenState();
}

class _TelephoneScreenState extends State<TelephoneScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _loading = false;

  Future<void> _sendCode() async {
    if (_phoneController.text.isEmpty) return;
    setState(() => _loading = true);

await AuthService()
        .sendCode("+${_phoneController.text.trim()}", context);

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Verify Phone",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [IconButton(onPressed: () {print(AuthService().user!.phoneNumber);}, icon: Icon(Icons.question_answer))],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              const Text(
                "Enter your phone number",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "We’ll send you an SMS verification code",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 32),

              // Input field
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  hintText: "Phone number",
                  prefixIcon: const Icon(Icons.phone),
                  prefixText: "+",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              // Send Code button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _sendCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Send Code",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
