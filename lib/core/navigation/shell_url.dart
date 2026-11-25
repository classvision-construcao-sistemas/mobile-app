import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_routes.dart';

/// Mantém a aba do painel no endereço da versão web (`#/home?aba=turmas`),
/// para o F5 e os links abrirem na mesma tela.
abstract final class ShellUrl {
  /// Abas do painel acadêmico (coordenador, professor...).
  static const academic = [
    'inicio',
    'turmas',
    'alunos',
    'professores',
    'chamadas',
    'relatorios',
    'perfil',
    'notificacoes',
  ];

  /// Abas do painel do administrador da instituição.
  static const institutionAdmin = [
    'inicio',
    'turmas',
    'alunos',
    'professores',
    'chamadas',
    'relatorios',
    'configuracoes',
  ];

  /// Abas do painel do administrador da instituição no celular.
  static const institutionAdminMobile = [
    'inicio',
    'turmas',
    'chamadas',
    'coordenadores',
    'mais',
  ];

  /// Abas do painel do administrador geral.
  static const systemAdmin = [
    'inicio',
    'instituicoes',
    'administradores',
    'atividade',
    'configuracoes',
  ];

  /// Posição da aba [tab] em [tabs], ou [fallback] se não existir.
  static int indexOf(List<String> tabs, String? tab, int fallback) {
    final index = tab == null ? -1 : tabs.indexOf(tab);
    return index < 0 ? fallback : index;
  }

  /// Troca o endereço sem criar uma entrada nova no histórico.
  static void show(List<String> tabs, int index) {
    if (!kIsWeb || index < 0 || index >= tabs.length) return;
    SystemNavigator.routeInformationUpdated(
      uri: Uri(path: AppRoutes.home, queryParameters: {'aba': tabs[index]}),
      replace: true,
    );
  }
}
