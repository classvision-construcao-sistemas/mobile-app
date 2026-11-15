# ClassVision Native Admin Panels Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar em Flutter as 25 pranchetas do ClassVision com login único orientado por papel, painéis responsivos e ações demonstrativas funcionais.

**Architecture:** A sessão global resolve `UserRole` pelo e-mail e encaminha para um shell específico. Um kit visual compartilhado reproduz tokens, sidebar, navegação mobile, cartões, tabelas e estados dos SVGs; repositórios `ChangeNotifier` mantêm os dados demonstrativos em memória. As páginas operacionais existentes permanecem ligadas aos fluxos atuais de câmera e chamada, recebendo variantes desktop e mobile.

**Tech Stack:** Flutter 3 / Dart 3.13, Material 3, Provider, flutter_test, Inter local.

**Spec:** `docs/superpowers/specs/2026-11-15-classvision-admin-implementation-design.md`

## Global Constraints

- As referências visuais são os arquivos `design/admin-panel/01-*.svg` até `25-*.svg`.
- Os alvos de renderização são `1440 × 1024` para desktop e `390 × 844` para mobile.
- A quebra entre desktop e mobile ocorre em `900 px`.
- Administrador do Sistema não recebe interface mobile; abaixo de `900 px` vê orientação para usar computador.
- Administrador do Sistema não pode receber dados acadêmicos; Coordenador não pode receber configurações institucionais ou gestão de usuários.
- Todas as telas usam widgets Flutter nativos e fonte Inter; os SVGs não são incorporados como tela.
- O fluxo existente de câmera, processamento facial, revisão e confirmação de chamada deve continuar funcionando.
- Não adicionar backend, persistência ou dependências de UI.
- Preservar alterações locais preexistentes em arquivos Flutter gerados e `android/build/`.

## Review Focus

- E-mail com maiúsculas ou espaços deve resolver o mesmo papel após normalização.
- Rotas digitadas diretamente não podem ultrapassar a permissão do papel autenticado.
- Administrador do Sistema em largura mobile deve ver somente a orientação desktop, sem conteúdo global parcial.
- Listas vazias e filtros sem resultado devem preservar o layout e mostrar estado vazio claro.
- Formulário de instituição inválido não cria dados nem avança para a confirmação.

---

### Task 1: Sessão, papéis e encaminhamento do login

**Files:**
- Create: `lib/core/auth/user_role.dart`
- Create: `lib/core/auth/app_user.dart`
- Create: `lib/core/auth/role_resolver.dart`
- Create: `lib/core/auth/app_session.dart`
- Modify: `lib/features/auth/viewmodels/login_view_model.dart`
- Modify: `lib/features/auth/views/login_page.dart`
- Modify: `lib/app.dart`
- Modify: `lib/core/navigation/app_routes.dart`
- Test: `test/core/auth/role_resolver_test.dart`
- Test: `test/features/auth/login_routing_test.dart`

**Interfaces:**
- Produces: `enum UserRole { systemAdmin, institutionAdmin, coordinator }`.
- Produces: `AppUser(name, email, role, institution)` and `RoleResolver.resolve(String email) -> AppUser`.
- Produces: `AppSession.user`, `AppSession.signIn(email)`, `AppSession.signOut()` and `AppSession.initialRoute`.
- Consumes: existing `LoginViewModel` loading/password behavior and `AppRoutes`.

- [ ] **Step 1: Write the failing role-resolution tests**

Assert that normalized `arthur@classvision.app` resolves to System Administrator, `marina.costa@ifgoiano.edu.br` resolves to Institution Administrator, another valid institutional e-mail resolves to Coordinator, and whitespace/case do not change the result.

- [ ] **Step 2: Run the role tests to verify RED**

Run: `flutter test test/core/auth/role_resolver_test.dart`

Expected: FAIL because `RoleResolver`, `AppUser` and `UserRole` do not exist.

- [ ] **Step 3: Implement the minimal auth domain and session**

Use the exact demonstration identities from the spec. `AppSession` remains in memory and exposes the route allowed for the authenticated role.

- [ ] **Step 4: Run the role tests to verify GREEN**

Run: `flutter test test/core/auth/role_resolver_test.dart`

Expected: PASS.

- [ ] **Step 5: Write failing login-routing widget tests**

At `390 × 844`, assert neutral copy `Acesso ao ClassVision`; submit each demo e-mail and assert the correct shell marker. Assert sign-out returns to login. Assert a direct forbidden route redirects to the allowed shell.

- [ ] **Step 6: Run login-routing tests to verify RED**

Run: `flutter test test/features/auth/login_routing_test.dart`

