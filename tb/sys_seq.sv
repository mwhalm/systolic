class sys_base_seq extends uvm_sequence #(sys_item);
	`uvm_object_utils(sys_base_seq)

	function new(string name = "sys_base_seq");
		super.new(name);
	endfunction

	task body();
		`uvm_info("SEQ", "Starting sequnce", UVM_MEDIUM)
		`ifdef CONV
			`uvm_do_with(req, {operation == OP_CONV;})
		`else 
			`uvm_do_with(req, {operation == OP_MM;})
		`endif
		`uvm_info("SEQ", "Finishing sequnce", UVM_MEDIUM)
	endtask
endclass