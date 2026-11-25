import 'package:web/web.dart' as web;

import 'session_store.dart';

SessionStore createSessionStore() => _BrowserSessionStore();

class _BrowserSessionStore implements SessionStore {
  static const _key = 'classvision.session';

  @override
  String? read() {
    try {
      return web.window.sessionStorage.getItem(_key);
    } catch (_) {
      return null;
    }
  }

  @override
  void write(String value) {
    try {
      web.window.sessionStorage.setItem(_key, value);
    } catch (_) {
      // Navegação privada sem armazenamento: o login só não sobrevive ao F5.
    }
  }

  @override
  void clear() {
    try {
      web.window.sessionStorage.removeItem(_key);
    } catch (_) {}
  }
}
