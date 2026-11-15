# ClassVision Admin Roles SVG Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the existing ClassVision SVG package with a distinct global System Administrator panel and institution-level coordinator management.

**Architecture:** Add nine standalone desktop SVG artboards for the global platform domain, update the existing institution settings artboard, and add one mobile coordinator-management artboard. Extend the existing PowerShell validator so all 25 files are checked as one coherent, Figma-ready package.

**Tech Stack:** Plain SVG 1.1, Inter text elements, PowerShell validation, Figma import.

**Spec:** `docs/superpowers/specs/2026-11-15-classvision-admin-roles-design.md`

## Global Constraints

- System Administrator sees only institutions, administrators, users, statuses and audit events; no academic records.
- Institution Administrator inherits Coordinator operations and additionally manages institution settings, integrations and Coordinators.
- Coordinator never receives global, team-management or integration actions.
- Desktop artboards are exactly `1440 × 1024`; the new mobile artboard is exactly `390 × 844`.
- Retain copy as editable `<text>` nodes using Inter and use no external images, URLs or symbols.
- Reuse the existing ClassVision palette and institutional demonstration data.

## Review Focus

- Global screens must not expose class, student, attendance or academic-report data.
- Institution creation must include the institution and first administrator as a two-step flow and email invitation.
- Institution details may show Coordinators read-only, while only the Institution Administrator variant edits them.
- Shared names, statuses and totals must match across global dashboard, institutions, details and administrator lists.
- Every screen must remain importable as standalone SVG with the correct artboard and editable copy.

---

### Task 1: Extend validation for role-aware assets

**Files:**
- Modify: `design/admin-panel/scripts/validate-svg-assets.ps1`
- Modify: `design/admin-panel/README.md`

**Interfaces:**
- Consumes: the existing `Test-AdminSvgAssets` inventory and SVG conventions.
- Produces: validation for 25 total artboards and documentation of the three roles.

- [ ] **Step 1: Add failing inventory assertions for files 16–25**

Require the nine global desktop filenames and one institutional mobile filename, exact artboard dimensions, visible role-specific headings and editable `<text>` nodes.

- [ ] **Step 2: Run the validator and observe the ten missing-file failures**

Run: `powershell -ExecutionPolicy Bypass -File design/admin-panel/scripts/validate-svg-assets.ps1`

Expected: FAIL listing files 16–25 only.

- [ ] **Step 3: Document roles, import order and global/institutional frame naming in the README**

- [ ] **Step 4: Commit**

```bash
git add design/admin-panel/scripts/validate-svg-assets.ps1 design/admin-panel/README.md
git commit -m "chore: extend admin role SVG validation"
```

### Task 2: Create global entry, dashboard and institution-list screens

**Files:**
- Create: `design/admin-panel/16-system-admin-login-desktop.svg`
- Create: `design/admin-panel/17-system-dashboard-desktop.svg`
- Create: `design/admin-panel/18-institutions-desktop.svg`

**Interfaces:**
- Consumes: global navigation and visual rules from the specification.
- Produces: the entry point and main discovery flow for the System Administrator.

- [ ] **Step 1: Create the three desktop artboards**

Login identifies global access; dashboard shows administrative platform metrics and activity only; institutions shows searchable status/admin/user columns without academic data.

- [ ] **Step 2: Run validation**

Expected: files 16–18 pass; files 19–25 remain missing.

- [ ] **Step 3: Commit**

```bash
git add design/admin-panel/16-system-admin-login-desktop.svg design/admin-panel/17-system-dashboard-desktop.svg design/admin-panel/18-institutions-desktop.svg
git commit -m "feat: add global admin overview SVGs"
```

### Task 3: Create institution onboarding and detail flow

**Files:**
- Create: `design/admin-panel/19-create-institution-desktop.svg`
- Create: `design/admin-panel/20-institution-detail-desktop.svg`
- Create: `design/admin-panel/24-institution-created-desktop.svg`

**Interfaces:**
- Consumes: institution names, statuses and administrators from Task 2.
- Produces: a complete create/detail/success flow.

