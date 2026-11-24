# ClassVision - Front-End

**Disciplina:** Construção de Sistemas  
**Curso:** Sistemas de Informação  
**Instituição:** Instituto Federal Goiano - Câmpus Urutaí  

---

## 📖 Sobre o Projeto

Este repositório contém o código-fonte do front-end do projeto **ClassVision**, desenvolvido como parte dos requisitos da disciplina de Construção de Sistemas. A aplicação foi projetada para ser multiplataforma, possuindo suportes nativos (Android, iOS, Web, Windows, macOS e Linux) a partir de uma única base de código.

## 🚀 Tecnologias Utilizadas

*   **Framework Mobile/Web/Desktop:** Flutter
*   **Linguagem:** Dart
*   **Versionamento:** Git e GitHub

## ⚙️ Pré-requisitos

Antes de começar, você precisará ter as seguintes ferramentas instaladas em sua máquina:
*   [Flutter SDK](https://flutter.dev/docs/get-started/install)
*   [Dart SDK](https://dart.dev/get-dart) (geralmente incluído com o Flutter)
*   Uma IDE compatível, como **VS Code**, **Android Studio** ou **IntelliJ IDEA**, com os respectivos plugins do Flutter e Dart instalados.

## 🛠️ Como Executar

```bash
# Clone este repositório
$ git clone [URL_DO_SEU_REPOSITORIO]

# Acesse a pasta do projeto no terminal/cmd
$ cd ClassVision-Front

# Instale as dependências do Flutter
$ flutter pub get

# Execute a aplicação (selecione o emulador ou dispositivo web/desktop desejado)
$ flutter run
```

### Todos os microsserviços de uma vez (recomendado)

A pasta irmã [`infra/`](../infra/README.md) sobe banco, Milvus, os 4
microsserviços e um gateway com `docker compose up -d --build`. Depois, aponte o
app para o gateway — todos os serviços passam a usar esse endereço:

```bash
flutter run --dart-define=API_GATEWAY_URL=http://localhost:8000
# emulador Android: --dart-define=API_GATEWAY_URL=http://10.0.2.2:8000
```

| Variável (`--dart-define`) | Serviço | Padrão sem gateway |
|---|---|---|
| `API_GATEWAY_URL` | todos | — |
| `AUTH_API_BASE_URL` | cv-authentication-service | Railway (produção) |
| `TURMA_API_BASE_URL` | turma-service | `localhost:8081` |
| `AUDITORIA_API_BASE_URL` | auditoria-service | `localhost:8082` |
| `FACE_API_BASE_URL` | reconhecimento-facial-service | `localhost:5000` |

No emulador Android, `localhost` vira `10.0.2.2` automaticamente. Todos os
serviços precisam usar o mesmo `JWT_SECRET` do serviço de autenticação.

## Autenticação

O login, os usuários e as instituições vêm do microsserviço
[`cv-authentication-service`](https://github.com/classvision-construcao-sistemas/cv-authentication-service).

Por padrão o app usa a API publicada no Railway:
`https://cv-authentication-service-production.up.railway.app`
(ex.: `GET /api/usuarios/listar-usuarios`).

Para usar um backend rodando localmente, informe o endereço com `AUTH_API_BASE_URL`:

- Web/Desktop/iOS Simulator:
  `flutter run --dart-define=AUTH_API_BASE_URL=http://localhost:8080`.
- Emulador Android:
  `flutter run --dart-define=AUTH_API_BASE_URL=http://10.0.2.2:8080`.
- Dispositivo físico: use o IP da máquina na mesma rede, por exemplo:
  `flutter run --dart-define=AUTH_API_BASE_URL=http://192.168.0.10:8080`.

As duas APIs podem ser configuradas juntas:

```bash
flutter run \
  --dart-define=AUTH_API_BASE_URL=http://192.168.0.10:8080 \
  --dart-define=FACE_API_BASE_URL=http://192.168.0.10:5000
```

Como funciona no app:

- **Login** (`POST /api/auth/login`): o token JWT devolvido é decodificado para
  obter `id`, `nome`, `email`, `role` e `instituicaoId`, que alimentam o início,
  o perfil e os menus. Todas as chamadas protegidas enviam
  `Authorization: Bearer <token>`.
- **Sessão**: o token fica só em memória e vale 1 hora. Ao expirar, ou quando a
  API responder `401` (usuário desativado, e-mail alterado...), o app volta para
  o login com o motivo. "Sair da conta" descarta o token.
- **Sem autocadastro**: as contas são criadas por um administrador, como define
  o serviço. A tela de login não oferece "Criar conta".
- **Perfil**: mostra nome, perfil de acesso, e-mail e a instituição
  (`GET /api/instituicoes/buscar-instituicao/{id}`).
- **Usuários** (Perfil → Administração): `COORDENADOR` consulta;
  `ADMIN_INSTITUICAO` e `ADMINISTRADOR` cadastram, editam, ativam, desativam e
  excluem, sempre só com roles até o próprio nível. A edição exige informar a
  senha, porque a API sempre a substitui ao salvar. Ao editar o próprio perfil,
  o app entra de novo para atualizar o token.
- **Instituições**: o `ADMINISTRADOR` cadastra, edita, ativa e desativa; o
  `ADMIN_INSTITUICAO` edita nome e telefone da própria instituição.

O app esconde o que o perfil não pode fazer, mas quem garante as permissões é
a API: as mensagens de erro dela (`descricao`) são exibidas como vieram.

> No navegador (`flutter run -d chrome`), o serviço de autenticação ainda não
> tem CORS configurado, então as chamadas são bloqueadas. Use Android, iOS ou
> desktop.

Na primeira subida do serviço é criado o administrador geral
`admin@classvision.com` / `admin123456` (troque a senha fora do ambiente local).

## Cursos e turmas

Cursos, turmas e vínculos de alunos vêm do microsserviço
[`turma-service`](https://github.com/classvision-construcao-sistemas/turma-service),
que valida o mesmo JWT do serviço de autenticação (as chamadas enviam
`Authorization: Bearer <token>`).

O endereço é configurado com `TURMA_API_BASE_URL`. Sem ele, o app usa
`http://localhost:8081` (ou `http://10.0.2.2:8081` no emulador Android). Como o
serviço de autenticação já ocupa a 8080, suba o turma-service localmente com
`PORT=8081`:

```bash
flutter run \
  --dart-define=AUTH_API_BASE_URL=http://192.168.0.10:8080 \
  --dart-define=TURMA_API_BASE_URL=http://192.168.0.10:8081 \
  --dart-define=FACE_API_BASE_URL=http://192.168.0.10:5000
```

Como funciona no app:

- **Turmas** (`GET /turmas`, `GET /cursos`): carregadas logo após o login e na
  tela de turmas (puxe para atualizar). O serviço já devolve só as turmas da
  instituição do token; o `ADMINISTRADOR` vê todas.
- **Cadastro e edição** (`POST`/`PUT /turmas`, `DELETE /turmas/{id}`):
  `ADMINISTRADOR`, `ADMIN_INSTITUICAO` e `COORDENADOR`. O formulário pede curso,
  nome, ano letivo, turno, sala e período (`dd/mm/aaaa`, enviado como
  `aaaa-mm-dd`). Também é possível cadastrar um curso (`POST /cursos`) na
  instituição do usuário.
- **Alunos da turma** (`POST`/`DELETE /turmas/{id}/alunos`): ao cadastrar um
  aluno numa turma, perfis com permissão (os acima e `SECRETARIO`) também criam
  o vínculo; a matrícula numérica é o `alunoId`. Nome, responsável e telefone
  ficam com a biometria no reconhecimento-facial-service e são buscados pela
  matrícula (`GET /api/v1/alunos/{matricula}`) ao carregar as turmas. Para os
  demais perfis o aluno fica só na sessão, como antes.
- Erros da API (`mensagem` e `campos`) são exibidos como vieram, e um `401`
  encerra a sessão.

## Chamada e histórico

As chamadas de turmas do turma-service passam pelo
[`auditoria-service`](https://github.com/classvision-construcao-sistemas/auditoria-service):

1. **Prévia** (`POST /auditorias/previa`): o app envia a foto; o serviço
   consulta os alunos ativos da turma e o reconhecimento facial e devolve quem
   foi reconhecido. Nada é gravado nesta etapa.
2. **Conferência**: o coordenador ajusta presenças na tela de revisão.
3. **Confirmação** (`POST /auditorias`): grava a chamada revisada.
4. **Histórico** (`GET /auditorias`): alimenta Chamadas, Início, Alunos
   (frequência), Relatórios e Notificações.

Só `COORDENADOR` e `ADMINISTRADOR` gravam chamadas (RN-01 do auditoria-service).
Para os demais perfis, e para fotos sem turma, a chamada usa o reconhecimento
facial direto e fica só na sessão (a tela de confirmação avisa).

## Painéis por perfil

Após o login, o JWT define automaticamente a área exibida:

- `ADMINISTRADOR` abre o painel global, exclusivo para desktop.
- `ADMIN_INSTITUICAO` abre a administração da instituição; a gestão de coordenadores também possui versão mobile.
- `COORDENADOR`, `PROFESSOR`, `SECRETARIO` e `ASSISTENTE` usam a área acadêmica responsiva.

As permissões também são verificadas ao abrir rotas diretamente. As 25 telas de referência editáveis ficam em `design/admin-panel/`, com pranchetas desktop de `1440 × 1024` e mobile de `390 × 844`.

## Reconhecimento facial

O app envia fotos em `multipart/form-data` para o microsserviço que está na
pasta irmã `reconhecimento-facial-service`, sempre com o cabeçalho
`Authorization: Bearer <token>` da sessão (o serviço exige o JWT).

- Emulador Android: `flutter run` usa automaticamente `http://10.0.2.2:5000`.
- Dispositivo físico: use o IP da máquina na mesma rede, por exemplo:
  `flutter run --dart-define=FACE_API_BASE_URL=http://192.168.0.10:5000`.
- Desktop/iOS Simulator: o endereço padrão é `http://localhost:5000`.

Antes de fazer uma chamada, abra uma turma, adicione um aluno e tire a foto
facial solicitada. A matrícula usada nesse cadastro é a chave que relaciona o
resultado da API ao aluno exibido no app.

## 📐 Estrutura do Projeto

O projeto segue a estrutura padrão de um aplicativo Flutter, organizada nos seguintes diretórios principais identificados no repositório:
*   `lib/`: Contém o código-fonte principal da aplicação em Dart (telas, componentes, lógica de negócios). O arquivo de entrada é o `main.dart`.
*   `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/`: Códigos e configurações específicas para a construção nativa em cada plataforma.
*   `pubspec.yaml`: Arquivo de configuração de pacotes, dependências e assets (como ícones) do projeto.

## 👥 Autores



## 📄 Licença

Este projeto possui fins acadêmicos.
