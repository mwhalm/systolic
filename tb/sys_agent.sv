class sys_agent extends uvm_agent;

    `uvm_component_utils(sys_agent)

    sys_sequencer sequencer;
    sys_driver driver;
    sys_monitor monitor;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sequencer = sys_sequencer::type_id::create("sequencer", this);
        driver    = sys_driver::type_id::create("driver", this);
        monitor   = sys_monitor::type_id::create("monitor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction

endclass