; Gutter "run" buttons. Each match exposes its non-underscore captures to
; tasks.json as $ZED_CUSTOM_<capture>, and `tag` selects which tasks are offered.

; Sub Main / Function Main: the program entry point.
(
	(method_declaration
		name: (identifier) @run
		(#match? @run "^(?i)main$")) @_
	(#set! tag vb-main)
)

; Test methods (MSTest, NUnit, xUnit), as the class's direct member so the
; class name is available to build a fully qualified test filter.
(
	[
		(class_block
			name: (identifier) @vb_test_class
			(method_declaration
				attributes: (attribute_block
					(attribute
						name: [(identifier) (namespace_name)] @_attribute))
				name: (identifier) @run @vb_test_method) @_)
		(module_block
			name: (identifier) @vb_test_class
			(method_declaration
				attributes: (attribute_block
					(attribute
						name: [(identifier) (namespace_name)] @_attribute))
				name: (identifier) @run @vb_test_method) @_)
	]
	(#match? @_attribute "^(?i)([A-Za-z_][A-Za-z0-9_]*\\.)*(TestMethod|DataTestMethod|Test|TestCase|TestCaseSource|Theory|Fact)(Attribute)?$")
	(#set! tag vb-test)
)

; Test classes: run every test in the class.
(
	(class_block
		name: (identifier) @run @vb_test_class
		(method_declaration
			attributes: (attribute_block
				(attribute
					name: [(identifier) (namespace_name)] @_attribute))))
	(#match? @_attribute "^(?i)([A-Za-z_][A-Za-z0-9_]*\\.)*(TestMethod|DataTestMethod|Test|TestCase|TestCaseSource|Theory|Fact)(Attribute)?$")
	(#set! tag vb-test-class)
)
