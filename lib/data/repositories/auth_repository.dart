import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';
import '../services/auth_api.dart';
import '../services/session_store.dart';

/// Sessão do usuário e acesso às rotas protegidas do cv-authentication-service.
///
/// O token fica em memória e, na web, também no `sessionStorage` da aba
/// ([SessionStore]), para o login sobreviver ao F5. Ao fechar a aba ou o app,
/// ou quando o token expira (1 hora), é preciso entrar de novo. Qualquer
/// `401` de uma rota protegida encerra a sessão.
class AuthRepository extends ChangeNotifier {
  AuthRepository({required this.api, SessionStore? store})
    : _store = store ?? MemorySessionStore() {
    _restore();
  }

  final AuthApi api;
  final SessionStore _store;

  AuthSession? _session;
  Institution? _institution;
  String? _logoutReason;
  bool _disposed = false;

  AuthSession? get session => _session;

  bool get isAuthenticated {
    final session = _session;
    return session != null && !session.isExpired;
  }

  UserRole? get role => _session?.role;

  /// Instituição do usuário logado (carregada logo após o login).
  Institution? get institution => _institution;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final session = await api.login(email: email, password: password);
    final institutionChanged = _session?.institutionId != session.institutionId;
    _session = session;
    _save(session);
    if (institutionChanged) _institution = null;
    _logoutReason = null;
    notifyListeners();
    unawaited(refreshInstitution());
    return session;
  }

  /// Descarta o token. Não existe logout no servidor.
  void logout({String? reason}) {
    if (_session == null) return;
    _session = null;
    _store.clear();
    _institution = null;
    _logoutReason = reason;
    notifyListeners();
  }

  void _save(AuthSession session) => _store.write(
    jsonEncode({
      'token': session.token,
      'tipo': session.tokenType,
      'expiraEm': session.expiresAt.toIso8601String(),
    }),
  );

  /// Retoma a sessão salva (ex.: depois de recarregar a página).
  void _restore() {
    try {
      final raw = _store.read();
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(json['expiraEm'] as String);
      final remaining = expiresAt.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        _store.clear();
        return;
      }
      _session = AuthSession.fromToken(
        json['token'] as String,
        tokenType: json['tipo'] as String? ?? 'Bearer',
        expiresInMs: remaining.inMilliseconds,
      );
      unawaited(refreshInstitution());
    } catch (_) {
      _store.clear();
    }
  }

  /// Motivo do último logout automático (sessão expirada, token recusado...).
  String? consumeLogoutReason() {
    final reason = _logoutReason;
    _logoutReason = null;
    return reason;
  }

  /// Encerra a sessão se o token já expirou. Retorna se ela continua válida.
  bool ensureValidSession() {
    final session = _session;
    if (session == null) return false;
    if (session.isExpired) {
      logout(reason: 'Sua sessão expirou. Entre novamente.');
      return false;
    }
    return true;
  }

  Future<void> refreshInstitution() async {
    final id = _session?.institutionId;
    if (id == null) return;
    try {
      final institution = await _authorized(
        (session) => api.getInstitution(session, id),
      );
      if (_disposed || _session?.institutionId != id) return;
      _institution = institution;
      notifyListeners();
    } on AuthApiException {
      // O perfil continua funcionando só com os dados do token.
    }
  }

  // ------------------------------------------------------------ Permissões

  bool isCurrentUser(AppUser user) =>
      _session?.userId != null && user.id == _session?.userId;

  /// Espelha as regras da API: mesma instituição (exceto o admin geral) e
  /// alvo com nível igual ou menor que o do usuário logado.
  bool canManageUser(AppUser user) {
    final session = _session;
    final role = session?.role;
    if (session == null || role == null || !role.canManageUsers) return false;
    if (!role.isGeneralAdmin && user.institutionId != session.institutionId) {
      return false;
    }
    return user.roleLevel <= role.level;
  }

  // -------------------------------------------------------------- Usuários

  Future<List<AppUser>> listUsers() => _authorized(api.listUsers);

  Future<AppUser> getUser(int id) =>
      _authorized((session) => api.getUser(session, id));

  Future<AppUser> createUser(UserPayload payload) =>
      _authorized((session) => api.createUser(session, payload));

  /// Atualiza um usuário. Quando o alvo é o próprio usuário logado, entra de
  /// novo com os dados enviados: o token guarda nome/e-mail do momento do
  /// login, e trocar o e-mail invalida o token anterior.
  Future<AppUser> updateUser(int id, UserPayload payload) async {
    final isSelf = id == _session?.userId;
    final updated = await _authorized(
      (session) => api.updateUser(session, id, payload),
    );
    if (isSelf) {
      try {
        await login(email: payload.email, password: payload.password);
      } on AuthApiException {
        logout(reason: 'Seus dados foram atualizados. Entre novamente.');
      }
    }
    return updated;
  }

  Future<AppUser> setUserActive(int id, {required bool active}) => _authorized(
    (session) => active
        ? api.activateUser(session, id)
        : api.deactivateUser(session, id),
  );

  Future<void> deleteUser(int id) =>
      _authorized((session) => api.deleteUser(session, id));

  // ---------------------------------------------------------- Instituições

  Future<List<Institution>> listInstitutions() =>
      _authorized(api.listInstitutions);

  Future<Institution> getInstitution(int id) =>
      _authorized((session) => api.getInstitution(session, id));

  Future<Institution> createInstitution(InstitutionPayload payload) =>
      _authorized((session) => api.createInstitution(session, payload));

  Future<Institution> updateInstitution(
    int id,
    InstitutionPayload payload,
  ) async => _rememberOwnInstitution(
    await _authorized((session) => api.updateInstitution(session, id, payload)),
  );

  Future<Institution> setInstitutionActive(
    int id, {
    required bool active,
  }) async => _rememberOwnInstitution(
    await _authorized(
      (session) => active
          ? api.activateInstitution(session, id)
          : api.deactivateInstitution(session, id),
    ),
  );

  // --------------------------------------------------------------- Interno

  Institution _rememberOwnInstitution(Institution institution) {
    if (institution.id == _session?.institutionId) {
      _institution = institution;
      notifyListeners();
    }
    return institution;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<T> _authorized<T>(
    Future<T> Function(AuthSession session) request,
  ) async {
    final session = _session;
    if (session == null || !ensureValidSession()) {
      throw const AuthApiException(
        'Sua sessão expirou. Entre novamente.',
        statusCode: 401,
      );
    }
    try {
      return await request(session);
    } on AuthApiException catch (error) {
      if (error.isUnauthorized && identical(_session, session)) {
        logout(reason: 'Sua sessão foi encerrada. Entre novamente.');
      }
      rethrow;
    }
  }
}
