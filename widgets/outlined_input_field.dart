import 'package:flutter/material.dart';

enum TextFieldType {
  text,
  password,
  email,
}
class OutlinedInputField extends StatelessWidget {
  const OutlinedInputField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.type = TextFieldType.text,
    this.validator
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final TextFieldType type;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final isPassword = type == TextFieldType.password;

    return TextFormField(
      controller: controller,
      validator: validator,
      textInputAction: TextInputAction.search,
      // validator: validator,
      style: const TextStyle(
        color: Color(0xFF1A2B47),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      obscureText: isPassword,
      enableSuggestions: !isPassword,
      autocorrect: !isPassword,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF40556C), fontSize: 13),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF162F48),
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFC6D2DE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFC6D2DE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFC6D2DE), width: 1.5),
        ),
      ),
    );
  }
}
