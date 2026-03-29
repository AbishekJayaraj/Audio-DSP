module audio_dsp_top #(
  parameter int SAMPLE_W = 16,
  parameter int TAPS     = 16
)(
  input  logic                       clk,
  input  logic                       rst_n,

  // stream in
  input  logic                       in_valid,
  output logic                       in_ready,
  input  logic signed [SAMPLE_W-1:0] in_sample,

  // control
  input  logic signed [15:0]         gain_q15,
  input  logic                       bypass_gain,
  input  logic                       bypass_fir,

  // coeff load
  input  logic                       coeff_we,
  input  logic [$clog2(TAPS)-1:0]    coeff_addr,
  input  logic signed [15:0]         coeff_data,

  // stream out
  output logic                       out_valid,
  input  logic                       out_ready,
  output logic signed [SAMPLE_W-1:0] out_sample
);
  logic                       v1_valid, v1_ready;
  logic signed [SAMPLE_W-1:0] v1_sample;

  gain_block #(
    .SAMPLE_W(SAMPLE_W),
    .GAIN_W(16),
    .ACC_W(40)
  ) u_gain (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .in_ready(in_ready),
    .in_sample(in_sample),
    .gain_q15(gain_q15),
    .bypass_gain(bypass_gain),
    .out_valid(v1_valid),
    .out_ready(v1_ready),
    .out_sample(v1_sample)
  );

  fir_parallel #(
    .SAMPLE_W(SAMPLE_W),
    .COEFF_W(16),
    .TAPS(TAPS),
    .ACC_W(48)
  ) u_fir (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(v1_valid),
    .in_ready(v1_ready),
    .in_sample(v1_sample),
    .coeff_we(coeff_we),
    .coeff_addr(coeff_addr),
    .coeff_data(coeff_data),
    .bypass_fir(bypass_fir),
    .out_valid(out_valid),
    .out_ready(out_ready),
    .out_sample(out_sample)
  );

endmodule