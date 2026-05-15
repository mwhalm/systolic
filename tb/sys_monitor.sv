class sys_monitor extends uvm_component;
    `uvm_component_utils(sys_monitor)

    virtual systolic_if #(.N(N), .IA_WIDTH(IA_WIDTH), .W_WIDTH(W_WIDTH), .OA_WIDTH(OA_WIDTH)).mon vif;

    uvm_analysis_port #(sys_item) mon_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        mon_port = new("mon_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual systolic_if#(.N(N), .IA_WIDTH(IA_WIDTH), .W_WIDTH(W_WIDTH), .OA_WIDTH(OA_WIDTH)).mon)::get(
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
            for (int i = 0; i < N; i++) begin
                for (int j = 0; j < N; j++) begin
                    item.act[i][j] = vif.oa_out[i][j];
                end
            end
            mon_port.write(item);
            `uvm_info("MON", "Captured systolic output matrix", UVM_MEDIUM)
            wait(vif.done == 1'b0);
        end
    endtask
endclass