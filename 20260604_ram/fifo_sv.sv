`timescale 1ns / 1ps

module fifo_sv(
    input logic clk,
    input logic rst_n,
    input logic [7:0] push_data,
    input logic push,
    input logic pop,
    output logic [7:0] pop_data,
    output logic full,
    output logic empty
);


    logic [3:0] wptr, rptr; //wire

reg_file U_REG_FILE(
    .*, //Automatic Mapping
    .wdata(push_data),
    .waddr(wptr),
    .raddr(rptr),
    .we(push && ~full),
    .rdata(pop_data)
);


control_unit U_CU(
    .*,
    .wptr(),
    .rptr()
);


endmodule



module reg_file (
    input logic clk,
    input logic [7:0] wdata,
    input logic [3:0] waddr,
    input logic [3:0] raddr,
    input logic we,
    output logic [7:0] rdata
);

    logic [7:0] reg_file [0:15]; //address 4bit x dk tlqkf ram 주소 비트의 2의 n승 그래서 16


        always_ff @(posedge clk) begin
            if (we) begin
                reg_file[waddr] <= wdata;
            end 
        end

    assign rdata = reg_file[raddr];



endmodule

module control_unit(
    input  logic clk,
    input  logic rst_n,
    input  logic push,
    input  logic pop,
    output logic [3:0] wptr,
    output logic [3:0] rptr,
    output logic full,
    output logic empty    
);

    logic [3:0] wptr_reg, wptr_next;
    logic [3:0] rptr_reg, rptr_next;
    logic empty_reg, empty_next;
    logic full_reg, full_next;

    assign rptr = rptr_reg;
    assign wptr = wptr_reg;
    assign full = full_reg;
    assign empty = empty_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rptr_reg  <= 0;
            wptr_reg  <= 0;
            full_reg  <= 0;
            empty_reg <= 1;
        end else begin
            wptr_reg  <= wptr_next;
            rptr_reg  <= rptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    always_comb begin
        wptr_next  = wptr_reg;
        rptr_next  = rptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;

        case({push, pop})
            2'b10: begin // Push only
                if (!full_reg) begin
                    wptr_next = wptr_reg + 1;
                    empty_next = 0;
                    if (wptr_next == rptr_reg) begin
                        full_next = 1;
                    end
                end 
            end
            2'b01: begin // Pop only
                if(!empty_reg) begin
                    rptr_next = rptr_reg + 1;
                    full_next = 0;
                    if (rptr_next == wptr_reg) begin
                        empty_next = 1;
                    end
                end
            end
            2'b11: begin // Push & Pop
                if(full_reg) begin // 가득 찼을 땐 Pop 우선
                    rptr_next = rptr_reg + 1;
                    full_next = 0;
                end else if(empty_reg) begin // 비었을 땐 Push 우선
                    wptr_next = wptr_reg + 1;
                    empty_next = 0;
                end else begin // 둘 다 수행 (개수는 유지)
                    wptr_next = wptr_reg + 1;
                    rptr_next = rptr_reg + 1;
                end
            end
            default: ; // 2'b00 일 때 기본값(현재상태 유지)이 적용됨
        endcase
    end
endmodule




