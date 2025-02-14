module spart_tb;

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

spart s1(
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

spart s2(
    .clk(clk),
    .rst(rst),
    .iocs(iocs),
    .iorw(iorw1),
    .rda(rda1),
    .tbr(tbr1),
    .ioaddr(ioaddr1),
    .databus(databus1),
    .txd(txd1),
    .rxd(txd0)
);


assign databus0 = db_select0 ? databus_logic0 : 8'bz;
assign databus1 = db_select1 ? databus_logic1 : 8'bz;

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
    iorw0 = 0;
    ioaddr0 = '0;
    db_select0 = 0;
    rxd0 = 0;

    // Apply reset
    #10;
    rst = 1;
    #10;

    @(posedge clk)
    iocs = 1;

    //Init Spart 0 and Spart 1
    ioaddr0 = 2'b10; //Select lower DB
    ioaddr1 = 2'b10; //Select lower DB
    db_select0 = 1;
    db_select1 = 1;
    databus_logic0 = 8'ha2; //load 162 for 9600 Baud
    databus_logic1 = 8'ha2;
    iorw0 = 0;
    iorw1 = 0;
    @(posedge clk) //Writing to DB buffer is single cycle
    databus_logic0 = '0;
    databus_logic1 = '0;
    ioaddr0 = 2'b11; //Select upper DB
    ioaddr1 = 2'b11;
    iorw0 = 0;  
    iorw1 = 0;  
    @(posedge clk) //Writing to DB Buffer is single cycle
    iorw0 = 1;
    iorw1 = 1;
    @(posedge clk)

    //Transmit Data on Spart 0
    ioaddr0 = 2'b00;
    databus_logic0 = 8'h67;
    iorw0 = 0;

    @(posedge tbr0);
    iorw0 = 1;

    //Recieving Data on Spart 1
    repeat (100) @(posedge clk); //wait to make sure rda1 stays high

    //read data
    ioaddr1 = 2'b00;
    iorw1 = 1;
    db_select1 = 0;
    @(posedge clk);

    repeat (100) @(posedge clk);

    //Read status register
    ioaddr0 = 2'b01;
    iorw0 = 1;
    ioaddr1 = 2'b01;
    iorw1 = 1;
    db_select0 = 0;
    db_select1 = 0;
    @(posedge clk);

    repeat (100) @(posedge clk);

    //Transmit data on Spart 1
    ioaddr1 = 2'b00;
    iorw1 = 0;
    db_select1 = 1;
    databus_logic1 = 8'h23;
    @(posedge tbr1);

    //Transmit data on Spart 0
    ioaddr0 = 2'b00;
    iorw0 = 0;
    db_select0 = 1;
    databus_logic0 = 8'h99;
    @(posedge tbr0);

    //Recieve on both spart 1 and spart 0
    iorw0 = 1;
    iorw1 = 1;
    db_select0 = 0;
    db_select1 = 0;

    #50;
    $stop;
  end


endmodule