import 'package:class_vision/core/config/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the services published on Railway by default', () {
    expect(ApiConfig.gatewayUrl, isNull);
    expect(ApiConfig.authBaseUrl, ApiConfig.defaultAuthBaseUrl);
    expect(ApiConfig.turmaBaseUrl, ApiConfig.defaultTurmaBaseUrl);
    expect(ApiConfig.auditoriaBaseUrl, ApiConfig.defaultAuditoriaBaseUrl);
    expect(ApiConfig.facialRecognitionBaseUrl, ApiConfig.defaultFacialBaseUrl);
    for (final url in [
      ApiConfig.authBaseUrl,
      ApiConfig.turmaBaseUrl,
      ApiConfig.auditoriaBaseUrl,
      ApiConfig.facialRecognitionBaseUrl,
    ]) {
      expect(url, startsWith('https://'));
      expect(url, endsWith('.up.railway.app'));
    }
  });
}
