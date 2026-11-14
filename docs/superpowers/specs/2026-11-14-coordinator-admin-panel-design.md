# Painel administrativo responsivo para coordenadores — design

## Intenção

Criar um conjunto de telas completas, em SVG e prontas para importação no Figma, para o painel administrativo do ClassVision. O painel será operado por coordenadores de instituições de ensino para acompanhar e administrar dados acadêmicos e as chamadas realizadas pelo aplicativo mobile.

## Objetivos

- Entregar um painel único responsivo, com composição desktop e mobile para os fluxos principais.
- Manter continuidade visual com o aplicativo atual: Inter, azul `#2563EB`, fundo `#F5F7FA`, superfícies brancas e bordas suaves.
- Cobrir a operação de coordenação: visão geral, turmas, alunos, professores, chamadas, relatórios, notificações e configurações.
- Criar SVGs organizados como pranchetas completas, contendo navegação, conteúdo, estados e dados realistas.

## Não objetivos

- Não implementar o painel em Flutter ou conectar dados reais nesta etapa.
- Não criar fluxos de uso para professores ou alunos.
- Não redesenhar as telas mobile de chamada já existentes.

## Usuário e permissões

O único perfil representado será **Coordenador**. O coordenador pode consultar indicadores e registros, administrar cadastros acadêmicos, revisar chamadas que exigem atenção, editar presenças individuais, confirmar chamadas em nome do professor, gerar relatórios e ajustar as configurações da instituição. A gestão de equipe será tratada como convites para outros coordenadores, sem introduzir hierarquias de papéis nesta versão.

## Abordagens consideradas

1. **Painel único responsivo (escolhida):** as mesmas áreas e fluxos se reorganizam para desktop e celular. No desktop há menu lateral persistente; no mobile, cabeçalho compacto e barra de navegação inferior. É a opção escolhida pelo usuário porque reduz duplicação e mantém o painel coerente entre os dispositivos.
2. **Web completo e mobile resumido:** favoreceria relatórios e cadastros no desktop, mas deixaria o coordenador sem autonomia no celular.
3. **Dois produtos independentes:** permitiria experiências muito específicas, com maior custo de design e uma biblioteca de telas maior.

## Sistema visual

- **Tipografia:** Inter.
- **Cores-base:** primária `#2563EB`; texto forte `#1A1A2E`; texto secundário `#667085`; fundo `#F5F7FA`; superfície `#FFFFFF`; borda `#E0E6ED`.
- **Semântica:** sucesso `#1F8C4F` / verde claro `#E6FAED`; atenção `#E38F14` / amarelo claro `#FFF5DB`; alerta `#C72933` / rosa claro `#FFEBED`.
- **Raios:** 12–16 px para painéis, cartões, entradas e botões.
- **Desktop de referência:** 1440 × 1024 px. **Mobile de referência:** 390 × 844 px.

## Navegação e conteúdo

### Desktop

- Barra lateral com logotipo ClassVision, seletor de unidade, itens de navegação e perfil da coordenadora.
- Topo contextual com busca, notificações e avatar.
- Área de conteúdo em grade, com cartões de métricas, filtros e tabelas.

### Mobile

- Cabeçalho com título da seção, busca ou ação contextual e sino de alertas.
- Conteúdo com cartões empilhados, filtros horizontais e listas tocáveis.
- Barra inferior com: Início, Turmas, Chamadas, Relatórios e Mais.

## Telas SVG a entregar

1. **Dashboard desktop:** métricas de presença, gráfico semanal, pendências, turmas em andamento e atividades recentes.
2. **Dashboard mobile:** versão responsiva do resumo, pendências e próximas aulas.
3. **Turmas desktop:** listagem, filtros, busca, indicador de ocupação e ação de criar turma.
4. **Detalhe da turma desktop:** informações da turma, presença mensal, alunos, professor responsável e histórico de chamadas.
5. **Alunos desktop:** tabela com busca, filtros, status de cadastro e ações de gestão.
6. **Professores desktop:** listagem de docentes, turmas atribuídas, contato, status e ação de convite.
7. **Central de chamadas desktop:** filtros por período/turma/status e tabela de chamadas, incluindo casos que precisam de revisão.
8. **Revisão de chamada desktop:** tela operacional para validar presença, editar presenças individuais, registrar ajustes e confirmar uma chamada em nome do professor.
9. **Relatórios desktop:** filtros, gráficos, comparativos e botão de exportação.
10. **Configurações desktop:** dados da instituição, regras de presença, integração de IA e convites para a equipe de coordenação.
11. **Turmas mobile:** lista com busca, filtros e cartões de status das turmas.
12. **Chamadas mobile:** histórico com filtros por status e acesso à revisão.
13. **Relatórios mobile:** resumo de indicadores, gráfico de presença e filtros de período.
14. **Mais mobile:** acesso a alunos, professores, notificações e configurações.
15. **Notificações mobile:** painel de alertas para pendências, baixa presença e confirmações recentes.

## Dados de demonstração

- Instituição: Instituto Federal Goiano — Câmpus Urutaí.
- Coordenadora: Marina Costa.
- Semestre: 2026/2.
- Os nomes de alunos, professores e turmas serão fictícios, porém consistentes entre telas.

## Critérios de aceite

- Cada SVG abre e pode ser importado no Figma sem dependências externas.
- Textos permanecem como elementos `<text>` com família Inter para preservarem a edição no Figma; não serão convertidos em curvas.
- Todas as telas têm hierarquia, navegação e conteúdo completos, sem áreas de placeholder.
- Desktop e mobile compartilham a mesma linguagem visual e informações coerentes.
- A tela de revisão de chamada deixa claro como o coordenador identifica e resolve pendências.

## Decisões de implementação

- Cada tela será um arquivo SVG independente, com 1440 × 1024 px (desktop) ou 390 × 844 px (mobile).
- Ícones serão desenhados com traços SVG simples para preservar editabilidade no Figma.
- As telas usarão componentes repetidos (menu, cabeçalho, cartões, chips, tabelas e botões) com medidas e cores consistentes.
