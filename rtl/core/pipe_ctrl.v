
module pipe_ctrl(
  input  wire                  rst,
  input  wire                  stall_req_if,
  input  wire                  stall_req_id,
  input  wire                  stall_req_ex,
  input  wire                  stall_req_mem,
  input  wire [`RegWidth-1:0]  cp0_epc,
  input  wire [`RegWidth-1:0]  except_type,

  output reg  [`RegWidth-1:0]  pc_new,
  output reg                   flush,
  output reg  [5:0]            stall_ctrl       
);

//  stall_ctrl[0] : pc ctrl, "1" stall.
//  stall_ctrl[1] : if stage ctrl , "1" stall.
//  stall_ctrl[2] : id stage ctrl , "1" stall.
//  stall_ctrl[3] : ex stage ctrl , "1" stall.
//  stall_ctrl[4] : ma stage ctrl , "1" stall.
//  stall_ctrl[5] : wb stage ctrl , "1" stall.

  always @ (*) begin
    if(rst == `RstEnable) begin
      stall_ctrl <= 6'b000000;
      flush      <= 1'b0;
      pc_new     <= {`RegWidth{1'b0}};
    end else if(except_type != {`RegWidth{1'b0}})begin
       flush      <= 1'b1;
       stall_ctrl <= 6'b000000;
       case (except_type)
           32'h00000001:
           begin   //interrupt
               pc_new <= 32'h00000020;
           end
           32'h00000008:
           begin   //syscall
               pc_new <= 32'h00000040;
           end
           32'h0000000a:
           begin   //inst_invalid
               pc_new <= 32'h00000040;
           end
           32'h0000000d:
           begin   //trap
               pc_new <= 32'h00000040;
           end
           32'h0000000c:
           begin   //ov
               pc_new <= 32'h00000040;
           end
           32'h0000000e:
           begin   //eret
               pc_new <= cp0_epc;
           end
           default : begin
           end
       endcase
    end else if(stall_req_mem== 1'b1) begin
      stall_ctrl <= 6'b011111; // stall "pc" "if" "id" "ex" "mem"
      flush      <= 1'b0;
      pc_new     <= {`RegWidth{1'b0}};
    end else if(stall_req_ex == 1'b1) begin
      stall_ctrl <= 6'b001111; // stall "pc" "if" "id" "ex"
      flush      <= 1'b0;
      pc_new     <= {`RegWidth{1'b0}};
    end else if(stall_req_id == 1'b1) begin
      stall_ctrl <= 6'b000111; // stall "pc" "if" "id" 
      flush      <= 1'b0;
      pc_new     <= {`RegWidth{1'b0}};
    end else if(stall_req_if == 1'b1) begin

      stall_ctrl <= 6'b000111; // stall "pc" "if" "id" 
      // stall id stage for special: jump or branch instruction
      // make sure the relatively position of branch inst and the delayslot inst
      flush      <= 1'b0;
      pc_new     <= {`RegWidth{1'b0}};
    end else begin
      stall_ctrl <= 6'b000000;
      flush      <= 1'b0;
      pc_new     <= {`RegWidth{1'b0}};
    end    //if
  end      //always
            
endmodule
