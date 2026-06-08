class sys_driver extends uvm_driver #(sys_item);
    `uvm_component_utils(sys_driver)

    virtual systolic_if #(.M_SIZE(M_SIZE), .K_SIZE(K_SIZE), .N_SIZE(N_SIZE), .IA_WIDTH(IA_WIDTH), 
        .W_WIDTH(W_WIDTH), .OA_WIDTH(OA_WIDTH), .FILTER_SIZE(FILTER_SIZE), .H(H), .W(W), .P(P), .Q(Q)).drv vif;

    uvm_analysis_port #(sys_item) drv_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        drv_port = new("drv_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual systolic_if #(.M_SIZE(M_SIZE), .K_SIZE(K_SIZE), .N_SIZE(N_SIZE), .IA_WIDTH(IA_WIDTH), 
        .W_WIDTH(W_WIDTH), .OA_WIDTH(OA_WIDTH), .FILTER_SIZE(FILTER_SIZE), .H(H), .W(W), .P(P), .Q(Q)).drv)::get(
                this, "", "vif", vif
            )) begin
            `uvm_fatal("NOVIF", "Driver could not get virtual interface")
        end
    endfunction

    task run_phase(uvm_phase phase);
        sys_item item;
        reset_dut();
        forever begin
            seq_item_port.get_next_item(item);
            drive_item(item);
            seq_item_port.item_done();
        end
    endtask

    task reset_dut();
        vif.rst   <= 1'b0;
        vif.start <= 1'b0;
        vif.method <= 2'b00;

        foreach (vif.ia_in[i])
            foreach (vif.ia_in[i][j])
                vif.ia_in[i][j] <= '0;
        foreach (vif.w_in[i])
            foreach (vif.w_in[i][j])
                vif.w_in[i][j] <= '0;

        repeat(5)
            @(posedge vif.clk);

        vif.rst <= 1'b1;
    endtask

    task drive_item(sys_item item);
        if(item.operation == OP_MM)
            drive_mm(item);
        else
            drive_conv(item);
    endtask

    task drive_conv(sys_item item);
        for (int i = 0; i < H; i++) begin
            for (int j = 0; j < W; j++) begin
                vif.conv_ia_in[i][j] <= item.conv_ia[i][j];
            end
        end
        for (int i = 0; i < FILTER_SIZE; i++) begin
            for (int j = 0; j < FILTER_SIZE; j++) begin
                vif.filter_in[i][j]  <= item.filter[i][j];
            end
        end

        `uvm_info("DRV", "Driving Convolution", UVM_MEDIUM)
        drv_port.write(item);
        vif.method <= 2'b11; // choose row stationary
        @(posedge vif.clk);
        vif.start <= 1'b1;
        @(posedge vif.clk);
        vif.start <= 1'b0;
        @(posedge vif.clk);
        @(posedge vif.clk);
        wait (vif.done === 1'b1);
        @(posedge vif.clk);
        @(posedge vif.clk);
        `uvm_info("DRV", "Finished driving convolution", UVM_MEDIUM)
    endtask

    task drive_mm(sys_item item);
        logic [1 : 0] dataflows [0 : 3];
        int m = 3;

        for (int i = 0; i < 3; i++) begin
            dataflows[i] = i;
        end

        for (int i = 0; i < M_SIZE; i++) begin
            for (int j = 0; j < K_SIZE; j++) begin
                vif.ia_in[i][j] <= item.ia[i][j];
            end
        end
        for (int i = 0; i < K_SIZE; i++) begin
            for (int j = 0; j < N_SIZE; j++) begin
                vif.w_in[i][j]  <= item.w[i][j];
            end
        end

        for(int i = 0; i < m; i++) begin
            `uvm_info("DRV", "Driving Matrix Multiply", UVM_MEDIUM)
            `uvm_info("DRV", $sformatf("Dataflow = %b", dataflows[i]), UVM_MEDIUM)
            drv_port.write(item);
            vif.method <= dataflows[i];
            @(posedge vif.clk);
            vif.start <= 1'b1;
            @(posedge vif.clk);
            vif.start <= 1'b0;
            @(posedge vif.clk);
            @(posedge vif.clk);
            wait (vif.done === 1'b1);
            @(posedge vif.clk);
            @(posedge vif.clk);
        end
        `uvm_info("DRV", "Finished driving matrix multiply", UVM_MEDIUM)
    endtask
endclass