`include "uvm_macros.svh"
import uvm_pkg::*;


//                                                  중요도
// `uvm_info("TAG", "항상 보이는 메시지", UVM_NONE)    0
// `uvm_info("TAG", "중요한 메시지", UVM_LOW)         100
// `uvm_info("TAG", "보통 메시지", UVM_MEDIUM)        200 <- 기본값
// `uvm_info("TAG",  상세 메시지", UVM_HIGH)          300
// `uvm_info("TAG", "전문 메시지", UVM_FULL)          400
// `uvm_info("TAG", "디버그용 메시지", UVM_DEBUG)      500

//출력 옵션을 UVM MEDIUM으로 하면 
// `uvm_info("TAG", "상시 츌력", UVM_FATAL)   우선순위라는게 없이 그냥 출력됨. 필터 없음


//TLM
//발신  ->  수신
//port  ->  export  1:1통신
//port  ->  analysis_imp(implementation)(수신쪽에서 구현한다) 1:N 통신
//port: 수신에서 구현한 기능을 이용해 전송한다.
//imp는 1:N 통신을 담당함
//
//
//


interface adder_if(
    input logic clk,
    input logic rst_n
);
    logic [7:0] a;
    logic [7:0] b;
    logic [8:0] y;
endinterface
 //하나의 페이즈가 종료되어야 다음 페이즈로 넘어감, 그전까진 Block 상태
class adder_seq_item extends uvm_sequence_item; //Q. 얘는 왜 팩토리에 등록안하는가?

    rand logic [7:0] a;
    rand logic [7:0] b;
    logic [8:0] y;
    function new(string name = "adder_seq_item"); //A. 그냥 변수이기 때문이다. 프레임에 고정되어 있는애다 아니다. Stimulus임
        super.new(name);        
    endfunction

    `uvm_object_utils_begin(adder_seq_item) //Factory 등록 절차
        `uvm_field_int(a, UVM_ALL_ON)
        `uvm_field_int(b, UVM_ALL_ON)
        `uvm_field_int(y, UVM_ALL_ON)
    `uvm_object_utils_end
    //클래스가 중요한게 아니라 아이템이 중요함
    
    function string convert2string();
        return $sformatf("a=%0d, b=%0d, y=%0d", a, b, y);
        
    endfunction

endclass


class adder_sequence extends uvm_sequence #(adder_seq_item); 
    `uvm_object_utils(adder_sequence)

    int loop_count;
    
    function new(string name = "adder_sequence");
        super.new(name);        
    endfunction
    // Sequence에서 virtual~body() 부터 endtask 까지
    // start 시점에 body를 띄움
    
    
    virtual task body(); //바디가 동작점( == run)
    // sequence의 body() task 실행
        adder_seq_item item;
        for (int i=0; i<loop_count; i++) begin
            item = adder_seq_item::type_id::create($sformatf("item_%0d",i));

            start_item(item); //[1], [3]
            // raise_objection -> factory 멈추지마
            // [seq] 1. drv의 응답전까지 Block 상테
            // [drv] 2. item 요청(ACK 응답)
            // [seq] 3. item 요청(실제 요청)
            // [seq] 4. item 전송
            // [drv] 5. 응답, item 응답(0x100 주소)
            // [drv] 6. 완료 응답
            // [seq] 7.응답 다음 라인 명령어 실행
            // [seq] <-> [sequencer(arbitor: 중재자)] <-> [drv]
            // 시퀀서를 통해 클래스끼리 요청/응답을 주고 받음
            // 시퀀서 중재자 역할을 하고 있음

            if (!item.randomize()) `uvm_fatal(get_type_name(),"Randomization failed!")
            // seq.start(env.agt.sqr) => 멤버.멤버.멤버 형식으로 참조하여 연결해줌, 즉,  sequence와 sequencer 연결
            finish_item(item); // [4]
            // start_item(item) -> 나 아이템 전송 준비가 됐다!(바보같음) 응답오기전까지는 가만히 있음

            `uvm_info(get_type_name(), $sformatf(
                "[%0d/%0d] %s", i+1, loop_count, item.convert2string()),UVM_HIGH)
        end
    endtask
