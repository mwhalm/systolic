class sys_item extends uvm_sequence_item;
	`uvm_object_utils(sys_item)

	rand logic signed [IA_WIDTH - 1 : 0] ia [0 : N - 1][0 : N - 1];
	rand logic signed [W_WIDTH - 1 : 0] w [0 : N - 1][0 : N - 1];

	logic signed [OA_WIDTH - 1 : 0] exp [0 : N - 1][0 : N - 1];
	logic signed [OA_WIDTH - 1 : 0] act [0 : N - 1][0 : N - 1];

	function new(string name = "sys_item");
		super.new(name);
	endfunction

	constraint range {
	    foreach (ia[i])
	        foreach (ia[i][j])
	            ia[i][j] inside {[-5 : 5]};

	    foreach (w[i])
	        foreach (w[i][j])
	            w[i][j] inside {[-5 : 5]};
	}

	function void post_randomize();
		do_mm();
		print_matrices();
	endfunction

	function void do_mm();
		int signed c;
		for(int i = 0; i < N; i++) begin
			for(int j = 0; j < N; j++) begin
				c = 0;
				for(int k = 0; k < N; k++) begin
					c += int'(ia[i][k]) * int'(w[k][j]);
				end
				exp[i][j] = c;
			end
		end
	endfunction

	function void print_matrices();
		$write("IA:\n");
		for(int i = 0; i < N; i++) begin
			for(int j = 0; j < N; j++) begin
				$write("%d ", ia[i][j]);
			end
			$write("\n");
		end

		$write("Weights:\n");
		for(int i = 0; i < N; i++) begin
			for(int j = 0; j < N; j++) begin
				$write("%d ", w[i][j]);
			end
			$write("\n");
		end

		$write("Expected:\n");
		for(int i = 0; i < N; i++) begin
			for(int j = 0; j < N; j++) begin
				$write("%d ", exp[i][j]);
			end
			$write("\n");
		end		
	endfunction
endclass