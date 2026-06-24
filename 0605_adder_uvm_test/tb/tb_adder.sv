// UVM 매크로 사용
`include "uvm_macros.svh"
// UVM 패키지 전체 사용
import uvm_pkg::*;


// DUT랑 testbench에서 같이 쓸 신호 묶음
interface adder_intf;
    // adder의 첫 번째 8-bit 입력
    logic [7:0] a;
    // adder의 두 번째 8-bit 입력
    logic [7:0] b;
    // 8-bit + 8-bit 결과에서 carry까지 받아야 해서 9-bit
    logic [8:0] y;
endinterface



// sequence, driver, monitor, scoreboard가 주고받을 transaction
class adder_seq_item extends uvm_sequence_item;
    // randomize()로 만들 첫 번째 입력값
    rand logic [7:0] a;
    // randomize()로 만들 두 번째 입력값
    rand logic [7:0] b;
    // monitor가 DUT 출력값 받아서 scoreboard로 넘길 변수
    logic [8:0] y;


    // adder_seq_item 생성자
    function new(string name = "adder_seq_item");
        // 부모 uvm_sequence_item 생성자 호출
        super.new(name);
    endfunction

    // adder_seq_item factory 등록 + field 등록 시작
    `uvm_object_utils_begin(adder_seq_item)
        // a를 print/copy/compare에 포함
        `uvm_field_int(a, UVM_DEFAULT)
        // b를 print/copy/compare에 포함
        `uvm_field_int(b, UVM_DEFAULT)
        // y를 print/copy/compare에 포함
        `uvm_field_int(y, UVM_DEFAULT)
    // factory + field 등록 끝
    `uvm_object_utils_end
endclass


