; Scopes referenced by config.toml (`not_in = ["string", "comment"]`), so a
; `"` typed inside a string or comment is not auto-closed.

(comment) @comment.inclusive

[
	(string_literal)
	(interpolated_string_literal)
	(character_literal)
] @string
