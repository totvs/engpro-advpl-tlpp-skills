---
name: mvc-generator
description: "Generate Protheus MVC (Model-View-Controller) screen structures including ModelDef, ViewDef, MenuDef, and Browse functions. Supports single-entity (Modelo 1) and master-detail (Modelo 3) patterns with FWFormModel, FWFormView, FWMBrowse, validations, triggers, and entry point hooks. Use when user says 'create MVC screen', 'ModelDef ViewDef', 'FWFormModel', 'master-detail screen'."
license: MIT
metadata:
  domain: Protheus
  maintainer: Customizações ADVPL/TLPP
  author: Thalion Starforge
  version: '4.1.1'
  category: Code Generation
---

# Protheus MVC Generator

## Overview

Generate complete Protheus MVC screen implementations following the TOTVS framework patterns. Protheus MVC separates business rules (Model), visual presentation (View), and navigation/actions (Controller/Browse) using the `FWFormModel` and `FWFormView` framework classes, plus `FWMBrowse` for the Browse grid. This skill generates the three mandatory functions (`ModelDef`, `ViewDef`, `MenuDef`) plus the Browse function that composes them.

> **Correction (v4.1.1):** `FWFormBrowse` is not a real Protheus class — the Browse grid is built with `FWMBrowse`. Likewise, `MPFormModel` has no `SetCommit()`/`SetActivate()`/`SetVldActive()` methods; pass `bPreValid`, `bPosValid`, and `bCommit` as the 2nd–4th positional parameters of `MPFormModel():New()` instead (see the Checklist and code templates below). Earlier examples using those fabricated names produced runtime "class not found" errors.

## When to Use

Use this skill when:

- Creating a new CRUD screen for a Protheus table
- Building a master-detail form (e.g., invoice header + items)
- Generating MVC boilerplate from a table alias
- Adding validations, triggers, and entry point hooks to MVC screens
- Migrating legacy AxCadastro/Mbrowse screens to MVC

---

## MVC Architecture in Protheus

### Core Components

```
┌─────────────────────────────────────────┐
│  Main Function (e.g., MYMOD01)          │
│  ├── MenuDef()  → Menu actions          │
│  └── FWMBrowse → Browse grid            │
│       ├── ModelDef() → Business rules   │
│       │    ├── FWFormStruct → Schema    │
│       │    ├── FWFormFieldsModel (Form) │
│       │    ├── FWFormGridModel (Grid)   │
│       │    └── Validations / Triggers   │
│       └── ViewDef()  → Visual layout    │
│            ├── FWFormStruct → Schema    │
│            ├── Form panels              │
│            └── Grid panels              │
└─────────────────────────────────────────┘
```

### User Function Responsibilities

| Function      | Purpose                                                              | Returns              |
| ------------- | -------------------------------------------------------------------- | -------------------- |
| `ModelDef()`  | Defines the data model: fields, validations, relationships, triggers | `FWFormModel` object |
| `ViewDef()`   | Defines the visual layout: panels, grids, field arrangement          | `FWFormView` object  |
| `MenuDef()`   | Defines available actions: Include, Edit, Delete, View, Copy         | Array of menu items  |
| Main Function | Creates `FWMBrowse` and activates the screen                         | —                    |

---

## Bundled Reference Files

This skill uses progressive disclosure. The SKILL.md body covers the architecture, generation workflow, the checklist, and troubleshooting. Detailed code templates and API references are in the `references/` directory — read them on demand based on the scenario:

| Reference File | When to Read | Content |
| --- | --- | --- |
| [references/mvc-code-templates.md](references/mvc-code-templates.md) | Generating **MVC code** — Single Entity (Modelo 1) or Master-Detail (Modelo 3) templates, event handlers, validation/commit patterns | Full code templates for both MVC patterns, ModelDef/ViewDef/MenuDef boilerplate, validation handlers, commit handlers |
| [references/mvc-api-reference.md](references/mvc-api-reference.md) | Customizing **FWFormStruct**, adjusting **View layout** (boxes, tabs), configuring **MenuDef** actions, or adding custom menu buttons | FWFormStruct parameters, structure customization (RemoveField, SetProperty, FWBuildFeature), HBox/VBox/Folder layout, action codes table, custom actions |

> Also refer to [references/sonarqube-rules-reference.md](../references/sonarqube-rules-reference.md) for the complete SonarQube rules reference shared across skills.

---

## Generation Workflow

### Step 1: Gather Requirements

Determine the generation pattern from the user's request:

| Scenario | MVC Pattern | Key Characteristic |
| --- | --- | --- |
| Simple CRUD (single table) | Single Entity (Modelo 1) | `AddFields` only, no grid |
| Master-detail (header + items) | Master-Detail (Modelo 3) | `AddFields` + `AddGrid` + `SetRelation` |
| Legacy migration (AxCadastro/Mbrowse) | Depends on current structure | Analyze existing code to choose pattern |

