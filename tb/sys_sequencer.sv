class sys_sequencer extends uvm_sequencer #(sys_item);
    `uvm_component_utils(sys_sequencer)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass