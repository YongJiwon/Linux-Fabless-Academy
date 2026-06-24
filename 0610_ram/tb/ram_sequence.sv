class ram_base_seq extends uvm_sequence #(ram_seq_item);
    `uvm_object_utils(ram_base_seq)

    function new(string name = "ram_base_seq");
        super.new(name);
    endfunction

    // Write 제어 태스크
    task do_write(bit [7:0] addr, bit [7:0] data);
        ram_seq_item item;
        item = ram_seq_item::type_id::create("item");
        
        start_item(item);
            item.we    = 1'b1;
            item.addr  = addr;
            item.wdata = data; 
        finish_item(item);     
    endtask

    // Read 제어 태스크 (읽은 데이터를 받아오기 위해 output 설정)
    task do_read(bit [7:0] addr, output bit [7:0] rdata_out);
        ram_seq_item item;
        item = ram_seq_item::type_id::create("item");
        
        start_item(item);
            item.we    = 1'b0;
            item.addr  = addr;
            item.wdata = 8'h00; 
        finish_item(item);     
        
        rdata_out = item.rdata; 
    endtask
endclass


class ram_wr_rd_seq extends ram_base_seq; 
    `uvm_object_utils(ram_wr_rd_seq)

    rand int num;
    constraint c_num { num inside {[600 : 900]}; }

    function new(string name = "ram_wr_rd_seq");
        super.new(name);
    endfunction

    virtual task body();
        bit [7:0] addr_q[$];
        bit [7:0] addr;
        bit [7:0] rdata_buf; 

        `uvm_info(get_type_name(), $sformatf("wr_rd 시나리오 시작 (%0d 반복)", num), UVM_LOW)
        
        // 순차 쓰기 동작
        repeat (num) begin 
            addr = $urandom_range(0, 255); // 0~255 전 영역 타격으로 커버리지 만족 우수
            do_write(addr, $urandom_range(0, 255));
            addr_q.push_back(addr);
        end
        
        // 순차 읽기 동작
        foreach (addr_q[i]) begin
            do_read(addr_q[i], rdata_buf); 
        end

        `uvm_info(get_type_name(), "wr_rd 시나리오 종료.", UVM_LOW)
    endtask
endclass

class ram_random_seq extends ram_base_seq; 
    `uvm_object_utils(ram_random_seq)
    
    rand int num;
    constraint c_num { num inside {[10 : 30]}; } 

    function new(string name = "ram_random_seq");
        super.new(name);
    endfunction

    virtual task body();
        ram_seq_item item;
        `uvm_info(get_type_name(), $sformatf("Random 시나리오 시작 (%0d 반복)", num), UVM_LOW)
        
        repeat(num) begin
            item = ram_seq_item::type_id::create("item");
            start_item(item);
            
            
            if (!item.randomize() with { we dist { 1'b1 := 6, 1'b0 := 4 }; }) begin
                `uvm_error(get_type_name(), "아이템 랜덤화 실패!")
            end
            
            finish_item(item); 
        end
        
        `uvm_info(get_type_name(), "Random 시나리오 종료.", UVM_LOW)
    endtask
endclass

/*class ram_base_seq extends uvm_sequence #(ram_seq_item);
    `uvm_object_utils(ram_base_seq)

    // UVM object 규칙: 생성자 인자에 기본값 명시
    function new(string name = "ram_base_seq");
        super.new(name);
    endfunction

    // Write 제어 태스크
    task do_write(bit [7:0] addr, bit [7:0] data);
        ram_seq_item item;
        item = ram_seq_item::type_id::create("item");
        
        start_item(item);
            item.we    = 1'b1;
            item.addr  = addr;
            item.wdata = data; // 인자 이름(data)과 일치하도록 수정
        finish_item(item);     // ⭕ item 인스턴스를 아규먼트로 넘기는 것이 맞습니다.
    endtask

    // Read 제어 태스크 (읽은 데이터를 받아오기 위해 output 설정)
    task do_read(bit [7:0] addr, output bit [7:0] rdata_out);
        ram_seq_item item;
        item = ram_seq_item::type_id::create("item");
        
        start_item(item);
            item.we    = 1'b0;
            item.addr  = addr;
            item.wdata = 8'h00; // Read 시 쓰기 데이터 버스는 초기화
        finish_item(item);     // ⭕ item 인스턴스를 아규먼트로 넘기는 것이 맞습니다.
        
        rdata_out = item.rdata; // 드라이버가 받아온 최종 데이터를 출력 변수에 할당
    endtask
endclass


class ram_wr_rd_seq extends ram_base_seq; 
    `uvm_object_utils(ram_wr_rd_seq)

    rand int num;
    constraint c_num { num inside {[600 : 900]}; }

    function new(string name = "ram_wr_rd_seq");
        super.new(name);
    endfunction

    virtual task body();
        bit [7:0] addr_q[$];
        bit [7:0] addr;
        bit [7:0] rdata_buf; // do_read 인자 매칭용 임시 버퍼

        `uvm_info(get_type_name(), $sformatf("wr_rd 시나리오 시작 (%0d 반복)", num), UVM_LOW)
        
        // 순차 쓰기 동작
        repeat (num) begin 
            addr = $urandom_range(0, 255); // 메모리 주소 스펙 가용 범위 반영
            do_write(addr, $urandom_range(0, 255));
            addr_q.push_back(addr);
        end
        
        // 순차 읽기 동작
        foreach (addr_q[i]) begin
            do_read(addr_q[i], rdata_buf); // 인자 개수 불일치 해결
        end

        `uvm_info(get_type_name(), "wr_rd 시나리오 종료.", UVM_LOW)
    endtask
endclass

class ram_random_seq extends ram_base_seq; 
    `uvm_object_utils(ram_random_seq)
    
    rand int num;
    constraint c_num { num inside {[10 : 30]}; } // 비어있던 제약조건 보완

    // UVM 규격에 맞게 생성자 구조 수정
    function new(string name = "ram_random_seq");
        super.new(name);
    endfunction

    virtual task body();
        ram_seq_item item;
        `uvm_info(get_type_name(), $sformatf("Random 시나리오 시작 (%0d 반복)", num), UVM_LOW)
        
        repeat(num) begin
            item = ram_seq_item::type_id::create("item");
            start_item(item);
            
            // 괄호 구조 및 인라인 제약조건 내부 변수명 오타 수정 (write -> we)
            if (!item.randomize() with {
                we dist {
                    1'b1 := 6,
                    1'b0 := 4
                }; // 중괄호 내부 세미콜론 허용 범위 검증 완료
            }) begin
                `uvm_error(get_type_name(), "아이템 랜덤화 실패!")
            end
            
            finish_item(item); // ⭕ item 인스턴스를 아규먼트로 넘기는 것이 맞습니다.
        end
        
        `uvm_info(get_type_name(), "Random 시나리오 종료.", UVM_LOW)
    endtask
endclass*/