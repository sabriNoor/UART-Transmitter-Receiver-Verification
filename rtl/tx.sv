module Tx_Path(
    input logic clk, reset,
    input logic [Data_Width-1:0] data_in,
    input logic tx_valid,
    output logic tx_ready,
    output logic tx,
    input logic parity_en,
    input logic parity_type  // 0 even, 1 odd
);

    parameter Data_Width = 8;
    parameter OverSampling = 16;

    localparam Counter_Width = $clog2(OverSampling);
    logic [Counter_Width-1:0] clk_count;
    localparam Index_Width = $clog2(Data_Width+1);
    logic [Index_Width-1:0] bit_index;

    logic [Data_Width-1:0] shift_reg;
    logic [Data_Width-1:0] data_reg;

    typedef enum logic [2:0] {
        IDLE, 
        START, 
        DATA,
        PARITY,
        STOP,
        DONE
    } state_t;

    state_t current_state, next_state;

    // State register
    always @(posedge clk or negedge reset) begin
        if(!reset) begin
            current_state <= IDLE;
        end 
        else begin
            current_state <= next_state;
        end
    end

    // Clock counter
    always @(posedge clk or negedge reset) begin
        if(!reset) begin
            clk_count <= 0;
        end
        else if(current_state == IDLE) begin
            clk_count <= 0;
        end
        else if(clk_count == (OverSampling - 1)) begin
            clk_count <= 0;
        end
        else begin
            clk_count <= clk_count + 1;
        end       
    end

    
    always @(posedge clk or negedge reset) begin
        if(!reset) begin
            bit_index <= 0;
            data_reg <= 0;
            shift_reg <= 0;
        end
        else if(current_state == IDLE) begin
            bit_index <= 0;
            if(tx_valid) begin
                data_reg <= data_in;
                shift_reg <= data_in;
            end
        end
        else if((current_state == DATA) && (clk_count == (OverSampling - 1))) begin
            bit_index <= bit_index + 1;
            shift_reg <= shift_reg >> 1;
        end
      
    end

    // FSM and output logic
    always_comb begin
        next_state = current_state;
        tx_ready = 0;
        tx = 1; // Default to idle state
        
        case(current_state)
            IDLE: begin
                tx_ready = 1;
                tx = 1; // idle state
                if(tx_valid) begin
                    next_state = START;
                end
            end
            START: begin
                tx = 0; // start bit
                if(clk_count == (OverSampling - 1)) begin
                    next_state = DATA;
                end
            end
            DATA: begin
                tx = shift_reg[0]; // LSB first
                if((clk_count == (OverSampling - 1))) begin
                    if(bit_index == Data_Width - 1) begin
                        next_state = PARITY;
                    end
                end
            end
            PARITY: begin
               tx = parity_type == 0 ? ~^data_reg  : ^data_reg; 
                if(clk_count == (OverSampling - 1)) begin
                    next_state = DATA;
                end
            end
            STOP: begin
                tx = 1; // stop bit
                if(clk_count == (OverSampling - 1)) begin
                    next_state = DONE;
                end
            end
            DONE: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

endmodule