Read the appropriate reference files based on the pattern identified:
- **Code generation** → read [references/mvc-code-templates.md](references/mvc-code-templates.md)
- **Structure customization or layout** → read [references/mvc-api-reference.md](references/mvc-api-reference.md)

### Step 2: Generate Code

Using the selected template from the reference files, adapt it to the user's specific requirements:
- Replace table aliases (`ZZ1`, `ZZ2`, `ZZ3`) with actual table aliases
- Replace function/model IDs (`MYMOD01`, `MYMOD01M`) with actual routine names
- Add/remove fields, validations, and triggers as needed
- Adjust View layout proportions and structure

### Step 3: Validate Against Checklist

Run through the MVC Generation Checklist below to verify completeness.

---

## MVC Generation Checklist

### Model (ModelDef)

- [ ] `FWFormStruct(1, "XXX")` loaded for each table
- [ ] Fields removed/customized as needed
- [ ] Model created with `MPFormModel():New("UNIQUE_ID")`
- [ ] `AddFields` called for form sections
- [ ] `AddGrid` called for grid sections (master-detail)
- [ ] Relationship defined with `SetRelation` for grids
- [ ] Model and sub-model descriptions set
- [ ] `SetPrimaryKey({})` called
- [ ] `bPreValid`, `bPosValid`, and `bCommit` blocks passed positionally to `MPFormModel():New()` (there is no `SetActivate`/`SetVldActive`/`SetCommit` method)
- [ ] Grid line validation passed as `bPreLine`/`bPosLine` positional params to `AddGrid()` (there is no `SetPreLine`/`SetVldLine` method)

### View (ViewDef)

- [ ] Model loaded with `FWLoadModel("ROUTINE_NAME")`
- [ ] `FWFormStruct(2, "XXX")` loaded for each table
- [ ] `FWFormView():New()` created
- [ ] Model set with `SetModel(oModel)`
- [ ] `AddField` and/or `AddGrid` called for each visual section
- [ ] Layout boxes created (`CreateHorizontalBox`, `CreateVerticalBox`)
- [ ] Views assigned to boxes with `SetOwnerView`
- [ ] Screen proportions make sense (header vs. detail)

### MenuDef

- [ ] Standard CRUD operations included (1-5)
- [ ] Custom actions added if needed
- [ ] Menu item names match `VIEWDEF.ROUTINE_NAME`

### General

- [ ] `#include "fwmvcdef.ch"` present
- [ ] `#include "totvs.ch"` present
- [ ] Browse function creates `FWMBrowse` and sets alias
- [ ] Legends added to browse if the table has status fields
- [ ] Validation messages use `Help()` function
- [ ] `FWFormCommit(oModel)` called in commit handler for standard persistence
- [ ] Custom tables registered in SX2/SX3 data dictionary before use

### SonarQube Compliance

- [ ] `FWFormCommit(oModel)` is used for persistence — never override a `FormCommit` method; to intercept commit behavior, pass a custom block as the `bCommit` (4th) positional parameter of `MPFormModel():New()`
- [ ] No UI calls (`MsgAlert`, `MsgYesNo`, `Aviso`, `Help`, `Pergunte`, `ParamBox`) inside commit/validation handlers that execute within a transaction
- [ ] Error handling uses `Try-Catch`, not `ErrorBlock`
- [ ] Logging via `FWLogMsg()`, not `ConOut()`
- [ ] No `IIF()` in expressions — use `If/Else/EndIf`
- [ ] Includes in lowercase (e.g., `#include "totvs.ch"`)
- [ ] `GetMV()` / `ExistBlock()` results cached before loops (especially in grid validations)
- [ ] No direct access to SX3 via `DbSelectArea` — use `FWFormStruct()` or `FWSX3Util()`

> Refer to [references/sonarqube-rules-reference.md](../references/sonarqube-rules-reference.md) for the complete SonarQube rules reference.

---

## Troubleshooting

- **"Field not found in SX3"**: The field referenced in `FWFormStruct` must exist in the data dictionary (SX3). Run `CFGX023()` or use SIGACFG to register missing fields.
- **ModelDef/ViewDef mismatch**: Every field ID added to `FWFormModel` must have a corresponding entry in `FWFormView`. Verify that model and view structures reference the same field set.
- **Grid rows not saving**: Ensure `FWFormCommit(oModel)` is called in the commit block. For master-detail, the grid model must be added with `AddGrid()` and linked via `SetOwner()`.
- **Browse shows no records**: Verify `FWMBrowse():SetAlias()` points to the correct table alias and that the table is accessible from the current branch/company.
- **Validation not triggering**: Field-level validators must be registered in SX3 (X3_VALID) or via `SetFieldAction()` on the model. Check that the trigger field ID matches exactly.

