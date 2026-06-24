`timescale 1ns/1ps

`include "uvm_macros.svh"
import uvm_pkg::*;

interface ram_if(
    input logic clk,
    input logic rst_n
);

    logic [7:0] addr;
    logic [7:0] wdata;
    logic [7:0] rdata;
    logic we;
    logic [7:0] register_file [0:63];
endinterface

class ram_seq_item extends uvm_sequence_item;

    rand logic [7:0] wdata;
    rand logic [7:0] addr;
    rand logic we;
    logic [7:0] rdata;
    logic [7:0] register_file [0:63];

    constraint c_addr_range {
        addr inside {[0:63]};
    };

    function new(string name = "ram_seq_item");
        super.new(name);
    endfunction

    `uvm_object_utils_begin(ram_seq_item)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(wdata, UVM_ALL_ON)
        `uvm_field_int(we, UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
    `uvm_object_utils_end

    function string convert2string();
        return $sformatf("addr=%0d, wdata=%0d, we=%0d, rdata=%0h", addr, wdata, we, rdata);
    endfunction

endclass

class ram_sequence extends uvm_sequence #(ram_seq_item);
    `uvm_object_utils(ram_sequence)

    int loop_count;

    function new(string name = "ram_sequence");
        super.new(name);
    endfunction

    virtual task body();
        ram_seq_item item;

        // 먼저 전체 주소를 한 번씩 write해서 read-before-write로 인한 X 기대값을 줄인다.
        for (int i = 0; i < 64; i++) begin
            item = ram_seq_item::type_id::create($sformatf("init_wr_%0d", i));
            start_item(item);
            if (!item.randomize() with {
                addr == i;
                we == 1'b1;
            }) begin
                `uvm_fatal(get_type_name(), "Initialization write randomization failed!")
            end
            finish_item(item);
            `uvm_info(get_type_name(), $sformatf("[INIT %0d/64] %s", i + 1, item.convert2string()), UVM_HIGH)
        end

        for (int i = 0; i < loop_count; i++) begin
            item = ram_seq_item::type_id::create($sformatf("item_%0d", i));
            start_item(item);
            if (!item.randomize()) begin
                `uvm_fatal(get_type_name(), "Randomization failed!")
            end
            finish_item(item);
            `uvm_info(get_type_name(), $sformatf("[%0d/%0d] %s", i + 1, loop_count, item.convert2string()), UVM_HIGH)
        end
    endtask
endclass

class ram_component1 extends uvm_component;
    `uvm_component_utils(ram_component1)
    uvm_analysis_imp #(ram_seq_item, ram_component1) ap_imp_comp1;

    function new(string name, uvm_component c);
        super.new(name, c);
        ap_imp_comp1 = new("ap_imp_comp1", this);
    endfunction

    virtual function void write(ram_seq_item item);
        `uvm_info(get_type_name(), $sformatf("       ap_imp_comp1 : %s", item.convert2string()), UVM_MEDIUM)
    endfunction

endclass

class ram_component2 extends uvm_component;
    `uvm_component_utils(ram_component2)
    uvm_analysis_imp #(ram_seq_item, ram_component2) ap_imp_comp2;

    function new(string name, uvm_component c);
        super.new(name, c);
        ap_imp_comp2 = new("ap_imp_comp2", this);
    endfunction

    virtual function void write(ram_seq_item item);
        `uvm_info(get_type_name(), $sformatf("       ap_imp_comp2: %s", item.convert2string()), UVM_MEDIUM)
    endfunction

endclass

class ram_subscriber extends uvm_subscriber #(ram_seq_item);
    `uvm_component_utils(ram_subscriber)

    function new(string name, uvm_component c);
        super.new(name, c);
    endfunction

    virtual function void write(ram_seq_item item);
        `uvm_info(get_type_name(), $sformatf("  ram_subscriber: %s", item.convert2string()), UVM_MEDIUM)
    endfunction
endclass

class ram_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(ram_scoreboard)

    uvm_analysis_imp #(ram_seq_item, ram_scoreboard) ap_imp;
    logic [7:0] mem [0:63];
    bit valid [0:63];
    int total_count;
    int checked_count;
    int skipped_count;
    int fail_count;
    int pass_count;

    function new(string name, uvm_component c);
        super.new(name, c);
        ap_imp = new("ap_imp", this);
        total_count = 0;
        checked_count = 0;
        skipped_count = 0;
        fail_count = 0;
        pass_count = 0;
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        foreach (mem[i]) begin
            mem[i] = '0;
            valid[i] = 1'b0;
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction

    virtual task run_phase(uvm_phase phase);
    endtask

    virtual function void write(ram_seq_item item);
        total_count++;

        if (item.we == 1'b1) begin
            mem[item.addr] = item.wdata;
            valid[item.addr] = 1'b1;
            `uvm_info(get_type_name(), $sformatf("[WRITE] Addr:%0d <= Data:%0h", item.addr, item.wdata), UVM_MEDIUM)
        end else begin
            if (!valid[item.addr]) begin
                skipped_count++;
                `uvm_warning(get_type_name(), $sformatf("[READ SKIP] Addr:%0d was never written. DUT rdata:%0h", item.addr, item.rdata))
                return;
            end

            checked_count++;
            if (item.rdata === mem[item.addr]) begin
                `uvm_info(get_type_name(), $sformatf("[READ PASS] Addr:%0d => Data:%0h (Expected:%0h)", item.addr, item.rdata, mem[item.addr]), UVM_MEDIUM)
                pass_count++;
            end else begin
                `uvm_error(get_type_name(), $sformatf("[READ FAIL] Addr:%0d => Data:%0h (Expected:%0h)", item.addr, item.rdata, mem[item.addr]))
                fail_count++;
            end
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "============= Scoreboard Summary =============", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Total   : %0d", total_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Checked : %0d", checked_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Skipped : %0d", skipped_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Pass    : %0d", pass_count), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Fail    : %0d", fail_count), UVM_LOW)

        if (fail_count > 0) begin
            `uvm_error(get_type_name(), $sformatf("TEST FAILED: %0d mismatches detected!", fail_count))
        end else begin
            `uvm_info(get_type_name(), $sformatf("TEST PASSED: %0d checked reads matched!", pass_count), UVM_LOW)
        end
    endfunction
endclass

class ram_driver extends uvm_driver #(ram_seq_item);
    `uvm_component_utils(ram_driver)

    virtual ram_if a_if;

    function new(string name, uvm_component c);
        super.new(name, c);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ram_if)::get(this, "", "a_if", a_if)) begin
            `uvm_fatal(get_type_name(), "a_if를 찾을 수 없습니다.")
        end
        `uvm_info(get_type_name(), "build_phase 실행 완료.", UVM_HIGH)
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction

    virtual task drive_item(ram_seq_item item);
        @(posedge a_if.clk);
        a_if.addr <= item.addr;
        a_if.wdata <= item.wdata;
        a_if.we <= item.we;
        `uvm_info(get_type_name(), item.convert2string(), UVM_HIGH)

        // monitor가 read data를 다음 cycle에 sample하므로, read command 뒤에는
        // 다음 item을 바로 drive하지 않고 한 cycle을 더 기다린다.
        if (item.we == 1'b0) begin
            @(posedge a_if.clk);
        end
    endtask

    virtual task run_phase(uvm_phase phase);
        ram_seq_item item;

        a_if.addr <= '0;
        a_if.wdata <= '0;
        a_if.we <= 1'b0;

        @(posedge a_if.rst_n);
        forever begin
            seq_item_port.get_next_item(item);
            drive_item(item);
            seq_item_port.item_done();
        end
    endtask

    virtual function void report_phase(uvm_phase phase);
    endfunction

endclass

class ram_monitor extends uvm_monitor;
    `uvm_component_utils(ram_monitor)

    uvm_analysis_port#(ram_seq_item) ap;
    virtual ram_if a_if;

    function new(string name, uvm_component c);
        super.new(name, c);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual ram_if)::get(this, "", "a_if", a_if)) begin
            `uvm_fatal(get_type_name(), "a_if를 찾을 수 없습니다.")
        end
        `uvm_info(get_type_name(), "build_phase 실행 완료.", UVM_HIGH)
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction

    virtual task run_phase(uvm_phase phase);
        ram_seq_item item;

        @(posedge a_if.rst_n);

        forever begin
            @(posedge a_if.clk);
            #1;
            item = ram_seq_item::type_id::create("item");
            item.addr = a_if.addr;
            item.wdata = a_if.wdata;
            item.we = a_if.we;

            if (a_if.we == 1'b0) begin
                @(posedge a_if.clk);
                #1;
                item.rdata = a_if.rdata;
            end else begin
                item.rdata = 8'hx;
            end

            ap.write(item);
            `uvm_info(get_type_name(), item.convert2string(), UVM_MEDIUM)
        end
    endtask

    virtual function void report_phase(uvm_phase phase);
    endfunction

endclass

class ram_agent extends uvm_agent;
    `uvm_component_utils(ram_agent)

    uvm_sequencer #(ram_seq_item) sqr;
    ram_driver drv;
    ram_monitor mon;

    function new(string name, uvm_component c);
        super.new(name, c);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sqr = uvm_sequencer#(ram_seq_item)::type_id::create("sqr", this);
        drv = ram_driver::type_id::create("drv", this);
        mon = ram_monitor::type_id::create("mon", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction

    virtual task run_phase(uvm_phase phase);
    endtask

    virtual function void report_phase(uvm_phase phase);
    endfunction

endclass

class ram_env extends uvm_env;
    `uvm_component_utils(ram_env)

    ram_agent agt;
    ram_scoreboard scb;
    ram_component1 cmp1;
    ram_component2 cmp2;
    ram_subscriber subs;

    function new(string name, uvm_component c);
        super.new(name, c);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = ram_agent::type_id::create("agt", this);
        scb = ram_scoreboard::type_id::create("scb", this);
        cmp1 = ram_component1::type_id::create("comp1", this);
        cmp2 = ram_component2::type_id::create("comp2", this);
        subs = ram_subscriber::type_id::create("subs", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.ap.connect(scb.ap_imp);
        agt.mon.ap.connect(cmp1.ap_imp_comp1);
        agt.mon.ap.connect(cmp2.ap_imp_comp2);
        agt.mon.ap.connect(subs.analysis_export);
    endfunction

    virtual task run_phase(uvm_phase phase);
    endtask

    virtual function void report_phase(uvm_phase phase);
    endfunction

endclass

class ram_test extends uvm_test;
    `uvm_component_utils(ram_test)

    ram_env env;

    function new(string name, uvm_component c);
        super.new(name, c);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = ram_env::type_id::create("env", this);
        `uvm_info(get_type_name(), "build phase", UVM_HIGH)
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info(get_type_name(), "ram_sequence seq 실행", UVM_DEBUG)
    endfunction

    virtual task run_phase(uvm_phase phase);
        ram_sequence seq;
        `uvm_info(get_type_name(), "ram_sequence seq 실행", UVM_DEBUG)
        phase.raise_objection(this);
        `uvm_info(get_type_name(), "phase.raise_objection(this) 실행", UVM_DEBUG)
        seq = ram_sequence::type_id::create("seq", this);
        `uvm_info(get_type_name(), "ram_sequence::type_id::create(\"seq\", this) 실행", UVM_DEBUG)
        seq.loop_count = 100;
        `uvm_info(get_type_name(), "seq.loop_count = 100 실행", UVM_DEBUG)
        seq.start(env.agt.sqr);
        `uvm_info(get_type_name(), "seq.start(env.agt.sqr) 실행", UVM_DEBUG)

        // 마지막 read response가 monitor/scoreboard에 전달될 시간을 준다.
        repeat (5) @(posedge env.agt.drv.a_if.clk);
        phase.drop_objection(this);
    endtask

    virtual function void report_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction

endclass

module tb_ram;
    logic clk;
    logic rst_n;

    always #5 clk = ~clk;

    ram_if a_if(
        clk,
        rst_n
    );

    ram dut(
        .clk(a_if.clk),
        .rst_n(a_if.rst_n),
        .addr(a_if.addr),
        .wdata(a_if.wdata),
        .we(a_if.we),
        .rdata(a_if.rdata)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        a_if.addr = '0;
        a_if.wdata = '0;
        a_if.we = 1'b0;
        #20 rst_n = 1;
    end

    initial begin
        uvm_config_db#(virtual ram_if)::set(null, "*", "a_if", a_if);
        run_test("ram_test");
    end
endmodule
