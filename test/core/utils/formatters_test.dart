import 'package:class_vision/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validates and formats CPF', () {
    expect(isValidCpf('52998224725'), isTrue);
    expect(isValidCpf('529.982.247-25'), isTrue);
    expect(isValidCpf('52998224724'), isFalse);
    expect(isValidCpf('111.111.111-11'), isFalse);
    expect(isValidCpf('123'), isFalse);
    expect(formatCpf('52998224725'), '529.982.247-25');
  });

  test('normalizes numeric and alphanumeric CNPJ', () {
    expect(normalizeCnpj('10.651.417/0005-00'), '10651417000500');
    expect(normalizeCnpj('12.abc.345/01de-35'), '12ABC34501DE35');
    expect(isValidCnpjFormat('12.ABC.345/01DE-35'), isTrue);
    expect(isValidCnpjFormat('12.345'), isFalse);
    expect(formatCnpj('10651417000500'), '10.651.417/0005-00');
  });

  test('validates and formats phones with DDD', () {
    expect(isValidPhone('(64) 3465-1900'), isTrue);
    expect(isValidPhone('64999998888'), isTrue);
    expect(isValidPhone('3465-1900'), isFalse);
    expect(formatPhone('6434651900'), '(64) 3465-1900');
    expect(formatPhone('64999998888'), '(64) 99999-8888');
  });

  test('parses and formats the dd/MM/yyyy dates used by the API', () {
    expect(parseBrDate('25/03/1990'), DateTime(1990, 3, 25));
    expect(parseBrDate('31/02/2026'), isNull);
    expect(parseBrDate('1990-03-25'), isNull);
    expect(formatBrDate(DateTime(1990, 3, 5)), '05/03/1990');
    expect(
      parseBrDateTime('12/11/2026 09:30:00'),
      DateTime(2026, 11, 12, 9, 30),
    );
  });

  test('masks digits while typing', () {
    final formatter = DigitMaskInputFormatter('###.###.###-##');
    TextEditingValue type(String text) => formatter.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: text),
    );

    expect(type('5299').text, '529.9');
    expect(type('52998224725').text, '529.982.247-25');
    expect(type('529.').text, '529');
    expect(type('529982247251234').text, '529.982.247-25');
  });
}
