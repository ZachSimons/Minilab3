module spart_driver_tb;

logic clk, rst, iocs;

//Spart 0
logic iorw0, rda0, tbr0, txd0, rxd0, db_select0;
logic [1:0] ioaddr0;
tri [7:0] databus0;
logic [7:0] databus_logic0;

//Spart 1
logic iorw1, rda1, tbr1, txd1, rxd1, db_select1;
logic [1:0] ioaddr1;
tri [7:0] databus1;
logic [7:0] databus_logic1;

//Driver
logic [1:0] br_cfg;
logic iocs_driver, iorw_driver;
logic [1:0] ioaddr_driver;
tri [7:0] databus_driver;

//connected to tb
spart s0(
    .clk(clk),
    .rst(rst),
    .iocs(iocs),
    .iorw(iorw0),
    .rda(rda0),
    .tbr(tbr0),
    .ioaddr(ioaddr0),
    .databus(databus0),
    .txd(txd0),
    .rxd(txd1)
    );

//connected to driver
spart s1(
    .clk(clk),
    .rst(rst),
    .iocs(iocs_driver),
    .iorw(iorw_driver),
    .rda(rda1),
    .tbr(tbr1),
    .ioaddr(ioaddr_driver),
    .databus(databus_driver),
    .txd(txd1),
    .rxd(txd0)
);

//connected to spart1
driver d0(
    .clk(clk),
    .rst(rst),
    .br_cfg(br_cfg),
    .iocs(iocs_driver),
    .iorw(iorw_driver),
    .rda(rda1),
    .tbr(tbr1),
    .ioaddr(ioaddr_driver),
    .databus(databus_driver)
);

/*
driver d0(
    .clk(clk),
    .rst(rst),
    .br_cfg(br_cfg),
    .iocs(),
    .iorw(),
    .rda(),
    .tbr(),
    .ioaddr(),
    .databus()
);
*/
assign databus0 = db_select0 ? databus_logic0 : 8'bz;
assign databus1 = db_select1 ? databus_driver : 8'bz;

// Clock generation
always begin
    #5 clk = ~clk;  // Clock period of 10 units
end

// Test sequence
initial begin
    // Initialize signals
    clk = 0;
    rst = 0;
    br_cfg = 2'b01;
    db_select1 = 0;
    db_select0 = 0;

    // Apply reset
    #10;
    rst = 1;
    #10;

    //Init spart0
    iocs = 1;
    ioaddr0 = 2'b10;
    iorw0 = 0;
    databus_logic0 = 8'h58;
    db_select0 = 1;
    @(posedge clk);
    ioaddr0 = 2'b11;
    iorw0 = 0;
    databus_logic0 = 8'h14;
    db_select0 = 1;
    @(posedge clk);

    iorw0 = 1;

    #1000000;
    //Write to spart0

    @(posedge clk);
    ioaddr0 = 2'b00;
    iorw0 = 0;
    databus_logic0 = 8'h46;
    db_select0 = 1;
    @(posedge clk);

    iorw0 = 1;
    db_select0 = 0;
    @(posedge rda0);


    #1009999;

    rst = 0;
    br_cfg = 2'b11;
    db_select1 = 0;
    db_select0 = 0;

    // Apply reset
    #10;
    rst = 1;
    #10;

    //Init spart0
    iocs = 1;
    ioaddr0 = 2'b10;
    iorw0 = 0;
    databus_logic0 = 8'h16;
    db_select0 = 1;
    @(posedge clk);
    ioaddr0 = 2'b11;
    iorw0 = 0;
    databus_logic0 = 8'h05;
    db_select0 = 1;
    @(posedge clk);


    @(posedge clk);
    ioaddr0 = 2'b00;
    iorw0 = 0;
    databus_logic0 = 8'h24;
    db_select0 = 1;
    @(posedge clk);

    iorw0 = 1;
    db_select0 = 0;


    #1009999;

    $stop;
  end


endmodule