// 100개의 random transaction 만드는 sequence == generator
class adder_seq extends uvm_sequence #(adder_seq_item); //== generator
    // adder_seq는 component가 아니라 object라서 object macro로 factory 등록
    `uvm_object_utils(adder_seq) //얘는 팩토리 등록할 때 컴포넌트가 아니라 오브젝트임. 오브젝트 = 하나의 데이터/트랜잭션/스티뮬러스

    // randomize해서 driver로 넘길 transaction handle
    adder_seq_item a_seq_item;

    // adder_seq 생성자
    function new(string name = "adder_seq");
        // 부모 uvm_sequence 생성자 호출
        super.new(name);
    endfunction

    // sequence start하면 실행되는 body task
    virtual task body ();
        // transaction 하나 만든 뒤 repeat에서 재사용
        a_seq_item = adder_seq_item::type_id::create("SEQ_ITEM");
        // a, b random 값 100번 생성
        repeat(100) begin
            // sequencer-driver handshake 시작, driver 준비될 때까지 대기
            start_item(a_seq_item);
            // a, b randomize
            if (!a_seq_item.randomize()) begin
                // randomize 실패 시 error 출력
                `uvm_error("SEQ_ITEM", "Fail to generate random value!")
            end else begin
                // randomize 성공하면 driver로 보낼 data 생성됐다고 출력
                `uvm_info("SEQ", "Data send to Driver!",UVM_LOW)
            end
            // item 작성 끝났다고 sequencer에 알림
            finish_item(a_seq_item);
        end
    endtask


endclass

// sequencer에서 transaction 받아서 interface a, b 구동하는 driver
class adder_drv extends uvm_driver #(adder_seq_item);

    // adder_drv factory에 component로 등록
    `uvm_component_utils(adder_drv)

    // 실제 interface instance를 가리킬 virtual interface handle
    virtual adder_intf adder_if;
    // sequencer에서 받을 transaction handle
    adder_seq_item a_seq_item;

    // adder_drv 생성자, c는 부모 component
    function new(string name = "adder_drv", uvm_component c = null);
        // 부모 uvm_driver 생성자 호출
        super.new(name, c);
    endfunction

    // build_phase에서 driver용 객체 생성 + config_db 조회
    virtual function void build_phase(uvm_phase phase);
        // 부모 build_phase 먼저 실행
        super.build_phase(phase);
        // driver에서 쓸 sequence item 생성
        a_seq_item = adder_seq_item::type_id::create("SEQ_ITEM", this);
        // tb_adder에서 set한 virtual interface 가져옴
        if(!uvm_config_db#(virtual adder_intf)::get(this, "", "adder_if", adder_if)) begin
            // interface 못 가져오면 DUT 입력 못 넣으니까 simulation 중단
            `uvm_fatal(get_name(),"Unable to access adder interface.");
        end
    endfunction


    // run_phase에서 transaction 받아 DUT 입력 구동
    virtual task run_phase(uvm_phase phase);
        // driver run_phase 시작 확인용
        $display("Display run phase");
        // sequence transaction 계속 받기 위해 무한 반복
        forever begin
            // sequencer에서 다음 transaction 받음
            seq_item_port.get_next_item(a_seq_item);
            // transaction a를 interface a에 입력
            adder_if.a <= a_seq_item.a;
            // transaction b를 interface b에 입력
            adder_if.b <= a_seq_item.b;
            // DUT 계산하고 monitor가 읽을 시간 확보
            #10;
            // 현재 transaction 처리 끝났다고 sequencer에 알림
            seq_item_port.item_done();
        end
    endtask
endclass


// interface의 a, b, y를 읽어서 scoreboard로 넘기는 monitor
class adder_mon extends uvm_monitor;

    // adder_mon factory에 component로 등록
    `uvm_component_utils(adder_mon)
    // monitor transaction을 scoreboard로 보낼 analysis port
    uvm_analysis_port#(adder_seq_item) send;

    // DUT와 연결된 interface를 가리킬 virtual interface handle
    virtual adder_intf adder_if;
    // monitor가 읽은 a, b, y를 담을 transaction handle
    adder_seq_item a_seq_item;


    // adder_mon 생성자, c는 부모 component
    function new(string name = "adder_mon", uvm_component c = null);
        // 부모 uvm_monitor 생성자 호출
        super.new(name, c);
        // analysis port 생성
        send = new("send",this);
    endfunction

    // build_phase에서 monitor용 item 생성 + virtual interface 조회
    virtual function void build_phase(uvm_phase phase);
        // 부모 build_phase 먼저 실행
        super.build_phase(phase);
        // monitor에서 쓸 sequence item 생성
        a_seq_item = adder_seq_item::type_id::create("SEQ_ITEM", this);
        // tb_adder에서 set한 virtual interface 가져옴
        if(!uvm_config_db#(virtual adder_intf)::get(this, "", "adder_if", adder_if)) begin
            // interface 못 가져오면 DUT 신호 못 읽으니까 simulation 중단
            `uvm_fatal(get_name(),"Unable to access adder interface.")
        end
    endfunction


    // run_phase에서 일정 시간마다 interface 읽어서 scoreboard로 전달
    virtual task run_phase(uvm_phase phase);
        // test 동작하는 동안 계속 monitor
        forever begin
            // driver 입력 후 DUT 출력 반영될 때까지 대기
            #10;
            // 현재 a를 transaction에 저장
            a_seq_item.a = adder_if.a;
            // 현재 b를 transaction에 저장
            a_seq_item.b = adder_if.b;
            // 현재 y를 transaction에 저장
            a_seq_item.y = adder_if.y;
            // scoreboard로 data 보낸다고 출력
            `uvm_info("MON","Send data to Scoreboard",UVM_LOW)
            // analysis port로 scoreboard write()에 transaction 전달
            send.write(a_seq_item);
        end
    endtask



endclass

// monitor transaction으로 DUT 출력이 맞는지 검사하는 scoreboard
class adder_scb extends uvm_scoreboard;

    // adder_scb factory에 component로 등록
    `uvm_component_utils(adder_scb)
    // monitor analysis port와 연결할 analysis imp
    uvm_analysis_imp#(adder_seq_item, adder_scb) recv;

    // adder_scb 생성자, c는 부모 component
    function new(string name = "adder_scb", uvm_component c = null);
        // 부모 uvm_scoreboard 생성자 호출
        super.new(name, c);
        // analysis imp 생성, monitor가 write하면 scoreboard write() 호출
        recv = new("READ",this);
    endfunction


    // monitor transaction 들어오면 호출되는 비교 함수
    virtual function void write(adder_seq_item data);
        // monitor에서 data 받았다고 출력
        `uvm_info("SCB", "Data received from Monitor", UVM_LOW)
        // a, b를 9-bit로 늘려서 carry 안 잘리게 더한 뒤 y와 비교
        if ({1'b0, data.a} + {1'b0, data.b} == data.y) begin
            // expected와 y 같으면 PASS
            `uvm_info("SCB", $sformatf("PASS!, a:%0d + b:%0d = y:%0d", data.a, data.b, data.y),UVM_LOW)
        end
        else begin
            // expected와 y 다르면 FAIL error 출력
            `uvm_error("SCB", $sformatf("FAIL!, a:%0d + b:%0d = y:%0d", data.a, data.b, data.y))
        end
    endfunction

    // scoreboard connect_phase, 지금은 따로 연결할 건 없음
    virtual function void connect_phase(uvm_phase phase);
        // 부모 connect_phase 호출
        super.connect_phase(phase);
    endfunction


endclass

// driver, monitor, sequencer 묶는 agent
class adder_agent extends uvm_agent;
    // adder_agent factory에 component로 등록
    `uvm_component_utils(adder_agent)
    // interface 읽는 monitor handle
    adder_mon a_mon;
    // interface 구동하는 driver handle
    adder_drv a_drv;
    // sequence와 driver 사이에서 transaction 전달하는 sequencer handle
    uvm_sequencer#(adder_seq_item) a_sqr;

    // adder_agent 생성자, c는 부모 component
    function new(string name = "adder_agent", uvm_component c = null);
        // 부모 uvm_agent 생성자 호출
        super.new(name, c);
    endfunction


    // build_phase에서 monitor, driver, sequencer 생성
    virtual function void build_phase(uvm_phase phase);
        // 부모 build_phase 먼저 실행
        super.build_phase(phase);
        // monitor instance 생성, 이름은 MON
        a_mon = adder_mon::type_id::create("MON", this);
        // driver instance 생성, 이름은 DRV
        a_drv = adder_drv::type_id::create("DRV", this);
        // sequencer instance 생성, 이름은 SQR
        a_sqr = uvm_sequencer#(adder_seq_item)::type_id::create("SQR",this);

    endfunction

    // connect_phase에서 driver와 sequencer 연결
    virtual function void connect_phase(uvm_phase phase);
        // 부모 class의 connect_phase를 먼저 실행합니다.
        super.connect_phase(phase);
        // driver가 item 받을 수 있게 port/export 연결
        a_drv.seq_item_port.connect(a_sqr.seq_item_export);
    endfunction


endclass


// agent와 scoreboard 묶는 environment
class adder_env extends uvm_env;
    // adder_env factory에 component로 등록
    `uvm_component_utils(adder_env)

    // driver, monitor, sequencer가 들어있는 agent handle
    adder_agent a_agt;
    // monitor transaction 비교할 scoreboard handle
    adder_scb a_scb;

    // adder_env 생성자, c는 부모 component
    function new(string name = "adder_env", uvm_component c = null);
        // 부모 uvm_env 생성자 호출
        super.new(name, c);
    endfunction

    // build_phase에서 agent와 scoreboard 생성
    virtual function void build_phase(uvm_phase phase);
        // 부모 build_phase 먼저 실행
        super.build_phase(phase);
        // agent instance 생성, 이름은 AGENT
        a_agt = adder_agent::type_id::create("AGENT", this);
        // scoreboard instance 생성, 이름은 SCB
        a_scb = adder_scb::type_id::create("SCB", this);
    endfunction

    // connect_phase에서 monitor analysis port와 scoreboard analysis imp 연결
    virtual function void connect_phase(uvm_phase phase);
        // 부모 class의 connect_phase를 먼저 실행합니다.
        super.connect_phase(phase);
        // monitor의 send.write()가 scoreboard write()로 들어가게 연결
        a_agt.a_mon.send.connect(a_scb.recv);
    endfunction



endclass


// UVM simulation 시작하는 최상위 test class
class adder_test extends uvm_test;
    // adder_test factory에 component로 등록
    `uvm_component_utils(adder_test) //factory의 adder_test 등록 macro

    // run_phase에서 시작할 sequence handle
    adder_seq a_seq;
    // agent와 scoreboard가 들어있는 env handle
    adder_env a_env;



    // adder_test 생성자, c는 부모 component
    function new(string name = "adder_test", uvm_component c = null);
        // 부모 uvm_test 생성자 호출
        super.new(name, c);
    endfunction


    // build_phase에서 sequence와 env 생성
    virtual function void build_phase(uvm_phase phase);
        // 부모 build_phase 먼저 실행
        super.build_phase(phase);
        // sequence 생성, 이름은 SEQ
        a_seq = adder_seq::type_id::create("SEQ", this);
        // env 생성, 이름은 ENV
        a_env = adder_env::type_id::create("ENV", this);
    endfunction

    // run_phase에서 objection 올리고 sequence 실행, 끝나면 내림
    virtual task run_phase(uvm_phase phase);
        // sequence 실행 중 simulation 안 끝나게 objection 올림
        phase.raise_objection(this);
        // env-agent-sequencer에서 sequence 시작
        a_seq.start(a_env.a_agt.a_sqr);
        // sequence 끝났으니 objection 내려서 simulation 종료 허용
        phase.drop_objection(this);
    endtask

endclass

// testbench 최상위 module
module tb_adder();


    // DUT와 UVM testbench가 같이 쓸 interface instance
    adder_intf adder_if();

    // 검증할 adder DUT instance, adder module 파일도 같이 compile해야 함
    adder dut(
        // DUT a와 interface a 연결
        .a(adder_if.a),
        // DUT b와 interface b 연결
        .b(adder_if.b),
        // DUT y와 interface y 연결
        .y(adder_if.y)
    );

    // waveform dump 설정
    initial begin
        // FSDB 파일 이름 지정
        $fsdbDumpfile("wave.fsdb");
        // FSDB dump hierarchy 지정
        $fsdbDumpvars(0);
    end


    // config_db 설정 후 test 시작
    initial begin
        // 모든 UVM component가 adder_if key로 interface 가져가게 등록
        uvm_config_db#(virtual adder_intf)::set(null, "*", "adder_if", adder_if);
        // factory에서 adder_test 생성하고 UVM phase 시작
        run_test("adder_test");
    end



endmodule
