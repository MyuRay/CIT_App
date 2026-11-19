import 'package:flutter/material.dart';
import 'contact_chat_screen.dart';

/// Keep existing navigation entry points opening the user's single chat.
class ContactFormScreen extends StatelessWidget {
  const ContactFormScreen({super.key});
  @override
  Widget build(BuildContext context) => const ContactChatScreen();
}
