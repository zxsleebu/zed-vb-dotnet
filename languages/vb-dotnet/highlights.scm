; ---------------------------------------------------------------------------
; VB.NET syntax highlighting
;
; Requires the *patched* CodeAnt-AI/tree-sitter-vb-dotnet grammar (see README).
; Upstream compiles every keyword to a hidden regex token, which tree-sitter
; queries cannot capture. The patch aliases them to plain names like "Class",
; which is what the string patterns below match against.
; ---------------------------------------------------------------------------

; --- Comments -------------------------------------------------------------

(comment) @comment

; --- Preprocessor ---------------------------------------------------------

(preprocessor_directive) @preproc

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
] @keyword

(modifier) @keyword

; --- Operators ------------------------------------------------------------

[
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
] @operator

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
] @operator

(relational_operator) @operator

; --- Punctuation ----------------------------------------------------------

[
	"("
	")"
	"{"
	"}"
] @punctuation.bracket

[
	"."
	","
	":"
] @punctuation.delimiter

; --- Literals -------------------------------------------------------------

(string_literal) @string
(interpolated_string_literal) @string
(character_literal) @string
(date_literal) @string.special

(integer_literal) @number
(floating_point_literal) @number

(boolean_literal) @boolean
"Nothing" @constant.builtin

(interpolation
	"{" @punctuation.special
	"}" @punctuation.special)

; --- Types ----------------------------------------------------------------

(primitive_type) @type.builtin

(type (namespace_name) @type)
(type (generic_type (namespace_name) @type))
(type (array_type (namespace_name) @type))

(imports_statement namespace: (namespace_name) @type)
(namespace_block name: (namespace_name) @type)

; --- Declarations ---------------------------------------------------------

(class_block name: (identifier) @type)
(module_block name: (identifier) @type)
(structure_block name: (identifier) @type)
(interface_block name: (identifier) @type)
(delegate_declaration name: (identifier) @type)
(type_parameter name: (identifier) @type)

(enum_block name: (identifier) @enum)
(enum_member name: (identifier) @variant)

(method_declaration name: (identifier) @function)
(property_declaration name: (identifier) @property)
(event_declaration name: (identifier) @property)
(raise_event_statement name: (identifier) @property)

(const_declaration name: (identifier) @constant)
(variable_declarator name: (identifier) @variable)
(for_statement variable: (identifier) @variable)
(for_each_statement variable: (identifier) @variable)

(parameter name: (identifier) @variable.parameter)
(lambda_parameter name: (identifier) @variable.parameter)

(label_statement label: (identifier) @label)
(goto_statement label: (identifier) @label)

; --- Usage ----------------------------------------------------------------

(member_access member: (identifier) @property)
(with_member_access member: (identifier) @property)
(qualified_member member: (identifier) @property)
(member_initializer member: (identifier) @property)
(argument name: (identifier) @variable.parameter)

(invocation target: (identifier) @function)
(invocation target: (member_access member: (identifier) @function))

; --- Attributes -----------------------------------------------------------

(attribute name: (identifier) @attribute)
(attribute name: (namespace_name) @attribute)
(attribute target: (identifier) @attribute)

(attribute_block
	"<" @punctuation.bracket
	">" @punctuation.bracket)
