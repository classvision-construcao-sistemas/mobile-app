import 'package:flutter/services.dart';

/// Formatos usados pelo cv-authentication-service e documentos brasileiros.

String onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

int? asInt(Object? value) => switch (value) {
  final int number => number,
  final num number => number.toInt(),
  final String text => int.tryParse(text.trim()),
  _ => null,
};

/// CPF com dígitos verificadores válidos (com ou sem pontuação).
bool isValidCpf(String value) {
  final digits = onlyDigits(value);
  if (digits.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(digits)) {
    return false;
  }
  final numbers = digits.split('').map(int.parse).toList();
  for (var position = 9; position < 11; position++) {
    var sum = 0;
    for (var index = 0; index < position; index++) {
      sum += numbers[index] * (position + 1 - index);
    }
    if ((sum * 10) % 11 % 10 != numbers[position]) return false;
  }
  return true;
}

String formatCpf(String value) {
  final digits = onlyDigits(value);
  if (digits.length != 11) return value;
  return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.'
      '${digits.substring(6, 9)}-${digits.substring(9)}';
}

/// CNPJ sem pontuação e em maiúsculas (aceita o formato alfanumérico).
String normalizeCnpj(String value) =>
    value.toUpperCase().replaceAll(RegExp(r'[^0-9A-Z]'), '');

/// Confere apenas o formato; os dígitos verificadores são validados pela API.
bool isValidCnpjFormat(String value) =>
    RegExp(r'^[0-9A-Z]{12}\d{2}$').hasMatch(normalizeCnpj(value));

String formatCnpj(String value) {
  final cnpj = normalizeCnpj(value);
  if (cnpj.length != 14) return value;
  return '${cnpj.substring(0, 2)}.${cnpj.substring(2, 5)}.'
      '${cnpj.substring(5, 8)}/${cnpj.substring(8, 12)}-${cnpj.substring(12)}';
}

/// DDD + número, com 10 ou 11 dígitos.
bool isValidPhone(String value) {
  final digits = onlyDigits(value);
  return digits.length == 10 || digits.length == 11;
}

String formatPhone(String value) {
  final digits = onlyDigits(value);
  return switch (digits.length) {
    10 =>
      '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-'
          '${digits.substring(6)}',
    11 =>
      '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-'
          '${digits.substring(7)}',
    _ => value,
  };
}

/// Data no formato `dd/MM/yyyy`, o único aceito pela API.
DateTime? parseBrDate(String? value) {
  final match = RegExp(
    r'^(\d{2})/(\d{2})/(\d{4})$',
  ).firstMatch(value?.trim() ?? '');
  if (match == null) return null;
  final day = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final year = int.parse(match.group(3)!);
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return null;
  }
  return date;
}

/// Data e hora no formato `dd/MM/yyyy HH:mm:ss` devolvido pela API.
DateTime? parseBrDateTime(String? value) {
  final match = RegExp(
    r'^(\d{2})/(\d{2})/(\d{4})[ T](\d{2}):(\d{2})(?::(\d{2}))?$',
  ).firstMatch(value?.trim() ?? '');
  if (match == null) return null;
  return DateTime(
    int.parse(match.group(3)!),
    int.parse(match.group(2)!),
    int.parse(match.group(1)!),
    int.parse(match.group(4)!),
    int.parse(match.group(5)!),
    int.parse(match.group(6) ?? '0'),
  );
}

String formatBrDate(DateTime date) =>
    '${_twoDigits(date.day)}/${_twoDigits(date.month)}/'
    '${date.year.toString().padLeft(4, '0')}';

String formatBrDateTime(DateTime date) =>
    '${formatBrDate(date)} ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';

String _twoDigits(int value) => value.toString().padLeft(2, '0');

/// Aplica uma máscara numérica enquanto o usuário digita (`#` = dígito).
class DigitMaskInputFormatter extends TextInputFormatter {
  DigitMaskInputFormatter(this.mask);

  final String mask;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = onlyDigits(newValue.text);
    final buffer = StringBuffer();
    var index = 0;
    for (var i = 0; i < mask.length && index < digits.length; i++) {
      if (mask[i] == '#') {
        buffer.write(digits[index++]);
      } else {
        buffer.write(mask[i]);
      }
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
