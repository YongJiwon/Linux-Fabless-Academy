class ram_driver extends uvm_driver #(ram_seq_item);
    `uvm_component_utils(ram_driver)
    
    virtual ram_if r_if;

    function new(string name = "ram_driver", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual ram_if)::get(this, "", "r_if", r_if))
            `uvm_fatal(get_type_name(), "virtual interface(vif)를 config_db에서 찾지 못함.")
    endfunction

    virtual task run_phase(uvm_phase phase);
        ram_seq_item rsp; 

        forever begin
            seq_item_port.get_next_item(req);
            
            // 1. 클럭 동기화 후 버스에 제어 신호 및 주소 인가
            @(r_if.drv_cb); 
            r_if.drv_cb.we    <= req.we;
            r_if.drv_cb.addr  <= req.addr;
            r_if.drv_cb.wdata <= req.wdata;

            // 2. Read 동작(we == 0)일 경우에만 하드웨어 rdata가 나올 때까지 1클럭 더 대기 후 샘플링
            if (req.we == 1'b0) begin
                @(r_if.drv_cb); // Memory Read Latency (1-cycle 지연) 동기화
                req.rdata = r_if.drv_cb.rdata; // 메모리가 출력한 진짜 데이터를 req에 수집
                
                // ⭕ Response 패킷 생성 및 시퀀스로 전송하여 핸드셰이크 완료
                rsp = ram_seq_item::type_id::create("rsp");
                rsp.set_id_info(req);  // 시퀀스가 보낸 원본 req 번호와 ID 맵핑 가공
                rsp.rdata = req.rdata; // 수집한 실제 데이터를 응답 패킷에 복사
                
                seq_item_port.put_response(rsp); // 시퀀서 채널을 통해 응답 통보
            end

            `uvm_info(get_type_name(), $sformatf("구동 완료: %s", req.convert2string()), UVM_HIGH)
            seq_item_port.item_done();
        end    
    endtask
endclass

/*class ram_driver extends uvm_driver #(ram_seq_item);
    `uvm_component_utils(ram_driver)
    virtual ram_if r_if;

    
    function new(string name = "ram_driver", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual ram_if)::get(this, "", "r_if", r_if))
            `uvm_fatal(get_type_name(), "virtual interface(vif)를 config_db에서 찾지 못함.")
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);
            
    
            @(r_if.drv_cb); 
            r_if.drv_cb.we    <= req.we;
            r_if.drv_cb.addr  <= req.addr;
            r_if.drv_cb.wdata <= req.wdata;

            `uvm_info(get_type_name(), $sformatf("구동: %s", req.convert2string()), UVM_HIGH)
            seq_item_port.item_done();
        end    
    endtask
endclass

*/