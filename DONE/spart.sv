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
    output logic rda,
    output logic tbr,
    input [1:0] ioaddr,
    inout [7:0] databus,
    output logic txd,
    input logic rxd
    );

    localparam RESET = 3'b000;
    localparam IDLE = 3'b001;
    localparam TRANSMIT = 3'b010;
    localparam RECEIVE = 3'b011;
    logic [2:0] state, nxt_state;
    logic [3:0] transmit_counter, receive_counter;
    logic [8:0] transmit_data;
    logic [9:0] receive_data;
    logic [7:0] r_data, status;
    logic capture, transmit_enable, receive_enable, sample_enable, 
        proc_rec, baud_enable_rec, baud_enable_tr, new_divisor, read_status;
    logic [15:0] divisor, baud_counter;

    logic rxd_ff, rxd_ff_ff;

    assign databus = proc_rec ? r_data : (read_status ? status : 'z);


    ///////// baud rate gen ////////////

    always_ff @(posedge clk, negedge rst) begin
        if(~rst) begin
            baud_counter <= divisor;
            baud_enable_rec <= 1'b0;
            baud_enable_tr <= 1'b0;
        end
        else if(new_divisor) begin
            baud_counter <= divisor;
        end
        else if(baud_counter == (divisor / 2)) begin
            baud_counter <= baud_counter - 1;
            baud_enable_rec <= 1'b1;
        end
        else if (baud_counter == 0) begin
            baud_enable_tr <= 1'b1;
            baud_counter <= divisor;
        end
        else if (sample_enable | transmit_enable)begin //maybe enable
            baud_counter <= baud_counter - 1;
            baud_enable_rec <= 0;
            baud_enable_tr <= 0;
        end
        else begin
            baud_counter <= divisor;
            baud_enable_rec <= 0;
            baud_enable_tr <= 0;
        end 
    end


    //////// Transmit ///////////

    always_ff @(posedge clk, negedge rst) begin
        if(~rst) begin
            transmit_data <= {transmit_data, 1'b0};
            txd <= 1;
        end
        else if(capture) begin
            transmit_counter <= '0;
            transmit_data <= {databus, 1'b0};
        end
        else if((baud_enable_tr && transmit_enable) | transmit_counter == 0) begin
            txd <= transmit_data[0];
            transmit_data <= {1'b1, transmit_data[8:1]};
            transmit_counter <= transmit_counter + 1;
        end
        else if(transmit_counter == 0) begin
            txd <= 1;
        end
    end

    always_ff @(posedge clk) begin
        rxd_ff <= rxd;
        rxd_ff_ff <= rxd_ff;
    end

    ////////////// receive //////////////

    always_ff @(posedge clk, negedge rst) begin
        if(~rst) begin
            sample_enable <= 0;
            receive_data <= '0;
            receive_counter <= '0;
            rda <= 1'b0;
        end
        else if(~rxd_ff_ff && ~sample_enable) begin
            sample_enable <= 1'b1;
            receive_data <= '0;
            receive_counter <= '0;
        end
        else if(receive_counter == 10 && baud_enable_rec && sample_enable) begin
            receive_counter <= receive_counter + 1;
        end
        else if(receive_counter == 11 && baud_enable_tr && sample_enable) begin
            rda <= 1'b1;
            sample_enable <= 1'b0;
        end
        else if(receive_counter == 9) begin
            receive_data <= {receive_data[7:0], rxd_ff_ff};
            receive_counter <= receive_counter + 1;
            if(receive_counter == 9) begin
                //We want to flip data back to MSB bit first
                r_data[7] <= receive_data[0];
                r_data[6] <= receive_data[1];
                r_data[5] <= receive_data[2];
                r_data[4] <= receive_data[3];
                r_data[3] <= receive_data[4];
                r_data[2] <= receive_data[5];
                r_data[1] <= receive_data[6];
                r_data[0] <= receive_data[7];
            end
        end
        else if(baud_enable_rec && sample_enable) begin
            receive_data <= {receive_data[7:0], rxd};
            receive_counter <= receive_counter + 1;
        end
        else if (proc_rec) begin
            rda <= 1'b0;
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
        transmit_enable = 1'b0;
        nxt_state = IDLE;
        proc_rec = 1'b0;
        new_divisor = 1'b0;
        read_status = 1'b0;
	    case(state)
	    	RESET : begin
                transmit_enable = 1'b0;
                nxt_state = IDLE;
                proc_rec = 1'b0;
                tbr = 1'b1;
					if(~iorw && iocs && (ioaddr==2'b11 || ioaddr==2'b10)) begin
								  if(ioaddr == 2'b11) begin
										divisor = {databus,divisor[7:0]};
										new_divisor = 1;
								  end
								  else begin
										divisor = {divisor[15:8],databus};
										new_divisor = 1;
								  end
							 end
					end
            IDLE : begin
                if(~iorw && iocs && ioaddr==2'b00) begin
                    capture = 1'b1;
                    tbr = 1'b0;
                    nxt_state = TRANSMIT;
                end
                else if(iorw && iocs && ioaddr==2'b00) begin
                    proc_rec = 1'b1;
                end
                else if(iorw && iocs && ioaddr==2'b01) begin
                    status = {6'b0,tbr,rda};
                    read_status = 1;
                    nxt_state = IDLE;
                end
                else if(~iorw && iocs && (ioaddr==2'b11 || ioaddr==2'b10)) begin
                    if(ioaddr == 2'b11) begin
                        divisor = {databus,divisor[7:0]};
                        new_divisor = 1;
                    end
                    else begin
                        divisor = {divisor[15:8],databus};
                        new_divisor = 1;
                    end
                end
            end
	    	TRANSMIT : begin
                capture = 1'b0;
	    		transmit_enable = 1'b1;
                if(transmit_counter == 11) begin
                    tbr = 1'b1;
                    transmit_enable = 1'b0;
                    nxt_state = IDLE;
                end
                else begin
                    nxt_state = TRANSMIT;
                end
	    	end
            RECEIVE : begin
                nxt_state = IDLE;
            end
	    	default : nxt_state = RESET;
	    endcase
end



endmodule
