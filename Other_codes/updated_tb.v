`timescale 1ns/1ps

module tb_audio_dsp;

    // Inputs
    reg clk;
    reg rst;
    reg signed [15:0] audio_in;
    reg valid_in;
    reg [1:0] gain_sel;

    // Outputs
    wire signed [15:0] audio_out;
    wire valid_out;

    // File handling
    integer file_in, file_out;
    integer r;

    // Instantiate DUT
    audio_dsp_top uut (
        .clk(clk),
        .rst(rst),
        .audio_in(audio_in),
        .valid_in(valid_in),
        .gain_sel(gain_sel),
        .audio_out(audio_out),
        .valid_out(valid_out)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        valid_in = 0;
        audio_in = 0;
        gain_sel = 2'b01; // 1x gain

        // Open files
        file_in  = $fopen("audio_samples.txt", "r");
        file_out = $fopen("output_samples.txt", "w");

        if (file_in == 0) begin
            $display("ERROR: Cannot open audio_samples.txt");
            $finish;
        end

        // Reset
        #20;
        rst = 0;
        valid_in = 1;

        // Read samples
        while (!$feof(file_in)) begin
            r = $fscanf(file_in, "%d\n", audio_in);
            #10;

            if (valid_out) begin
                $fwrite(file_out, "%d\n", audio_out);
            end
        end

        // Stop streaming
        valid_in = 0;

        // Close files
        $fclose(file_in);
        $fclose(file_out);

        #50;
        $stop;
    end

endmodule