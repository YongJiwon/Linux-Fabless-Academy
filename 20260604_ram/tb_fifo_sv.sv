`timescale 1ns / 1ps

// UVM class랑 macro 사용
`include "uvm_macros.svh"
import uvm_pkg::*;

// 기존 ram_interface 그대로 사용
// driver/monitor가 virtual interface로 받아서 DUT 신호 구동/관측
interface ram_interface;
    logic       clk;
    logic [7:0] addr;
    logic [7:0] wdata;
    logic       we;
    logic [7:0] rdata;
endinterface

// 기존 transaction에 대응되는 UVM sequence item
// 기존 addr, wdata, we, rdata만 유지, 새 control field는 안 넣음
class ram_seq_item extends uvm_sequence_item;
    rand bit [7:0] addr;
    rand bit [7:0] wdata;
    rand bit       we;
    bit      [7:0] rdata;

    // 기존 debug_print 형식 유지, GEN/DRV/MON/SCB 값 확인용
    function void debug_print(string name);
        $display("%t : [%s] addr = %d, wdata = %d, we = %d, rdata = %d",
                 $time, name, addr, wdata, we, rdata);
    endfunction

    function new(string name = "ram_seq_item");
        super.new(name);
    endfunction

    // sequence item factory 등록 + transaction field 등록
    `uvm_object_utils_begin(ram_seq_item)
        `uvm_field_int(addr,  UVM_DEFAULT)
        `uvm_field_int(wdata, UVM_DEFAULT)
        `uvm_field_int(we,    UVM_DEFAULT)
        `uvm_field_int(rdata, UVM_DEFAULT)
    `uvm_object_utils_end
endclass

// 기존 generator에 대응되는 UVM sequence
// mailbox put/get 대신 start_item/finish_item 사용
class ram_sequence extends uvm_sequence #(ram_seq_item);
    `uvm_object_utils(ram_sequence)

    ram_seq_item tr;

    function new(string name = "ram_sequence");
        super.new(name);
    endfunction

    virtual task body();
        // gen.run(40)처럼 random transaction 40개 생성
        repeat (40) begin
            tr = ram_seq_item::type_id::create("tr");

            start_item(tr);
            // constraint 없이 addr, wdata, we randomize
            assert (tr.randomize())
            else `uvm_error("GEN", "[GEN] tr.randomize() error!")

            // 기존 GEN debug_print 유지
            tr.debug_print("GEN");
            finish_item(tr);
        end
    endtask
endclass

// 기존 driver에 대응되는 UVM driver
// gen2drv_mbox.get(tr) 대신 get_next_item(tr)
class ram_driver extends uvm_driver #(ram_seq_item);
    `uvm_component_utils(ram_driver)

    ram_seq_item tr;
    virtual ram_interface ram_if;

    function new(string name = "ram_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // top에서 config DB에 넣은 virtual interface 가져옴
        if (!uvm_config_db#(virtual ram_interface)::get(this, "", "ram_vif", ram_if)) begin
            `uvm_fatal(get_name(), "Unable to access ram interface.")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            // sequence가 보낸 다음 transaction 대기
            seq_item_port.get_next_item(tr);
            tr.debug_print("DRV");

            // 기존 driver 타이밍 유지: posedge -> #1 -> blocking drive
            @(posedge ram_if.clk);
            #1;

            ram_if.addr  = tr.addr;
            ram_if.wdata = tr.wdata;
            ram_if.we    = tr.we;

            // 현재 transaction drive 끝났다고 sequencer에 알림
            seq_item_port.item_done();
        end
    endtask
endclass

