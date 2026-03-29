module fir_parallel #(
  parameter int SAMPLE_W = 16,
  parameter int COEFF_W  = 16,
  parameter int TAPS     = 16,
  parameter int ACC_W    = 48
)(
  input  logic                         clk,
  input  logic                         rst_n,

  // streaming in
  input  logic                         in_valid,
  output logic                         in_ready,
  input  logic signed [SAMPLE_W-1:0]   in_sample,

  // coeff load
  input  logic                         coeff_we,
  input  logic [$clog2(TAPS)-1:0]      coeff_addr,
  input  logic signed [COEFF_W-1:0]    coeff_data,

  // control
  input  logic                         bypass_fir,

  // streaming out
  output logic                         out_valid,
  input  logic                         out_ready,
  output logic signed [SAMPLE_W-1:0]   out_sample
);
  // Backpressure: 1-stage output register
  assign in_ready = out_ready || !out_valid;

  logic signed [SAMPLE_W-1:0] x [0:TAPS-1];
  logic signed [COEFF_W-1:0]  h [0:TAPS-1];

  // coefficient write
  integer i;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (i = 0; i < TAPS; i++) begin
        h[i] <= '0;
      end
    end else if (coeff_we) begin
      h[coeff_addr] <= coeff_data;
    end
  end

  // delay line shift on accepted input
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (i = 0; i < TAPS; i++) begin
        x[i] <= '0;
      end
    end else if (in_valid && in_ready) begin
      x[0] <= in_sample;
      for (i = 1; i < TAPS; i++) begin
        x[i] <= x[i-1];
      end
    end
  end

  // combinational FIR sum for current delay line contents
  logic signed [ACC_W-1:0] acc;
  logic signed [ACC_W-1:0] prod [0:TAPS-1];

  always_comb begin
    for (int k = 0; k < TAPS; k++) begin
      prod[k] = $signed(x[k]) * $signed(h[k]); // Q1.15 * Q1.15 => Q2.30
    end

    acc = '0;
    for (int k = 0; k < TAPS; k++) begin
      acc += prod[k];
    end
  end

  logic signed [SAMPLE_W-1:0] fir_sat;

  fxp_saturate_round #(
    .IN_W(ACC_W),
    .OUT_W(SAMPLE_W),
    .SHIFT(15) // back to Q1.15
  ) u_sat (
    .in_val(acc),
    .out_val(fir_sat)
  );

  // output register
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out_valid  <= 1'b0;
      out_sample <= '0;
    end else begin
      if (in_ready) begin
        out_valid <= in_valid;
        if (in_valid) begin
          out_sample <= bypass_fir ? in_sample : fir_sat;
        end
      end
    end
  end
endmodule