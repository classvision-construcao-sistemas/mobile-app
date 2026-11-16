import 'dart:convert';

import '../../core/utils/formatters.dart';

/// Perfis do cv-authentication-service, com o mesmo nível de privilégio da API.
enum UserRole {
  administrador('ADMINISTRADOR', 100, 'Administrador geral'),
  adminInstituicao('ADMIN_INSTITUICAO', 80, 'Administrador da instituição'),
  coordenador('COORDENADOR', 60, 'Coordenador de curso'),
  professor('PROFESSOR', 40, 'Professor'),
  secretario('SECRETARIO', 40, 'Secretário'),
  assistente('ASSISTENTE', 20, 'Assistente de coordenação');

  const UserRole(this.apiName, this.level, this.label);

  /// Nome enviado e recebido pela API (sempre em maiúsculas).
  final String apiName;

  /// Quanto maior, mais privilégio. Ninguém concede role acima do próprio nível.
  final int level;
  final String label;

  static UserRole? fromApi(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toUpperCase().replaceFirst('ROLE_', '');
    for (final role in UserRole.values) {
      if (role.apiName == normalized) return role;
    }
    return null;
  }

  bool get isGeneralAdmin => this == UserRole.administrador;

  /// Cadastra, edita, ativa, desativa e exclui usuários.
  bool get canManageUsers =>
      this == UserRole.administrador || this == UserRole.adminInstituicao;

  /// Lista e consulta usuários da instituição.
  bool get canViewUsers => canManageUsers || this == UserRole.coordenador;

  /// Cadastra, ativa e desativa instituições.
  bool get canManageInstitutions => this == UserRole.administrador;

  /// Edita os dados da instituição (o admin da instituição, só a própria).
  bool get canEditInstitution => canManageUsers;

  /// Roles que este perfil pode conceder a outros usuários.
  List<UserRole> get assignableRoles => canManageUsers
      ? UserRole.values.where((role) => role.level <= level).toList()
      : const [];

  String get permissionsSummary => switch (this) {
    UserRole.administrador => 'Todas as instituições, usuários e turmas',
    UserRole.adminInstituicao =>
      'Usuários e dados da instituição, turmas e chamadas',
    UserRole.coordenador =>
      'Consulta de usuários, turmas, chamadas e histórico',
    UserRole.professor ||
    UserRole.secretario ||
    UserRole.assistente => 'Turmas, chamadas e histórico',
  };
}

/// Lê o payload de um JWT sem validar a assinatura.
///
/// O front só usa esses dados para montar a interface; quem garante a
/// segurança é a API, que valida o token em toda requisição.
Map<String, dynamic> decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3 || parts[1].isEmpty) {
    throw const FormatException('Token JWT inválido.');
  }
  final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
  final decoded = jsonDecode(payload);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Token JWT inválido.');
  }
  return decoded;
}

/// Sessão do usuário logado, montada a partir do token devolvido no login.
class AuthSession {
  const AuthSession({
    required this.token,
    required this.tokenType,
    required this.expiresAt,
    required this.userId,
    required this.name,
    required this.email,
    required this.roleName,
    required this.institutionId,
  });

  /// [expiresInMs] vem da resposta do login e é contado a partir do relógio
  /// do aparelho, o que evita erros quando o relógio está adiantado ou
  /// atrasado em relação ao servidor. Sem ele, usa a claim `exp` do token.
  factory AuthSession.fromToken(
    String token, {
    String tokenType = 'Bearer',
    int? expiresInMs,
    DateTime? now,
  }) {
    final claims = decodeJwtPayload(token);
    final issuedAt = now ?? DateTime.now();
    final exp = asInt(claims['exp']);
    final DateTime expiresAt;
    if (expiresInMs != null && expiresInMs > 0) {
      expiresAt = issuedAt.add(Duration(milliseconds: expiresInMs));
    } else if (exp != null) {
      expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } else {
      expiresAt = issuedAt.add(const Duration(hours: 1));
    }

    return AuthSession(
      token: token,
      tokenType: tokenType.trim().isEmpty ? 'Bearer' : tokenType.trim(),
      expiresAt: expiresAt,
      userId: asInt(claims['id']),
      name: claims['nome']?.toString().trim() ?? '',
      email: (claims['email'] ?? claims['sub'])?.toString() ?? '',
      roleName: claims['role']?.toString() ?? '',
      institutionId: asInt(claims['instituicaoId']),
    );
  }