endclass


class adder_component1 extends uvm_component;
    `uvm_component_utils(adder_component1)
    uvm_analysis_imp #(adder_seq_item, adder_component1) ap_imp_comp1; //class 임
    function new (string name, uvm_component c);
        super.new(name,c);
        ap_imp_comp1 = new("ap_imp_comp1",this);
    endfunction
    
    virtual function void write(adder_seq_item item);
        `uvm_info(get_type_name(),$sformatf("       ap_imp_comp1 : %s",item.convert2string()), UVM_MEDIUM)
    endfunction

endclass

class adder_component2 extends uvm_component;
    `uvm_component_utils(adder_component2)
    uvm_analysis_imp #(adder_seq_item, adder_component2) ap_imp_comp2; //class 임

    function new (string name, uvm_component c);
        super.new(name,c);
        ap_imp_comp2 = new("ap_imp_comp2",this);
    endfunction

    virtual function void write(adder_seq_item item);
        `uvm_info(get_type_name(),$sformatf("       ap_imp_comp2: %s",item.convert2string()), UVM_MEDIUM)
    endfunction

    
endclass


//subscriber는 coverage 기능에 많이 씀, 커버리지가 뭐임?
class adder_subscriber extends uvm_subscriber #(adder_seq_item);
//                                                  type
    `uvm_component_utils(adder_subscriber)
    //subscriber는 uvm_analysis_imp 가 필요없음, 내부에 이미 존재하고 있음
    function new (string name, uvm_component c );
        super.new(name,c);
    endfunction
    

    virtual function void write(adder_seq_item item);
        `uvm_info(get_type_name(), $sformatf("  adder_subscriber: %s", item.convert2string()),UVM_MEDIUM)
    endfunction
endclass


