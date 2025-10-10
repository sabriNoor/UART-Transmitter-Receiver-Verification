module Rx #(
    parameter Data_Width = 8,
    parameter OverSampling = 16
) 
(
    input  logic clk,
    input  logic reset,
    input  logic rx,               // serial input line
    input  logic parity_en,
    input  logic parity_type,      // 0 even, 1 odd
    output logic [Data_Width-1:0] data_out,
    output logic rx_valid,
    output logic parity_error,
);

    localparam Counter_Width = $clog2(OverSampling);
    logic [Counter_Width-1:0] clk_count;
    logic parity_bit;
    logic actual_parity_bit;

    logic [Data_Width-1:0] shift_reg;
    localparam Index_Width = $clog2(Data_Width+1);
    logic [Index_Width-1:0] bit_index;

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

    // Bit index and shift register
    always @(posedge clk or negedge reset) begin
        if(!reset) begin
            bit_index <= 0;
            shift_reg <= 0;
            parity_bit<=0;
        end
        else if(current_state == IDLE) begin
            bit_index <= 0;
            shift_reg <= 0; 
            parity_bit<=0;
        end
        else if((current_state == DATA) && (clk_count == ((OverSampling/2) - 1))) begin
            shift_reg <= shift_reg>>1 | rx<<(Data_Width-1);
            bit_index <= bit_index + 1;
            // eg: if Data_Width=8, Data_Transmitted= 1001_1100 LSB first so
            // first bit comes in is 0, so shift_reg=0000_0000 | 0<<7 = 0000_0000
            // second bit comes in is 0, so shift_reg=0000_0000 | 0<<7 = 0000_0000
            // third bit comes in is 1, so shift_reg=0000_0000 | 1<<7 = 1000_0000
            // fourth bit comes in is 1, so shift_reg=0100_0000 | 1<<7 = 1100_0000
            // fifth bit comes in is 1, so shift_reg=0110_0000 | 1<<7 = 1110_0000
            // sixth bit comes in is 0, so shift_reg=0111_0000 | 0<<7 = 0111_0000
            // seventh bit comes in is 0, so shift_reg=0011_1000 | 0<<7 = 0011_1000
            // eighth bit comes in is 1, so shift_reg=1001_1100 | 1<<7 = 1001_1100
        end
        else if((current_state == PARITY) && (clk_count == ((OverSampling/2) - 1))) begin
            parity_bit<=rx;
        end
      
    end

    // FSM
    always_comb begin
        case(current_state)
        IDLE: begin
            if(rx==0) begin
                next_state = START;
            end
            else begin
                next_state = IDLE;
            end
        end
        START: begin
            if(clk_count == (OverSampling/2)-1) begin
                if(rx==0) begin
                    next_state = DATA;
                end
                else begin
                    next_state = IDLE;
                end
            end       
        end
        DATA: begin
            if(clk_count==(OverSampling - 1)) begin
                if(bit_index == Data_Width-1) begin
                    if(parity_en) begin
                        next_state = PARITY;
                    end
                    else begin
                        next_state = STOP;
                    end
                end
                else begin
                    next_state = DATA;
                end
            end
                   
        end
        PARITY: begin
            if(clk_count==(OverSampling - 1)) begin
                next_state = STOP;
            end
        end
        STOP: begin
            if(clk_count==(OverSampling - 1)) begin
                next_state = DONE;
            end
        end
        DONE: begin
            next_state = IDLE;
        end
        endcase
    end

    // output logic
    always_comb begin
        if(reset==0) begin
            rx_valid=0;
            parity_error=0;
            data_out=0;
        end
        else begin
            case(current_state) 
                DONE: begin
                    rx_valid=1;
                    data_out=shift_reg;
                    if(parity_en) begin
                        actual_parity_bit = parity_type == 0 ? ~^shift_reg  : ^shift_reg; 
                        parity_error= actual_parity_bit!=parity_bit? 1 : 0;
                    end
                end
                default: begin
                    rx_valid=0;
                    parity_error=0;
                end
            endcase
        end
      
    end

endmodule