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

## Autenticação

O login, os usuários e as instituições vêm do microsserviço
[`cv-authentication-service`](https://github.com/classvision-construcao-sistemas/cv-authentication-service).

- Emulador Android: `flutter run` usa automaticamente `http://10.0.2.2:8080`.
- Dispositivo físico: use o IP da máquina na mesma rede, por exemplo:
  `flutter run --dart-define=AUTH_API_BASE_URL=http://192.168.0.10:8080`.
- Desktop/iOS Simulator: o endereço padrão é `http://localhost:8080`.
- API publicada (Railway): `--dart-define=AUTH_API_BASE_URL=https://<dominio-da-api>`.

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

## Painéis por perfil

Após o login, o JWT define automaticamente a área exibida:

- `ADMINISTRADOR` abre o painel global, exclusivo para desktop.
- `ADMIN_INSTITUICAO` abre a administração da instituição; a gestão de coordenadores também possui versão mobile.
- `COORDENADOR`, `PROFESSOR`, `SECRETARIO` e `ASSISTENTE` usam a área acadêmica responsiva.

As permissões também são verificadas ao abrir rotas diretamente. As 25 telas de referência editáveis ficam em `design/admin-panel/`, com pranchetas desktop de `1440 × 1024` e mobile de `390 × 844`.

## Reconhecimento facial

O app envia fotos em `multipart/form-data` para o microsserviço que está na
pasta irmã `reconhecimento-facial-service`.

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
