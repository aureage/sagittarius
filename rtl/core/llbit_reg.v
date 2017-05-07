module llbit_reg(

    input wire                    clk,
    input wire                    rst,
    
    input wire                    we,
    input wire                    flush,  // exception flag "1" valid
    input wire                    llbit_i,
    
    output reg                    llbit_o
);

    always @ (posedge clk)
    begin
        if (rst == 1'b1)
        begin
            llbit_o <= 1'b0;
        end
        else if((flush == 1'b1)) // if exception occured set llbit "0"
        begin
            llbit_o <= 1'b0;
        end
        else if((we == 1'b1))
        begin
            llbit_o <= llbit_i;
        end
    end

endmodule
