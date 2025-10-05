`timescale 1ns / 1ps

module mac_slice_faulty #(
    parameter N = 256
)(
    input         clk,
    input  [N-1:0]    in_array,
    input  [4*N-1:0]  weight_array,
    input  [N-1:0]    sa0_cells,
    input  [N-1:0]    sa1_cells,
    output [4*N-1:0]  product_array
    );
    wire [4*N-1:0] product_nom;
    
    mac_slice u_nom (
        .clk(clk),
        .in_array(in_array),
        .weight_array(weight_array),
        .product_array(product_nom)
    );
    
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : g_fault_mux
            wire [3:0] p_nom_i = product_nom[4*i +: 4];
            assign product_array[4*i +: 4] =
                    sa1_cells[i] ? 4'hF :
                    sa0_cells[i] ? 4'h0 :
                                   p_nom_i;
        end
    endgenerate
    
endmodule
