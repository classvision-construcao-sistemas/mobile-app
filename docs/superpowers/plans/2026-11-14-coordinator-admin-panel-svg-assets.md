# Coordinator Admin Panel SVG Assets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a complete, editable SVG screen pack for ClassVision coordinators, covering desktop and mobile administrative workflows.

**Architecture:** SVG files live in `design/admin-panel/`, one self-contained artboard per file. Desktop files share a left sidebar, contextual header, card grid and table patterns; mobile files share a compact header and bottom navigation. A single validation script checks SVG dimensions, editability constraints and required copy before visual import into Figma.

**Tech Stack:** Plain SVG 1.1, Inter text elements, PowerShell validation, Figma import.

**Spec:** `docs/superpowers/specs/2026-11-14-coordinator-admin-panel-design.md`

## Global Constraints

- Target users are institutional coordinators only.
- Use Inter and retain all copy as editable `<text>` nodes; do not convert copy to paths.
- Use the existing ClassVision palette: primary `#2563EB`, background `#F5F7FA`, surface `#FFFFFF`, primary text `#1A1A2E`, secondary text `#6B7280`, border `#E5E7EB`, success `#22C55E`, warning `#F59E0B`, error `#C72933`.
- Desktop artboards are exactly `1440 × 1024`; mobile artboards are exactly `390 × 844`.
- Files must be standalone and importable into Figma with no external image, font, stylesheet or symbol dependencies.
- Use realistic, consistent fictional data for Instituto Federal Goiano — Câmpus Urutaí, semester 2026/2 and coordinator Marina Costa.

## Review Focus

- SVG import: test each file has one matching `width`, `height` and `viewBox` so Figma does not crop or scale it unexpectedly.
- Text editability: test files have `<text>` copy and no conversion of labels or values into `<path>` elements.
- Cross-screen consistency: test the names of key classes, people and attendance counts stay consistent among dashboard, class detail, calls and reports.
- Responsive navigation: test every desktop page contains the coordinator sidebar and every mobile page contains the five-target bottom navigation.
- Attendance correction: test the attendance review screen exposes individual status edits, audit information and a confirmation action.

---

### Task 1: Establish the editable SVG foundation and validation

**Files:**
- Create: `design/admin-panel/README.md`
- Create: `design/admin-panel/scripts/validate-svg-assets.ps1`
- Test: `design/admin-panel/scripts/validate-svg-assets.ps1`

**Interfaces:**
- Consumes: the visual tokens and screen inventory defined in the specification.
- Produces: `Test-AdminSvgAssets -Root <path>` validation command for all subsequent screen assets.

- [ ] **Step 1: Write the failing SVG asset validation checks**

Add `Test-AdminSvgAssets` checks asserting that each supplied SVG has a root `<svg>`, an explicit expected artboard size, an exact viewBox, at least one `<text>` node, no `<image>` node and no remote `href`.

- [ ] **Step 2: Run validation to verify it fails with an empty asset directory**

Run: `powershell -ExecutionPolicy Bypass -File design/admin-panel/scripts/validate-svg-assets.ps1`

Expected: FAIL reporting the missing inventory of 15 SVG files.

- [ ] **Step 3: Implement the shared asset conventions in `design/admin-panel/README.md` and the validator**

Document imports, file names, desktop/mobile artboard sizes, palette and the requirement to retain `<text>` elements. Make the script check the exact inventory from Tasks 2–5.

- [ ] **Step 4: Run validation to verify the validator parses and reports only missing files**

Run: `powershell -ExecutionPolicy Bypass -File design/admin-panel/scripts/validate-svg-assets.ps1`

Expected: the script exits non-zero and lists only assets not yet created.

- [ ] **Step 5: Commit**

```bash
git add design/admin-panel
git commit -m "chore: add admin SVG asset conventions"
```

### Task 2: Create desktop operational overview assets

**Files:**
- Create: `design/admin-panel/01-dashboard-desktop.svg`
- Create: `design/admin-panel/02-classes-desktop.svg`
- Create: `design/admin-panel/03-class-detail-desktop.svg`
- Test: `design/admin-panel/scripts/validate-svg-assets.ps1`

**Interfaces:**
- Consumes: asset rules from Task 1.
- Produces: desktop dashboard and class-management SVGs using the shared sidebar/header architecture.

- [ ] **Step 1: Extend the validation inventory tests with the three filenames and desktop 1440 × 1024 constraint**

The assertions must require `Visão geral`, `Turmas` and `Detalhes da turma` as visible editable labels in their corresponding SVGs.

- [ ] **Step 2: Run the validator and verify the three missing desktop assets fail**

Run: `powershell -ExecutionPolicy Bypass -File design/admin-panel/scripts/validate-svg-assets.ps1`

