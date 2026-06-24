`include "uvm_macros.svh" //기본 시스템 베릴로그 매크로 헤더파일 
import uvm_pkg::*; //uvm 패키지 전부 사용



//실행 순서




class hello_test extends uvm_test; //Callee     부모 클래스
    `uvm_component_utils(hello_test) //세미콜론 안 씀(매크로임) //자식 클래스
    //--------------------------- START new() ------------------------------//
    function new(string name = "hello_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new() 
    //--------------------------- END new() --------------------------------//


    //--------------------------- START build_phase ------------------------//
    function void build_phase(uvm_phase phase); //phase : 순서/단계 //실행전 단계
        super.build_phase(phase);
        `uvm_info("BUILD_PHASE","[1] build_phase run.",UVM_LOW);
    endfunction
    //--------------------------- END build_phase --------------------------//


    //------------------------ START connect_phase -------------------------// 준비단계
    function void connect_phase(uvm_phase phase); //실헹전 단계
        super.connect_phase(phase);
        `uvm_info("CONNECT_PHASE","[2] connect_phase run.",UVM_LOW);
    endfunction
    //------------------------- END connect_phase ---------------------------//


    //------------------------ START run_phase ------------------------------// 실행단계
    task run_phase(uvm_phase phase); //실행단계
        phase.raise_objection(this); //UVM 멈추지 마세용
        `uvm_info("RUN_PHASE","[3] run_phase run.",UVM_LOW);
        `uvm_info("HELLO","첫 번째 UVM 프로그램이 실행되었습니다.!",UVM_LOW);
        `uvm_warning("WARN","Warning 메시지 입니다");
        `uvm_error("ERROR","ERROR 메시지 입니다");
        `uvm_info("RUN_PHASE","[4] run_phase stop.",UVM_LOW);
        phase.drop_objection(this); //UVM 이제 멈춰도 돼용
    endtask
    //--------------------------- END run_phase -----------------------------//



    //--------------------------- START report_phase ------------------------------//
    function void report_phase(uvm_phase phase); 
        super.report_phase(phase);
        `uvm_info("REPORT_PHASE","[5] connect_phase run.",UVM_LOW);
    endfunction
    //--------------------------- END report_phase ------------------------------//

endclass //hello_test


module test_uvm();

    initial begin 
        run_test("hello_test");//uvm 트리거 신호 : Caller
        //run_test : 고유한 함수
        //"hello_test" : hello_test라는 이름을 가진 클래스를 찾아
        //그러고 나서 헬로테스트의 객체 생성
    end
    

endmodule