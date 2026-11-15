# Painéis administrativos e papéis do ClassVision — design

## Intenção

Corrigir a arquitetura de administração do ClassVision conforme a regra explicada no áudio de referência: o Administrador do Sistema cadastra instituições e seus primeiros administradores; cada Administrador da Instituição gerencia a própria instituição e seus coordenadores; os Coordenadores executam a operação acadêmica cotidiana.

## Papéis

### Administrador do Sistema

- Atua globalmente, fora do contexto de uma instituição específica.
- Cadastra, edita, ativa, suspende e consulta instituições.
- Cria o primeiro Administrador da Instituição durante o cadastro institucional.
- Acompanha quantidade de instituições, usuários, status e atividade da plataforma.
- Não visualiza turmas, alunos, chamadas, presença ou relatórios acadêmicos das instituições.
- Usa apenas o painel web/desktop.

### Administrador da Instituição

- Atua somente na instituição à qual pertence.
- Possui todas as funções operacionais disponíveis aos Coordenadores.
- Convida, consulta, ativa e desativa Coordenadores da própria instituição.
- Edita dados, regras e integrações da própria instituição.
- Usa o painel web responsivo e a experiência mobile institucional.

### Coordenador

- Atua somente na instituição à qual pertence.
- Gerencia turmas, alunos, professores, chamadas e relatórios.
- Pode revisar e editar presenças individuais.
- Não gerencia Coordenadores, não altera integrações e não acessa outras instituições.
- Usa o painel web responsivo e a experiência mobile institucional.

## Abordagens consideradas

1. **Painéis separados por domínio — escolhida:** painel global exclusivo para o Administrador do Sistema; painel institucional compartilhado entre Administrador da Instituição e Coordenador, com itens restritos por permissão. Mantém a navegação simples e reaproveita os 15 SVGs já criados.
2. **Um painel único para todos os papéis:** esconderia menus conforme o usuário, mas misturaria instituições e operação acadêmica no mesmo modelo mental.
3. **Três produtos separados:** duplicaria a experiência institucional sem benefício, pois Administrador da Instituição e Coordenador compartilham quase todas as tarefas.

## Sistema visual

Os novos SVGs seguem o sistema existente: Inter, primária `#2563EB`, fundo `#F5F7FA`, superfícies `#FFFFFF`, texto `#1A1A2E`, secundário `#6B7280`, borda `#E5E7EB`, sucesso `#22C55E`, atenção `#F59E0B` e erro `#C72933`.

O painel global deve ser reconhecível como parte do ClassVision, porém com navegação voltada a **Visão geral**, **Instituições**, **Administradores**, **Atividade** e **Configurações da plataforma**.

## Novos SVGs desktop — Administrador do Sistema

1. **Login administrativo:** autenticação separada com identificação de acesso global.
2. **Dashboard global:** total de instituições, instituições ativas, administradores, usuários e atividade recente.
3. **Instituições:** tabela pesquisável com instituição, administrador responsável, número de usuários, data de cadastro e status.
4. **Cadastrar instituição:** formulário completo com dados institucionais e criação do primeiro Administrador da Instituição.
5. **Detalhe da instituição:** resumo, administrador, coordenadores, números acadêmicos, status, atividade e ações de editar/suspender.
6. **Administradores institucionais:** tabela global de administradores, instituição, contato, último acesso e status.
7. **Atividade da plataforma:** trilha de auditoria com filtros por ação, instituição, usuário e período.
8. **Configurações da plataforma:** preferências globais, políticas de convite, notificações administrativas e status dos serviços.
9. **Instituição cadastrada:** confirmação da criação e do envio do convite ao primeiro Administrador da Instituição.

O cadastro será apresentado em duas etapas: **Dados da instituição** e **Primeiro administrador**. Os campos mínimos da instituição são nome, CNPJ ou código INEP, contato, endereço e status. Os campos mínimos do administrador são nome, e-mail e telefone. O acesso inicial será enviado por convite de e-mail; nenhuma senha temporária será exibida no painel.

## Ajustes nos SVGs institucionais existentes

- Atualizar **Configurações desktop** para mostrar lista de Coordenadores, convite por e-mail, status de convite e ações de ativar/desativar.
- Criar **Gestão de coordenadores mobile** para o Administrador da Instituição, com lista, status e envio de convite.
- Registrar claramente que essa seção aparece apenas para o Administrador da Instituição.
- Manter os demais SVGs operacionais para ambos os papéis institucionais.
- Adicionar indicações discretas de papel no perfil: “Administrador da instituição” ou “Coordenador”.
- No detalhe global da instituição, a equipe de Coordenadores será somente informativa; o Administrador do Sistema não poderá editá-la.
- Nas telas operacionais compartilhadas, o perfil demonstrado será “Coordenador”. Dados institucionais, equipe e integrações usarão a variante “Administrador da instituição”.

## Dados de demonstração

- Plataforma: ClassVision.
- Administrador do Sistema: Arthur Silva.
- Instituição principal: Instituto Federal Goiano — Câmpus Urutaí.
- Administradora da Instituição: Marina Costa.
- Coordenadores: Lucas Ferreira, Juliana Prado e Fernanda Alves.
- Dados e contagens devem permanecer coerentes entre dashboard, listagens e detalhes.

## Critérios de aceite

- Os nove novos SVGs globais possuem `1440 × 1024`; a nova tela institucional mobile possui `390 × 844`. Todos são independentes e importáveis no Figma.
- Todos os textos permanecem como elementos `<text>` editáveis com Inter.
- Nenhuma tela usa imagens ou dependências externas.
- O fluxo de cadastro cria instituição e primeiro administrador como uma única operação conceitual.
- O Administrador da Instituição consegue gerenciar Coordenadores no painel institucional.
- O Coordenador não recebe affordances para gerenciar usuários administrativos ou integrações.
- A separação entre plataforma global e instituição é compreensível sem explicação externa.

## Não objetivos

- Implementar autenticação, API ou regras de autorização nesta etapa.
- Criar aplicativo mobile para o Administrador do Sistema.
- Criar novos papéis além dos três definidos.
