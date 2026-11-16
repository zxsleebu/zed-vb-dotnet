; Blocks terminated by "End <something>"
(namespace_block "End" @end) @indent
(class_block "End" @end) @indent
(module_block "End" @end) @indent
(structure_block "End" @end) @indent
(interface_block "End" @end) @indent
(enum_block "End" @end) @indent
(method_declaration "End" @end) @indent
(constructor_declaration "End" @end) @indent
(property_declaration "End" @end) @indent
(get_accessor "End" @end) @indent
(set_accessor "End" @end) @indent
(event_declaration "End" @end) @indent
(add_handler_block "End" @end) @indent
(remove_handler_block "End" @end) @indent
(raise_event_block "End" @end) @indent
(if_statement "End" @end) @indent
(select_case_statement "End" @end) @indent
(while_statement "End" @end) @indent
(try_statement "End" @end) @indent
(with_statement "End" @end) @indent
(using_statement "End" @end) @indent
(sync_lock_statement "End" @end) @indent

; Blocks with their own terminator keyword
(do_statement "Loop" @end) @indent
(for_statement "Next" @end) @indent
(for_each_statement "Next" @end) @indent

; Clauses that indent their bodies but have no terminator of their own
(elseif_clause) @indent
(else_clause) @indent
(case_block) @indent
(case_else_block) @indent
(catch_block) @indent
(finally_block) @indent

; Anchors for `decrease_indent_patterns` in config.toml: a new `Case` line
; aligns with the previous one.
(case_block) @start.case
(case_else_block) @start.case
