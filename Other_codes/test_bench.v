`timescale 1ns/1ps

module tb_audio_dsp;

    reg clk;
    reg rst;
    reg signed [15:0] audio_in;
    reg valid_in;
    reg [1:0] gain_sel;

    wire signed [15:0] audio_out;
    wire valid_out;

    // Instantiate DUT (Device Under Test)
    audio_dsp_top uut (
        .clk(clk),
        .rst(rst),
        .audio_in(audio_in),
        .valid_in(valid_in),
        .gain_sel(gain_sel),
        .audio_out(audio_out),
        .valid_out(valid_out)
    );

    // Clock generation (10ns period)
    always #5 clk = ~clk;

    integer i;

    initial begin
        // Initialize
        clk = 0;
        rst = 1;
        valid_in = 0;
        audio_in = 0;
        gain_sel = 2'b01; // 1x gain

        // Reset
        #20;
        rst = 0;

        // Start sending samples
        valid_in = 1;

        // Simulated audio input (ramp signal)
        for (i = 0; i < 20; i = i + 1) begin
            audio_in = i * 100;
            #10;
        end

        // Change gain (test feature)
        gain_sel = 2'b10; // 2x gain

        for (i = 0; i < 20; i = i + 1) begin
            audio_in = i * 50;
            #10;
        end

        // Stop
        valid_in = 0;
        #50;

        $stop;
    end

endmodule