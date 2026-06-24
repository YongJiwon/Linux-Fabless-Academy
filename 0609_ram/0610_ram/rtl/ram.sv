`timescale 1ns/1ps

module ram(
    input logic clk,
    input logic rst_n,
    input logic [7:0] addr ,
    input logic [7:0] wdata ,
    input logic we,
    output logic [7:0] rdata

);
    

logic [7:0] register [0:63];

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rdata <= 0;
    end else begin
        if (we) begin
            register[addr] <= wdata;
        end else begin
            rdata <= register[addr];
        end
    end
end



endmodule