# VB.NET for Zed

Visual Basic .NET support for the [Zed](https://zed.dev) editor:

- syntax highlighting, outline, bracket matching, auto-indent and Vim text objects
  from a tree-sitter grammar;
- completion, go to definition, find references, rename, hover, signature help,
  diagnostics, code actions, formatting and inlay hints from **vb-ls**, the Roslyn
  language server with Visual Basic enabled;
- snippets, build/run/test tasks, and ▶ buttons on `Sub Main` and test methods.

## Install

> **Not yet in the Zed extension registry.** Until it lands,
> use *From source* below.

### Requirements

- **.NET 10 SDK or newer** ([download](https://dotnet.microsoft.com/download/dotnet)),
  with `dotnet` on PATH. The language server runs on it and uses its MSBuild to load
  your projects. You need it even if your projects target an older .NET or .NET
  Framework. A newer SDK, such as .NET 11, works on its own; the server rolls forward
  to it.
- **For .NET Framework projects** (the long, non-SDK-style `.vbproj` files): Windows
  with Visual Studio 2022 or *Build Tools for Visual Studio*. Include the *.NET desktop
  build tools* workload and the targeting packs for your framework version. The
  language server loads these projects through Visual Studio's MSBuild, and the MSBuild
  tasks below use it to build them.
- Restore NuGet packages once, by building in Visual Studio, running `nuget restore`, or
  using the *build solution (MSBuild)* task below. Until they are restored, the language
  server reports the references as missing.

Without the .NET SDK you still get highlighting, outline, snippets and indentation. You
only lose the language server features.

### From the registry

`Ctrl+Shift+P` / `Cmd+Shift+P` -> **zed: extensions** -> search **VB.NET** -> Install.

### From source

```sh
git clone https://github.com/Kellett/zed-vb-dotnet
```

`Ctrl+Shift+P` -> **zed: install dev extension** -> select the clone.

The extension contains Rust code, which Zed compiles to WebAssembly itself. A dev
install therefore needs Rust installed through [rustup](https://rustup.rs), not a
distro package. The first install also needs network access to clone and compile the
grammar.

If you already have a copy installed, remove it from the Extensions panel first. A dev
extension and a registry one with the same id will conflict. Other VB.NET extensions
also register a language for `.vb`, so uninstall those to avoid clashes.

### Check it worked

Open a `.vb` file from a folder containing your `.sln`. Keywords, strings and comments
should be coloured, and the outline panel (`Ctrl+Shift+O`) should list your classes and
methods.

On first use the extension downloads the language server (about 45 MB, from
nuget.org). Roslyn then loads the solution, which can take a minute for a large one;
progress shows in the status bar. When it finishes, hover over a type or press `F12` on it.

To see what the server is doing: `Ctrl+Shift+P` -> **dev: open language server logs**
-> *vb-ls*.

If the file opens as plain text, another extension may have claimed `.vb`. Either switch
manually with `Ctrl+Shift+P` -> **editor: toggle language selector** -> **VB.NET**, or
force it in your settings:

```json
{
  "file_types": {
    "VB.NET": ["vb"]
  }
}
```

## Language server

The language server is [vb-ls](https://github.com/CoolCoderSuper/vb-ls) (MIT). It is
Microsoft's Roslyn language server, the engine behind the VS Code C# extension, with a
small patch that turns Visual Basic on. Your code is analysed by the real VB compiler,
so diagnostics match what Visual Studio shows.

**How the server is found** (first match wins):

1. `lsp.vb-ls.binary.path` in your Zed settings.
2. `vb-ls` on PATH, installed with `dotnet tool install -g vb-ls`. Use this if you want
   to manage the version yourself.
3. Otherwise the extension downloads a pinned, reviewed version (vb-ls 0.4.0) from
   nuget.org into its own folder and runs it with your `dotnet`. nuget.org package
   versions are immutable, so this is always the same build.

**Which projects load.** The server looks, in this order, for:

1. the solution named in `.vscode/settings.json` in the folder you opened in Zed.
   Roslyn reads this file even outside VS Code, and the path is relative to the folder:

   ```json
   { "dotnet.defaultSolution": "src/MyApp.sln" }
   ```

2. exactly one `.sln` or `.slnx` at the folder's root;
3. otherwise every `.vbproj` and `.csproj` anywhere under the folder.

The third step needed two fixes in vb-ls 0.4.0, which the extension applies to the
downloaded server (both are same-length byte swaps in the DLL, applied only when the
bytes match that exact build):

- it searched only `*.csproj` (the `.vbproj` change came after the release), so the
  pattern becomes `*.??proj`;
- it handed the project list to a background task and then freed the list, usually
  before the task had read it, so nothing loaded. VB files then opened with no project
  and no references, with errors like *"a reference to the assembly
  `<Missing Core Assembly>` containing the type `Object` is required"* or *"type
  `System.String` is not defined"*. The extension skips that early free.

A third fix applies however the project is loaded. .NET Framework VB projects get
`mscorlib` from the compiler's `/sdkpath` rather than from a `/reference`, and the server
dropped it, so even a loaded project showed the same errors. The extension patches the
VB command-line parser to put `mscorlib.dll` from `/sdkpath` into the references.
SDK-style projects (`<Project Sdk=...>`) were never affected.

The log line *"project … has unresolved dependencies"* (German: *"weist nicht aufgelöste
Abhängigkeiten auf"*) is expected for projects using `packages.config`: the server looks
for the `obj/project.assets.json` that only `PackageReference` projects have. Packages
from `packages.config` still resolve once restored (build once in Visual Studio).

To check, open **dev: open language server logs** -> *vb-ls*. It should say
`Found single solution file`, `Using VS Code settings to auto load solution` or
`Discovered N projects to auto load`, followed by a successful load of your `.vbproj`.
If a VB file still shows `<Missing Core Assembly>`, its project did not load; the log
says why.

**What works:**

- completion, including types from namespaces you haven't imported yet (accepting one
  adds the `Imports` line);
- go to definition, which opens decompiled metadata for framework types, and go to
  implementation;
- find references and rename;
- hover, signature help and document highlights;
- code actions and quick fixes;
- formatting;
- document and workspace symbols;
- diagnostics for the whole solution.

**Inlay hints** (parameter names at call sites) are off by default in Zed. To turn them on:

```json
{ "inlay_hints": { "enabled": true } }
```

**Semantic highlighting** from Roslyn can be layered on top of tree-sitter. Roslyn knows
whether a name is a class, a module, a local or a field, so this adds information. See
[Colours like Visual Studio](#colours-like-visual-studio) below.

**Server options** go under `lsp.vb-ls.settings`, grouped the way Roslyn names them. The
example below shows the extension's defaults; anything you set is merged on top of them:

```json
{
  "lsp": {
    "vb-ls": {
      "settings": {
        "background_analysis": {
          "dotnet_compiler_diagnostics_scope": "FullSolution",
          "dotnet_analyzer_diagnostics_scope": "OpenFiles"
        },
        "completion": {
          "dotnet_show_completion_items_from_unimported_namespaces": true
        },
        "inlay_hints": {
          "dotnet_enable_inlay_hints_for_parameters": true
        }
      }
    }
  }
}
```

The scope values are `None`, `OpenFiles` and `FullSolution`. On a very large solution, set
compiler diagnostics to `OpenFiles`. The rest of the defaults are in
[`src/lib.rs`](src/lib.rs). Every available option is listed in Roslyn's
`DidChangeConfigurationNotificationHandler`.

## Colours like Visual Studio

Highlighting follows Visual Studio's own classification, taken from Roslyn:

- **Control-flow keywords are a separate class.** `If`/`Then`/`Else`, `For`/`To`/`Next`,
  `For Each`/`In`, `Do`/`Loop`, `While`, `Select Case`, `Try`/`Catch`/`Finally`, `Return`,
  `Throw`, `Exit …`, `Continue …` and `GoTo` are control keywords. Other keywords, such as
  `Dim`, `As`, `Sub` and `New`, are not. The split depends on context: `End If` is control
  but `End Sub` is not, and `To` in `For` is control but in `Dim a(0 To 5)` it is not.
- **Some words are keywords in VB.** Primitive types (`Integer`, `String`, `Object`),
  `Nothing`, `Me`/`MyBase` and conversion operators (`CType`, `DirectCast`, `CStr`, …)
  are keywords.
- **Types are split up further.** Classes, interfaces, enums and type parameters each have
  their own class. Enum members and constants have one too.
- **Qualified names are split.** In `System.IO.MemoryStream`, only `MemoryStream` is a
  type; `System.IO` is a namespace.
- **`#1/1/2000#` date literals** are coloured as numbers.

Every capture ends in `.vb` (`keyword.control.vb`, `type.interface.vb`, …). Any theme
falls back to its normal colours, and you can recolour VB alone without touching other
languages.

For the closest match to Visual Studio / VS Code with the **VSCode Dark Polished** theme,
add this to your Zed `settings.json`:

```json
{
  "languages": {
    "VB.NET": {
      // Roslyn's semantic colours on top of tree-sitter: locals vs fields vs
      // properties, types used in expressions, obsolete members struck through.
      "semantic_tokens": "combined"
    }
  },
  "colorize_brackets": true,
  "indent_guides": { "coloring": "indent_aware" },
  "theme_overrides": {
    "VSCode Dark Polished": {
      "syntax": {
        "keyword.vb": { "color": "#569CD6" },
        "keyword.modifier.vb": { "color": "#569CD6" },
        "keyword.control.vb": { "color": "#C586C0" },
        "type.builtin.vb": { "color": "#569CD6" },
        "constant.builtin.vb": { "color": "#569CD6" },
        "variable.special.vb": { "color": "#569CD6" },
        "type.interface.vb": { "color": "#B8D7A3" },
        "type.enum.vb": { "color": "#B8D7A3" },
        "type.parameter.vb": { "color": "#B8D7A3" },
        "comment.doc.tag.vb": { "color": "#808080" },
        "preproc.vb": { "color": "#9B9B9B" }
      }
    }
  }
}
```

Because every key ends in `.vb`, other languages keep the theme's own colours. For another
theme, put its name in place of `VSCode Dark Polished`.

## Tasks and run buttons

`Ctrl+Shift+P` -> **task: spawn** lists these tasks. The ▶ in the gutter next to
`Sub Main`, a test method or a test class runs the matching task directly.

| Task | Use for |
| --- | --- |
| *build solution* / *rebuild solution (MSBuild)* | .NET Framework solutions. Uses Visual Studio's MSBuild and restores `packages.config`. |
| *build current project (MSBuild)* | The nearest `.vbproj` above the open file. |
| *build and run current project (MSBuild)* | ▶ on `Sub Main`. Builds, then runs the project's `.exe` from `bin\`. |
| *test … (MSBuild + vstest)* | ▶ on MSTest/NUnit/xUnit tests in .NET Framework test projects. |
| *dotnet build / test / run* | SDK-style projects, on any OS. |

The MSBuild tasks run in PowerShell, so they are Windows-only. MSBuild is located with
`vswhere`. To use a different one, set the `VB_MSBUILD` environment variable to the full
path of `MSBuild.exe`.

## Snippets

Type a prefix and pick the snippet from the completion menu. Some of them:

| Prefix | Expands to |
| --- | --- |
| `sub`, `func`, `afunc`, `ctor` | `Sub`, `Function`, `Async Function … As Task(Of T)`, `Sub New` |
| `prop`, `propfull`, `propr`, `propnotify` | auto, backing-field, read-only and `INotifyPropertyChanged` properties |
| `if`, `ife`, `select`, `for`, `foreach`, `dowhile`, `while` | the block together with its `End …` / `Next` / `Loop` |
| `try`, `tryf`, `using`, `with`, `lock` | `Try`/`Catch`[/`Finally`], `Using`, `With`, `SyncLock` |
| `class`, `classi`, `module`, `main`, `interface`, `enum`, `struct` | type declarations |
| `handler`, `event`, `addhandler`, `raise` | a WinForms-style event handler with `Handles`, and other event code |
| `summary`, `param`, `returns` | `'''` XML documentation |
| `testm`, `testc`, `test`, `fact` | MSTest, NUnit and xUnit tests |

The full list is in [`snippets/vb.net.json`](snippets/vb.net.json).

## Editor defaults

Tabs and a tab width of 4 are the defaults, matching Visual Studio. To use spaces
instead, override this in your Zed settings:

```json
{
  "languages": {
    "VB.NET": {
      "hard_tabs": false
    }
  }
}
```

## Why this needs a forked grammar

Zed had no VB.NET extension, and the only tree-sitter grammar for the language,
[CodeAnt-AI/tree-sitter-vb-dotnet](https://github.com/CodeAnt-AI/tree-sitter-vb-dotnet),
could not parse ordinary VB.NET. Measured over 4,151 real files (2.3M lines):

| | Files parsing cleanly |
| --- | --- |
| Upstream grammar | 7% |
| [This fork](https://github.com/Kellett/tree-sitter-vb-dotnet) | **93%** |

Three of the defects were fundamental:

**Keywords were invisible to queries.** Every keyword was built from a case-insensitive
regex, which tree-sitter compiles to a *hidden* token. Hidden tokens never appear in the
syntax tree, so no query could capture `Class`, `Sub`, `End`, `If` or `Dim`. This alone
makes a working `highlights.scm` impossible, which is likely why no VB.NET extension
existed.

**Generics didn't parse.** `type_argument_list` and `type_parameters` were missing their
parentheses, so `As List(Of String)` was a syntax error.

**Identifiers beginning with a keyword broke.** `subtotal` lexed as `Sub` + `To` + `tal`,
and `RemoveAt(1)` was swallowed as a `REM` comment.

The fork also adds `Inherits`/`Implements` on their own line, `As New`, nested types,
member `Implements`/`Handles` clauses, `RaiseEvent`/`AddHandler`/`RemoveHandler`
statements, `With`-block `.member` access, array bounds expressions, single-line and
nested `If/Else`, `From { }` initialisers, import aliases, nullable types, `Select`
without `Case`, UTF-8 BOM handling, multi-line brace initialisers, omitted arguments and
generic method calls.

These fixes have been offered upstream. If they land, this extension will point back at
the original repository.

## Known limitations

- **LINQ query syntax** (`From x In xs Where ... Select ...`) and **XML literals** are not
  implemented by the grammar. They account for most of the remaining 7%. A parse error
  greys out highlighting from that point to the end of the enclosing block. The language
  server is unaffected; turning on `semantic_tokens` restores colour there.
- **`CType(x, Dictionary(Of String, Foo))`** - a type used as a call argument doesn't
  parse. Supporting it made type names and expressions ambiguous and cost accuracy
  elsewhere, so it was left out.
- **Files with no trailing newline** produce a zero-width `MISSING` node at end of file.
  This is cosmetic; highlighting is unaffected. A proper fix needs an external scanner.
- **`#Region` and `#If`** are treated as opaque trivia, so the whole line takes a single
  colour.
- **No automatic `End If` / `End Sub`.** Visual Studio inserts these through a VS-only
  protocol extension that Zed doesn't speak. The snippets (`if`, `sub`, …) insert the
  whole block instead.
- **No debugger.** netcoredbg, the open-source .NET debugger, handles .NET Core/.NET 5+
  but not .NET Framework, which is what most VB.NET code targets.
- **VBA and VB6 are not supported.** They are different languages with different syntax.

## Contributing

Issues and pull requests welcome, on either this repository or the
[grammar fork](https://github.com/Kellett/tree-sitter-vb-dotnet).

Highlighting, outline, indent, text-object and run-button behaviour live in
`languages/vb-dotnet/*.scm` here. Anything about what does or doesn't *parse* belongs in
the grammar fork. Language server integration is in `src/lib.rs`.

Install from source as above, then edit the `.scm` files in place and run
`Ctrl+Shift+P` -> **zed: reload extensions** to see the change. You only need to rebuild
if you've changed the grammar or `src/lib.rs`. To check the Rust side:

```sh
rustup target add wasm32-wasip2
cargo test
cargo build --release --target wasm32-wasip2
```

To check a query compiles and see what it captures, run this from a clone of the
grammar fork:

```sh
tree-sitter query /path/to/zed-vb-dotnet/languages/vb-dotnet/highlights.scm examples/sample.vb
```

`examples/sample.vb` in the grammar fork exercises most of the queries. If you're fixing
a highlighting gap, adding a case to it is the most useful thing you can do.

## Licence

MIT. See [LICENSE](LICENSE).

The bundled grammar is a fork of CodeAnt-AI/tree-sitter-vb-dotnet, also MIT. The
language server, downloaded at runtime, is
[vb-ls](https://github.com/CoolCoderSuper/vb-ls), MIT, built on
[Roslyn](https://github.com/dotnet/roslyn), MIT.
