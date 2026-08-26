# VB.NET for Zed

Visual Basic .NET support for the [Zed](https://zed.dev) editor: syntax highlighting,
code outline, bracket matching and auto-indent for `.vb` files.

## Install

> **Not yet in the Zed extension registry.** Until it lands,
> use *From source* below.

### From the registry

`Ctrl+Shift+P` / `Cmd+Shift+P` -> **zed: extensions** -> search **VB.NET** -> Install.

That is the whole thing. Zed clones the grammar named in `extension.toml`, compiles it to
WebAssembly and loads the queries for you, so there's no separate grammar to install, no
language server to download and no toolchain to set up.

### From source

```sh
git clone https://github.com/Kellett/zed-vb-dotnet
```

`Ctrl+Shift+P` -> **zed: install dev extension** -> select the clone.

You only need this repository; Zed fetches the grammar from GitHub itself. First install
needs network access while it clones and compiles the grammar, which takes a few seconds.
After that it's cached.

If you already have a copy installed, remove it from the Extensions panel first. A dev
extension and a registry one with the same id will conflict.

### Check it worked

Open a `.vb` file. Keywords, strings and comments should be coloured, and the outline
panel (`Ctrl+Shift+O`) should list your classes and methods.

If it opens as plain text, another extension may have claimed `.vb`. Either switch
manually with `Ctrl+Shift+P` -> **editor: toggle language selector** -> **VB.NET**, or
force it in your settings:

```json
{
  "file_types": {
    "VB.NET": ["vb"]
  }
}
```

## What you get

- **Syntax highlighting** - keywords, types, strings (including interpolated), comments,
  numbers, dates, attributes, operators, declaration names, parameters and labels.
- **Outline** - namespaces, classes, modules, structures, interfaces, enums and their
  members, in the outline panel and breadcrumbs.
- **Bracket matching** for `()`, `{}` and attribute `<>`.
- **Auto-indent** for every block form: `End Class`, `End Sub`, `Next`, `Loop`, and the
  clause bodies of `ElseIf`, `Else`, `Case`, `Catch` and `Finally`.

Tabs and a tab width of 4 are the defaults, matching Visual Studio. Override in your Zed
settings if you prefer spaces:

```json
{
  "languages": {
    "VB.NET": {
      "hard_tabs": false
    }
  }
}
```

## No language server

This extension provides highlighting only. There is no open-source VB.NET language
server, so completions, go-to-definition and diagnostics are not available. If that
changes, contributions are welcome.

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
  greys out highlighting from that point to the end of the enclosing block.
- **`CType(x, Dictionary(Of String, Foo))`** - a type used as a call argument doesn't
  parse. Supporting it made type names and expressions ambiguous and cost accuracy
  elsewhere, so it was left out.
- **Files with no trailing newline** produce a zero-width `MISSING` node at end of file.
  This is cosmetic; highlighting is unaffected. A proper fix needs an external scanner.
- **`#Region` and `#If`** are treated as opaque trivia, so the whole line takes a single
  colour.
- **VBA and VB6 are not supported.** They are different languages with different syntax.

## Contributing

Issues and pull requests welcome, on either this repository or the
[grammar fork](https://github.com/Kellett/tree-sitter-vb-dotnet).

Highlighting, outline, indent and bracket behaviour live in
`languages/vb-dotnet/*.scm` here. Anything about what does or doesn't *parse* belongs in
the grammar fork.

Install from source as above, then edit the `.scm` files in place and run
`Ctrl+Shift+P` -> **zed: reload extensions** to see the change. No rebuild needed unless
you've touched the grammar.

To check a query compiles and see what it captures, from a clone of the grammar fork:

```sh
tree-sitter query /path/to/zed-vb-dotnet/languages/vb-dotnet/highlights.scm examples/sample.vb
```

`examples/sample.vb` in the grammar fork exercises most of the queries. If you're fixing
a highlighting gap, adding a case to it is the most useful thing you can do.

## Licence

MIT. See [LICENSE](LICENSE).

The bundled grammar is a fork of CodeAnt-AI/tree-sitter-vb-dotnet, also MIT.
