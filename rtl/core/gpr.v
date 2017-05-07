

module gpr(
    input wire                           clk,
    input wire                           rst,
    // write port 
    input wire                           we,
    input wire[`GPR_AddrWidth-1:0]       waddr,
    input wire[`GPR_DataWidth-1:0]       wdata,
    // read port1
    input wire                           re1,
    input wire[`GPR_AddrWidth-1:0]       raddr1,
    output reg[`GPR_DataWidth-1:0]       rdata1,
    // read port2
    input wire                           re2,
    input wire[`GPR_AddrWidth-1:0]       raddr2,
    output reg[`GPR_DataWidth-1:0]       rdata2
);

    reg[`GPR_DataWidth-1:0]  regs[0:`GPR_Num-1];


    always @ (posedge clk) begin
        if (rst == `RstDisable) begin
            if((we == 1'b1) && (waddr != 32'h0)) begin
                regs[waddr] <= wdata;
            end
        end
    end
    
    always @ (*) begin
        if(rst == `RstEnable) begin
            rdata1 <= 1'b0;
        end else if(raddr1 == 32'h0) begin
            rdata1 <= 1'b0;
        end else if((raddr1 == waddr) && (we == 1'b1) && (re1 == 1'b1)) begin
            rdata1 <= wdata; // for RAW consideration in one cycle
        end else if(re1 == 1'b1) begin
            rdata1 <= regs[raddr1];
        end else begin
            rdata1 <= 1'b0;
        end
    end

    always @ (*) begin
        if(rst == `RstEnable) begin
            rdata2 <= 1'b0;
        end else if(raddr2 == 32'h0) begin
            rdata2 <= 1'b0;
        end else if((raddr2 == waddr) && (we == 1'b1) && (re2 == 1'b1)) begin
            rdata2 <= wdata;
        end else if(re2 == 1'b1) begin
            rdata2 <= regs[raddr2];
        end else begin
            rdata2 <= 1'b0;
        end
    end

endmodule
