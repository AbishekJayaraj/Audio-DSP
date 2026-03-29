module fir_filter #(
    parameter N = 8,
    parameter DATA_WIDTH = 16
)(
    input wire clk,
    input wire rst,
    input wire signed [DATA_WIDTH-1:0] x_in,
    input wire valid_in,

    output reg signed [DATA_WIDTH-1:0] y_out,
    output reg valid_out
);

    // Shift register
    reg signed [DATA_WIDTH-1:0] shift_reg [0:N-1];

    // Coefficients (constant)
    reg signed [DATA_WIDTH-1:0] coeff [0:N-1];

    integer i;

    // Initialize coefficients (low-pass type)
    initial begin
        coeff[0] = 16'd1;
        coeff[1] = 16'd2;
        coeff[2] = 16'd3;
        coeff[3] = 16'd4;
        coeff[4] = 16'd4;
        coeff[5] = 16'd3;
        coeff[6] = 16'd2;
        coeff[7] = 16'd1;
    end

    reg signed [2*DATA_WIDTH-1:0] acc;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1)
                shift_reg[i] <= 0;

            y_out <= 0;
            valid_out <= 0;
        end else begin
            if (valid_in) begin
                // Shift operation
                for (i = N-1; i > 0; i = i - 1)
                    shift_reg[i] <= shift_reg[i-1];

                shift_reg[0] <= x_in;

                // MAC (Multiply-Accumulate)
                acc = 0;
                for (i = 0; i < N; i = i + 1)
                    acc = acc + shift_reg[i] * coeff[i];

                // Scale down (avoid overflow)
                y_out <= acc >>> 4;

                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule