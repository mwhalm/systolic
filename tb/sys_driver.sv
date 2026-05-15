class sys_driver extends uvm_driver #(sys_item);
    `uvm_component_utils(sys_driver)

    virtual systolic_if #(.N(N), .IA_WIDTH(IA_WIDTH), .W_WIDTH(W_WIDTH), .OA_WIDTH(OA_WIDTH)).drv vif;

    uvm_analysis_port #(sys_item) drv_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        drv_port = new("drv_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual systolic_if #(.N(N), .IA_WIDTH(IA_WIDTH), .W_WIDTH(W_WIDTH), .OA_WIDTH(OA_WIDTH)).drv)::get(
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
        logic [1 : 0] dataflows [0 : 3];
        int i, j, m = 2;

        for (i = 0; i < 4; i++) begin
            dataflows[i] = i;
        end

        `uvm_info("DRV", "Driving systolic array", UVM_MEDIUM)

        for (i = 0; i < N; i++) begin
            for (j = 0; j < N; j++) begin
                vif.ia_in[i][j] <= item.ia[i][j];
                vif.w_in[i][j]  <= item.w[i][j];
            end
        end

        for(i = 0; i < m; i++) begin
            `uvm_info("DRV", $sformatf("Dataflow = %b", dataflows[i]), UVM_MEDIUM)
            drv_port.write(item);
            @(posedge vif.clk);
            vif.start <= 1'b1;
            vif.method <= dataflows[i];
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