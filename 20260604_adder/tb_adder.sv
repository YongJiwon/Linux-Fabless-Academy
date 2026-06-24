`timescale 1ns/1ps

module tb_adder;

    // 1. 테스트 입력 및 출력 신호 선언
    logic [15:0] a;
    logic [15:0] b;
    logic        c_in;
    
    logic [15:0] sum;
    logic        c_out;

    // 2. 검증 대상 모듈(DUT: Design Under Test) 인스턴스화
    cla_16bit U_DUT (
        .a     (a),
        .b     (b),
        .c_in  (c_in),
        .sum   (sum),
        .c_out (c_out)
    );

    // 3. 테스트 시나리오 적용 (Stimulus)
    initial begin
        // 터미널 모니터링 설정: 신호가 바뀔 때마다 값을 출력
        $monitor("Time=%0dt ns | A=0x%h (%0d), B=0x%h (%0d), Cin=%b | Sum=0x%h (%0d), Cout=%b", 
                 $time, a, a, b, b, c_in, sum, sum, c_out);

        // [Case 0] 초기화
        a = 16'h0000; b = 16'h0000; c_in = 1'b0;
        #10;

        // [Case 1] 일반적인 양수 덧셈 (상위 비트 캐리 없음)
        a = 16'h1234; b = 16'h5678; c_in = 1'b0;
        #10;

        if (sum !== 16'h69AC || c_out !== 1'b0) $display(">>> [ERROR] Case 1 Failed!");
        // [Case 2] Carry In(c_in)이 들어오는 경우의 연산
        a = 16'h00A0; b = 16'h000B; c_in = 1'b1;
        #10;
        if (sum !== 16'h00AC || c_out !== 1'b0) $display(">>> [ERROR] Case 2 Failed!");

        // [Case 3] 최상위 비트 바로 아래에서 자리올림이 발생하는 경우 (RCA와 속도 비교 지점)
        a = 16'h7FFF; b = 16'h0001; c_in = 1'b0;
        #10;
        if (sum !== 16'h8000 || c_out !== 1'b0) $display(">>> [ERROR] Case 3 Failed!");

        // [Case 4] 최종 16비트 범위 초과로 c_out(최종 Carry)이 발생하는 경우
        a = 16'hFFFF; b = 16'h0001; c_in = 1'b0;
        #10;
        if (sum !== 16'h0000 || c_out !== 1'b1) $display(">>> [ERROR] Case 4 Failed!");

        // [Case 5] 경계 조건 테스트 (최대값 + 최대값 + c_in)
        a = 16'hFFFF; b = 16'hFFFF; c_in = 1'b1;
        #10;
        if (sum !== 16'hFFFF || c_out !== 1'b1) $display(">>> [ERROR] Case 5 Failed!");

        // 테스트 종료 알림
        $display(">>> Simulation Finished Successfully!");
        $finish;
    end

    // 4. Verdi/DVE 파형 저장을 위한 로직 (필요시 주석 해제)
  
    initial begin

        $fsdbDumpfile("tb_adder.fsdb");
        $fsdbDumpvars(0, tb_adder);
    end
endmodule
