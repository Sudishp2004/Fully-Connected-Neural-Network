module fc_layer #(
    parameter IN_NEURONS  = 784,
    parameter OUT_NEURONS = 128,
    parameter DATA_W      = 16,
    parameter WEIGHTS_FILE = "weights.mem",
    parameter BIASES_FILE  = "biases.mem"
)(
    input clk,
    input rst,
    input start,
    input signed [IN_NEURONS*DATA_W-1:0] in_data,
    output reg signed [OUT_NEURONS*DATA_W-1:0] out_data,
    output reg done
);

    reg signed [DATA_W*2-1:0] mac_sum [0:OUT_NEURONS-1];
    reg [15:0] in_cnt;

    reg signed [DATA_W-1:0] weights [0:OUT_NEURONS*IN_NEURONS-1];
    reg signed [DATA_W-1:0] biases  [0:OUT_NEURONS-1];

    integer i;

    initial begin
        $readmemh(WEIGHTS_FILE, weights);
        $readmemh(BIASES_FILE, biases);
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            in_cnt <= 0;
            done   <= 0;
            for (i=0; i<OUT_NEURONS; i=i+1) mac_sum[i] <= 0;
        end else if (start && !done) begin
            if (in_cnt == 0) begin
                for (i=0; i<OUT_NEURONS; i=i+1) mac_sum[i] <= biases[i];
            end

            for (i=0; i<OUT_NEURONS; i=i+1) begin
                mac_sum[i] <= mac_sum[i] +
                              ( $signed(in_data[in_cnt*DATA_W +: DATA_W]) *
                                weights[i*IN_NEURONS + in_cnt] >>> 8 );
            end

            if (in_cnt == IN_NEURONS-1) begin
                for (i=0; i<OUT_NEURONS; i=i+1) begin
                    out_data[i*DATA_W +: DATA_W] <=
                        (mac_sum[i][DATA_W*2-1]) ? 0 : (mac_sum[i] >>> 8);
                end
                done <= 1;
            end else begin
                in_cnt <= in_cnt + 1;
            end
        end
    end
endmodule
module top_fc(
    input clk,
    input rst,
    input start,
    input signed [784*16-1:0] in_data,
    output signed [10*16-1:0] final_out,
    output done
);

    wire signed [128*16-1:0] out1;
    wire signed [64*16-1:0]  out2;
    wire signed [10*16-1:0]  out3;
    wire done1, done2, done3;

    fc_layer #(
        .IN_NEURONS(784), .OUT_NEURONS(128), .DATA_W(16),
        .WEIGHTS_FILE("fc1_w.mem"), .BIASES_FILE("fc1_b.mem")
    ) fc1 (
        .clk(clk), .rst(rst), .start(start),
        .in_data(in_data), .out_data(out1), .done(done1)
    );

    fc_layer #(
        .IN_NEURONS(128), .OUT_NEURONS(64), .DATA_W(16),
        .WEIGHTS_FILE("fc2_w.mem"), .BIASES_FILE("fc2_b.mem")
    ) fc2 (
        .clk(clk), .rst(rst), .start(done1),
        .in_data(out1), .out_data(out2), .done(done2)
    );

    fc_layer #(
        .IN_NEURONS(64), .OUT_NEURONS(10), .DATA_W(16),
        .WEIGHTS_FILE("fc3_w.mem"), .BIASES_FILE("fc3_b.mem")
    ) fc3 (
        .clk(clk), .rst(rst), .start(done2),
        .in_data(out2), .out_data(out3), .done(done3)
    );

    assign final_out = out3;
    assign done = done3;

endmodule
