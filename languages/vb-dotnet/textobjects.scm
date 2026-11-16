; Vim-mode text objects and motions: af/if (function), ac/ic (class),
; gc (comment), ]m/[m and ]]/[[.

; Functions: Sub / Function / Sub New / Property / Event, plus accessor bodies
(method_declaration
	[
		(statement)
		(comment)
	]* @function.inside) @function.around

(constructor_declaration
	[
		(statement)
		(comment)
	]* @function.inside) @function.around

(property_declaration
	[
		(get_accessor)
		(set_accessor)
	]* @function.inside) @function.around

(get_accessor
	(statement)* @function.inside) @function.around

(set_accessor
	(statement)* @function.inside) @function.around

(lambda_expression
	[
		(statement)
		(expression)
	]* @function.inside) @function.around

; Types
(class_block
	[
		(const_declaration)
		(constructor_declaration)
		(dim_statement)
		(event_declaration)
		(field_declaration)
		(method_declaration)
		(property_declaration)
		(type_declaration)
		(blank_line)
		(comment)
		(preprocessor_directive)
	]* @class.inside) @class.around

(module_block
	[
		(const_declaration)
		(constructor_declaration)
		(dim_statement)
		(event_declaration)
		(field_declaration)
		(method_declaration)
		(property_declaration)
		(type_declaration)
		(blank_line)
		(comment)
		(preprocessor_directive)
	]* @class.inside) @class.around

(structure_block
	[
		(const_declaration)
		(constructor_declaration)
		(dim_statement)
		(event_declaration)
		(field_declaration)
		(method_declaration)
		(property_declaration)
		(type_declaration)
		(blank_line)
		(comment)
		(preprocessor_directive)
	]* @class.inside) @class.around

(interface_block
	[
		(event_declaration)
		(method_declaration)
		(property_declaration)
		(type_declaration)
		(blank_line)
		(comment)
		(preprocessor_directive)
	]* @class.inside) @class.around

(enum_block
	[
		(enum_member)
		(blank_line)
		(comment)
	]* @class.inside) @class.around

(comment)+ @comment.around