Expected: FAIL because session-aware routing and neutral login do not exist.

- [ ] **Step 7: Wire session into login and application routes**

Keep e-mail/password validation, add discrete demo access helpers, and replace hardcoded `/home` navigation with `AppSession.initialRoute`.

- [ ] **Step 8: Run auth tests and commit**

Run: `flutter test test/core/auth/role_resolver_test.dart test/features/auth/login_routing_test.dart`

Expected: PASS.

Commit: `feat: add role-based ClassVision session`

---

### Task 2: Kit visual e shells responsivos

**Files:**
- Create: `lib/core/layout/app_breakpoints.dart`
- Create: `lib/core/widgets/classvision_logo.dart`
- Create: `lib/core/widgets/admin_sidebar.dart`
- Create: `lib/core/widgets/admin_mobile_navigation.dart`
- Create: `lib/core/widgets/admin_page_scaffold.dart`
- Create: `lib/core/widgets/admin_cards.dart`
- Create: `lib/core/widgets/status_badge.dart`
- Create: `lib/core/widgets/desktop_required_view.dart`
- Modify: `lib/core/theme/app_colors.dart`
- Modify: `lib/core/theme/app_theme.dart`
- Test: `test/core/widgets/admin_shell_test.dart`

**Interfaces:**
- Produces: `AppBreakpoints.isDesktop(BoxConstraints)`, using `900` as the threshold.
- Produces: `AdminPageScaffold(role, selectedDestination, destinations, body, onDestinationSelected)`.
- Produces: reusable metric, filter, table, empty-state and status widgets matching the SVG tokens.
- Consumes: `UserRole` from Task 1.

- [ ] **Step 1: Write failing shell layout tests**

Assert sidebar presence and bottom-navigation absence at `1440 × 1024`; inverse at `390 × 844`; System Administrator at mobile size renders `Acesse pelo computador` and no global destinations.

- [ ] **Step 2: Run shell tests to verify RED**

Run: `flutter test test/core/widgets/admin_shell_test.dart`

Expected: FAIL because the responsive shell does not exist.

- [ ] **Step 3: Implement design tokens and shell primitives**

Match `#2563EB`, `#F5F7FA`, `#FFFFFF`, `#1A1A2E`, `#6B7280`, `#E5E7EB`, global sidebar `#0F172A`, Inter, 12–20 px radii and restrained shadows from the SVGs.

- [ ] **Step 4: Run shell tests and commit**

Run: `flutter test test/core/widgets/admin_shell_test.dart`

Expected: PASS without overflow exceptions.

Commit: `feat: add responsive admin design system`

---

### Task 3: Dados administrativos demonstrativos

**Files:**
- Create: `lib/features/admin/domain/admin_models.dart`
- Create: `lib/features/admin/data/admin_repository.dart`
- Test: `test/features/admin/data/admin_repository_test.dart`

**Interfaces:**
- Produces: `Institution`, `InstitutionAdmin`, `CoordinatorAccount`, `PlatformActivity`, `PlatformSettings` and status enums.
- Produces: `AdminRepository` queries and mutations for search, filters, institution creation/status, coordinator invitation/status and settings toggles.
- Consumes: fixed demo data from the SVG spec.

- [ ] **Step 1: Write failing repository behavior tests**

Cover initial metrics, normalized search, empty result, create institution with first administrator as one operation, invalid create rejection, active/inactive/pending coordinator transitions, invitation re-send/cancel and settings toggles.

- [ ] **Step 2: Run repository tests to verify RED**

Run: `flutter test test/features/admin/data/admin_repository_test.dart`

Expected: FAIL because models and repository do not exist.

- [ ] **Step 3: Implement minimal in-memory models and repository**

Seed IF Goiano/Marina/Lucas/Juliana/Fernanda plus the global demo institutions and audit rows used by screens 17–25. Notify listeners only on mutations.

- [ ] **Step 4: Run repository tests and commit**

Run: `flutter test test/features/admin/data/admin_repository_test.dart`

Expected: PASS.

Commit: `feat: add administrative demo state`

---

### Task 4: Shell e telas do Administrador do Sistema

**Files:**
- Create: `lib/features/admin/views/system_admin_shell.dart`
- Create: `lib/features/admin/views/system_dashboard_page.dart`
- Create: `lib/features/admin/views/institutions_page.dart`
- Create: `lib/features/admin/views/create_institution_page.dart`
- Create: `lib/features/admin/views/institution_detail_page.dart`
- Create: `lib/features/admin/views/institution_created_page.dart`
- Create: `lib/features/admin/views/institution_admins_page.dart`
- Create: `lib/features/admin/views/platform_activity_page.dart`
- Create: `lib/features/admin/views/platform_settings_page.dart`
- Modify: `lib/app.dart`
- Test: `test/features/admin/system_admin_pages_test.dart`
- Test: `test/features/admin/system_admin_flow_test.dart`

