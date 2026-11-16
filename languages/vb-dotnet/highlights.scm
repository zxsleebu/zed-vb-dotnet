; ---------------------------------------------------------------------------
; VB.NET syntax highlighting
;
; Requires the *patched* CodeAnt-AI/tree-sitter-vb-dotnet grammar (see README).
; Upstream compiles every keyword to a hidden regex token, which tree-sitter
; queries cannot capture. The patch aliases them to plain names like "Class",
; which is what the string patterns below match against.
;
; Classification follows Visual Studio (Roslyn's VB ClassificationHelpers):
; control-flow keywords are told apart from other keywords *by context*
; (`End` in `End If` is control, in `End Sub` it is not), primitive types and
; `Nothing`/`Me` are keywords, and so on.
;
; Every capture carries a `.vb` suffix. Zed resolves a capture to the longest
; dotted prefix the theme defines, so `@keyword.control.vb` falls back to
; `keyword.control` and then `keyword` in any theme. The suffix lets users
; recolour VB alone through `theme_overrides` (see README) without touching
; other languages.
;
; Zed gives precedence to the *later* pattern when two capture the same node,
; so specific patterns come after general ones.
; ---------------------------------------------------------------------------

; --- Comments -------------------------------------------------------------

(comment) @comment.vb

; ''' XML documentation comments
((comment) @comment.doc.vb
	(#match? @comment.doc.vb "^'''"))

; --- Preprocessor ---------------------------------------------------------

(preprocessor_directive) @preproc.vb

; --- Keywords -------------------------------------------------------------

[
	"Option"
	"Explicit"
	"Strict"
	"Infer"
	"Compare"
	"Binary"
	"Text"
	"On"
	"Off"
	"Imports"
	"Namespace"
	"Class"
	"Module"
	"Structure"
	"Interface"
	"Enum"
	"Delegate"
	"Sub"
	"Function"
	"Property"
	"Event"
	"Get"
	"Set"
	"AddHandler"
	"RemoveHandler"
	"RaiseEvent"
	"Inherits"
	"Implements"
	"Handles"
	"(Of"
	"As"
	"New"
	"From"
	"Const"
	"Dim"
	"ReDim"
	"Preserve"
	"If"
	"Then"
	"Else"
	"ElseIf"
	"Select"
	"Case"
	"While"
	"Do"
	"Loop"
	"Until"
	"For"
	"Each"
	"In"
	"To"
	"Step"
	"Next"
	"Try"
	"Catch"
	"Finally"
	"When"
	"Throw"
	"With"
	"Using"
	"SyncLock"
	"Return"
	"Exit"
	"Continue"
	"GoTo"
	"Call"
	"End"
	"Optional"
	"ByVal"
	"ByRef"
	"ParamArray"
	; Operator keywords are plain keywords in Visual Studio.
	"Not"
	"And"
	"Or"
	"Xor"
	"AndAlso"
	"OrElse"
	"Mod"
	"Is"
	"IsNot"
	"Like"
	"TypeOf"
	"AddressOf"
] @keyword.vb

(modifier) @keyword.modifier.vb

; Primitive types (`Integer`, `String`, `Object`, ...) are keywords in VB.
(primitive_type) @type.builtin.vb

"Nothing" @constant.builtin.vb

; Keywords the grammar parses as identifiers.
((identifier) @variable.special.vb
	(#match? @variable.special.vb "^(?i)(me|mybase|myclass)$"))

((identifier) @keyword.vb
	(#match? @keyword.vb "^(?i)(await|global)$"))

; --- Control-flow keywords (Visual Studio's "Keyword - Control") ----------

(if_statement
	[
		"If"
		"Then"
		"Else"
		"End"
		; single-line `If x Then Return` / `Then Exit For` / ...
		"Return"
		"Exit"
		"Continue"
		"Throw"
		"GoTo"
		"Do"
		"For"
		"While"
		"Select"
		"Try"
		"Sub"
		"Function"
		"Property"
	] @keyword.control.vb)

(elseif_clause
	[
		"ElseIf"
		"Then"
	] @keyword.control.vb)

(else_clause "Else" @keyword.control.vb)

(ternary_expression "If" @keyword.control.vb)

(select_case_statement
	[
		"Select"
		"Case"
		"End"
	] @keyword.control.vb)

(case_block "Case" @keyword.control.vb)

(case_else_block
	[
		"Case"
		"Else"
	] @keyword.control.vb)

(for_statement
	[
		"For"
		"To"
		"Next"
	] @keyword.control.vb)

(for_each_statement
	[
		"For"
		"Each"
		"In"
		"Next"
	] @keyword.control.vb)

(while_statement
	[
		"While"
		"End"
	] @keyword.control.vb)

(do_statement
	[
		"Do"
		"Loop"
		"While"
		"Until"
	] @keyword.control.vb)

(try_statement
	[
		"Try"
		"End"
	] @keyword.control.vb)

(catch_block "Catch" @keyword.control.vb)

(finally_block "Finally" @keyword.control.vb)

(return_statement "Return" @keyword.control.vb)

(throw_statement "Throw" @keyword.control.vb)

(goto_statement "GoTo" @keyword.control.vb)

; `Exit For`, `Exit Sub`, `Continue Do`, ...: every word is a control keyword.
(exit_statement _ @keyword.control.vb)

(continue_statement _ @keyword.control.vb)

; --- Operators ------------------------------------------------------------

[
	"+"
	"-"
	"*"
	"/"
	"\\"
	"^"
	"&"
	"="
	"<>"
	"<"
	">"
	"<="
	">="
	"<<"
	">>"
	"+="
	"-="
	"*="
	"/="
	"\\="
	"^="
	"&="
	"<<="
	">>="
	"?"
] @operator.vb

(relational_operator) @operator.vb

; --- Punctuation ----------------------------------------------------------

[
	"("
	")"
	"{"
	"}"
] @punctuation.bracket.vb

[
	"."
	","
	":"
] @punctuation.delimiter.vb

; --- Literals -------------------------------------------------------------

(string_literal) @string.vb
(interpolated_string_literal) @string.vb
(character_literal) @string.vb

; Visual Studio colours #1/1/2000# date literals as numbers.
(date_literal) @number.vb
(integer_literal) @number.vb
(floating_point_literal) @number.vb

(boolean_literal) @boolean.vb

(interpolation
	"{" @punctuation.special.vb
	"}" @punctuation.special.vb)

; --- Namespaces -----------------------------------------------------------

(imports_statement namespace: (namespace_name (identifier) @namespace.vb))
(imports_statement alias: (identifier) @type.vb)
(namespace_block name: (namespace_name (identifier) @namespace.vb))

; --- Types ----------------------------------------------------------------

; In `System.Text.StringBuilder` only the last part is the type; the
; qualifiers before it are namespaces.
(type (namespace_name (identifier) @namespace.vb))
(type (generic_type (namespace_name (identifier) @namespace.vb)))
(type (array_type (namespace_name (identifier) @namespace.vb)))

(type (namespace_name (identifier) @type.vb .))
(type (generic_type (namespace_name (identifier) @type.vb .)))
(type (array_type (namespace_name (identifier) @type.vb .)))

; --- Declarations ---------------------------------------------------------

(class_block name: (identifier) @type.vb)
(module_block name: (identifier) @type.vb)
(structure_block name: (identifier) @type.vb)
(delegate_declaration name: (identifier) @type.vb)
(interface_block name: (identifier) @type.interface.vb)
(enum_block name: (identifier) @type.enum.vb)
(type_parameter name: (identifier) @type.parameter.vb)

(enum_member name: (identifier) @constant.enum.vb)
(const_declaration name: (identifier) @constant.vb)

(method_declaration name: (identifier) @function.vb)
(property_declaration name: (identifier) @property.vb)
(event_declaration name: (identifier) @property.vb)
(raise_event_statement name: (identifier) @property.vb)

(variable_declarator name: (identifier) @variable.vb)
(for_statement variable: (identifier) @variable.vb)
(for_each_statement variable: (identifier) @variable.vb)
(catch_block exception: (identifier) @variable.vb)
(using_statement resource: (identifier) @variable.vb)
(redim_statement array: (identifier) @variable.vb)

(parameter name: (identifier) @variable.parameter.vb)
(lambda_parameter name: (identifier) @variable.parameter.vb)

(label_statement label: (identifier) @label.vb)
(goto_statement label: (identifier) @label.vb)

; --- Usage ----------------------------------------------------------------

(member_access member: (identifier) @property.vb)
(with_member_access member: (identifier) @property.vb)
(qualified_member member: (identifier) @property.vb)
(member_initializer member: (identifier) @property.vb)
(argument name: (identifier) @variable.parameter.vb)

(invocation target: (identifier) @function.vb)
(invocation target: (member_access member: (identifier) @function.vb))

(unary_expression
	operator: "AddressOf"
	operand: (expression [
		(identifier) @function.vb
		(member_access member: (identifier) @function.vb)
	]))

; Conversion operators and other intrinsics look like calls but are keywords.
(invocation
	target: (identifier) @keyword.vb
	(#match? @keyword.vb "^(?i)(ctype|directcast|trycast|cbool|cbyte|cchar|cdate|cdbl|cdec|cint|clng|cobj|csbyte|cshort|csng|cstr|cuint|culng|cushort|gettype|nameof|getxmlnamespace)$"))

; --- Attributes -----------------------------------------------------------

; Visual Studio colours attribute names as the classes they are.
(attribute name: (identifier) @type.attribute.vb)
(attribute name: (namespace_name (identifier) @type.attribute.vb .))
(attribute target: (identifier) @keyword.vb)

(attribute_block
	"<" @punctuation.bracket.vb
	">" @punctuation.bracket.vb)
