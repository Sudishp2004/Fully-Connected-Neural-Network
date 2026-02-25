`timescale 1ns/1ps

module tb_top_fc;

    reg clk = 0;
    reg rst = 1;
    reg start = 0;
    reg signed [784*16-1:0] in_data;
    wire signed [10*16-1:0] final_out;
    wire done;

    top_fc dut (
        .clk(clk), .rst(rst), .start(start),
        .in_data(in_data), .final_out(final_out), .done(done)
    );

    always #5 clk = ~clk;

    integer i;
    reg signed [15:0] img_mem [0:783];
    integer max_idx;
    reg signed [15:0] val;
    reg signed [15:0] max_val;

    initial begin
        // Load test digit
        $readmemh("test_digit.mem", img_mem);

        // Flatten into in_data
        for (i = 0; i < 784; i = i + 1)
            in_data[i*16 +: 16] = img_mem[i];

        // Reset sequence
        #20 rst = 0;
        #10 start = 1;
        #10 start = 0;

        // Wait for completion
        wait(done);

        // Argmax
        max_val = -32768;
        max_idx = 0;
        for (i = 0; i < 10; i = i + 1) begin
            val = final_out[i*16 +: 16];
            if (val > max_val) begin
                max_val = val;
                max_idx = i;
            end
        end

        $display("Predicted digit: %0d", max_idx);
        #20 $finish;
    end
endmodule
