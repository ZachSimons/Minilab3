module spart_tb;

logic clk, rst, iocs, iorw, rda, tbr, txd, rxd, db_select;
logic [1:0] ioaddr;
tri [7:0] databus;
logic [7:0] databus_logic;


spart s1(
    .clk(clk),
    .rst(rst),
    .iocs(iocs),
    .iorw(iorw),
    .rda(rda),
    .tbr(tbr),
    .ioaddr(ioaddr),
    .databus(databus),
    .txd(txd),
    .rxd(rxd)
    );


assign databus = db_select ? databus_logic : 8'bz;

// Clock generation
always begin
    #5 clk = ~clk;  // Clock period of 10 units
end

// Test sequence
initial begin
    // Initialize signals
    clk = 0;
    rst = 0;
    iocs = 0;
    iorw = 0;
    ioaddr = '0;
    db_select = 0;
    rxd = 1;

    // Apply reset
    #10;
    rst = 1;
    #10;
    iocs = 0;

    @(posedge clk)
    iocs = 1;
    iorw = 0;
    ioaddr = 2'b10;
    db_select = 1;
    @(posedge clk)
    databus_logic = 8'b10100010;
    iorw = 0;
    ioaddr = 2'b11;
    @(posedge clk)
    databus_logic = '0;
    @(posedge clk)
    db_select = 0;
    iocs = 0;

    #50;
    $stop;
  end


endmodule