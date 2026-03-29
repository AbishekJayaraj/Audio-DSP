module tb_audio_dsp;
  localparam int SAMPLE_W = 16;
  localparam int TAPS     = 16;

  logic clk, rst_n;

  logic in_valid;
  logic in_ready;
  logic signed [SAMPLE_W-1:0] in_sample;

  logic signed [15:0] gain_q15;
  logic bypass_gain, bypass_fir;

  logic coeff_we;
  logic [$clog2(TAPS)-1:0] coeff_addr;
  logic signed [15:0] coeff_data;

  logic out_valid;
  logic out_ready;
  logic signed [SAMPLE_W-1:0] out_sample;

  audio_dsp_top #(
    .SAMPLE_W(SAMPLE_W),
    .TAPS(TAPS)
  ) dut (
    .clk, .rst_n,
    .in_valid, .in_ready, .in_sample,
    .gain_q15, .bypass_gain, .bypass_fir,
    .coeff_we, .coeff_addr, .coeff_data,
    .out_valid, .out_ready, .out_sample
  );

  // clock
  initial clk = 0;
  always #5 clk = ~clk;

  task automatic send_sample(input logic signed [SAMPLE_W-1:0] s);
    begin
      in_valid  <= 1'b1;
      in_sample <= s;
      // wait until accepted
      do @(posedge clk); while (!(in_valid && in_ready));
      in_valid <= 1'b0;
      in_sample <= '0;
    end
  endtask

  initial begin
    // defaults
    rst_n = 0;
    in_valid = 0;
    in_sample = 0;
    out_ready = 1;

    gain_q15 = 16'sh4000; // 0.5 in Q1.15
    bypass_gain = 0;
    bypass_fir  = 0;

    coeff_we = 0;
    coeff_addr = '0;
    coeff_data = '0;

    repeat (5) @(posedge clk);
    rst_n = 1;
    repeat (2) @(posedge clk);

    // Load coefficients: simple moving average h[k] = 1/TAPS
    // 1/16 = 0.0625 -> Q1.15 = 0.0625 * 32768 = 2048 = 0x0800
    for (int k = 0; k < TAPS; k++) begin
      @(posedge clk);
      coeff_we   <= 1'b1;
      coeff_addr <= k[$clog2(TAPS)-1:0];
      coeff_data <= 16'sh0800;
    end
    @(posedge clk);
    coeff_we <= 1'b0;

    // Send a step + some alternating noise to see smoothing
    for (int n = 0; n < 10; n++) begin
      send_sample(16'sh0000);
    end

    for (int n = 0; n < 50; n++) begin
      // step to ~0.8 plus small alternating component
      logic signed [15:0] base = 16'sh6666; // ~0.8
      logic signed [15:0] noise = (n[0] ? 16'sh0400 : -16'sh0400);
      send_sample(base + noise);
    end

    // Change gain to 1.0 (0x7FFF approx)
    @(posedge clk);
    gain_q15 <= 16'sh7FFF;

    for (int n = 0; n < 30; n++) begin
      send_sample(16'sh2000); // small tone-ish constant
    end

    repeat (20) @(posedge clk);
    $finish;
  end

endmodule