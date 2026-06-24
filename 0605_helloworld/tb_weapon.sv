class weapon;
    string name;

    function new(string name);
        this.name= name;
        
    endfunction
    
    virtual function void shot(); //virtual => 내용 재정의 가능
        $display("  [%s] ... (무기 없음)",name);
    endfunction
endclass

class M16 extends weapon;
    function new (string name);
        super.new(name);
    endfunction

    virtual function void shot();
        $display("  [%s] ... 탕탕탕 !!!",name);
    endfunction


endclass

class K2 extends weapon;
    function new (string name);
        super.new(name);
    endfunction

    virtual function void shot();
        $display("  [%s] ... 빵빵빵 !!!",name);
    endfunction


endclass

class AUG extends weapon;
    function new (string name);
        super.new(name);
    endfunction

    virtual function void shot();
        $display("  [%s] 삐~~익~~~~ 텅텅텅 !!!",name);
    endfunction


endclass


module tb_weapon();
    initial begin
        weapon BlackPink = new("No Weapon"); //weapon 타입 핸들 BlackPink가 weapon 객체를 가리킨다
        //스택이라 위에서부터 내려옴
        //BlackPink [0x00] = ([0x100])
        //M16 handler [0x00] = ([0x200])
        //AUG handler [0x00] = ([0x300])
        //K2 handler [0x00] = ([0x400])
        //--------------------------------//
        // K2 instance [0x400]
        // AUG instance [0x300]
        // M16 instance [0x200]
        // Weapon instance [0x100]
        //더미(?)라서 낮은 번지에 위치함

        M16 m16 = new("M16");
        AUG aug = new("AUG");
        K2 k2 = new("K2");

        $display("====== 다형성 데모 ======");
        BlackPink.shot();

        $display("====== 무기 M16으로 변경 ======");
        BlackPink = m16;
        BlackPink.shot();


        $display("====== 무기 AUG로 변경 ======");
        BlackPink = aug;
        BlackPink.shot();

        $display("====== 무기 K2로 변경 ======");
        BlackPink = k2;
        BlackPink.shot();

    end

    
endmodule