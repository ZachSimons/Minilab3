//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:  
// 
// Create Date:    
// Design Name: 
// Module Name:    driver 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module driver(
    input clk,
    input rst,
    input [1:0] br_cfg,
    output logic iocs,
    output logic iorw,
    input logic rda,
    input logic tbr,
    output logic [1:0] ioaddr,
    inout [7:0] databus
    );

    localparam RESET = 3'b000;
    localparam IDLE = 3'b001;
    localparam TRANSMIT = 3'b010;
    localparam RECEIVE = 3'b011;


    logic [2:0] next_state, state;
    logic [7:0] config_data_low, config_data_high, transmit_data, recieved_data;

    logic rst_done, db_select_low, db_select_high, data_ready, transmit_select;

    assign databus =    (db_select_low) ? config_data_low : 
                        (db_select_high ? config_data_high :
                        (transmit_select ? recieved_data : 8'bz));
    
    // CONFIG           Baud Rate       Divisor (HEX) SYS_Clock / Baud Rate
    // br_cfg = 00      4800            0x28B1
    // br_cfg = 01      9600            0x1458
    // br_cfg  = 10     19200           0x0A2C
    // br_cfg = 11      38400           0x0516

    //State Machine
    always @ (posedge clk or negedge rst) begin
        if(!rst) begin
            state <= RESET;
        end
        else begin
            state <= next_state;
        end
    end

    //DB write
    always_ff @(posedge clk or negedge rst) begin
        if(!rst) begin
            rst_done <= 1'b0;
        end
        else if(state == RESET && ~rst_done) begin
            rst_done <= 1'b1;
        end
        else if(rst_done) begin
            rst_done <= 1'b0;
        end
    end

    always @(*) begin
        next_state = IDLE;
        iocs = 1'b1;
        iorw = 1'b1;
        db_select_low = 1'b0;
        db_select_high = 1'b0;
        transmit_select = 1'b0;
        ioaddr = 2'b00;

        case (state)
            RESET : begin
                if(~rst_done) begin
                    db_select_low = 1'b1;
                    ioaddr = 2'b10;
                    if(br_cfg == 2'b00) begin
                        config_data_low = 8'hB1;
                    end
                    else if(br_cfg == 2'b01) begin
                        config_data_low = 8'h58;
                    end
                    else if(br_cfg == 2'b10) begin
                        config_data_low = 8'h2C;
                    end
                    else if(br_cfg == 2'b11) begin
                        config_data_low = 8'h16;
                    end
                    iorw = 1'b0;
                    next_state = RESET;
                end
                else begin
                    ioaddr = 2'b11;
                    db_select_high = 1'b1;
                    if(br_cfg == 2'b00) begin
                        config_data_high = 8'h28;
                    end
                    else if(br_cfg == 2'b01) begin
                        config_data_high = 8'h14;
                    end
                    else if(br_cfg == 2'b10) begin
                        config_data_high = 8'h0A;
                    end
                    else if(br_cfg == 2'b11) begin
                        config_data_high = 8'h05;
                    end
                    iorw = 1'b0;
                    next_state = IDLE;
                end
            end
            IDLE : begin
                /*
                if(data_ready) begin
                    next_state = TRANSMIT;
                end
                */
                if(rda) begin
                    next_state = RECEIVE;
                end
            end
            TRANSMIT : begin
                iorw = 1'b0;
                ioaddr = 2'b00;
                data_ready = 1'b0;
                transmit_select = 1'b1;
                next_state = IDLE;
            end
            RECEIVE : begin
                iorw = 1'b1;
                ioaddr = 2'b00;
                recieved_data = databus;
                data_ready = 1'b1;
                next_state = TRANSMIT;
            end
        endcase
    end


endmodule
