module gain_control #(
    parameter DATA_WIDTH = 16
)(
    input wire clk,
    input wire rst,
    input wire signed [DATA_WIDTH-1:0] x_in,
    input wire [1:0] gain_sel,   // 00=0.5x, 01=1x, 10=2x
    input wire valid_in,

    output reg signed [DATA_WIDTH-1:0] y_out,
    output reg valid_out
);

    always @(posedge clk) begin
        if (rst) begin
            y_out <= 0;
            valid_out <= 0;
        end else begin
            if (valid_in) begin
                case (gain_sel)
                    2'b00: y_out <= x_in >>> 1; // 0.5x
                    2'b01: y_out <= x_in;       // 1x
                    2'b10: y_out <= x_in <<< 1; // 2x
                    default: y_out <= x_in;
                endcase
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end

endmodule