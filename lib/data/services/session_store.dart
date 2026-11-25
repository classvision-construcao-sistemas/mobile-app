import 'session_store_memory.dart'
    if (dart.library.js_interop) 'session_store_web.dart'
    as platform;

/// Onde a sessão (token) sobrevive a um recarregamento da página.
///
/// Na web usa o `sessionStorage` da aba: o login continua depois do F5, mas
/// some ao fechar a aba, sem ficar gravado no navegador. Nos apps nativos o
/// token segue só em memória, como recomenda o serviço de autenticação.
abstract class SessionStore {
  String? read();
  void write(String value);
  void clear();

  /// Armazenamento da plataforma atual.
  factory SessionStore.platform() => platform.createSessionStore();
}

/// Guarda só em memória (padrão dos testes e dos apps nativos).
class MemorySessionStore implements SessionStore {
  String? _value;

  @override
  String? read() => _value;

  @override
  void write(String value) => _value = value;

  @override
  void clear() => _value = null;
}
