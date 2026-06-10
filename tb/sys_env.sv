class sys_env extends uvm_env;

    `uvm_component_utils(sys_env)

    sys_agent agent;
    sys_scoreboard scoreboard;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = sys_agent::type_id::create("agent", this);
        scoreboard = sys_scoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.mon_port.connect(scoreboard.act_fifo.analysis_export);
        agent.driver.drv_port.connect(scoreboard.exp_fifo.analysis_export);
    endfunction
endclass