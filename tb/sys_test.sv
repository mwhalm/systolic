class sys_test extends uvm_test;

    `uvm_component_utils(sys_test)

    sys_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = sys_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        sys_base_seq seq;
        phase.raise_objection(this);
        seq = sys_base_seq::type_id::create("seq");
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask
endclass