// 기존 monitor에 대응되는 UVM monitor
// mon2scb_mbox.put(tr) 대신 analysis port write(tr)
class ram_monitor extends uvm_monitor;
    `uvm_component_utils(ram_monitor)

    ram_seq_item tr;
    uvm_analysis_port #(ram_seq_item) send;
    virtual ram_interface ram_vif;

    function new(string name = "ram_monitor", uvm_component parent = null);
        super.new(name, parent);
        send = new("send", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // top에서 config DB에 넣은 virtual interface 가져옴
        if (!uvm_config_db#(virtual ram_interface)::get(this, "", "ram_vif", ram_vif)) begin
            `uvm_fatal(get_name(), "Unable to access ram interface.")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        // 첫 번째 posedge는 초기값이라 넘김
        @(posedge ram_vif.clk);
    
        forever begin
            @(posedge ram_vif.clk);
    
            tr = ram_seq_item::type_id::create("tr", this);
            tr.addr  = ram_vif.addr;
            tr.wdata = ram_vif.wdata;
            tr.we    = ram_vif.we;
            tr.rdata = ram_vif.rdata;
    
            tr.debug_print("MON");
            send.write(tr);
        end
    endtask
endclass

// 기존 scoreboard에 대응되는 UVM scoreboard
// monitor가 write() 호출하면 기존 scoreboard 검증 로직 실행
class ram_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(ram_scoreboard)

    ram_seq_item tr;
    uvm_analysis_imp #(ram_seq_item, ram_scoreboard) recv;

    int total_cnt = 0;
    int pass_cnt  = 0;
    int fail_cnt  = 0;

    // 기존 8-bit mem 유지, 부호 문제 없게 unsigned byte 사용
    byte unsigned mem[256];

    function new(string name = "ram_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        recv = new("recv", this);
    endfunction

    virtual function void write(ram_seq_item data);
        tr = data;
        tr.debug_print("SCB");

        // monitor가 보낸 모든 transaction을 total count에 포함
        total_cnt++;

        // write면 mem 갱신, read면 rdata 비교
        if (tr.we) begin
            mem[tr.addr] = tr.wdata;
        end
        else begin
            if (tr.rdata == mem[tr.addr]) begin
                pass_cnt++;
                $display("%t : PASS addr = %d, rdata = %d, we = %d, wdata = %d, mem[addr] = %d",
                         $time,
                         tr.addr,
                         tr.rdata,
                         tr.we,
                         tr.wdata,
                         mem[tr.addr]);
            end
            else begin
                fail_cnt++;
                $display(
                    "%t : FAIL addr = %d, rdata = %d, we = %d, wdata = %d, mem[addr] = %d",
                    $time,
                    tr.addr,
                    tr.rdata,
                    tr.we,
                    tr.wdata,
                    mem[tr.addr]
                );
            end
        end
    endfunction
endclass

// generator-driver-monitor 묶음을 UVM agent로 구성
// 원본에 없는 active/passive, coverage는 안 넣음
class ram_agent extends uvm_agent;
    `uvm_component_utils(ram_agent)

    ram_driver drv;
    ram_monitor mon;
    uvm_sequencer #(ram_seq_item) sqr;

    function new(string name = "ram_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        drv = ram_driver::type_id::create("drv", this);
        mon = ram_monitor::type_id::create("mon", this);
        sqr = uvm_sequencer#(ram_seq_item)::type_id::create("sqr", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // gen2drv_mbox 대신 sequencer-driver TLM 연결
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
endclass

// 기존 environment에 대응되는 UVM env
// 기존 구조대로 agent랑 scoreboard만 포함
class ram_env extends uvm_env;
    `uvm_component_utils(ram_env)

    ram_agent      agent;
    ram_scoreboard scb;

    function new(string name = "ram_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        agent = ram_agent::type_id::create("agent", this);
        scb   = ram_scoreboard::type_id::create("scb", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // mon2scb_mbox 대신 monitor analysis port와 scoreboard analysis imp 연결
        agent.mon.send.connect(scb.recv);
    endfunction
endclass

// 기존 top 실행 제어랑 environment.run() 역할을 UVM test로 옮김
class ram_test extends uvm_test;
    `uvm_component_utils(ram_test)

    ram_sequence seq;
    ram_env      env;

    function new(string name = "ram_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        seq = ram_sequence::type_id::create("seq", this);
        env = ram_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);

        // gen.run(40)에 해당하는 sequence를 agent sequencer에서 실행
        seq.start(env.agent.sqr);

        // 기존 join_any 뒤 #10 대기 유지
        #10;

        // 기존 summary 출력 형식 유지
        $display("env run task end");
        $display("____________________________");
        $display("** SRAM IP Verification **");
        $display("** total test run num = %d **", env.scb.total_cnt);
        $display("** pass num = %d **", env.scb.pass_cnt);
        $display("** fail num = %d **", env.scb.fail_cnt);
        $display("*****************************");

        // $stop 대신 objection 내려서 UVM 방식으로 종료
        phase.drop_objection(this);
    endtask
endclass

module tb_ram_sv();
    ram_interface ram_if();

    // DUT 포트 이름/연결 방식 그대로 유지
    ram_ip dut(
        .clk   (ram_if.clk),
        .addr  (ram_if.addr),
        .wdata (ram_if.wdata),
        .we    (ram_if.we),
        .rdata (ram_if.rdata)
    );

    // 기존 10ns period clock 유지
    always #5 ram_if.clk = ~ram_if.clk;

    initial begin
        // 초기 clock 0
        ram_if.clk = 0;

        // UVM component들이 config DB에서 virtual interface 가져가게 등록
        uvm_config_db #(virtual ram_interface)::set(
            null,
            "*",
            "ram_vif",
            ram_if
        );

        // env.run() 대신 UVM test 시작
        run_test("ram_test");
    end

    initial begin
        // FSDB 파일 이름 지정
        $fsdbDumpfile("wave.fsdb");
        // FSDB dump hierarchy 지정
        $fsdbDumpvars(0);
    end

endmodule




/*`timescale 1ns / 1ps

// =======================================================================
// 1. Transaction Class
// =======================================================================
class transaction;
    rand bit [7:0] addr;   // 인터페이스 규격과 매칭되도록 변수명 수정
    rand bit [7:0] wdata;
    rand bit       we;
         bit [7:0] rdata;

    // debug_print 내부의 변수 이름 매칭 완료
    function void debug_print(string name);
        $display("%t : [%s] addr = %d, wdata = %d, we = %d, rdata = %d", 
                 $time, name, addr, wdata, we, rdata);
    endfunction
endclass

// =======================================================================
// 2. Interface Definition
// =======================================================================
interface ram_interface;
    logic       clk;
    logic       rst_n; // driver의 preset에서 사용하므로 인터페이스에 추가
    logic [7:0] addr;
    logic [7:0] wdata;
    logic       we;
    logic [7:0] rdata;
endinterface

// =======================================================================
// 3. Generator Class
// =======================================================================
class generator;
    transaction tr; 
    mailbox #(transaction) gen2drv_mbox;
    event event_gen_next;

    function new(mailbox#(transaction) gen2drv_mbox, event event_gen_next);
        this.gen2drv_mbox = gen2drv_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run(int count);
        repeat (count) begin
            tr = new();
            if (!tr.randomize()) begin
                $error("[GEN] tr.randomize() error!");
            end
            gen2drv_mbox.put(tr);
            tr.debug_print("GEN");
            @(event_gen_next);
        end
    endtask
endclass

// =======================================================================
// 4. Driver Class
// =======================================================================
class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual ram_interface ram_if; // 이름 통일 (ram_if)

    function new(mailbox#(transaction) gen2drv_mbox, virtual ram_interface ram_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.ram_if = ram_if;        
    endfunction

    task preset(); 
        ram_if.rst_n = 1'b1; // ram_vif -> ram_if 오타 고침
    endtask 

    task run();
        forever begin 
            gen2drv_mbox.get(tr);
            tr.debug_print("DRV");
            
            // 실제 인터페이스 핀에 신호를 바인딩 (주석 해제 및 타이밍 동기화)
            @(posedge ram_if.clk);
            ram_if.addr  <= tr.addr;
            ram_if.wdata <= tr.wdata;
            ram_if.we    <= tr.we;
        end
    endtask
endclass

// =======================================================================
// 5. Monitor Class
// =======================================================================
class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual ram_interface ram_vif;

    function new(mailbox#(transaction) mon2scb_mbox, virtual ram_interface ram_vif);
        this.mon2scb_mbox = mon2scb_mbox;
        this.ram_vif = ram_vif;
    endfunction

    task run();
        // 1클록 대기 후 안정적인 샘플링 유도
        @(posedge ram_vif.clk); 
        forever begin
            @(posedge ram_vif.clk); 
            #1; // Hold 타임 확보 후 샘플링
            tr = new();
            tr.addr  = ram_vif.addr;
            tr.wdata = ram_vif.wdata;
            tr.we    = ram_vif.we;
            tr.rdata = ram_vif.rdata;
            mon2scb_mbox.put(tr);
            tr.debug_print("MON");
        end
    endtask
endclass

// =======================================================================
// 6. Scoreboard Class
// =======================================================================
class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event event_gen_next;
    
    int total_cnt = 0, pass_cnt = 0, fail_cnt = 0;
    byte mem[256];

    function new(mailbox #(transaction) mon2scb_mbox, event event_gen_next);
        this.mon2scb_mbox = mon2scb_mbox;
        this.event_gen_next = event_gen_next;
    endfunction

    task run();
        forever begin
            mon2scb_mbox.get(tr);
            tr.debug_print("SCB");
            
            if (tr.we) begin 
                mem[tr.addr] = tr.wdata; 
                $display("%t : [SCB] WRITE PASS (addr=%d, data=%d)", $time, tr.addr, tr.wdata);
                pass_cnt++; // 쓰기도 통계에 반영
                total_cnt++;
            end else begin 
                total_cnt++;
                if (tr.rdata === mem[tr.addr]) begin
                    pass_cnt++;
                    $display("%t : [SCB] READ PASS", $time);
                end else begin
                    fail_cnt++;
                    $display("%t : [SCB] READ FAIL addr = %d, rdata = %d, mem[addr] = %d", 
                             $time, tr.addr, tr.rdata, mem[tr.addr]);
                end
            end
            -> event_gen_next;
        end
    endtask
endclass

// =======================================================================
// 7. Environment Class
// =======================================================================
class environment;
    generator   gen;
    driver      drv;
    monitor     mon;
    scoreboard  scb;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    event event_gen_next;

    function new(virtual ram_interface ram_vif);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen = new(gen2drv_mbox, event_gen_next);
        drv = new(gen2drv_mbox, ram_vif);
        mon = new(mon2scb_mbox, ram_vif);
        scb = new(mon2scb_mbox, event_gen_next);
    endfunction

    task run();
        drv.preset(); // 드라이버 초기화 구문 탑재
        fork
            gen.run(40);
            drv.run();
            mon.run();
            scb.run();
        join_any
        #100; // 시뮬레이션 잔여 파형이 출력될 시간 확보
        $display("env run task end");
        $display("____________________________");
        $display("** SRAM IP Verification **");
        $display("** total test run num = %d **", scb.total_cnt);
        $display("** pass num = %d **", scb.pass_cnt);
        $display("** fail num = %d **", scb.fail_cnt);
        $display("*****************************");
        $finish; // $stop 대신 완전 종료 처리
    endtask
endclass

// =======================================================================
// 8. Top Testbench Module
// =======================================================================
module tb_fifo_sv();
    ram_interface ram_if();
    
    ram_ip dut(
        .clk(ram_if.clk),
        .addr(ram_if.addr),
        .wdata(ram_if.wdata),
        .we(ram_if.we),
        .rdata(ram_if.rdata)
    );

    always #5 ram_if.clk = ~ram_if.clk;

    environment env;

	int log_file;
	
    initial begin
	    log_file = $fopen("ram.log","w");
        ram_if.clk = 0;
        env = new(ram_if);
        env.run();
	#100;
	$fclose(log_file);
    end

	 initial begin
	        $fsdbDumpfile("tb_fifo_sv.fsdb");
        
	        $fsdbDumpvars(0, tb_fifo_sv);
 	end

endmodule

*/