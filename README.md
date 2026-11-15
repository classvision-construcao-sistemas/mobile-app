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

## Acessos de demonstração

A tela de login identifica o perfil pelo e-mail e abre automaticamente a área permitida:

- `arthur@classvision.app` — Administrador do Sistema. O painel global é exclusivo para desktop; no celular o app orienta o usuário a acessar pelo computador.
- `marina.costa@ifgoiano.edu.br` — Administradora da Instituição. Configurações e equipe aparecem no desktop, e a gestão de coordenadores possui uma versão mobile dedicada.
- `lucas.ferreira@ifgoiano.edu.br` — Coordenador. A área acadêmica é responsiva, com barra lateral no desktop e navegação inferior no celular.

A senha de demonstração pode ser qualquer valor com pelo menos seis caracteres. As permissões continuam protegidas após o login: coordenadores não acessam administração institucional ou global, e administradores globais não recebem destinos acadêmicos.

As telas de referência editáveis estão em `design/admin-panel/`, com pranchetas desktop de `1440 × 1024` e mobile de `390 × 844`.

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
