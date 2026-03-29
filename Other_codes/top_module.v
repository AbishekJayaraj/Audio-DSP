module audio_dsp_top (
    input wire clk,
    input wire rst,
    input wire signed [15:0] audio_in,
    input wire valid_in,
    input wire [1:0] gain_sel,

    output wire signed [15:0] audio_out,
    output wire valid_out
);

    wire signed [15:0] fir_out;
    wire fir_valid;

    // FIR Filter Instance
    fir_filter fir_inst (
        .clk(clk),
        .rst(rst),
        .x_in(audio_in),
        .valid_in(valid_in),
        .y_out(fir_out),
        .valid_out(fir_valid)
    );

    // Gain Control Instance
    gain_control gain_inst (
        .clk(clk),
        .rst(rst),
        .x_in(fir_out),
        .gain_sel(gain_sel),
        .valid_in(fir_valid),
        .y_out(audio_out),
        .valid_out(valid_out)
    );

endmodule