**Interfaces:**
- Produces: `SystemAdminShell` with destinations dashboard, institutions, administrators, activity and settings.
- Produces: create/detail/success flow consuming `AdminRepository`.
- Consumes: shell widgets from Task 2, repository from Task 3 and authenticated System Administrator from Task 1.

- [ ] **Step 1: Write failing page-coverage tests**

At `1440 × 1024`, assert the identifying texts and primary actions for SVGs 17, 18, 20, 21, 22 and 23; assert no academic labels `Turmas`, `Alunos`, `Chamadas` or `Presença` appear in the global shell.

- [ ] **Step 2: Run page tests to verify RED**

Run: `flutter test test/features/admin/system_admin_pages_test.dart`

Expected: FAIL because the pages do not exist.

- [ ] **Step 3: Implement global shell and read-only pages**

Build dashboard metrics/chart, institution table, detail summary, administrator table, audit filters including user and platform settings including notifications. Match SVG copy, data and composition.

- [ ] **Step 4: Run page tests to verify GREEN**

Run: `flutter test test/features/admin/system_admin_pages_test.dart`

Expected: PASS with no overflow.

- [ ] **Step 5: Write failing institution-flow tests**

Cover required validation, two visible form sections, successful creation of Colégio Horizonte/Paulo Nunes, invitation confirmation, detail navigation and cancel behavior.

- [ ] **Step 6: Run flow tests to verify RED**

Run: `flutter test test/features/admin/system_admin_flow_test.dart`

Expected: FAIL because the onboarding interaction is incomplete.

- [ ] **Step 7: Implement create and success flow**

Reproduce SVGs 19 and 24 using native form fields, confirmation state and repository mutation. Destructive suspension uses a confirmation dialog.

- [ ] **Step 8: Run system-admin tests and commit**

Run: `flutter test test/features/admin/system_admin_pages_test.dart test/features/admin/system_admin_flow_test.dart`

Expected: PASS.

Commit: `feat: implement system administrator panel`

---

### Task 5: Administração da instituição e Coordenadores

**Files:**
- Create: `lib/features/institution_admin/views/institution_admin_shell.dart`
- Create: `lib/features/institution_admin/views/institution_settings_page.dart`
- Create: `lib/features/institution_admin/views/coordinators_page.dart`
- Modify: `lib/app.dart`
- Test: `test/features/institution_admin/institution_admin_pages_test.dart`
- Test: `test/features/institution_admin/coordinator_management_test.dart`

**Interfaces:**
- Produces: role-aware institutional shell that adds settings/team destinations only for `institutionAdmin`.
- Produces: desktop settings matching SVG 09 and mobile coordinator management matching SVG 25.
- Consumes: current operational pages as shell destinations and `AdminRepository` coordinator mutations from Task 3. Task 6 later replaces those page bodies with their responsive variants without changing this shell contract.

- [ ] **Step 1: Write failing permission and layout tests**

Assert Institution Administrator sees settings/team on desktop and Coordinators on mobile; Coordinator never sees these destinations; SVG 09 texts appear at `1440 × 1024`; SVG 25 texts appear at `390 × 844`.

- [ ] **Step 2: Run permission tests to verify RED**

Run: `flutter test test/features/institution_admin/institution_admin_pages_test.dart`

Expected: FAIL because the institutional admin shell does not exist.

- [ ] **Step 3: Implement role-aware shell and settings screens**

Match active/inactive/pending rows, invite field, permission note, integration status and profile identity Marina Costa.

- [ ] **Step 4: Write failing coordinator-action tests**

Assert invite, activate, deactivate, re-send and cancel update visible state; empty/invalid e-mail is rejected; destructive actions ask for confirmation.

- [ ] **Step 5: Run action tests to verify RED**

Run: `flutter test test/features/institution_admin/coordinator_management_test.dart`

Expected: FAIL because interactions are not wired.

- [ ] **Step 6: Wire repository actions and run tests**

Run: `flutter test test/features/institution_admin/institution_admin_pages_test.dart test/features/institution_admin/coordinator_management_test.dart`

Expected: PASS.

- [ ] **Step 7: Commit**

Commit: `feat: implement institution administrator panel`

---

### Task 6: Operação acadêmica responsiva do Coordenador

