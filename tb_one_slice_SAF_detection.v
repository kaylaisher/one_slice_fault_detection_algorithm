`timescale 1ns / 10ps

module tb_one_slice_SAF_detection;

  // Clock
  reg clk = 0;
  always #10 clk = ~clk;

  // DUT I/O
  reg  [255:0]  in_array;
  reg  [1023:0] weight_array;
  wire [1023:0] product_array;
  
  reg [255:0] sa0_cells;
  reg [255:0] sa1_cells;
  
  reg           fault;
  
  initial begin
    fault = 1'b0;
  end

  mac_slice_faulty dut (
    .clk          (clk),
    .in_array     (in_array),
    .weight_array (weight_array),
    .sa0_cells(sa0_cells),
    .sa1_cells(sa1_cells),
    .product_array(product_array)
  );

  initial begin
    weight_array = {1024{1'b1}};
    in_array     = {256{1'b0}}; // M0: w0 (all zeros)
    sa0_cells    = 256'b0;
    sa1_cells    = 256'b0;
    fault        = 1'b0;

// EXAMPLE STUCK AT FAULTS
    sa0_cells[7] = 1'b1;
    sa1_cells[42] = 1'b1;
    sa0_cells[123] = 1'b1;
    sa1_cells[200] = 1'b1;
    
  end

  // -------------------------
  // MATS FSM: { w0 ; ↑(r0,w1) ; ↓(r1) }
  // -------------------------
  localparam S_M0_W0     = 3'd0;
  localparam S_M1_READ0  = 3'd1;
  localparam S_M1_WRITE1 = 3'd2;
  localparam S_M1_NEXT   = 3'd3;
  localparam S_M2_READ1  = 3'd4;
  localparam S_M2_NEXT   = 3'd5;
  localparam S_DONE      = 3'd6;
  
  reg [2:0]   state;
  reg [8:0]   idx;
  //reg [255:0] mask, mask_next;
  reg [255:0]   mask;
  
  initial begin
    state     = S_M0_W0;
    idx       = 9'd0;
    mask      = 256'b0;
    //mask_next = 256'b0;
  end
  
  always @(posedge clk) begin
    fault <= 1'b0;
  
    case(state)
        
        S_M0_W0: begin
            mask      <= 256'b0;
            idx       <= 9'd0;
            state     <= S_M1_READ0;
        end
        
        // up r0 
        S_M1_READ0: begin
            if (product_array[4*idx +: 4] !== 4'd0) begin
                fault <= 1'b1;
                $display("[%0t] M1 r0 FAIL @addr=%0d : got=%0d exp=0", $time, idx, product_array[4*idx +: 4]);
            end
            state <= S_M1_WRITE1;
        end
        
        // up w1
        S_M1_WRITE1: begin
            mask[idx] <= 1'b1;
            in_array  <= mask | (256'h1 << idx);
            state     <= S_M1_NEXT;
        end
        
        // up next address
        S_M1_NEXT: begin
            if (idx == 9'd255) begin
                state <= S_M2_READ1;
            end
            else begin
                idx   <= idx + 9'd1;
                state <= S_M1_READ0;
            end
        end
    
        //down r1
        S_M2_READ1: begin
            if (product_array[4*idx +: 4] !== 4'd15) begin
                fault  <= 1'b1;
                $display("[%0t] M2 r1 FAIL @addr=%0d : got=%0d exp=15", $time, idx, product_array[4*idx +: 4]);
            end
            state <= S_M2_NEXT;
        end
        
        // down next address
        S_M2_NEXT: begin
            if (idx == 9'd0) begin
                state <= S_DONE;
            end
            else begin
                idx   <= idx - 9'd1;
                state <= S_M2_READ1;
            end
        end
        S_DONE: begin
            if (!fault) $display("[%0t] MATS PASSED", $time);
            else         $display("[%0t] MATS COMPLETED with faults", $time);
            $finish;
        end
        
         default: state <= state;
    
    endcase
  end
 

endmodule