Expected: FAIL listing the three overview/class SVGs.

- [ ] **Step 3: Create `01-dashboard-desktop.svg`**

Include sidebar navigation, top search/notification/profile controls, presence metric cards, weekly presence chart, review queue, active classes and recent activity for Marina Costa.

- [ ] **Step 4: Create `02-classes-desktop.svg` and `03-class-detail-desktop.svg`**

Create a searchable/filterable class table and an individual class view with monthly presence, roster, responsible professor and call history. Keep students/totals consistent with the dashboard.

- [ ] **Step 5: Run the validator to verify the three overview/class assets pass**

Run: `powershell -ExecutionPolicy Bypass -File design/admin-panel/scripts/validate-svg-assets.ps1`

Expected: these three assets pass; the remaining inventory is still reported as missing.

- [ ] **Step 6: Commit**

```bash
git add design/admin-panel/01-dashboard-desktop.svg design/admin-panel/02-classes-desktop.svg design/admin-panel/03-class-detail-desktop.svg design/admin-panel/scripts/validate-svg-assets.ps1
git commit -m "feat: add coordinator desktop overview assets"
```

### Task 3: Create desktop people and attendance-management assets

**Files:**
- Create: `design/admin-panel/04-students-desktop.svg`
- Create: `design/admin-panel/05-teachers-desktop.svg`
- Create: `design/admin-panel/06-attendance-center-desktop.svg`
- Create: `design/admin-panel/07-attendance-review-desktop.svg`
- Test: `design/admin-panel/scripts/validate-svg-assets.ps1`

**Interfaces:**
- Consumes: shared desktop architecture from Task 2 and the data consistency constraints.
- Produces: people-management, attendance queue and editable review artifacts.

- [ ] **Step 1: Add validation checks for people and attendance SVG labels**

Require `Alunos`, `Professores`, `Chamadas` and `Revisar chamada`; specifically assert the review page includes per-student editable status affordances and `Confirmar chamada`.

- [ ] **Step 2: Run the validator and verify these four files fail as missing**

Run: `powershell -ExecutionPolicy Bypass -File design/admin-panel/scripts/validate-svg-assets.ps1`

Expected: FAIL listing the four people/attendance SVGs.

- [ ] **Step 3: Create `04-students-desktop.svg` and `05-teachers-desktop.svg`**

Create usable management tables with search, filters, compact avatars, status chips, row actions and primary actions for student creation and teacher invitation.

- [ ] **Step 4: Create `06-attendance-center-desktop.svg` and `07-attendance-review-desktop.svg`**

Create a filterable attendance history/exception queue and a detailed review screen that displays source/audit information, individual presence selectors, reason notes, confirmation and return actions.

- [ ] **Step 5: Run the validator and verify the people/attendance assets pass**

Run: `powershell -ExecutionPolicy Bypass -File design/admin-panel/scripts/validate-svg-assets.ps1`

Expected: the assets created in this task pass; only unfinished report/settings/mobile screens are missing.

- [ ] **Step 6: Commit**

```bash
git add design/admin-panel/04-students-desktop.svg design/admin-panel/05-teachers-desktop.svg design/admin-panel/06-attendance-center-desktop.svg design/admin-panel/07-attendance-review-desktop.svg design/admin-panel/scripts/validate-svg-assets.ps1
git commit -m "feat: add coordinator attendance management assets"
```

### Task 4: Create desktop reporting and settings assets

**Files:**
- Create: `design/admin-panel/08-reports-desktop.svg`
- Create: `design/admin-panel/09-settings-desktop.svg`
- Test: `design/admin-panel/scripts/validate-svg-assets.ps1`

**Interfaces:**
- Consumes: desktop architecture and data model established in Tasks 2–3.
- Produces: visual reporting and administrative settings SVGs.

- [ ] **Step 1: Add report/settings copy assertions to the validation script**

Require `Relatórios`, `Exportar relatório`, `Configurações`, `Regras de presença` and `Integração de IA`.

- [ ] **Step 2: Run the validator and verify these files fail as missing**

Run: `powershell -ExecutionPolicy Bypass -File design/admin-panel/scripts/validate-svg-assets.ps1`

Expected: FAIL listing report/settings assets.

- [ ] **Step 3: Create `08-reports-desktop.svg` and `09-settings-desktop.svg`**

Provide a report page with period/class filters, trend charts, comparison tables and export action; provide settings with institution profile, attendance rules, AI integration health and coordinator invitations.

- [ ] **Step 4: Run the validator to verify both desktop final assets pass**

Run: `powershell -ExecutionPolicy Bypass -File design/admin-panel/scripts/validate-svg-assets.ps1`

