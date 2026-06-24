`include "uvm_macros.svh"
//import uvm_pkg::*; //모듈 밖이든 안이든 선언위치는 상관 없음
import ram_pkg::*; //근데, 밖에 두면 전역 선언임, 내부에 두변 지역 선언


module tb_top();
    logic clk;

    initial clk =0;
    always #5 clk =~clk;

    ram_if r_if(.clk(clk));


    ram dut(
        .clk(r_if.clk),
        .addr(r_if.addr),
        .wdata(r_if.wdata),
        .we(r_if.we),
        .rdata(r_if.rdata)
    );

    initial begin
        //해당 라인 앞에 딜레이를 주게되면 엉뚱한 메시지가 뜨게됨, 그렇기 때문에 딜레이 절대 주면 안 됨
        //문법적으로 이슈는 없지만 툴에 이슈가 발생할 수 있음
        uvm_config_db#(virtual ram_if)::set(null,"*","r_if",r_if);
        run_test("ram_test");
    end

    initial begin
        //verdi에서 보려면 FSDB 파일이 필요함
        $fsdbDumpfile("ram_tb.fsdb");
        $fsdbDumpvars(0);
        $fsdbDumpMDA(); //메모리 배열(mem) 덤프
    end

endmodule