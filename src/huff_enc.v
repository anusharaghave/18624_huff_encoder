module huff_encoder (
	clk,
	reset,
	io_in,
	io_out
);
	input wire clk;
	input wire reset;
	input wire [11:0] io_in;
	output reg [11:0] io_out;
	reg [23:0] data_in;
	reg [5:0] freq_in;
	reg [1:0] count;
	reg [2:0] odd_idx;
	reg [2:0] even_idx;
	wire [53:0] initial_node;
	reg [2:0] state;
	reg [19:0] huff_tree [0:5];
	reg [53:0] in_huff_tree;
	wire [71:0] out_huff_tree;
	wire [17:0] merged_node;
	reg [8:0] encoded_value;
	reg [8:0] encoded_mask;
	reg done;
	reg [2:0] encoded_value_h [0:5];
	reg [2:0] b;
	reg [2:0] c;
	reg [2:0] encoded_value_l;
	reg [2:0] encoded_value_r;
	freq_calc freq_calc_ins(
		.data_in(data_in),
		.freq_in(freq_in),
		.node(initial_node)
	);
	node_sorter node_sorter_ins(
		.clk(clk),
		.input_node(in_huff_tree[0+:54]),
		.output_node(out_huff_tree[18+:54])
	);
	merge_nodes merge_nodes_ins(
		.min_node(out_huff_tree[54+:18]),
		.second_min_node(out_huff_tree[36+:18]),
		.merged_node(merged_node)
	);
	always @(posedge clk) begin : huffman_enc
		if (reset) begin
			state <= 3'b001;
			b <= 3'b000;
			c <= 3'b000;
			done = 'b0;
			begin : sv2v_autoblock_1
				reg signed [31:0] i;
				for (i = 0; i < 3; i = i + 1)
					begin
						encoded_value[(2 - i) * 3+:3] = 'b0;
						encoded_mask[(2 - i) * 3+:3] = 'b0;
						in_huff_tree[((2 - i) * 18) + 17-:5] = 'b0;
						in_huff_tree[((2 - i) * 18) + 12-:2] = 'b0;
						in_huff_tree[((2 - i) * 18) + 10] = 'b0;
						in_huff_tree[((2 - i) * 18) + 9-:5] = 'b0;
						in_huff_tree[((2 - i) * 18) + 4-:5] = 'b0;
					end
			end
			begin : sv2v_autoblock_2
				reg signed [31:0] i;
				for (i = 0; i < 6; i = i + 1)
					begin
						encoded_value_h[i] = 'b0;
						huff_tree[i][19-:5] = 'b0;
						huff_tree[i][14] = 1'b0;
						huff_tree[i][3-:2] = 'b0;
						huff_tree[i][13-:5] = 'b0;
						huff_tree[i][8-:5] = 'b0;
						huff_tree[i][1-:2] = 'b0;
					end
			end
			io_out <= 'b0;
		end
		else
			case (state)
				3'b001: begin
					done = 'b0;
					data_in[(2 - c) * 8+:8] <= io_in[7:0];
					freq_in[(2 - c) * 2+:2] <= io_in[10:8];
					c <= c + 1'b1;
					state <= (c == 'd2 ? 3'b010 : 3'b001);
				end
				3'b010: begin
					count = 3;
					begin : sv2v_autoblock_3
						reg signed [31:0] i;
						for (i = 0; i < 3; i = i + 1)
							in_huff_tree[(2 - i) * 18+:18] = initial_node[(2 - i) * 18+:18];
					end
					state <= 3'b011;
				end
				3'b011: state <= 3'b100;
				3'b100: begin
					in_huff_tree[36+:18] = merged_node;
					in_huff_tree[0+:36] = out_huff_tree[0+:36];
					count = count - 1'b1;
					even_idx = count << 1'b1;
					odd_idx = even_idx + 1'b1;
					huff_tree[even_idx][19-:5] = out_huff_tree[71-:5];
					huff_tree[odd_idx][19-:5] = out_huff_tree[53-:5];
					huff_tree[even_idx][14] = out_huff_tree[64];
					huff_tree[odd_idx][14] = out_huff_tree[46];
					huff_tree[even_idx][13-:5] = out_huff_tree[63-:5];
					huff_tree[odd_idx][13-:5] = out_huff_tree[45-:5];
					huff_tree[even_idx][8-:5] = out_huff_tree[58-:5];
					huff_tree[odd_idx][8-:5] = out_huff_tree[40-:5];
					huff_tree[1][19-:5] = out_huff_tree[71-:5];
					huff_tree[1][14] = out_huff_tree[64];
					huff_tree[1][13-:5] = out_huff_tree[63-:5];
					huff_tree[1][8-:5] = out_huff_tree[58-:5];
					if (!(count[0] | count[1]))
						state <= 3'b101;
					else
						state <= 3'b011;
				end
				3'b101: begin
					begin : sv2v_autoblock_4
						reg signed [31:0] l;
						for (l = 5; l > 1; l = l - 1)
							begin : sv2v_autoblock_5
								reg signed [31:0] n;
								for (n = 1; n < 6; n = n + 1)
									if ((huff_tree[n][13-:5] == huff_tree[l][19-:5]) || (huff_tree[n][8-:5] == huff_tree[l][19-:5]))
										huff_tree[l][3-:2] = n;
							end
					end
					begin : sv2v_autoblock_6
						reg signed [31:0] n;
						for (n = 2; n < 6; n = n + 1)
							huff_tree[n][1-:2] = huff_tree[huff_tree[n][3-:2]][1-:2] + 1'b1;
					end
					state <= 3'b110;
				end
				3'b110: begin
					encoded_value_h[2][0] = 1'b0;
					encoded_value_h[3][0] = 1'b1;
					encoded_value_l = encoded_value_h[huff_tree[4][3-:2]] << 1'b1;
					encoded_value_r = (encoded_value_h[huff_tree[5][3-:2]] << 1'b1) | 1'b1;
					encoded_value_h[4] = encoded_value_l;
					encoded_value_h[5] = encoded_value_r;
					begin : sv2v_autoblock_7
						integer i;
						for (i = 0; i <= 2; i = i + 1)
							begin : sv2v_autoblock_8
								reg signed [31:0] n;
								for (n = 1; n < 6; n = n + 1)
									if (huff_tree[n][19-:5] == data_in[((2 - i) * 8) + 3-:4]) begin
										encoded_mask[(2 - i) * 3+:3] = (1'b1 << huff_tree[n][1-:2]) - 1'b1;
										encoded_value[(2 - i) * 3+:3] = encoded_value_h[n];
									end
							end
					end
					state <= 3'b111;
				end
				3'b111: begin
					done = 1'b1;
					io_out[8:0] <= {done, 2'b00, encoded_mask[(2 - b) * 3+:3], encoded_value[(2 - b) * 3+:3]};
					b <= b + 1'b1;
					state <= (b[0] && b[1] ? 3'b001 : 3'b111);
				end
				default: state <= 3'b001;
			endcase
	end
endmodule
module freq_calc (
	data_in,
	freq_in,
	node
);
	input wire [23:0] data_in;
	input wire [5:0] freq_in;
	output reg [53:0] node;
	always @(*) begin : sv2v_autoblock_1
		reg signed [31:0] i;
		for (i = 0; i < 3; i = i + 1)
			begin
				node[((2 - i) * 18) + 17-:5] = data_in[(2 - i) * 8+:8];
				node[((2 - i) * 18) + 12-:2] = freq_in[(2 - i) * 2+:2];
				node[((2 - i) * 18) + 9-:5] = 'b0;
				node[((2 - i) * 18) + 4-:5] = 'b0;
				node[((2 - i) * 18) + 10] = 1'b1;
			end
	end
endmodule
module node_sorter (
	clk,
	input_node,
	output_node
);
	input wire clk;
	input wire [53:0] input_node;
	output reg [53:0] output_node;
	reg [17:0] temp_node;
	always @(posedge clk) begin
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < 3; i = i + 1)
				output_node = input_node;
		end
		begin : sv2v_autoblock_2
			reg signed [31:0] j;
			for (j = 0; j < 2; j = j + 1)
				begin : sv2v_autoblock_3
					reg signed [31:0] k;
					for (k = 0; k < 2; k = k + 1)
						if (((output_node[((2 - k) * 18) + 12-:2] == output_node[((2 - (k + 1)) * 18) + 12-:2]) && (output_node[((2 - k) * 18) + 17-:5] > output_node[((2 - (k + 1)) * 18) + 17-:5])) || (output_node[((2 - k) * 18) + 12-:2] > output_node[((2 - (k + 1)) * 18) + 12-:2])) begin
							temp_node = output_node[(2 - k) * 18+:18];
							output_node[(2 - k) * 18+:18] = output_node[(2 - (k + 1)) * 18+:18];
							output_node[(2 - (k + 1)) * 18+:18] = temp_node;
						end
				end
		end
	end
endmodule
module merge_nodes (
	min_node,
	second_min_node,
	merged_node
);
	input wire [17:0] min_node;
	input wire [17:0] second_min_node;
	output wire [17:0] merged_node;
	assign merged_node[17-:5] = min_node[17-:5] + second_min_node[17-:5];
	assign merged_node[12-:2] = min_node[12-:2] + second_min_node[12-:2];
	assign merged_node[9-:5] = min_node[17-:5];
	assign merged_node[4-:5] = second_min_node[17-:5];
	assign merged_node[10] = 1'b0;
endmodule
