# Changelog

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
