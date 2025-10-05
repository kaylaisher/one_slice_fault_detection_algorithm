`timescale 1ns/1ps

module mac_slice (
    input clk,
    input  [255:0]  in_array,          // 256 x 1-bit
    input  [1023:0] weight_array,      // 256 x 4-bit, flattened
    output [1023:0] product_array      // 256 x 4-bit, flattened
);
    genvar i;
    generate
        for (i = 0; i < 256; i = i + 1) begin : mac_gen
            assign product_array[4*i +: 4] = in_array[i] ? weight_array[4*i +: 4] : 4'b0000;
        end
    endgenerate
    
  
    

endmodule
