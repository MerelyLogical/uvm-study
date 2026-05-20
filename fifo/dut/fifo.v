// Synchronous FWFT FIFO.
//
// Read-data is valid combinatorially whenever `empty` is low; asserting `rd_en`
// consumes the head on the next rising edge of `clk`. Writes asserted while
// `full` is high, or reads asserted while `empty` is high, are silently dropped.
//
// Uses the textbook extra-MSB pointer trick: when wr_ptr == rd_ptr in all bits
// the FIFO is empty; when they match in low bits but differ in the MSB it is
// full.

module fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
) (
    input  wire             clk,
    input  wire             rst_n,

    input  wire             wr_en,
    input  wire [WIDTH-1:0] wr_data,

    input  wire             rd_en,
    output wire [WIDTH-1:0] rd_data,

    output wire             full,
    output wire             empty
);

    localparam AW = $clog2(DEPTH);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [AW:0]      wr_ptr;
    reg [AW:0]      rd_ptr;

    wire do_wr = wr_en && !full;
    wire do_rd = rd_en && !empty;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= {(AW+1){1'b0}};
            rd_ptr <= {(AW+1){1'b0}};
        end else begin
            if (do_wr) begin
                mem[wr_ptr[AW-1:0]] <= wr_data;
                wr_ptr <= wr_ptr + 1'b1;
            end
            if (do_rd) begin
                rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end

    assign rd_data = mem[rd_ptr[AW-1:0]];
    assign empty   = (wr_ptr == rd_ptr);
    assign full    = (wr_ptr[AW] != rd_ptr[AW]) &&
                     (wr_ptr[AW-1:0] == rd_ptr[AW-1:0]);

endmodule
