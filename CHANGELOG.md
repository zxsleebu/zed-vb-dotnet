# Changelog

## 0.2.0

- **Language server.** vb-ls (Roslyn with Visual Basic enabled) provides completion,
  go to definition/implementation, find references, rename, hover, signature help,
  diagnostics, code actions, formatting, symbols and inlay hints. It is taken from
  `lsp.vb-ls.binary.path`, then `vb-ls` on PATH, and otherwise a pinned 0.4.0 is
  downloaded from nuget.org. Needs the .NET 10 SDK or newer (runs on
  .NET 11 via roll-forward). Projects load automatically from
  the worktree's `.sln`/`.slnx` or `.vbproj` files.
- **Roslyn options** are sent in the flat `visual_basic|group.option` form Roslyn
  requests, so settings actually apply in Zed. Users can override them under
  `lsp.vb-ls.settings`.
- **Coloured completion and symbol labels** by kind.
- **Tasks:** MSBuild (via vswhere) build/rebuild/run/vstest for .NET Framework
  projects on Windows, and `dotnet build/test/run` for SDK-style projects.
- **Run buttons** (`runnables.scm`) on `Sub Main`, MSTest/NUnit/xUnit test methods
  and test classes.
- **65 snippets** for blocks, members, properties, events, XML docs and tests.
- **`overrides.scm`**, so a `"` typed inside a string or comment is no longer
  auto-closed (`not_in` had no effect before).
- **`textobjects.scm`** for Vim mode (`af`/`if`, `ac`/`ic`, `gc`, `]m`, `]]`).
- **Line-based indentation** while a block is still unterminated, after `If … Then`,
  `Sub`, `For`, `Try` and so on. `Case` lines align with the previous `Case`.
- **Visual Studio's classification.** Control-flow keywords are their own class, split
  by context as Roslyn does (`End If` is control, `End Sub` is not). Primitive types,
  `Nothing`, `Me` and `CType`-style conversions count as keywords. Interfaces, enums,
  type parameters, enum members, constants, namespaces, parameters, locals and
  attributes each have their own class. Date literals are coloured as numbers.
- **`.vb`-suffixed captures** (`keyword.control.vb`, …) fall back to the theme's normal
  colours, and can be recoloured for VB alone via `theme_overrides`.
- **`semantic_token_rules.json`** maps every Roslyn token type, including the custom ones
  (`controlKeyword`, `field`, `module`, `xmlDocComment*`, …), onto the same classes.
  Obsolete members are struck through. Fields are told apart from properties.
- ```` ```vb ```` code fences in Markdown are highlighted as VB.NET.

## 0.1.0

Initial release.

- Syntax highlighting for `.vb` files: keywords, modifiers, built-in and user types,
  strings including interpolation, character and date literals, numbers, comments,
  preprocessor directives, attributes, operators, punctuation, declaration names,
  parameters, properties and labels.
- Outline entries for namespaces, classes, modules, structures, interfaces, enums, enum
  members, delegates, methods, constructors, properties and events.
- Bracket matching for `()`, `{}` and attribute `<>`.
- Auto-indent for `End`-terminated blocks, `Next`, `Loop`, and `ElseIf`/`Else`/`Case`/
  `Catch`/`Finally` clause bodies.
- Defaults to hard tabs at width 4.

Uses a fork of [CodeAnt-AI/tree-sitter-vb-dotnet](https://github.com/CodeAnt-AI/tree-sitter-vb-dotnet)
that raises the parse rate on real VB.NET from 7% to 93%. See the README for detail.
