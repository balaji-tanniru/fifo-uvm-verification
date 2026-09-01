package fifo_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  class fifo_item extends uvm_sequence_item;
    rand bit wr_en, rd_en;
    rand bit [7:0] data;
    bit [7:0] rdata;
    bit full, empty;
    `uvm_object_utils_begin(fifo_item)
      `uvm_field_int(wr_en, UVM_DEFAULT)
      `uvm_field_int(rd_en, UVM_DEFAULT)
      `uvm_field_int(data, UVM_HEX)
      `uvm_field_int(rdata, UVM_HEX)
      `uvm_field_int(full, UVM_DEFAULT)
      `uvm_field_int(empty, UVM_DEFAULT)
    `uvm_object_utils_end
    function new(string name="fifo_item"); super.new(name); endfunction
  endclass

  class fifo_sequence extends uvm_sequence #(fifo_item);
    `uvm_object_utils(fifo_sequence)
    function new(string name="fifo_sequence"); super.new(name); endfunction
    task body();
      repeat (100) begin
        req = fifo_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with { wr_en dist {1:=3,0:=1}; rd_en dist {1:=2,0:=2}; });
        finish_item(req);
      end
    endtask
  endclass

  class fifo_driver extends uvm_driver #(fifo_item);
    `uvm_component_utils(fifo_driver)
    virtual fifo_if vif;
    function new(string name, uvm_component parent); super.new(name,parent); endfunction
    function void build_phase(uvm_phase phase);
      if(!uvm_config_db#(virtual fifo_if)::get(this,"","vif",vif)) `uvm_fatal("NOVIF","fifo_if missing")
    endfunction
    task run_phase(uvm_phase phase);
      forever begin
        seq_item_port.get_next_item(req);
        @(negedge vif.clk); vif.wr_en<=req.wr_en; vif.rd_en<=req.rd_en; vif.data_in<=req.data;
        @(negedge vif.clk); vif.wr_en<=0; vif.rd_en<=0;
        seq_item_port.item_done();
      end
    endtask
  endclass

  class fifo_monitor extends uvm_monitor;
    `uvm_component_utils(fifo_monitor)
    virtual fifo_if vif;
    uvm_analysis_port #(fifo_item) ap;
    function new(string name, uvm_component parent); super.new(name,parent); ap=new("ap",this); endfunction
    function void build_phase(uvm_phase phase);
      if(!uvm_config_db#(virtual fifo_if)::get(this,"","vif",vif)) `uvm_fatal("NOVIF","fifo_if missing")
    endfunction
    task run_phase(uvm_phase phase);
      forever begin
        @(posedge vif.clk); #1;
        if(vif.rst_n && (vif.wr_en || vif.rd_en)) begin
          fifo_item t=fifo_item::type_id::create("t");
          t.wr_en=vif.wr_en; t.rd_en=vif.rd_en; t.data=vif.data_in; t.rdata=vif.data_out;
          t.full=vif.full; t.empty=vif.empty; ap.write(t);
        end
      end
    endtask
  endclass

  class fifo_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(fifo_scoreboard)
    uvm_analysis_imp #(fifo_item,fifo_scoreboard) imp;
    bit [7:0] model[$]; int checks, errors;
    function new(string name, uvm_component parent); super.new(name,parent); imp=new("imp",this); endfunction
    function void write(fifo_item t);
      bit can_write=(t.wr_en && model.size()<16);
      bit can_read=(t.rd_en && model.size()>0);
      bit [7:0] expected;
      if(can_read) begin
        expected=model.pop_front(); checks++;
        if(t.rdata!==expected) begin
          errors++;
          `uvm_error("FIFO_DATA",$sformatf("expected=%0h got=%0h",expected,t.rdata))
        end
      end
      if(can_write) model.push_back(t.data);
    endfunction
    function void report_phase(uvm_phase phase);
      `uvm_info("FIFO_SUMMARY",$sformatf("transactions_checked=%0d scoreboard_errors=%0d",checks,errors),UVM_NONE)
    endfunction
  endclass

  class fifo_coverage extends uvm_subscriber #(fifo_item);
    `uvm_component_utils(fifo_coverage)
    fifo_item tr;
    covergroup cg;
      cp_op: coverpoint {tr.wr_en,tr.rd_en} { bins idle={0}; bins read={1}; bins write={2}; bins simultaneous={3}; }
      cp_data: coverpoint tr.data { bins zero={0}; bins max={8'hff}; bins other=default; }
      op_x_data: cross cp_op,cp_data;
    endgroup
    function new(string name,uvm_component parent); super.new(name,parent); cg=new; endfunction
    function void write(fifo_item t); tr=t; cg.sample(); endfunction
  endclass

  class fifo_env extends uvm_env;
    `uvm_component_utils(fifo_env)
    uvm_sequencer #(fifo_item) seqr; fifo_driver drv; fifo_monitor mon; fifo_scoreboard sb; fifo_coverage cov;
    function new(string name,uvm_component parent); super.new(name,parent); endfunction
    function void build_phase(uvm_phase phase);
      seqr=uvm_sequencer#(fifo_item)::type_id::create("seqr",this); drv=fifo_driver::type_id::create("drv",this);
      mon=fifo_monitor::type_id::create("mon",this); sb=fifo_scoreboard::type_id::create("sb",this); cov=fifo_coverage::type_id::create("cov",this);
    endfunction
    function void connect_phase(uvm_phase phase);
      drv.seq_item_port.connect(seqr.seq_item_export); mon.ap.connect(sb.imp); mon.ap.connect(cov.analysis_export);
    endfunction
  endclass

  class fifo_test extends uvm_test;
    `uvm_component_utils(fifo_test)
    fifo_env env;
    function new(string name,uvm_component parent); super.new(name,parent); endfunction
    function void build_phase(uvm_phase phase); env=fifo_env::type_id::create("env",this); endfunction
    task run_phase(uvm_phase phase);
      fifo_sequence seq=fifo_sequence::type_id::create("seq"); phase.raise_objection(this); seq.start(env.seqr); #100; phase.drop_objection(this);
    endtask
  endclass
endpackage
