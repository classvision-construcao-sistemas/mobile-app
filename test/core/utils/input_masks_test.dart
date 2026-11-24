import 'package:class_vision/core/utils/formatters.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

String type(TextInputFormatter formatter, String text) => formatter
    .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text))
    .text;

void main() {
  group('PhoneInputFormatter', () {
    final formatter = PhoneInputFormatter();

    test('formats landlines and cell phones while typing', () {
      expect(type(formatter, '64'), '(64');
      expect(type(formatter, '6434651900'), '(64) 3465-1900');
      expect(type(formatter, '64999990000'), '(64) 99999-0000');
    });

    test('ignores letters and extra digits', () {
      expect(type(formatter, '(64) 9a9999-00001234'), '(64) 99999-0000');
    });

    test('produces values the API accepts', () {
      expect(isValidPhone(type(formatter, '6434651900')), isTrue);
      expect(
        RegExp(r'^\(?\d{2}\)?\s?\d{4,5}-?\d{4}$')
            .hasMatch(type(formatter, '64999990000')),
        isTrue,
      );
    });
  });

  group('CnpjInputFormatter', () {
    final formatter = CnpjInputFormatter();

    test('formats numeric CNPJ while typing', () {
      expect(type(formatter, '10651417'), '10.651.417');
      expect(type(formatter, '10651417000500'), '10.651.417/0005-00');
    });

    test('accepts the alphanumeric CNPJ in upper case', () {
      expect(type(formatter, '12abc34501de35'), '12.ABC.345/01DE-35');
      expect(isValidCnpjFormat(type(formatter, '12abc34501de35')), isTrue);
    });

    test('check digits are numeric and the length is capped', () {
      expect(type(formatter, '12ABC34501DEXY35999'), '12.ABC.345/01DE-35');
    });
  });
}
