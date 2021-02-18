module qimo
(
input clk,reset,
input up,left,right,
output [15:0]martix_c,
output [15:0]martix_r1,
output [15:0]martix_r2
);
wire[3:0] counter_flash;
wire[8:0] counter_process;
wire[15:0] new_row;
wire[511:0] martix; //16*16*2-1
wire [2:0]control; 
assign control = {up,left,right};
wire clk_control;
wire [3:0] player;
wire [3:0] max,min; 
wire [15:0]player_row;

assign player_row = {martix[48],martix[49],martix[50],martix[51],martix[52],martix[53],martix[54],martix[55],martix[56],martix[57],martix[58],martix[59],martix[60],martix[61],martix[62],martix[63]};
div_f d2(clk,4'hF,counter_flash);
div_c d3(clk,9'h1FF,clk_control);
contorller c4(clk_control,reset,martix,player_row,new_row,control,player,counter_process);
shifter s1(clk,reset,new_row,counter_process,martix);
flasher f1(clk,player,martix,counter_flash,martix_c,martix_r1,martix_r2);
decorder d4(clk,counter_process,new_row);
endmodule


module div_f
(input clk,
 input [3:0]max,
output reg [3:0]count);

always@(posedge clk)
begin
	if(count < max)
		count = count + 4'b1;
	else
		count = 4'b0;
end
endmodule

module div_c
(input clk,
 input [8:0]max,
output reg clk_c);
reg [8:0]count;
always@(posedge clk)
begin
	if(count < max)
	begin
		count = count + 9'b1;
		clk_c = 1'b0;
	end
	else
	begin
		count = 0;
		clk_c = 1'b1;
	end
end
endmodule


module contorller 
(
input clk,reset,
input [511:0]martix,
input [15:0]player_row,
input [15:0]new_row,
input [2:0]control,
output reg [3:0] player,
output reg [8:0]counter_process
);
reg [3:0]player_tmp;
reg [3:0]max;
reg [3:0]min;
reg [3:0]count_p;
reg [3:0]count_pt;
reg flag_lose;
reg [3:0]up_tmp; //n stage
reg flag_up;
reg [6:0]up_count;
initial player = 4'h2;
wire [9:0]_player ;

reg [15:0]tmp_count;
integer i;
assign _player = {5'h0,player};

always@(posedge clk)
begin
	if(counter_process>10'd279)
		;
	else if(flag_lose)
	begin
		if(up_tmp>4'h4&&up_tmp<4'hB)
			up_tmp = 4'hC;
		else if(up_tmp==4'h0)
			up_tmp = 4'h0;
		else
			up_tmp = up_tmp + 4'b1;
		case(up_tmp)
		4'hC:  player = player + 4'h2;
		4'hD:  player = player + 4'h1;
		4'hE:  player = player - 4'h1;
		4'hF:  player = 0;
		endcase			
	end
	else if(counter_process>10'd267)
	begin
		counter_process = counter_process + 9'd1;
		player = 4'd0;
	end
	else if(counter_process<10'd32)	
		counter_process = counter_process + 9'd1;
	else
	begin	
		if(up_count == 7'b1011)
		begin
			up_count = 7'b0;
			if(flag_up)
			begin
				player_tmp = player;
				case(up_tmp)
				4'h0:  player = player + 4'h3;
				4'h1:  player = player + 4'h2;
				4'h2:  player = player + 4'h2;
				4'h3:  player = player + 4'h1;
				4'h4:  player = player - 4'h1;
				4'h5:  player = player - 4'h2;
				4'h6:  player = player - 4'h2;
				4'h7:  player = player - 4'h3;
				4'h8:  player = player - 4'h3;
				4'h9:  player = player - 4'h4;
				4'hA:  player = player - 4'h4;
				4'hB:  player = player - 4'h4;
				default: player = 0;
				endcase
				up_tmp = up_tmp + 4'h1;
				if(up_tmp <= 4)//upward
				begin
				////max////////////
					count_pt=4'd0;
					count_p=4'd0;
					//while(!player_row[count_pt])
						for(i=0;i<16;i=i+1)
						begin
							if(i<=player_tmp)
								tmp_count[i] = 1'b0;
							else
								tmp_count[i] = 1'b1;
						end						
						tmp_count = tmp_count & player_row;
						for(i=15;i>0;i=i-1)
						begin
							if(tmp_count[i])
								count_pt = i[3:0] - 4'd1;
						end
					//end while(!player_row[count_pt])		
					if(!player_row[player])
					begin
					//while(!player_row[count_p])
						for(i=0;i<16;i=i+1)
						begin
							if(i<=player)
								tmp_count[i] = 1'b0;
							else
								tmp_count[i] = 1'b1;
						end
						tmp_count = tmp_count & player_row;
						for(i=15;i>0;i=i-1)
						begin
							if(tmp_count[i])
								count_p = i[3:0] - 4'd1;
						end
					//end while(!player_row[count_p])
					end	
					if(player < player_tmp)
						max = 4'd15;
					else if(count_p == count_pt)
						max = player;
					else
						max = count_pt;
					player = max;
				/////max///////////////
				end
				else //downward
				begin
				////min///////////
					count_pt=4'd0;
					count_p=4'd0;
					if(!player_row[player_tmp])
					begin
					//while(!player_row[count_pt])
						for(i=0;i<16;i=i+1)
						begin
							if(i>=player_tmp)
								tmp_count[i] = 1'b0;
							else
								tmp_count[i] = 1'b1;
						end
						tmp_count = tmp_count & player_row;
						for(i=0;i<16;i=i+1)
						begin
							if(tmp_count[i])
								count_pt = i[3:0] + 4'd1;
						end
					//end while(!player_row[count_pt])	
					end	
					if(!player_row[player])
					begin
					//while(!player_row[count_p])
						for(i=0;i<16;i=i+1)
						begin
							if(i>=player)
								tmp_count[i] = 1'b0;
							else
								tmp_count[i] = 1'b1;
						end
						tmp_count = tmp_count & player_row;
						for(i=0;i<16;i=i+1)
						begin
							if(tmp_count[i])
								count_p = i[3:0] + 4'd1;
						end
					//end while(!player_row[count_p])
					end	
					if(player > player_tmp)
						min = 4'd2;
					else if(count_p == count_pt)
						min = player;
					else
						min = count_pt;	
						player = min;
				////min/////////
				end
				if(player_row[player-1]||up_tmp>4'hB)
				begin
					flag_up = 1'b0;
					up_tmp = 4'h0;
				end
			end
		end
		else
		begin
			up_count = up_count + 7'b1;
		end
		if(control[2])//up
			flag_up = 1'b1;	
		if(control[1])//left
		begin
			if(counter_process > 32)
			begin
				if(!martix[32+15-_player])		//32+15-{5'b0,player}
					counter_process = counter_process - 9'b1;
			end
		end
		if(control[0])//right
		begin
			if(!martix[64+15-_player])			
				counter_process = counter_process + 9'b1;
		end
		if((player==4'd1||player==4'd0))
			flag_lose = 1;
		if(!player_row[player-1])
		begin
			if(up_tmp==4'b0)
			begin
				flag_up = 1'b1;
				up_tmp = 4'h4;
			end
		end
	end
	if(reset)
	begin
		flag_lose = 1'd0;
		counter_process = 9'd0;
		player = 4'd2;
	end
end

endmodule


module shifter
(input clk,reset,
 input [15:0]new_row,
 input [8:0]signal,
output reg [511:0]martix);
 reg   [8:0]signal_tmp;
 reg flag;
 
always@(posedge clk)
begin
	if(flag)
	begin
		if(signal > signal_tmp)
			martix = {new_row,martix[511:16]};
		else if(signal < signal_tmp)
			martix = {martix[511-16:0],new_row};
		signal_tmp = signal;
		flag = 1'b0;
	end	
	if(signal != signal_tmp)
		flag = 1'b1;
	if(reset)
		martix = 512'b0;
end
endmodule

module flasher
(input clk,
 input [3:0]player,
 input [511:0]martix,
 input [3:0]flash,
output reg [15:0]martix_c,
output reg [15:0]martix_r1,
output reg [15:0]martix_r2
);
reg [15:0]player_flash;
always@(posedge clk)
begin
	martix_c = 16'h00;
	martix_c[flash] =1;
	case(player)
		4'h0: player_flash = 16'b1000000000000000;
		4'h1: player_flash = 16'b0100000000000000;
		4'h2: player_flash = 16'b0010000000000000;
		4'h3: player_flash = 16'b0001000000000000;
		4'h4: player_flash = 16'b0000100000000000;
		4'h5: player_flash = 16'b0000010000000000;
		4'h6: player_flash = 16'b0000001000000000;
		4'h7: player_flash = 16'b0000000100000000;
		4'h8: player_flash = 16'b0000000010000000;
		4'h9: player_flash = 16'b0000000001000000;
		4'hA: player_flash = 16'b0000000000100000;
		4'hB: player_flash = 16'b0000000000010000;
		4'hC: player_flash = 16'b0000000000001000;
		4'hD: player_flash = 16'b0000000000000100;
		4'hE: player_flash = 16'b0000000000000010;
		4'hF: player_flash = 16'b0000000000000001;
	endcase
	case(flash)
		4'd00: begin
			martix_r1 = martix[015:000];
			martix_r2 = martix[271:256];				
		end
		4'd01: begin
			martix_r1 = martix[031:016];
			martix_r2 = martix[287:272];				
		end
		4'd02: begin
			martix_r1 = martix[047:032];
			martix_r2 = martix[303:288];					
		end
		4'd03: begin
			martix_r1 = martix[063:048]|player_flash;
			martix_r2 = martix[319:304];				
		end
		4'd04: begin
			martix_r1 = martix[079:064];
			martix_r2 = martix[335:320];				
		end
		4'd05: begin
			martix_r1 = martix[095:080];
			martix_r2 = martix[351:336];				
		end
		4'd06: begin
			martix_r1 = martix[111:096];
			martix_r2 = martix[367:352];				
		end
		4'd07: begin
			martix_r1 = martix[127:112];
			martix_r2 = martix[383:368];				
		end
		4'd08: begin
			martix_r1 = martix[143:128];
			martix_r2 = martix[399:384];				
		end
		4'd09: begin
			martix_r1 = martix[159:144];
			martix_r2 = martix[415:400];				
		end
		4'd10: begin
			martix_r1 = martix[175:160];
			martix_r2 = martix[431:416];				
		end
		4'd11: begin
			martix_r1 = martix[191:176];
			martix_r2 = martix[447:432];			
		end
		4'd12: begin
			martix_r1 = martix[207:192];
			martix_r2 = martix[463:448];				
		end
		4'd13: begin
			martix_r1 = martix[223:208];
			martix_r2 = martix[479:464];				
		end
		4'd14: begin
			martix_r1 = martix[239:224];
			martix_r2 = martix[495:480];				
		end
		4'd15: begin
			martix_r1 = martix[255:240];
			martix_r2 = martix[511:496];
		end	
	endcase	//martix_r = martix[(flash*8+7):(flash*8)];
end
endmodule

module decorder
(
input clk,
input [8:0]line,
output reg[15:0]decord);
 reg   [8:0]line_tmp;
 reg [8:0] line_cal;

always@(posedge clk)
begin
if(line_tmp != line)
begin
	if(line >= line_tmp)
		line_cal = line;
	else if(line < line_tmp)
		line_cal = line -9'd32;
end
line_tmp = line;
case(line_cal)
	000: decord = 16'b1100000000000000;
	001: decord = 16'b1100000000000000;
	002: decord = 16'b1100000000000000;
	003: decord = 16'b1100000000000000;
	004: decord = 16'b1100000000000000;
	005: decord = 16'b1100000000000000;
	006: decord = 16'b1100000000000000;
	007: decord = 16'b1100000000000000;
	008: decord = 16'b1100000000000000;
	009: decord = 16'b1100000000000000;
	010: decord = 16'b1100000000000000;
	011: decord = 16'b1100001100000000;
	012: decord = 16'b1100001100000000;
	013: decord = 16'b1100000000000000;
	014: decord = 16'b1100001100000000;
	015: decord = 16'b1100001100000000;
	016: decord = 16'b1100000000000000;
	017: decord = 16'b1100001100000000;
	018: decord = 16'b1100001100000000;
	019: decord = 16'b1100000000000000;
	020: decord = 16'b1100001100000000;
	021: decord = 16'b1100001100000000;
	022: decord = 16'b1100000000000000;
	023: decord = 16'b1100001100000000;
	024: decord = 16'b1100001100000000;
	025: decord = 16'b1100000000000000;
	026: decord = 16'b1100001100000000;
	027: decord = 16'b1100001100000000;
	028: decord = 16'b1100000000000000;
	029: decord = 16'b1100000000000000;
	030: decord = 16'b1100000000000000;
	031: decord = 16'b1100000000000000;
	032: decord = 16'b1100000000000000;
	033: decord = 16'b1100000000000000;
	034: decord = 16'b1100000000000000;
	035: decord = 16'b1100111000000000;
	036: decord = 16'b1111111000000000;
	037: decord = 16'b1111111000000000;
	038: decord = 16'b1100111000000000;
	039: decord = 16'b1100000000000000;
	040: decord = 16'b1100000000000000;
	041: decord = 16'b1100000000000000;
	042: decord = 16'b1100000000000000;
	043: decord = 16'b1100000000000000;
	044: decord = 16'b1100001110000000;
	045: decord = 16'b1111111110000000;
	046: decord = 16'b1111111110000000;
	047: decord = 16'b1100001110000000;
	048: decord = 16'b1100000000000000;
	049: decord = 16'b1100000000000000;
	050: decord = 16'b1100000000000000;
	051: decord = 16'b1100000000000000;
	052: decord = 16'b1100000000000000;
	053: decord = 16'b1100000111000000;
	054: decord = 16'b1111111111000000;
	055: decord = 16'b1111111111000000;
	056: decord = 16'b1100000111000000;
	057: decord = 16'b1100000000000000;
	058: decord = 16'b1100000000000000;
	059: decord = 16'b1100000000000000;
	060: decord = 16'b1100000000000000;
	061: decord = 16'b1100000000000000;
	062: decord = 16'b1100000000000000;
	063: decord = 16'b1100000000000000;
	064: decord = 16'b1100001110000000;
	065: decord = 16'b1111111110000000;
	066: decord = 16'b1111111110000000;
	067: decord = 16'b1100001110000000;
	068: decord = 16'b1100000000000000;
	069: decord = 16'b1100000000000000;
	070: decord = 16'b1100000000000000;
	071: decord = 16'b1100000000000000;
	072: decord = 16'b1100000000000000;
	073: decord = 16'b1100000000000000;
	074: decord = 16'b1100000000000000;
	075: decord = 16'b1100000000000000;
	076: decord = 16'b1100000000000000;
	077: decord = 16'b1100000000000000;
	078: decord = 16'b1100000000000000;
	079: decord = 16'b1100000000000000;
	080: decord = 16'b1100000000000000;
	081: decord = 16'b1100000000000000;
	082: decord = 16'b1100000000000000;
	083: decord = 16'b1100000000000000;
	084: decord = 16'b0000000000000000;
	085: decord = 16'b0000000000000000;
	086: decord = 16'b1100000000000000;
	087: decord = 16'b1100000000000000;
	088: decord = 16'b1100000000000000;
	089: decord = 16'b1100000000000000;
	090: decord = 16'b1100000000000000;
	091: decord = 16'b1100000000000000;
	092: decord = 16'b1100000000000000;
	093: decord = 16'b1100000000000000;
	094: decord = 16'b1100000000000000;
	095: decord = 16'b1100001100000000;
	096: decord = 16'b1100001100000000;
	097: decord = 16'b1100001100000000;
	098: decord = 16'b1100001100000000;
	099: decord = 16'b1100001100000000;
	100: decord = 16'b1100001100000000;
	101: decord = 16'b1100001100110000;
	102: decord = 16'b1100000000110000;
	103: decord = 16'b1100000000110000;
	104: decord = 16'b1100000000110000;
	105: decord = 16'b1100000000110000;
	106: decord = 16'b1100000000110000;
	107: decord = 16'b1100000000110000;
	108: decord = 16'b1100000000110000;
	109: decord = 16'b1100000000110000;
	110: decord = 16'b1100000000110000;
	111: decord = 16'b1100000000110000;
	112: decord = 16'b1100000000110000;
	113: decord = 16'b1100000000110000;
	114: decord = 16'b1100000000110000;
	115: decord = 16'b1100000000110000;
	116: decord = 16'b1100000000000000;
	117: decord = 16'b1100000000000000;
	118: decord = 16'b1100000000000000;
	119: decord = 16'b1100000000110000;
	120: decord = 16'b1100000000110000;
	121: decord = 16'b1100000000110000;
	122: decord = 16'b1100000000110000;
	123: decord = 16'b1100000000110000;
	124: decord = 16'b1100000000110000;
	125: decord = 16'b1100000000110000;
	126: decord = 16'b1100000000110000;
	127: decord = 16'b1100000000110000;
	128: decord = 16'b1100000000000000;
	129: decord = 16'b1100000000000000;
	130: decord = 16'b1100000000000000;
	131: decord = 16'b1100000110000000;
	132: decord = 16'b1100000110000000;
	133: decord = 16'b1100000110000000;
	134: decord = 16'b1100000110000000;
	135: decord = 16'b1100000000000000;
	136: decord = 16'b1100000000000000;
	137: decord = 16'b1100000000000000;
	138: decord = 16'b1100000000000000;
	139: decord = 16'b1100000000000000;
	140: decord = 16'b1100000000000000;
	141: decord = 16'b1100001100000000;
	142: decord = 16'b1100001100000000;
	143: decord = 16'b1100000000000000;
	144: decord = 16'b1100000000000000;
	145: decord = 16'b1100001100011000;
	146: decord = 16'b1100001100011000;
	147: decord = 16'b1100000000000000;
	148: decord = 16'b1100000000000000;
	149: decord = 16'b1100001100000000;
	150: decord = 16'b1100001100000000;
	151: decord = 16'b1100000000000000;
	152: decord = 16'b1100000000000000;
	153: decord = 16'b1100000000000000;
	154: decord = 16'b1100000000000000;
	155: decord = 16'b1100000000000000;
	156: decord = 16'b1100000000000000;
	157: decord = 16'b1100000000000000;
	158: decord = 16'b1100000000000000;
	159: decord = 16'b1100000000000000;
	160: decord = 16'b1110000000000000;
	161: decord = 16'b1111000000000000;
	162: decord = 16'b1111100000000000;
	163: decord = 16'b1111110000000000;
	164: decord = 16'b1111111000000000;
	165: decord = 16'b1100000000000000;
	166: decord = 16'b1100000000000000;
	167: decord = 16'b1111111000000000;
	168: decord = 16'b1111110000000000;
	169: decord = 16'b1111100000000000;
	170: decord = 16'b1111000000000000;
	171: decord = 16'b1110000000000000;
	172: decord = 16'b1100000000000000;
	173: decord = 16'b1100000000000000;
	174: decord = 16'b1100000000000000;
	175: decord = 16'b1100000000000000;
	176: decord = 16'b1110000000000000;
	177: decord = 16'b1111000000000000;
	178: decord = 16'b1111100000000000;
	179: decord = 16'b1111110000000000;
	180: decord = 16'b1111111000000000;
	181: decord = 16'b1111111000000000;
	182: decord = 16'b0000000000000000;
	183: decord = 16'b0000000000000000;
	184: decord = 16'b0000000000000000;
	185: decord = 16'b1111111000000000;
	186: decord = 16'b1111110000000000;
	187: decord = 16'b1111100000000000;
	188: decord = 16'b1111000000000000;
	189: decord = 16'b1110000000000000;
	190: decord = 16'b1100000000000000;
	191: decord = 16'b1100000000000000;
	192: decord = 16'b1100000000000000;
	193: decord = 16'b1100000000000000;
	194: decord = 16'b1100111000000000;
	195: decord = 16'b1111111000000000;
	196: decord = 16'b1111111000000000;
	197: decord = 16'b1100111000000000;
	198: decord = 16'b1100000000000000;
	199: decord = 16'b1100000000000000;
	200: decord = 16'b1100000000000000;
	201: decord = 16'b1100000000000000;
	202: decord = 16'b1100000000000000;
	203: decord = 16'b1100000000000000;
	204: decord = 16'b1100000110000000;
	205: decord = 16'b1100000110000000;
	206: decord = 16'b1100000110000000;
	207: decord = 16'b1100000110000000;
	208: decord = 16'b1100000110000000;
	209: decord = 16'b1100000110000000;
	210: decord = 16'b1100000110000000;
	211: decord = 16'b1100000000000000;
	212: decord = 16'b1100000000000000;
	213: decord = 16'b1100000000000000;
	214: decord = 16'b1100000000000000;
	215: decord = 16'b1100000000000000;
	216: decord = 16'b1100000000000000;
	217: decord = 16'b1100000000000000;
	218: decord = 16'b1100111000000000;
	219: decord = 16'b1111111000000000;
	220: decord = 16'b1111111000000000;
	221: decord = 16'b1100111000000000;
	222: decord = 16'b1110000000000000;
	223: decord = 16'b1111000000000000;
	224: decord = 16'b1111100000000000;
	225: decord = 16'b1111110000000000;
	226: decord = 16'b1111111000000000;
	227: decord = 16'b1111111100000000;
	228: decord = 16'b1111111110000000;
	229: decord = 16'b1111111111000000;
	230: decord = 16'b1111111111000000;
	231: decord = 16'b1100000000000000;
	232: decord = 16'b1100000000000000;
	233: decord = 16'b1100000000000000;
	234: decord = 16'b1100000000000000;
	235: decord = 16'b1100000000000000;
	236: decord = 16'b1100000000000000;
	237: decord = 16'b1100000000000000;
	238: decord = 16'b1100000000000000;
	239: decord = 16'b1100000000000000;
	240: decord = 16'b1111000000000000;
	241: decord = 16'b1111111111111000;
	242: decord = 16'b1111000000010000;
	243: decord = 16'b1100000000000000;
	244: decord = 16'b1100000000000000;
	245: decord = 16'b1100000000000000;
	246: decord = 16'b1100000000000000;
	247: decord = 16'b1100000000000000;
	248: decord = 16'b1100000000000000;
	249: decord = 16'b1111111100000000;
	250: decord = 16'b1111111000000000;
	251: decord = 16'b1111111111111000;
	252: decord = 16'b1111111000110000;
	253: decord = 16'b1111111100010000;
	254: decord = 16'b1100111000111000;
	255: decord = 16'b1100011111110000;
	256: decord = 16'b1100111000111000;
	257: decord = 16'b1111111100010000;
	258: decord = 16'b1111111000110000;
	259: decord = 16'b1111111111111000;
	260: decord = 16'b1111111000000000;
	261: decord = 16'b1111111100000000;
	262: decord = 16'b1100000000000000;
	263: decord = 16'b1100000000000000;
	264: decord = 16'b1100000000000000;
	265: decord = 16'b1100111000000000;
	266: decord = 16'b1101000000000000;
	267: decord = 16'b1100110000000000;
	268: decord = 16'b1100001000001000;
	269: decord = 16'b1100110000010000;
	270: decord = 16'b1101000011100000;
	271: decord = 16'b1100111000010000;
	272: decord = 16'b1100000000001000;
	273: decord = 16'b1101001011100000;
	274: decord = 16'b1101111010100000;
	275: decord = 16'b1101001011100000;
	276: decord = 16'b1100000000000000;
	277: decord = 16'b1101111011100000;
	278: decord = 16'b1100010010000000;
	279: decord = 16'b1100100011100000;
	280: decord = 16'b1101111000000000;
default: decord = 16'b0000000000000000;
endcase


end
endmodule


//pin right click/view/all pin list
//Project/Generate Tcl file for projet
//Tools/Tcl Scripts
//frequency = 10^5hz 100,000Hz