- [ ] **Step 1: Create the two-step onboarding artboard**

Show a progress stepper, minimum institution fields, first-administrator fields and explicit email-invitation copy.

- [ ] **Step 2: Create detail and success artboards**

Detail shows administrative metadata and read-only Coordinator summary only. Success confirms institution creation and invitation delivery.

- [ ] **Step 3: Run validation**

Expected: files 19, 20 and 24 pass with no academic-data labels.

- [ ] **Step 4: Commit**

```bash
git add design/admin-panel/19-create-institution-desktop.svg design/admin-panel/20-institution-detail-desktop.svg design/admin-panel/24-institution-created-desktop.svg
git commit -m "feat: add institution onboarding SVGs"
```

### Task 4: Create global administration, audit and settings screens

**Files:**
- Create: `design/admin-panel/21-institution-admins-desktop.svg`
- Create: `design/admin-panel/22-platform-activity-desktop.svg`
- Create: `design/admin-panel/23-platform-settings-desktop.svg`

**Interfaces:**
- Consumes: global shell and coherent demonstration data from Tasks 2–3.
- Produces: remaining platform-level management views.

- [ ] **Step 1: Create administrator, audit and settings artboards**

Administrators includes institution/contact/access/status; audit includes action/institution/user/period filters; settings includes invitation, notification and service-health preferences.

- [ ] **Step 2: Run validation**

Expected: all global desktop SVGs pass; only file 25 and institutional settings adjustment remain.

- [ ] **Step 3: Commit**

```bash
git add design/admin-panel/21-institution-admins-desktop.svg design/admin-panel/22-platform-activity-desktop.svg design/admin-panel/23-platform-settings-desktop.svg
git commit -m "feat: add global administration SVGs"
```

### Task 5: Add institution-level coordinator management

**Files:**
- Modify: `design/admin-panel/09-settings-desktop.svg`
- Create: `design/admin-panel/25-coordinators-mobile.svg`

**Interfaces:**
- Consumes: existing institutional shell and mobile navigation.
- Produces: web and mobile Coordinator-management variants reserved for Institution Administrators.

- [ ] **Step 1: Add desktop Coordinator list and invitation state**

Include email invitation, active/pending/inactive statuses and activate/deactivate actions with “Administrador da instituição” profile labeling.

- [ ] **Step 2: Create mobile Coordinator-management artboard**

Include search, Coordinator list, statuses, invite action and a back affordance into the institutional “Mais” area.

- [ ] **Step 3: Run full validation**

Run: `powershell -ExecutionPolicy Bypass -File design/admin-panel/scripts/validate-svg-assets.ps1`

Expected: PASS with 25 validated standalone SVG artboards.

- [ ] **Step 4: Commit**

```bash
git add design/admin-panel/09-settings-desktop.svg design/admin-panel/25-coordinators-mobile.svg design/admin-panel/scripts/validate-svg-assets.ps1 design/admin-panel/README.md
git commit -m "feat: add institution coordinator management SVGs"
```

### Task 6: Final visual and semantic verification

**Files:**
- Verify: `design/admin-panel/*.svg`

**Interfaces:**
- Consumes: all 25 SVGs.
- Produces: a verified Figma-ready handoff.

- [ ] **Step 1: Parse all SVGs as XML and run the validator**

Expected: 25 XML documents parse and validation passes.

- [ ] **Step 2: Render new artboards at native dimensions**

Confirm no clipping, overlapping copy or off-artboard content.

- [ ] **Step 3: Review role boundaries against the specification**

Confirm global screens contain no academic data and Coordinator screens contain no administrative-team controls.

## Self-review

- Spec coverage: all nine global desktop screens, institutional desktop update and mobile Coordinator screen have owning tasks.
- Step scan: each task creates a cohesive reviewable flow and ends with validation.
- Interface consistency: institution/admin demonstration data originates in Task 2 and is reused by Tasks 3–4.
- Review focus: role leakage, onboarding completeness, read-only global detail, data consistency and SVG integrity are explicitly checked.
- Proportion: the plan fixes filenames, content responsibilities and validation without prescribing every SVG primitive.
