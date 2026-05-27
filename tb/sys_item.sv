class sys_item extends uvm_sequence_item;
	`uvm_object_utils(sys_item)

	sys_op operation;

	rand logic signed [IA_WIDTH - 1 : 0] ia [0 : M_SIZE - 1][0 : K_SIZE - 1];
	rand logic signed [W_WIDTH - 1 : 0] w [0 : K_SIZE - 1][0 : N_SIZE - 1];

	logic signed [OA_WIDTH - 1 : 0] exp [0 : M_SIZE - 1][0 : N_SIZE - 1];
	logic signed [OA_WIDTH - 1 : 0] act [0 : M_SIZE - 1][0 : N_SIZE - 1];

    localparam int H = 5;
    localparam int W = 5;
    localparam int R = 3;
    localparam int S = 3;
    localparam int P = H - R + 1;
    localparam int Q = W - S + 1;
    localparam int X = R * S;      
    localparam int Z = P * Q;

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
		calculate_expected();
		print_matrices();
	endfunction

	function void calculate_expected();
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
endclass