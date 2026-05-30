class sys_item extends uvm_sequence_item;
	`uvm_object_utils(sys_item)

	rand sys_op operation;

	rand logic signed [IA_WIDTH - 1 : 0] ia [0 : M_SIZE - 1][0 : K_SIZE - 1];
	rand logic signed [W_WIDTH - 1 : 0] w [0 : K_SIZE - 1][0 : N_SIZE - 1];
	rand logic signed [IA_WIDTH - 1 : 0] conv_ia [0 : CONV_IA_ROW_SIZE - 1][0 : CONV_IA_ROW_SIZE - 1];
	rand logic signed [W_WIDTH - 1 : 0] filter [0 : FILTER_SIZE - 1][0 : FILTER_SIZE - 1];
	
	logic signed [OA_WIDTH - 1 : 0] conv_exp [0 : P - 1][0 : Q - 1];
	logic signed [OA_WIDTH - 1 : 0] conv_act [0 : P - 1][0 : Q - 1];
	logic signed [OA_WIDTH - 1 : 0] exp [0 : M_SIZE - 1][0 : N_SIZE - 1];
	logic signed [OA_WIDTH - 1 : 0] act [0 : M_SIZE - 1][0 : N_SIZE - 1];

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

	    foreach (conv_ia[i])
	        foreach (conv_ia[i][j])
	            conv_ia[i][j] inside {[-5 : 5]};

	    foreach (filter[i])
	        foreach (filter[i][j])
	            filter[i][j] inside {[-5 : 5]};
	}

	constraint op_dist {
    	operation dist {OP_MM := 0, OP_CONV := 100};
	}

	function void post_randomize();
		if(operation == OP_MM) begin
			matrix_multiply();
			print_matrices();
		end else begin
			convolution();
			print_conv();
		end
	endfunction

	function void matrix_multiply();
		int signed c;
		for(int i = 0; i < M_SIZE; i++) begin
			for(int j = 0; j < N_SIZE; j++) begin
				c = 0;
				for(int k = 0; k < K_SIZE; k++) begin
					c += int'(ia[i][k]) * int'(w[k][j]);
				end
				exp[i][j] = c;
			end
		end
	endfunction

	function void convolution();
		for(int p = 0; p < P; p++) begin
			for(int q = 0; q < Q; q++) begin
				conv_exp[p][q] = 0;
				for(int r = 0; r < R; r++)
					for(int s = 0; s < S; s++)
						conv_exp[p][q] += int'(filter[r][s]) * int'(conv_ia[p + r][q + s]);
			end
		end
	endfunction

	function void print_matrices();
		$write("IA:\n");
		for(int i = 0; i < M_SIZE; i++) begin
			for(int j = 0; j < K_SIZE; j++) begin
				$write("%d ", ia[i][j]);
			end
			$write("\n");
		end

		$write("Weights:\n");
		for(int i = 0; i < K_SIZE; i++) begin
			for(int j = 0; j < N_SIZE; j++) begin
				$write("%d ", w[i][j]);
			end
			$write("\n");
		end

		$write("Expected:\n");
		for(int i = 0; i < M_SIZE; i++) begin
			for(int j = 0; j < N_SIZE; j++) begin
				$write("%d ", exp[i][j]);
			end
			$write("\n");
		end		
	endfunction

	function void print_conv();
		$write("Conv IA:\n");
		for(int i = 0; i < CONV_IA_ROW_SIZE; i++) begin
			for(int j = 0; j < CONV_IA_ROW_SIZE; j++) begin
				$write("%d ", conv_ia[i][j]);
			end
			$write("\n");
		end

		$write("Filter:\n");
		for(int i = 0; i < FILTER_SIZE; i++) begin
			for(int j = 0; j < FILTER_SIZE; j++) begin
				$write("%d ", filter[i][j]);
			end
			$write("\n");
		end

		$write("Expected:\n");
		for(int i = 0; i < P; i++) begin
			for(int j = 0; j < Q; j++) begin
				$write("%d ", conv_exp[i][j]);
			end
			$write("\n");
		end		
	endfunction
endclass