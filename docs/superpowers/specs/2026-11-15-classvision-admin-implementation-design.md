# Implementação nativa dos painéis ClassVision

## Intenção

Transformar as 25 pranchetas em interfaces Flutter nativas e funcionais no projeto atual, mantendo a aparência das referências em `design/admin-panel/` e preservando o fluxo existente de câmera e reconhecimento facial. Um único login identifica o papel do usuário e abre o painel permitido para aquele papel.

## Objetivos

- Reproduzir as pranchetas com widgets Flutter, fonte Inter, cores, espaçamento, raios, hierarquia e conteúdo equivalentes.
- Suportar web/desktop em `1440 × 1024` e mobile em `390 × 844`, com adaptação segura para tamanhos intermediários.
- Usar o mesmo login para Administrador do Sistema, Administrador da Instituição e Coordenador.
- Impedir que Coordenadores visualizem configurações institucionais, integrações ou gestão de usuários administrativos.
- Manter os fluxos atuais de câmera, reconhecimento facial e revisão de chamada disponíveis ao Coordenador.
- Entregar navegação e ações demonstrativas funcionais com estado local, prontas para futura ligação à API.

## Não objetivos

- Criar ou modificar backend, banco de dados, autenticação real ou contratos de API.
- Persistir dados depois que o aplicativo for encerrado.
- Substituir as páginas por imagens ou incorporar os SVGs como telas inteiras.
- Alterar o fluxo técnico do reconhecimento facial existente.

## Restrições

- O código continua em Flutter/Dart e usa Provider, Material 3 e a estrutura atual do repositório.
- Não serão adicionadas dependências de interface sem necessidade.
- A implementação respeita os dados e as permissões definidos em `2026-11-15-classvision-admin-roles-design.md`.
- Arquivos gerados de Linux, macOS, Windows e `android/build/` já alterados no checkout principal não fazem parte deste trabalho.

## Abordagens consideradas

### 1. Aplicativo Flutter único, responsivo e orientado por papel — escolhida

O login resolve o papel, grava a sessão em memória e encaminha para um shell próprio. Componentes visuais e dados demonstrativos são compartilhados onde fizer sentido. Essa opção aproveita o projeto atual, mantém uma única base para mobile e web e evita divergência entre produtos.

### 2. Painel web separado dentro do mesmo repositório

Separaria o administrador global do app mobile. Daria isolamento visual, mas duplicaria tema, autenticação e modelos, além de contrariar a decisão de usar o mesmo login.

### 3. Rotas estáticas independentes sem sessão por papel

Seria mais rápido para demonstrar as telas, porém não provaria as permissões nem o fluxo real do produto. Foi descartada porque o painel precisa funcionar, não apenas parecer correto.

## Autenticação demonstrativa e sessão

O formulário continua com e-mail e senha e usa o título neutro **Acesso ao ClassVision**, pois o papel ainda não é conhecido antes do envio. Até existir autenticação real, o papel será resolvido pelo e-mail digitado:

- `arthur@classvision.app` → Administrador do Sistema.
- `marina.costa@ifgoiano.edu.br` → Administrador da Instituição.
- Qualquer outro e-mail institucional válido → Coordenador, usando Lucas Ferreira como perfil demonstrativo quando não houver dados de perfil.

O login apresentará acessos de demonstração discretos para permitir testar os três papéis sem criar um seletor que não existe no produto final. A sessão expõe `UserRole`, nome, e-mail e instituição. Sair encerra a sessão e volta ao login.

## Arquitetura de interface

### Shell responsivo

- A partir de `900 px`: menu lateral fixo, conteúdo com largura fluida e estrutura equivalente às pranchetas desktop.
- Abaixo de `900 px`: navegação inferior, cabeçalhos e cartões equivalentes às pranchetas mobile.
- As dimensões de referência são tratadas como alvos visuais; telas menores usam rolagem e telas maiores mantêm o conteúdo centralizado sem deformar elementos.
- Se o papel for Administrador do Sistema e a largura estiver abaixo de `900 px`, o aplicativo não adapta o painel global: mostra uma orientação para acessar pelo computador, pois esse papel é exclusivamente desktop e não possui pranchetas mobile.

### Administrador do Sistema

Usa somente o shell global escuro e as telas 16–24: login administrativo, visão geral, instituições, cadastro em duas etapas, detalhe, administradores institucionais, atividade, configurações e confirmação de criação. Não recebe rotas nem rótulos de turmas, alunos, chamadas ou presença.

### Administrador da Instituição

Usa o shell institucional e pode acessar a operação acadêmica, configurações, integração de IA e gestão de Coordenadores. A tela 09 é a experiência web de gestão da equipe e a tela 25 é a experiência mobile correspondente.

### Coordenador

Usa as telas operacionais 01–08 no desktop e 10–15 no mobile. Não recebe acesso às telas 09 e 25. O perfil demonstrativo é Lucas Ferreira. Câmera, processamento de IA, conferência e confirmação da chamada continuam usando as páginas existentes.

## Estado demonstrativo

Uma camada de dados administrativos em memória fornece as instituições, administradores, Coordenadores, métricas e auditorias mostradas nas pranchetas. Ela permite:

- cadastrar instituição e criar o primeiro administrador como uma operação;
- pesquisar e filtrar instituições e atividades;
- ativar, suspender e consultar instituições;
- convidar, ativar, desativar, reenviar e cancelar convite de Coordenadores;
- alternar preferências globais de convite e notificação.

As alterações atualizam imediatamente a interface, sem simular chamadas de rede.

## Fidelidade visual

- Fonte Inter em todos os textos.
- Paleta principal `#2563EB`, fundo `#F5F7FA`, superfícies brancas e sidebar global `#0F172A`.
- Raios, elevações leves, densidade de tabelas, cartões de métricas e estados seguem os SVGs.
- Ícones Material equivalentes substituem os símbolos tipográficos das referências quando aumentarem a legibilidade sem mudar a composição.
- Os SVGs permanecem como fonte de verdade para comparação visual; a tela renderizada não depende deles em tempo de execução.

## Navegação e comportamento

- O login encaminha diretamente para o shell do papel resolvido.
- O menu lateral e a navegação inferior mantêm o estado da seção atual.
- Linhas de tabela, cartões e ações principais abrem as rotas correspondentes.
- Formulários validam campos obrigatórios e exibem feedback no próprio fluxo.
- Ações destrutivas demonstrativas exigem confirmação.
- Teclado, foco, leitores de tela e áreas mínimas de toque são respeitados.

## Verificação

- Testes unitários cobrem resolução de papel e mutações do estado administrativo.
- Testes de widget cobrem redirecionamento por papel, limites de permissão, navegação principal e formulários.
- Testes de layout executam os tamanhos `390 × 844` e `1440 × 1024` sem overflow.
- A análise estática e a suíte Flutter completa devem passar.
- As telas principais de cada papel são renderizadas e comparadas visualmente com os SVGs antes da entrega.

## Decisões deixadas ao implementador

- Divisão exata dos widgets internos, desde que mantenha arquivos focados e reutilização responsável.
- Escolha entre `NavigationRail` customizada ou sidebar composta, priorizando fidelidade às referências.
- Pequenos ajustes para acessibilidade e tamanhos intermediários que não alterem o alvo visual nos dois tamanhos de referência.
