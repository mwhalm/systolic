class sys_monitor extends uvm_component;
    `uvm_component_utils(sys_monitor)

    virtual systolic_if #(.M_SIZE(M_SIZE), .K_SIZE(K_SIZE), .N_SIZE(N_SIZE), .IA_WIDTH(IA_WIDTH), 
    .W_WIDTH(W_WIDTH), .OA_WIDTH(OA_WIDTH),  .CONV_IA_ROW_SIZE(CONV_IA_ROW_SIZE), .FILTER_SIZE(FILTER_SIZE)).mon vif;

    uvm_analysis_port #(sys_item) mon_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        mon_port = new("mon_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual systolic_if#(.M_SIZE(M_SIZE), .K_SIZE(K_SIZE), .N_SIZE(N_SIZE), .IA_WIDTH(IA_WIDTH), 
        .W_WIDTH(W_WIDTH), .OA_WIDTH(OA_WIDTH),  .CONV_IA_ROW_SIZE(CONV_IA_ROW_SIZE), .FILTER_SIZE(FILTER_SIZE)).mon)::get(
                this, "", "vif", vif
            )) begin
            `uvm_fatal("NOVIF", "Monitor could not get virtual interface")
        end
    endfunction

    task run_phase(uvm_phase phase);
        sys_item item;
        forever begin
            @(posedge vif.clk);
            wait(vif.done == 1'b1);
            item = sys_item::type_id::create("mon_item");
            if(vif.method == 2'b11) begin
                for (int i = 0; i < P; i++) begin
                    for (int j = 0; j < Q; j++) begin
                        item.conv_act[i][j] = vif.oa_out[i][j];
                    end
                end
            end else begin
                for (int i = 0; i < M_SIZE; i++) begin
                    for (int j = 0; j < N_SIZE; j++) begin
                        item.act[i][j] = vif.oa_out[i][j];
                    end
                end
            end
            mon_port.write(item);
            `uvm_info("MON", "Captured systolic output matrix", UVM_MEDIUM)
            wait(vif.done == 1'b0);
        end
    endtask
endclass