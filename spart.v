//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:   
// Design Name: 
// Module Name:    spart 
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
module spart(
    input clk,
    input rst,
    input iocs,
    input iorw,
    output rda,
    output tbr,
    input [1:0] ioaddr,
    inout [7:0] databus,
    output txd,
    input rxd
    );

    localparam RESET = 3'b000;
    localparam TRANSMIT = 3'b001;
    localparam RECEIVE = 3'b010;
    localparam IDLE = 3'b011;
    localparam CON = 3'b100;
    localparam DB = 3'b101;
    logic [2:0] state, nxt_state;
    logic [2:0] transmit_counter, receive_counter;
    logic [8:0] transmit_data, receive_data;
    logic [7:0] r_data, status;
    logic capture, transmit_enable, receive_enable, sample_enable, proc_rec;
    logic [15:0] divisor, baud_counter;



    assign databus = proc_rec ? r_data : databus;


    ///////// baud rate gen ////////////

    always_ff @(posedge clk, negedge rst) begin
        if(~rst) begin
            baud_counter <= divisor;
            baud_enable <= 1'b0;
        end
        else if(baud_counter == 0) begin
            baud_counter <= divisor;
            baud_enable <= 1'b1;
        end
        else begin //maybe enable
            baud_counter <= baud_counter - 1;
            baud_enable <= 0;
        end
    end


    //////// Transmit ///////////

    always_ff @(posedge clk, negedge rst) begin
        if(~rst) begin
            transmit_data <= {transmit_data, 1'b0};
        end
        else if(capture) begin
            transmit_counter <= '0;
            transmit_data <= {databus, 1'b0};
        end
        else if(baud_enable && transmit_enable) begin
            txd <= transmit_data[0]
            transmit_data <= {1'b1, transmit_data[8:1]};
            transmit_counter <= transmit_counter + 1;
        end
    end


    ////////////// receive //////////////

    always_ff @(posedge clk, negedge rst) begin
        if(~rst) begin
            
        end
        else if(~rxd && ~sample_enable) begin
            sample_enable <= 1'b1;
            receive_data <= '0;
            receive_counter <= '0;
        end
        else if(baud_enable && sample_enable) begin
            receive_data <= {receive_data[7:0], rxd};
            receive_counter <= receive_counter + 1;
            if(receive_counter == 9) begin
                sample_enable <= '0;
                rda <= 1'b1;
                r_data <= receive_data[8:1];
            end
        end
    end


    ///////// State Machine //////

    always @ (posedge clk)
	if (!rst)
		state <= RESET;
	else
		state <= nxt_state;

    always @(*) begin
	    nxt_state = state;
        divisor = '0;
        transmit_enable = 1'b0;
        nxt_state = IDLE;
        proc_rec = 1'b0;
	    case(state)
	    	RESET : begin
	    		divisor = '0;
                transmit_enable = 1'b0;
                nxt_state = IDLE;
                proc_rec = 1'b0;
	    	end
            IDLE : begin
                if(~iorw && iocs && ioaddr==2'b00) begin
                    capture = 1'b1;
                    tbr = 1'b0;
                    nxt_state = TRANSMIT;
                end
                else if(iorw && iocs && ioaddr==2'b00) begin
                    nxt_state = RECEIVE;
                end
                else if(iorw && iocs && ioaddr==2'b01) begin
                    nxt_state = CON;
                end
                else if(~iorw && iocs && (ioaddr==2'b11 || ioaddr==2'b10)) begin
                    nxt_state = DB;
                end
            end
	    	TRANSMIT : begin
                capture = 1'b0;
	    		transmit_enable = 1'b1;
                if(transmit_counter == 10) begin
                    tbr = 1'b1;
                    transmit_enable = 1'b0;
                    nxt_state = IDLE;
                end
	    	end
            RECEIVE : begin
                proc_rec = 1'b1;
                nxt_state = IDLE;
            end
            CON : begin
                status = {6'b0,tbr,rda};
                nxt_state = IDLE;
            end
            DB : begin
                if(ioaddr == 2'b11) begin
                    divisor = {databus,divisor[7:0]};
                end
                else begin
                    divisor = {divisor[15:8],databus};
                end
                nxt_state = IDLE;
            end
	    	default : nxt_state = RESET;
	    endcase
end



endmodule