class adder_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(adder_scoreboard) //factory 등록 macro 기능
    uvm_analysis_imp #(adder_seq_item, adder_scoreboard) ap_imp; //class 임
    //                       type           class         handler           

    int fail_count;
    int pass_count;

    function new(string name, uvm_component c);
        super.new(name,c);
        ap_imp = new("ap_imp", this);
        fail_count = 0;
        pass_count = 0;
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction

    virtual task run_phase(uvm_phase phase);
    endtask

    
    virtual function void write(adder_seq_item item); //핸들러는 주소를 item이 받아 접근해서 사용할 수 있음
        `uvm_info(get_type_name(),$sformatf("received: %s",item.convert2string()),UVM_MEDIUM)
        if (item.y == item.a + item.b) begin
            `uvm_info(get_type_name(),$sformatf("Matched!: y:%0d === a:%0d + b:%0d",
                                                    item.y, item.a, item.b), UVM_MEDIUM)
            pass_count++;
        end else begin
            `uvm_error(get_type_name(), $sformatf("Mismatched!: y:%0d === a:%0d + b:%0d",
                                                    item.y, item.a, item.b))
            fail_count++;
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(),"============= Scoreboard Summary =============", UVM_LOW)  
        `uvm_info(get_type_name(), $sformatf("  Total transactions :%0d",pass_count + fail_count),UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Pass :%0d",pass_count),UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("  Fail :%0d",fail_count),UVM_LOW)

        if(fail_count >0) begin
            `uvm_error(get_type_name(),$sformatf("TEST FAILED: %0d mismatched detected!", fail_count))

        end else begin
            `uvm_info(get_type_name(),$sformatf("TEST PASSED: %0d all matches detected!", pass_count), UVM_LOW)
        end
    endfunction
endclass


class adder_driver extends uvm_driver #(adder_seq_item); //드라이버 한정 선언
    //드라이버 입장에서 시퀀스는 관심 없어, 시퀀서만으로 주고 받는거야(?)
    //시퀀서와 드라이버를 연결시켜주는 곳은 에이전트임 애초에 env.agt.sqr 순서로 참조하고 있잖아 
    `uvm_component_utils(adder_driver) //factory 등록 macro 기능

    virtual adder_if a_if;

    function new(string name, uvm_component c);
        super.new(name,c);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual adder_if)::get(this,"","a_if",a_if)) 
            `uvm_fatal(get_type_name(),"a_if를 찾을 수 없습니다.")
        `uvm_info(get_type_name(),"build_phase 실행 완료.",  UVM_HIGH);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction

    virtual task drive_item(adder_seq_item item);
        @(posedge a_if.clk);
        a_if.a <= item.a;
        a_if.b <= item.b;
        @(posedge a_if.clk);
        @(posedge a_if.clk);
        `uvm_info(get_type_name(),item.convert2string(), UVM_HIGH);
    endtask

    virtual task run_phase(uvm_phase phase);
        adder_seq_item item;
        @(posedge a_if.rst_n);
        forever begin
            seq_item_port.get_next_item(item); // [2] , 다음 아이템 실행해 
            // [DRV] 2. item 요청
            // 응답까지 대기 Block
            // [DRV] 5. 응답, item 응답(0x100 주소)
            drive_item(item);
            seq_item_port.item_done(); //아이템 전부 실행했어
            // [6] 완료 응답
        end
    endtask

    virtual function void report_phase(uvm_phase phase);

    endfunction

endclass


class adder_monitor extends uvm_monitor;
    `uvm_component_utils(adder_monitor) //factory 등록 macro 기능 //타입이 클래스임
    uvm_analysis_port#(adder_seq_item) ap; //analysis port 약자 ◇ - 클래스 핸들러
    virtual adder_if a_if;//type

    function new(string name, uvm_component c);
        super.new(name,c);
        ap = new("ap",this); //연결자 만들어줌
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual adder_if)::get(this,"","a_if",a_if)) 
            `uvm_fatal(get_type_name(),"a_if를 찾을 수 없습니다.")
        `uvm_info(get_type_name(),"build_phase 실행 완료.",  UVM_HIGH);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction

    virtual task run_phase(uvm_phase phase);
        adder_seq_item item;
        @(posedge a_if.rst_n);
        forever begin
            item = adder_seq_item::type_id::create("item");
            @(posedge a_if.clk); //들어가기전 정확한 타이밍 맞춰주기
            @(posedge a_if.clk); //한 클럭 더 줘야함
            item.a = a_if.a;
            item.b = a_if.b;
            @(posedge a_if.clk); //클럭 적용된 덧셈기니까 한클럭 지연후 출력값 기록
            item.y = a_if.y;
            ap.write(item); //스코어 보드에 넘겨줘
            `uvm_info(get_type_name(), item.convert2string(), UVM_MEDIUM);
        end
    endtask

    virtual function void report_phase(uvm_phase phase);

    endfunction

endclass


class adder_agent extends uvm_agent;
    `uvm_component_utils(adder_agent) //factory 등록 macro 기능
    uvm_sequencer #(adder_seq_item) sqr;
    adder_driver drv;
    adder_monitor mon;

    function new(string name, uvm_component c);
        super.new(name,c);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        //sqr(export)O -> ㅁ(port)drv
        sqr = uvm_sequencer#(adder_seq_item)::type_id::create("sqr",this);
        drv = adder_driver::type_id::create("drv",this);
        mon = adder_monitor::type_id::create("mon",this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
        //    caller                    callee
        // 드라이버가 호출합니다. 콜러가 커넥트합니다. 즉 드라이버가 커넥트 합니다. (명제냐)

        // seq_item_port.connect : 부모 클래스(uvm_driver)에 구현되어 있다.
        // seq_item_export : 부모 클래스(uvm_sequencer)에 구현되어 있다.
        //
        //
        //
        //
    endfunction

    virtual task run_phase(uvm_phase phase);

    endtask

    virtual function void report_phase(uvm_phase phase);

    endfunction

endclass

class adder_env extends uvm_env;


    adder_agent agt;
    adder_scoreboard scb;
    adder_component1 cmp1;
    adder_component2 cmp2;
    adder_subscriber subs;

    //sqr(export)O -> ㅁ(port)drv
    `uvm_component_utils(adder_env) //factory 등록 macro 기능


    function new(string name, uvm_component c);
        super.new(name,c);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = adder_agent::type_id::create("agt",this);
        scb = adder_scoreboard::type_id::create("scb",this);
        cmp1  = adder_component1::type_id::create("comp1",this);
        cmp2  = adder_component2::type_id::create("comp2",this);
        subs = adder_subscriber::type_id::create("subs",this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.ap.connect(scb.ap_imp); //어렵네요 커넥트가 메소드래요
        agt.mon.ap.connect(cmp1.ap_imp_comp1);
        agt.mon.ap.connect(cmp2.ap_imp_comp2);
        agt.mon.ap.connect(subs.analysis_export); //얘는 포트이름 고정임, 내장 기능이라
        //                      주소
        //subscriber는 커넥트만 해주면 다 보내줄 수 있다.
    endfunction

    virtual task run_phase(uvm_phase phase);
    endtask

    virtual function void report_phase(uvm_phase phase);
    endfunction

endclass
 

class adder_test extends uvm_test;
    `uvm_component_utils(adder_test)
        //Q. 컴포넌트 유틸즈가 무엇인가? 
        //A. 팩토리 하위 구조로 컴포넌트 계열과 오브젝트 계열이 있는데, 
        //오브젝트 계열은 [Sequence_item/Sequence], 
        //컴포넌트 계열은 [test, env, agent, driver, monitor, sequencer, scoreboard, subscriber]
        //Q. adder_test는 무엇인가?
        //A. factory 등록하는 애
        //Q. 
        //A.
    adder_env env;
    function new(string name, uvm_component c);
        //Q. uvm_component가 무엇인가?
        // A. 테스트벤치의 고정된 뼈대들의 최상위 부모 클래스. 
        //name과 parent 인자를 받아 트리(Hierarchy) 구조 내에서 자신의 위치를 가질 수 있게 해준다.

        super.new(name,c);
    endfunction
    
    //test -> env -> [scoreboard] / [agent]-> [sequencer/driver/monitor]

    //phase들은 그냥 알기쉽게 정의해놓은 키워드이며 각각의 절차마다 행해지는 함수 같은 것들이다.

    // build phase의 특징
    // 먼저 골격부터 생성하는 과정이라 바텀 업이 불가능하며 무조건 탑다운이여야한다
    // 쉽게 생각하면 함수 맨 위에 선언 안 해놓으면 없다고 에러 메시지 뜨잖음
    // 루트부터 순서대로 타고 내려가야 전체를 생성하는 것이 가능함
    // Build: "누가 누구를 포함하는가?" (상하 계층 구조 결정) Top-Down
    // Connect: "누가 누구와 데이터를 주고받는가?" (좌우 통신 관로 연결) Bottom-Up
    // Run: "이제 실제로 시나리오를 흘려보내자!" (병렬 동기 구동) Parallel
    // 즉, 빌드 페이즈는 골격 생성, 커넥트는 각 골격끼리 연결, run때는 연결된 환경에서 동작 수행

    // connect, run_phase의 특징
    // 얘는 빌드 생성이 완료된 후에 그 인자들을 가지고 작업을 시작함
    // 그렇기에 바텀업이 가능한 phase들이다
    // 이미 생성된 구조를 바탕으로 동작함
    // fork와 같은 형태를 띄고 있어서(상위에서 하위 모듈들로 전달같은 모양)
    // 독립적으로 동작하고 있음
    // 

    virtual function void build_phase(uvm_phase phase);
        //phase 메커니즘 - 시뮬레이션 순서(절차) 관리
        //- 생성 -> 연결 -> 실행 -> 결과 리포트(일반론
        //

        super.build_phase(phase);
        env = adder_env::type_id::create("env",this);
        //UVM_object 계열 - 데이터를 담는 용도 (Data Signal = Stimulus)
        //UVM_component 계열 - 테스트 벤치 구조를 만드는 용도(뼈대)
        //핸들러 - Class이름 :: type_id :: create(- , -)
        //factory에 인스턴스 생성 절차
        //Factory가 인스턴스 생성
        //오브젝트(인스턴스)를 수정 변경해야 할 경우 or '새로운' instance로 대체해야하는 경우 factory 생성으로 사용하면 쉽게 변경 가능
        //new()를 이용한 인스턴스일 경우 변경이 어렵다.
        //★ new로()하면 다른 코드들도 수정해야하지만, 인스턴스로 하면 쉽게 변경 가능하다 ★
        `uvm_info(get_type_name(), "build phase", UVM_HIGH)
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info(get_type_name(), "adder_sequence seq 실행", UVM_DEBUG)
    endfunction

    virtual task run_phase(uvm_phase phase);
    //phase 이름에 맞게 코딩해야함 ex) build_phase에 connect 코드가 입력 되면 안 된다.
    //얘만 task이며  task 내부에서만 시간 관리 가능함, 그 외는 함수들이라 시간제어 불가능
        adder_sequence seq;
        `uvm_info(get_type_name(), "adder_sequence seq 실행", UVM_DEBUG)

        phase.raise_objection(this);
        `uvm_info(get_type_name(), "phase.raise_objection(this) 실행", UVM_DEBUG)
        seq = adder_sequence::type_id::create("seq",this);
        `uvm_info(get_type_name(), "adder_sequence::type_id::create(\"seq\",this) 실행", UVM_DEBUG)
        seq.loop_count = 10;
        `uvm_info(get_type_name(), "seq.loop_count = 10 실행", UVM_DEBUG)
        seq.start(env.agt.sqr); //연결형태 6/8일 수업자료 참고
        `uvm_info(get_type_name(), "seq.start(env.agt.sqr) 실행", UVM_DEBUG)
        phase.drop_objection(this);
        // drop_objection -> factory 멈춰
        
        

    endtask

    virtual function void report_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction

endclass


module tb_adder();
    logic clk, rst_n;
    
    initial begin
        clk = 0;
        rst_n = 0;
        repeat(3) @(posedge clk);
        rst_n = 1;

    end

    always #5 clk =~clk;
    
    adder_if a_if(
        clk,
        rst_n
    );

    adder dut(
       .clk(a_if.clk),
       .rst_n(a_if.rst_n),
       .a(a_if.a),
       .b(a_if.b),
       .y(a_if.y)
    );
  
  initial begin
        uvm_config_db#(virtual adder_if)::set(null, "*", "a_if",a_if); //a_if라는 인터페이스 선언
        //Q. 여기서 #(변수)은 무엇을 의미하는가?
        //A. 가상 인터페이스
        //A. 저장되는 데이터 타입
        //Q. ::는 무엇인가?
        //A. 클래스 멤버를 의미한다.
        //Q. set은 무엇을 의미하는가?
        //A. DB에 저장하는 기능
        //Q. 별표(*)는 무엇인가? 
        //A. 와일드카드로 모든 컴포넌트(경로)가 받을 수 있음을 나타냄
        //Q. "a_if"는 무엇인가?
        //A. Key값이며, 문지열로 저장된다. get 동작시 해당 이름으로 검색 시행
        //Q. a_if(실제 인터페이스)는 무엇인가?
        //A. 실제 저장할 값에 해당한다. 즉, 인스턴스가 저장됨(메모리에 저장되는 해당위치의 주소)

        run_test("adder_test");
        //Q. 해당 구문은 무슨 역할을 하는가?
        //A. 트리거 역할, 즉 , UVM Factory 동작 트리거
        //Q. "adder_test"는 무엇인가?
        //A. uvm_test를 상속 받은 클래스의 이름 => adder_test를 인스턴스 시키고 동작하게 함

  end

endmodule

