module zuckberberg (  output wire [3:0] rowwrite,
						input [3:0] colread,
						input clk,
						output wire [3:0] data,
						
						output wire [3:0] grounds,
						output wire [6:0] display
					);
reg [15:0] data_all;
wire [3:0] keyout;
reg [25:0] clk1;
wire keypressed;
reg [2:0] state;
reg [15:0] buffer;
reg winner;

assign data=keyout;

sevensegment ss1 (.datain(data_all), .grounds(grounds), .display(display), .clk(clk));

keypad_ex  kp1(.rowwrite(rowwrite),.colread(colread),.clk(clk),.keyout(keyout),.keypressed(keypressed));






always @(posedge clk)
	case(state)
		3'b000:
				if (keypressed)
					begin
						if (keyout==4'hE)
							begin
								if (data_all>16'b1)
									state<=3'b11;
								else
									state<=3'b1;
							end
						else
							begin
								data_all<=(data_all<<4)+keyout;
								state<=3'b1;
							end

					end
		3'b001:
				if (~keypressed)
					state<=0;
					
		3'b010:
				if (keypressed)
					begin
						if(keyout==4'hF)
							begin
								if(buffer>16'h0)
									begin
										if(data_all > buffer)
											begin
												data_all<=data_all - buffer;
												winner<=winner+1;
												buffer<=16'b0;
											end
										else
											begin
												if((data_all==1) && (buffer==1))
													state<=3'b100;
												else
													state<=3'b011;
											end
									end
								else
									state<=3'b011;
							end
						else if(keyout==4'h1)
							begin
								buffer<=16'b01;
								state<=3'b011;
							end
						else if(keyout==4'h2)
							begin
								buffer<=16'b10;
								state<=3'b011;
							end
						else if(keyout==4'h3)
							begin
								buffer<=16'b11;
								state<=3'b011;
							end
						else
							begin
								buffer<=16'b0;
								state<=3'b011;
							end
				end
							
		3'b011:
				if (~keypressed)
						state<=3'b010;
		3'b100:
				if(winner % 2 == 1)
					data_all=16'hc1;
				else
					data_all=16'hc2;
				
				
		
	endcase
	
	
	
initial 
	begin
		buffer=16'b0;
		winner=0;
		state=0;
	end

endmodule

module keypad_ex (
						output reg [3:0] rowwrite,
						input [3:0] colread,
						input clk,
						output reg [3:0] keyout,
						output wire keypressed
						);
						
reg [25:0] clk1;
reg [3:0] keyread;
reg [3:0] rowpressed;
reg [3:0] pressedcol [0:3];
reg [11:0] rowpressed_buffer0;
reg [11:0] rowpressed_buffer1;
reg [11:0] rowpressed_buffer2;
reg [11:0] rowpressed_buffer3;

reg [3:0] rowpressed_debounced;
always @(posedge clk)
	clk1<=clk1+1;

always @(posedge clk1[15])
	rowwrite<={rowwrite[2:0], rowwrite[3]};

always @(posedge clk1[15])
	if (rowwrite== 4'b1110)
		begin
			rowpressed[0]<= ~(&colread); //colread=1111--> none of them pressed, colread=1110 --> 1, colread=1101-->2, 1011-->3, 0111->A
			pressedcol[0]<=colread;
		end
	else if (rowwrite==4'b1101)
		begin
			rowpressed[1]<= ~(&colread); //colread=1111--> none of them pressed, colread=1110 --> 4, colread=1101-->5, 1011-->6, 0111->B
			pressedcol[1]<=colread;
		end
	else if (rowwrite==4'b1011)
		begin
			rowpressed[2]<= ~(&colread); //colread=1111--> none of them pressed, colread=1110 --> 7, colread=1101-->8, 1011-->9, 0111->C
			pressedcol[2]<=colread;
		end
	else if (rowwrite==4'b0111)
		begin
			rowpressed[3]<= ~(&colread); //colread=1111--> none of them pressed, colread=1110 --> *(E), colread=1101-->0, 1011-->#(F), 0111->D
			pressedcol[3]<=colread;
		end
		
wire transition0_10;
wire transition0_01;

assign transition0_10=~|rowpressed_buffer0;
assign transition0_01=&rowpressed_buffer0;

wire transition1_10;
wire transition1_01;

assign transition1_10=~|rowpressed_buffer1;
assign transition1_01=&rowpressed_buffer1;

wire transition2_10;
wire transition2_01;

assign transition2_10=~|rowpressed_buffer2;
assign transition2_01=&rowpressed_buffer2;

wire transition3_10;
wire transition3_01;

assign transition3_10=~|rowpressed_buffer3; //kpd=1-->0
assign transition3_01=&rowpressed_buffer3;  //kpd=0-->1


always @(posedge clk1[15])
	begin
		rowpressed_buffer0<= {rowpressed_buffer0[10:0],rowpressed[0]};
		if (rowpressed_debounced[0]==0 && transition0_01)
			rowpressed_debounced[0]<=1;
		if (rowpressed_debounced[0]==1 && transition0_10)
			rowpressed_debounced[0]<=0;
	
	rowpressed_buffer1<= {rowpressed_buffer1[10:0],rowpressed[1]};
		if (rowpressed_debounced[1]==0 && transition1_01)
			rowpressed_debounced[1]<=1;
		if (rowpressed_debounced[1]==1 && transition1_10)
			rowpressed_debounced[1]<=0;
			
	rowpressed_buffer2<= {rowpressed_buffer2[10:0],rowpressed[2]};
		if (rowpressed_debounced[2]==0 && transition2_01)
			rowpressed_debounced[2]<=1;
		if (rowpressed_debounced[2]==1 && transition2_10)
			rowpressed_debounced[2]<=0;
	
	rowpressed_buffer3<= {rowpressed_buffer3[10:0],rowpressed[3]};
		if (rowpressed_debounced[3]==0 && transition3_01)
			rowpressed_debounced[3]<=1;
		if (rowpressed_debounced[3]==1 && transition3_10)
			rowpressed_debounced[3]<=0;
	end 

always @*
	begin
		if (rowpressed_debounced[0]==1)
			begin
				if (pressedcol[0]==4'b1110)
					keyread=4'h1;
				else if (pressedcol[0]==4'b1101)
					keyread=4'h2;
				else if (pressedcol[0]==4'b1011)
					keyread=4'h3;
				else if (pressedcol[0]==4'b0111)
					keyread=4'hA;
				else keyread=4'b0000;
			end
		else if (rowpressed_debounced[1]==1)
			begin
				if (pressedcol[1]==4'b1110)
					keyread=4'h4;
				else if (pressedcol[1]==4'b1101)
					keyread=4'h5;
				else if (pressedcol[1]==4'b1011)
					keyread=4'h6;
				else if (pressedcol[1]==4'b0111)
					keyread=4'hB;
				else keyread=4'b0000;
			end
		else if (rowpressed_debounced[2]==1)
			begin
				if (pressedcol[2]==4'b1110)
					keyread=4'h7;
				else if (pressedcol[2]==4'b1101)
					keyread=4'h8;
				else if (pressedcol[2]==4'b1011)
					keyread=4'h9;
				else if (pressedcol[2]==4'b0111)
					keyread=4'hC;
				else keyread=4'b0000;
			end
		else if (rowpressed_debounced[3]==1)
			begin
				if (pressedcol[3]==4'b1110)
					keyread=4'hE;
				else if (pressedcol[3]==4'b1101)
					keyread=4'h0;
				else if (pressedcol[3]==4'b1011)
					keyread=4'hF;
				else if (pressedcol[3]==4'b0111)
					keyread=4'hD;
				else keyread=4'b0000;
			end
		else keyread=4'b0000;
	end //always


assign keypressed= rowpressed_debounced[0]||rowpressed_debounced[1]||rowpressed_debounced[2]||rowpressed_debounced[3];
	
always @(posedge keypressed)
			keyout<=keyread;

initial rowwrite=4'b1110;		

endmodule

module sevensegment(datain, grounds, display, clk);
	input wire [15:0] datain;
	output reg [3:0] grounds;
	output reg [6:0] display;
	input clk;	
	reg [3:0] data [3:0];
	reg [1:0] count;
	reg [25:0] clk1;
	
	always @(posedge clk1[15])
		begin
			grounds <= {grounds[2:0],grounds[3]};
			count <= count + 1;
		end
	
	always @(posedge clk)
		clk1 <= clk1 + 1;
	
	always @(*)
		case(data[count])	
0:display=7'b1111110; //starts with a, ends with g
1:display=7'b0110000;
2:display=7'b1101101;
3:display=7'b1111001;
4:display=7'b0110011;
5:display=7'b1011011;
6:display=7'b1011111;
7:display=7'b1110000;
8:display=7'b1111111;
9:display=7'b1111011;
'ha:display=7'b1110111;
'hb:display=7'b0011111;
'hc:display=7'b0110111;
'hd:display=7'b0111101;
'he:display=7'b1001111;
'hf:display=7'b1000111;
//'hx:display=7';
default display=7'b1111111;
		endcase
	
	always @*
		begin
			data[0] = datain[15:12];
			data[1] = datain[11:8];
			data[2] = datain[7:4];
			data[3] = datain[3:0];
		end
		initial begin		
		count = 2'b0;
		grounds = 4'b1110;
		clk1 = 0;
	end
endmodule
