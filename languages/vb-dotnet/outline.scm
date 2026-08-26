(namespace_block
	"Namespace" @context
	name: (namespace_name) @name) @item

(class_block
	"Class" @context
	name: (identifier) @name) @item

(module_block
	"Module" @context
	name: (identifier) @name) @item

(structure_block
	"Structure" @context
	name: (identifier) @name) @item

(interface_block
	"Interface" @context
	name: (identifier) @name) @item

(enum_block
	"Enum" @context
	name: (identifier) @name) @item

(enum_member
	name: (identifier) @name) @item

(delegate_declaration
	"Delegate" @context
	name: (identifier) @name) @item

(method_declaration
	[
		"Sub"
		"Function"
	] @context
	name: (identifier) @name) @item

(constructor_declaration
	"Sub" @context
	"New" @name) @item

(property_declaration
	"Property" @context
	name: (identifier) @name) @item

(event_declaration
	"Event" @context
	name: (identifier) @name) @item
