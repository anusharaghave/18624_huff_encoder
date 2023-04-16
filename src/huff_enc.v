module huff_encoder (
	clk,
	reset,
	data_in,
	freq_in,
	encoded_value,
	encoded_mask,
	done
);
	input wire clk;
	input wire reset;
	input wire [23:0] data_in;
	input wire [8:0] freq_in;
	output reg [8:0] encoded_value;
	output reg [8:0] encoded_mask;
	output reg done;
	reg [20:0] character;
	reg [1:0] count;
	reg [2:0] odd_idx;
	reg [2:0] even_idx;
	wire [95:0] initial_node;
	reg [3:0] state;
	reg [31:0] huff_tree [0:5];
	reg [95:0] in_huff_tree;
	wire [127:0] out_huff_tree;
	wire [31:0] merged_node;
	reg [2:0] encoded_value_h [0:5];
	reg [2:0] n;
	reg [2:0] encoded_value_l;
	reg [2:0] encoded_value_r;
	reg is_n_odd;
	freq_calc freq_calc_ins(
		.data_in(data_in),
		.freq_in(freq_in),
		.node(initial_node)
	);
	node_sorter node_sorter_ins(
		.clk(clk),
		.input_node(in_huff_tree[0+:96]),
		.output_node(out_huff_tree[32+:96])
	);
	merge_nodes merge_nodes_ins(
		.min_node(out_huff_tree[96+:32]),
		.second_min_node(out_huff_tree[64+:32]),
		.merged_node(merged_node)
	);
	always @(posedge clk) begin : huffman_enc
		if (reset) begin
			state <= 4'b0000;
			n <= 3'd2;
			begin : sv2v_autoblock_1
				reg signed [31:0] i;
				for (i = 0; i < 3; i = i + 1)
					begin
						encoded_mask[(2 - i) * 3+:3] = 'b0;
						character[(2 - i) * 7+:7] = 'b0;
						in_huff_tree[((2 - i) * 32) + 31-:9] = 'b0;
						in_huff_tree[((2 - i) * 32) + 22-:4] = 'b0;
						in_huff_tree[((2 - i) * 32) + 18] = 'b0;
						in_huff_tree[((2 - i) * 32) + 17-:9] = 'b0;
						in_huff_tree[((2 - i) * 32) + 8-:9] = 'b0;
					end
			end
		end
		else
			case (state)
				4'b0000: begin
					done = 'b0;
					begin : sv2v_autoblock_2
						reg signed [31:0] i;
						for (i = 0; i < 6; i = i + 1)
							begin
								encoded_value_h[i] = 'b0;
								huff_tree[i][31-:9] = 'b0;
								huff_tree[i][22] = 1'b0;
								huff_tree[i][3-:2] = 'b0;
								huff_tree[i][21-:9] = 'b0;
								huff_tree[i][12-:9] = 'b0;
								huff_tree[i][1-:2] = 'b0;
							end
					end
					state <= 4'b0001;
				end
				4'b0001: state <= 4'b0010;
				4'b0010: begin
					count = 3;
					begin : sv2v_autoblock_3
						reg signed [31:0] i;
						for (i = 0; i < 3; i = i + 1)
							in_huff_tree[(2 - i) * 32+:32] = initial_node[(2 - i) * 32+:32];
					end
					state <= 4'b0011;
				end
				4'b0011: state <= 4'b0100;
				4'b0100: begin
					in_huff_tree[64+:32] = merged_node;
					in_huff_tree[0+:64] = out_huff_tree[0+:64];
					count = count - 1'b1;
					even_idx = count << 1'b1;
					odd_idx = even_idx + 1'b1;
					huff_tree[even_idx][31-:9] = out_huff_tree[127-:9];
					huff_tree[odd_idx][31-:9] = out_huff_tree[95-:9];
					huff_tree[even_idx][22] = out_huff_tree[114];
					huff_tree[odd_idx][22] = out_huff_tree[82];
					huff_tree[even_idx][21-:9] = out_huff_tree[113-:9];
					huff_tree[odd_idx][21-:9] = out_huff_tree[81-:9];
					huff_tree[even_idx][12-:9] = out_huff_tree[104-:9];
					huff_tree[odd_idx][12-:9] = out_huff_tree[72-:9];
					huff_tree[1][31-:9] = out_huff_tree[127-:9];
					huff_tree[1][22] = out_huff_tree[114];
					huff_tree[1][21-:9] = out_huff_tree[113-:9];
					huff_tree[1][12-:9] = out_huff_tree[104-:9];
					if (!(count[0] | count[1]))
						state <= 4'b0101;
					else
						state <= 4'b0011;
				end
				4'b0101: begin
					begin : sv2v_autoblock_4
						reg signed [31:0] l;
						for (l = 5; l > 1; l = l - 1)
							begin : sv2v_autoblock_5
								reg signed [31:0] n;
								for (n = 1; n < 6; n = n + 1)
									if ((huff_tree[n][21-:9] == huff_tree[l][31-:9]) || (huff_tree[n][12-:9] == huff_tree[l][31-:9]))
										huff_tree[l][3-:2] = n;
							end
					end
					state <= 4'b0110;
				end
				4'b0110: begin
					for (n = 2; n < 6; n = n + 1)
						huff_tree[n][1-:2] = huff_tree[huff_tree[n][3-:2]][1-:2] + 1'b1;
					state <= 4'b0111;
				end
				4'b0111: begin
					for (n = 2; n < 6; n = n + 1)
						begin
							encoded_value_l = encoded_value_h[huff_tree[n][3-:2]] << 1'b1;
							encoded_value_r = (encoded_value_h[huff_tree[n][3-:2]] << 1'b1) | 1'b1;
							is_n_odd = n[0];
							if (huff_tree[n][3-:2] != 1'b1)
								encoded_value_h[n] = (is_n_odd ? encoded_value_l : encoded_value_r);
							else if (huff_tree[n][3-:2] == 1'b1)
								encoded_value_h[n][0] = (is_n_odd ? 1'b0 : 1'b1);
						end
					state <= 4'b1000;
				end
				4'b1000: begin
					begin : sv2v_autoblock_6
						integer i;
						for (i = 2; i >= 0; i = i - 1)
							begin : sv2v_autoblock_7
								reg signed [31:0] n;
								for (n = 1; n < 6; n = n + 1)
									if (huff_tree[n][31-:9] == data_in[i * 8+:8]) begin
										encoded_mask[(2 - i) * 3+:3] = (1'b1 << huff_tree[n][1-:2]) - 1'b1;
										character[(2 - i) * 7+:7] = huff_tree[n][31-:9];
										encoded_value[(2 - i) * 3+:3] = encoded_value_h[n];
									end
							end
					end
					done = 1'b1;
				end
				default: state <= 4'b0000;
			endcase
	end
endmodule
module freq_calc (
	data_in,
	freq_in,
	node
);
	input wire [23:0] data_in;
	input wire [8:0] freq_in;
	output reg [95:0] node;
	always @(*) begin : sv2v_autoblock_1
		reg signed [31:0] i;
		for (i = 0; i < 3; i = i + 1)
			begin
				node[((2 - i) * 32) + 31-:9] = data_in[(2 - i) * 8+:8];
				node[((2 - i) * 32) + 22-:4] = freq_in[(2 - i) * 3+:3];
				node[((2 - i) * 32) + 17-:9] = 'b0;
				node[((2 - i) * 32) + 8-:9] = 'b0;
				node[((2 - i) * 32) + 18] = 1'b1;
			end
	end
endmodule
module node_sorter (
	clk,
	input_node,
	output_node
);
	input wire clk;
	input wire [95:0] input_node;
	output reg [95:0] output_node;
	reg [31:0] temp_node;
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
						if (((output_node[((2 - k) * 32) + 22-:4] == output_node[((2 - (k + 1)) * 32) + 22-:4]) && (output_node[((2 - k) * 32) + 31-:9] > output_node[((2 - (k + 1)) * 32) + 31-:9])) || (output_node[((2 - k) * 32) + 22-:4] > output_node[((2 - (k + 1)) * 32) + 22-:4])) begin
							temp_node = output_node[(2 - k) * 32+:32];
							output_node[(2 - k) * 32+:32] = output_node[(2 - (k + 1)) * 32+:32];
							output_node[(2 - (k + 1)) * 32+:32] = temp_node;
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
	input wire [31:0] min_node;
	input wire [31:0] second_min_node;
	output wire [31:0] merged_node;
	assign merged_node[31-:9] = min_node[31-:9] + second_min_node[31-:9];
	assign merged_node[22-:4] = min_node[22-:4] + second_min_node[22-:4];
	assign merged_node[17-:9] = min_node[31-:9];
	assign merged_node[8-:9] = second_min_node[31-:9];
	assign merged_node[18] = 1'b0;
endmodule
