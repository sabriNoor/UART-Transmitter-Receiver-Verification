module FIFO #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input  logic clk,
    input  logic reset,

    input  logic write_en,
    input  logic [WIDTH-1:0] data_in,

    input  logic read_en,
    output logic [WIDTH-1:0] data_out,

    output logic full,
    output logic empty
);

    localparam Ptr_Width=$clog2(DEPTH);
    logic [Ptr_Width-1:0] wr_ptr,rd_ptr;

    logic [WIDTH-1:0] mem [0:DEPTH-1]; 
    localparam Count_Width=$clog2(DEPTH+1);
    logic [Count_Width-1:0] count;

    always @(posedge clk or negedge reset)begin
        if(!reset) begin
            wr_ptr<=0;
            rd_ptr<=0;
            count<=0;
        end
        else begin
            if(write_en && read_en && count!=0 && count != DEPTH) begin
                mem[wr_ptr]<=data_in;
                data_out<=mem[rd_ptr];
                rd_ptr<=(rd_ptr+1) % DEPTH;
                wr_ptr<=(wr_ptr+1)% DEPTH;
            end
            else if(write_en && count!=DEPTH) begin
                mem[wr_ptr]<=data_in;
                wr_ptr<=(wr_ptr+1)% DEPTH;
                count<=count+1;
            end
            else if(read_en && count != 0) begin
                data_out<=mem[rd_ptr];
                rd_ptr<=(rd_ptr+1) % DEPTH;
                count<=count-1;
            end
        end
    end

    assign full = (count==DEPTH) ? 1: 0;
    assign empty = (count==0) ? 1: 0;


endmodule