Expected: all nine desktop files pass; six mobile assets remain missing.

- [ ] **Step 5: Commit**

```bash
git add design/admin-panel/08-reports-desktop.svg design/admin-panel/09-settings-desktop.svg design/admin-panel/scripts/validate-svg-assets.ps1
git commit -m "feat: add coordinator reporting and settings assets"
```

### Task 5: Create responsive mobile coordinator assets

**Files:**
- Create: `design/admin-panel/10-dashboard-mobile.svg`
- Create: `design/admin-panel/11-classes-mobile.svg`
- Create: `design/admin-panel/12-attendance-mobile.svg`
- Create: `design/admin-panel/13-reports-mobile.svg`
- Create: `design/admin-panel/14-more-mobile.svg`
- Create: `design/admin-panel/15-notifications-mobile.svg`
- Test: `design/admin-panel/scripts/validate-svg-assets.ps1`

**Interfaces:**
- Consumes: global palette, labels and data from desktop assets.
- Produces: the five bottom-navigation destinations plus the notification center, all on 390 × 844 artboards.

- [ ] **Step 1: Add mobile inventory and bottom-navigation validation checks**

Require the six mobile filenames, `390 × 844` dimensions, and editable labels for `Início`, `Turmas`, `Chamadas`, `Relatórios` and `Mais` in each primary mobile destination.

- [ ] **Step 2: Run the validator and verify the six mobile files fail as missing**

Run: `powershell -ExecutionPolicy Bypass -File design/admin-panel/scripts/validate-svg-assets.ps1`

Expected: FAIL listing the missing mobile assets.

- [ ] **Step 3: Create `10-dashboard-mobile.svg`, `11-classes-mobile.svg` and `12-attendance-mobile.svg`**

Adapt the desktop information architecture to compact cards and lists. Preserve dashboard metrics, class occupancy/status and attendance review alerts, while retaining accessible mobile target sizes.

- [ ] **Step 4: Create `13-reports-mobile.svg`, `14-more-mobile.svg` and `15-notifications-mobile.svg`**

Include readable mobile report summaries/filters, a More hub for secondary sections, and an alert list for pending reviews, low attendance and recent confirmations.

- [ ] **Step 5: Run the validator and verify the entire 15-SVG package passes**

Run: `powershell -ExecutionPolicy Bypass -File design/admin-panel/scripts/validate-svg-assets.ps1`

Expected: PASS with 15 validated SVG artboards and no external dependencies.

- [ ] **Step 6: Commit**

```bash
git add design/admin-panel/10-dashboard-mobile.svg design/admin-panel/11-classes-mobile.svg design/admin-panel/12-attendance-mobile.svg design/admin-panel/13-reports-mobile.svg design/admin-panel/14-more-mobile.svg design/admin-panel/15-notifications-mobile.svg design/admin-panel/scripts/validate-svg-assets.ps1
git commit -m "feat: add responsive coordinator mobile assets"
```

### Task 6: Verify Figma import readiness and package handoff

**Files:**
- Modify: `design/admin-panel/README.md`
- Test: `design/admin-panel/scripts/validate-svg-assets.ps1`

**Interfaces:**
- Consumes: complete asset package from Tasks 1–5.
- Produces: import instructions and verified deliverable paths.

- [ ] **Step 1: Add expected import and visual QA checks to the README**

Document one-file-per-artboard import, font fallback behavior, editable text verification and desktop/mobile frame naming.

- [ ] **Step 2: Run final technical validation**

Run: `powershell -ExecutionPolicy Bypass -File design/admin-panel/scripts/validate-svg-assets.ps1`

Expected: PASS.

- [ ] **Step 3: Perform visual QA of all SVGs at native dimensions**

Open each SVG in a browser or Figma-compatible renderer. Confirm there is no clipped content, text collision, missing shell/navigation, or contrast failure in success/warning/error states.

- [ ] **Step 4: Commit**

```bash
git add design/admin-panel/README.md
git commit -m "docs: add admin panel Figma import guide"
```

## Self-review

- **Spec coverage:** Tasks 2–5 map directly to the 15-screen inventory; Task 1 covers standalone/editable SVG requirements and Task 6 covers import validation.
- **Step scan:** Tasks are arranged by reusable architecture and verifiable screen groups. Each creates an independently reviewable set of SVGs.
- **Type consistency:** No runtime types are introduced. The validator interface is defined once in Task 1 and reused across all tasks.
- **Review Focus:** Technical, navigation, data-consistency and attendance-editing risks are represented in explicit validation requirements in Tasks 1, 3 and 5.
- **Proportion:** The plan specifies outputs, data and verification without prescribing each SVG primitive.
