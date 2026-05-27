class sys_scoreboard extends uvm_component;
    `uvm_component_utils(sys_scoreboard)

    uvm_tlm_analysis_fifo #(sys_item) exp_fifo;
    uvm_tlm_analysis_fifo #(sys_item) act_fifo;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        exp_fifo = new("exp_fifo", this);
        act_fifo = new("act_fifo", this);
    endfunction

    task run_phase(uvm_phase phase);
        sys_item exp_item;
        sys_item act_item;
        forever begin
            exp_fifo.get(exp_item);
            act_fifo.get(act_item);
            compare(exp_item, act_item);
        end
    endtask

    function void compare(sys_item exp_item, sys_item act_item);
        int errors = 0;
        for (int i = 0; i < M_SIZE; i++) begin
            for (int j = 0; j < N_SIZE; j++) begin
                if (act_item.act[i][j] !== exp_item.exp[i][j]) begin
                    errors++;
                end
            end
        end
        if (errors) begin
            `uvm_error("MISMATCH", "Matrices don't match")
            $write("Actual:\n");
            for(int i = 0; i < M_SIZE; i++) begin
                for(int j = 0; j < N_SIZE; j++) begin
                    $write("%d ", act_item.act[i][j]);
                end
                $write("\n");
            end
        end else begin
            `uvm_info("PASS", "Matrix multiply result matched expected output", UVM_LOW)     
        end
    endfunction

endclass