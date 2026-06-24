`include "uvm_macros.svh"
import uvm_pkg::*;
import ram_pkg::*; 

interface ram_if(input logic clk); // 포트에서 clk 선언 완료

    // 내부 logic clk; 중복 선언 삭제
    logic       we;
    logic [7:0] addr;
    logic [7:0] wdata;
    logic [7:0] rdata;

    // 드라이버용 클로킹 블록
    clocking drv_cb @(posedge clk);
        // 레이스 컨디션 방지를 위해 output 타임을 #1ns 또는 #1로 설정 권장
        default input #1step output #1ns; 
        output we;
        output addr;
        output wdata;
        input  rdata; // 드라이버 기준에서 rdata는 input입니다.
    endclocking

    // 모니터용 클로킹 블록
    clocking mon_cb @(posedge clk);
        default input #1step;
        input we;
        input addr;
        input wdata;
        input rdata;
    endclocking

    // modport 선언
    modport DRV (clocking drv_cb, input clk);
    modport MON (clocking mon_cb, input clk);

endinterface