**Files:**
- Modify: `lib/features/shell/views/main_shell.dart`
- Modify: `lib/core/viewmodels/main_shell_view_model.dart`
- Modify: `lib/core/widgets/app_bottom_navigation.dart`
- Modify: `lib/features/home/view/home_page.dart`
- Modify: `lib/features/classes/views/classes_page.dart`
- Modify: `lib/features/classes/views/class_details_page.dart`
- Modify: `lib/features/history/views/history_page.dart`
- Modify: `lib/features/profile/views/profile_page.dart`
- Create: `lib/features/students/views/students_page.dart`
- Create: `lib/features/teachers/views/teachers_page.dart`
- Create: `lib/features/reports/views/reports_page.dart`
- Create: `lib/features/notifications/views/notifications_page.dart`
- Test: `test/features/coordinator/coordinator_responsive_pages_test.dart`
- Test: `test/features/coordinator/coordinator_permissions_test.dart`

**Interfaces:**
- Produces: operational destinations dashboard, classes, students, teachers, attendance, reports, notifications and more.
- Produces: desktop layouts equivalent to SVGs 01–08 and mobile layouts equivalent to SVGs 10–15.
- Consumes: existing `SchoolRepository`, camera routes and attendance pages; shell from Task 2; `UserRole.coordinator` from Task 1.

- [ ] **Step 1: Write failing responsive page tests**

At both target sizes, assert the identifying copy and navigation labels for SVGs 01–08 and 10–15, Lucas Ferreira identity, correct Saturday copy for 14 November 2026, and no overflow.

- [ ] **Step 2: Run responsive tests to verify RED**

Run: `flutter test test/features/coordinator/coordinator_responsive_pages_test.dart`

Expected: FAIL because desktop variants and missing destinations do not exist.

- [ ] **Step 3: Implement responsive operational pages**

Preserve repository-backed empty/session states and existing camera/review flows. Use the SVGs as exact layout references rather than redesigning the pages.

- [ ] **Step 4: Write failing permission regression tests**

Assert Coordinator cannot reach institution settings/coordinator management by menu or direct route, while Institution Administrator can use operational pages and return to settings.

- [ ] **Step 5: Run permission tests to verify RED**

Run: `flutter test test/features/coordinator/coordinator_permissions_test.dart`

Expected: FAIL until route guards and shell destinations are complete.

- [ ] **Step 6: Complete role guards and run coordinator tests**

Run: `flutter test test/features/coordinator/coordinator_responsive_pages_test.dart test/features/coordinator/coordinator_permissions_test.dart`

Expected: PASS.

- [ ] **Step 7: Run existing camera/attendance tests and commit**

Run: `flutter test test/widget_test.dart test/features/ai_processing/ai_processing_view_model_test.dart test/data/repositories/school_repository_test.dart test/data/services/facial_recognition_api_test.dart`

Expected: PASS; existing camera/attendance behavior remains intact.

Commit: `feat: implement responsive coordinator workspace`

---

### Task 7: Fidelidade visual, acessibilidade e verificação final

**Files:**
- Create: `test/visual/admin_reference_sizes_test.dart`
- Modify: UI files from Tasks 2, 4, 5 and 6 only when a verification failure proves the need.
- Update: `README.md`

**Interfaces:**
- Consumes: all pages and routes from Tasks 1–6.
- Produces: verified application and instructions for the three demo identities.

- [ ] **Step 1: Write target-size render tests**

Pump every reachable screen at `1440 × 1024` or `390 × 844`, fail on Flutter exceptions/overflow, assert the expected top-level copy and verify role-specific destinations.

- [ ] **Step 2: Run render tests and fix only observed failures**

Run: `flutter test test/visual/admin_reference_sizes_test.dart`

Expected: PASS for all 25 references.

- [ ] **Step 3: Render representative screenshots**

Capture login, global dashboard, institution onboarding, institution settings, coordinator desktop dashboard and coordinator mobile dashboard. Compare against SVG references for spacing, alignment, color, typography and clipping; record any intentional accessibility-only deviation.

- [ ] **Step 4: Run formatting and static analysis**

Run: `dart format --output=none --set-exit-if-changed lib test`

Run: `flutter analyze`

Expected: zero errors and warnings introduced by this work.

- [ ] **Step 5: Run the complete suite**

Run: `flutter test`

Expected: all tests pass with zero failures.

- [ ] **Step 6: Validate design assets and repository diff**

Run: `powershell -ExecutionPolicy Bypass -File design/admin-panel/scripts/validate-svg-assets.ps1`

Run: `git diff --check`

Expected: 25 SVGs pass; no whitespace errors.

- [ ] **Step 7: Document demo access and commit**

Document the three demo e-mails, responsive behavior and desktop-only System Administrator rule.

Commit: `docs: document native admin panel access`
