class ram_monitor extends uvm_monitor;
    `uvm_component_utils(ram_monitor)

    virtual ram_if r_if;
    uvm_analysis_port #(ram_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual ram_if)::get(this, "", "r_if", r_if))
            `uvm_fatal(get_type_name(), "virtual interface(r_if)를 config_db에서 찾지 못함.")
    endfunction

    task run_phase(uvm_phase phase);
        ram_seq_item tr; 
        ram_seq_item pending_rd = null; 

        forever begin
            @(r_if.mon_cb); // 클럭 블로킹 지점
            
            // 1. 이전 클럭에 Read 요청이 있었다면, 이번 클럭에 버스에 뜬 rdata를 수집
            if(pending_rd != null) begin
                pending_rd.rdata = r_if.mon_cb.rdata;
                
                // ⭕ 버그 수정: tr 대신 완성이 끝난 pending_rd의 데이터를 출력해야 크래시가 안 납니다.
                `uvm_info(get_type_name(), $sformatf("%s", pending_rd.convert2string()), UVM_HIGH)
                
                // ⭕ 문법 에러 수정: ap.we() -> ap.write()로 변경하여 스코어보드로 브로드캐스팅
                ap.write(pending_rd); 
                pending_rd = null;
            end
            
            // 2. 현재 클럭의 커맨드(Write 또는 Read 요청) 샘플링
            tr = ram_seq_item::type_id::create("tr");
            tr.we    = r_if.mon_cb.we;
            tr.addr  = r_if.mon_cb.addr;
            tr.wdata = r_if.mon_cb.wdata;
            
            if (tr.we) begin
                // Write는 턴을 끌 필요 없이 주소와 데이터가 동시에 들어오므로 즉시 전송
                `uvm_info(get_type_name(), $sformatf("%s", tr.convert2string()), UVM_HIGH)
                ap.write(tr); // ⭕ 문법 에러 수정: ap.we() -> ap.write()
            end else begin
                // Read 요청이면 바로 보내지 않고, 다음 클럭에 rdata가 나올 때까지 pending 상태로 대기
                pending_rd = tr; 
            end
        end        
    endtask
endclass