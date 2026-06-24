class ram_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(ram_scoreboard)

    uvm_analysis_imp #(ram_seq_item, ram_scoreboard) imp;

    bit [7:0] mem_model [256];
    bit written[256]; // 쓰기 기록 확인용 플래그 배열

    int write_count = 0;
    int read_count  = 0; 
    int pass_count  = 0;
    int fail_count  = 0;
    int skipped_count = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        imp = new("imp", this);
    endfunction

    // ⭕ 보완: SystemVerilog 규격에 맞게 반환 타입 void 명시
    function void write(ram_seq_item tr);
        if (tr.we) begin
            write_count++;
            mem_model[tr.addr] = tr.wdata;
            written[tr.addr]   = 1'b1; // ⭕ 수정: 해당 주소에 쓰기가 완료되었음을 마킹합니다.
        end else begin
            // 한번도 쓰지 않은 주소를 읽으려고 하면 스킵 처리
            if (!written[tr.addr]) begin
                skipped_count++;
                `uvm_info(get_type_name(), $sformatf("SKIP: 써진 적 없는 주소 접근 ADDR=0x%02h", tr.addr), UVM_HIGH)
                return; 
            end
            
            // 정상적인 Read 비교 분석 시작
            read_count++;
            if (tr.rdata === mem_model[tr.addr]) begin
                pass_count++;
                `uvm_info(get_type_name(), $sformatf("PASS: %s (기대값=0x%02h)", tr.convert2string(), mem_model[tr.addr]), UVM_LOW) // 분석을 위해 LOW로 변경 추천
            end else begin
                fail_count++;
                `uvm_error(get_type_name(), $sformatf("FAIL: %s (기대값=0x%02h)", tr.convert2string(), mem_model[tr.addr]))
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCB", "======================================", UVM_LOW)
        `uvm_info("SCB", "======= Scoreboard 최종 리포트 ========", UVM_LOW)
        `uvm_info("SCB", $sformatf("  write count   : %0d", write_count), UVM_LOW)
        `uvm_info("SCB", $sformatf("  read count    : %0d", read_count), UVM_LOW)
        `uvm_info("SCB", $sformatf("  pass count    : %0d", pass_count), UVM_LOW)
        `uvm_info("SCB", $sformatf("  fail count    : %0d", fail_count), UVM_LOW)
        `uvm_info("SCB", $sformatf("  skipped count : %0d", skipped_count), UVM_LOW) // ⭕ 추가: 스킵된 이력도 출력하도록 보완
        `uvm_info("SCB", "======================================", UVM_LOW)
    endfunction
endclass

/*class ram_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(ram_scoreboard)

    uvm_analysis_imp #(ram_seq_item, ram_scoreboard) imp;

    bit [7:0] mem_model [256];
    bit written[256];

    int write_count=0;
    int read_count =0; 
    int pass_count=0;
    int fail_count =0;
    int skipped_count = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        imp = new("imp",this);
    endfunction

    function write(ram_seq_item tr);
        if (tr.we) begin
            write_count++;
            mem_model[tr.addr] = tr.wdata;
        end else begin
            if (!written[tr.addr]) begin
                skipped_count++;
                return;
            end
            read_count++;
            if (tr.rdata === mem_model[tr.addr]) begin
                pass_count++;
                `uvm_info(get_type_name(),$sformatf("PASS: %s (기대값=0x%02h)",tr.convert2string(), mem_model[tr.addr]),UVM_HIGH)
            end else begin
                fail_count++;
                `uvm_error(get_type_name(),$sformatf("FAIL: %s (기대값=0x%02h)",tr.convert2string(), mem_model[tr.addr]))
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCB", "======================================", UVM_LOW)
        `uvm_info("SCB", "======= Scoreboard 최종 리포트 ========", UVM_LOW)
        `uvm_info("SCB", $sformatf("  write count : %0d",write_count), UVM_LOW)
        `uvm_info("SCB", $sformatf("  read count : %0d",read_count), UVM_LOW)
        `uvm_info("SCB", $sformatf("  pass count : %0d",pass_count), UVM_LOW)
        `uvm_info("SCB", $sformatf("  fail count : %0d",fail_count), UVM_LOW)
        `uvm_info("SCB", "======================================", UVM_LOW)

        
    endfunction

endclass*/