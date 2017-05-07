

module inst_rom(

//    input    wire                                        clk,
    input wire                          ce,
    input wire[`InstBusAddrWidth-1:0]   addr,
    output reg[`InstBusDataWidth-1:0]   inst
    
);

    reg[`InstBusDataWidth-1:0]  inst_mem[0:`InstMemNum-1];

    initial $readmemh ( "test_case.pat", inst_mem );

    always @ (*) begin
        if (ce == 1'b0) begin
            inst <= 1'b0;
      end else begin
          inst <= inst_mem[addr[`InstMemNumLog2+1:2]];
        end
    end

endmodule