  final String token;
  final String tokenType;
  final DateTime expiresAt;
  final int? userId;
  final String name;
  final String email;
  final String roleName;
  final int? institutionId;

  UserRole? get role => UserRole.fromApi(roleName);

  String get roleLabel => role?.label ?? roleName;

  String get authorizationHeader => '$tokenType $token';

  bool isExpiredAt(DateTime moment) => !moment.isBefore(expiresAt);

  bool get isExpired => isExpiredAt(DateTime.now());

  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.first;
  }

  String get initials => initialsOf(name);
}

/// Usuário retornado pelas rotas `/api/usuarios`.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.cpf,
    required this.roleName,
    this.birthDate,
    this.institutionId,
    this.institutionName = '',
    this.createdAt,
    this.updatedAt,
    this.active = true,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: asInt(json['id']) ?? 0,
    name: json['nome']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    cpf: json['cpf']?.toString() ?? '',
    roleName: json['role']?.toString() ?? '',
    birthDate: parseBrDate(json['dataNascimento']?.toString()),
    institutionId: asInt(json['instituicaoId']),
    institutionName: json['instituicaoNome']?.toString() ?? '',
    createdAt: parseBrDateTime(json['criadoEm']?.toString()),
    updatedAt: parseBrDateTime(json['atualizadoEm']?.toString()),
    active: json['ativo'] != false,
  );

  final int id;
  final String name;
  final String email;
  final String cpf;
  final String roleName;
  final DateTime? birthDate;
  final int? institutionId;
  final String institutionName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool active;

  UserRole? get role => UserRole.fromApi(roleName);

  String get roleLabel => role?.label ?? roleName;

  /// Nível usado pela API para impedir escalada de privilégio (0 se desconhecido).
  int get roleLevel => role?.level ?? 0;

  String get initials => initialsOf(name);
}

/// Corpo de `cadastrar-usuario` e `atualizar-usuario` (atualização completa).
class UserPayload {
  const UserPayload({
    required this.name,
    required this.cpf,
    required this.email,
    required this.password,
    this.birthDate,
    this.roleName,
    this.institutionId,
  });

  final String name;
  final String cpf;
  final String email;

  /// A API sempre substitui a senha pelo valor enviado, inclusive na edição.
  final String password;
  final DateTime? birthDate;

  /// Omitido ou igual ao atual mantém a role.
  final String? roleName;

  /// Omitido mantém a instituição (o admin da instituição sempre omite).
  final int? institutionId;

  Map<String, dynamic> toJson() {
    final birth = birthDate;
    final role = roleName?.trim();
    final institution = institutionId;
    return {
      'nome': name.trim(),
      'cpf': onlyDigits(cpf),
      'email': email.trim(),
      'senha': password,
      if (birth != null) 'dataNascimento': formatBrDate(birth),
      if (role != null && role.isNotEmpty) 'role': role,
      'instituicaoId': ?institution,
    };
  }
}

/// Instituição retornada pelas rotas `/api/instituicoes`.
class Institution {
  const Institution({
    required this.id,
    required this.name,
    required this.cnpj,
    required this.phone,
    this.active = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Institution.fromJson(Map<String, dynamic> json) => Institution(
    id: asInt(json['id']) ?? 0,
    name: json['nome']?.toString() ?? '',
    cnpj: json['cnpj']?.toString() ?? '',
    phone: json['telefone']?.toString() ?? '',
    active: json['situacao']?.toString().toUpperCase() != 'INATIVA',
    createdAt: parseBrDateTime(json['criadoEm']?.toString()),
    updatedAt: parseBrDateTime(json['atualizadoEm']?.toString()),
  );

  final int id;
  final String name;
  final String cnpj;
  final String phone;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get formattedCnpj => formatCnpj(cnpj);

  String get formattedPhone => formatPhone(phone);
}

/// Corpo de `cadastrar-instituicao` e `atualizar-instituicao`.
class InstitutionPayload {
  const InstitutionPayload({
    required this.name,
    required this.cnpj,
    required this.phone,
  });

  final String name;
  final String cnpj;
  final String phone;

  Map<String, dynamic> toJson() => {
    'nome': name.trim(),
    'cnpj': normalizeCnpj(cnpj),
    'telefone': onlyDigits(phone),
  };
}

String initialsOf(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2);
  return parts.map((part) => part[0].toUpperCase()).join();
}
