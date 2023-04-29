# huffman_encoder

Anusha Raghavendra
18-224/624 Spring 2023 Final Tapeout Project

## Overview

//Algorithm
1. Read the characters(leaf node) and their corresponding frequencies array
2. First sort the input node list, find 1st and 2nd minimum. If tied, sort according to the ascii value
3. Allocate them to huff_tree, assign only is_leaf_node, child nodes (not parent node)
4. Merge nodes--> create internal node- sort and then add to huff tree -repeat until only 1 node is left
5. Iterate until the root node 
6. Start from i=count-1, left_node=2i, right_node=2i+1 (i decrementing from count-1 to 0), where count is the number of unique character count
7. Traverse the entire array to assign the parent node and level in the binary tree
8. Traverse again to assign the encodings to each character

## How it Works

1.	This design primarily comprises of a module huff_encoder, which can take one character as an input(io_in[7:0]-ascii value of characters), its corresponding frequency(io_in[10:8]) and data enable signal(io_in[11]) in a serial fashion until all 3 characters are read and collected in a register. A state machine is created with DATA_COLLECT as reset state. In total, there are 7 states. Each state takes one or more clock cycles. Hence, output encodings along with the mask value will be available after certain clock cycles. Once the output is ready, io_out[8] is asserted to represent done signal. In the first cycle after output encodings are available, io_out[7:0] represents character, and in the second cycle after this, io[5:0] represents {output_mask, output_value}. This repeat until all the outputs are read out.  
2.	After reset is asserted down, FSM goes to DATA_COLLECT state. 
3.	2nd state would be NODE_CREATE state, where character and frequency array is sent to node_create module to create a node list containing node and its correspinding frequency each of node_t type. This module returns the initial node.
4.	Then it goes to 3rd state: SORT, where list of nodes is being fed as input to a node_sorter module. Output is sorted list as per their frequencies. In case of tie, it sorts according to their ascii values. This tie breaker logic differentiates the Huffman encodings.
5.	4th state is MERGE, where a module merge_nodes select the first and second minimum from the sorted list, and creates a new node with a frequency equal to the sum of their frequencies. Other fields in the struct are set accordingly such as right and left nodes, which holds the ascii values of the merged nodes. This newly created node is added to the node list 
6.	Steps 3 and 4 are repeated until only 1 node is left 
7.	State 5 is the BUILD_TREE, where Huffman tree (array of nodes of type huff_tree_node_t) is created.  
8.	State 6 is ENCODE, where it's traversing the tree to assign parent and level in Huffman tree
9.	It then goes to ENCODE_VALUE state, where tree is traversed again to assign encodings based on parent encodings and level
10.	Final state is SEND_OUTPUT, where it just extracts the encodings and mask value for those input characters in the order of character input and serially sends it out with out_valid signal in io_out[8] bit.


To add images, upload them into the repo and use the following format to embed them in markdown:

![](image1.png)

## Inputs/Outputs

(describe what each of the 12 input and 12 output pins are used for; )

(if you have any specific dependency on clock frequency; i.e. for visual effects or for an external interface, explain it here.)

## Hardware Peripherals

(if you have any external hardware peripherals such as buttons, LEDs, sensors, etc, please explain them here. otherwise, remove this section)

## Design Testing / Bringup

(explain how to test your design; if relevant, give examples of inputs and expected outputs)

(if you would like your design to be tested after integration but before tapeout, provide a Python script that uses the Debug Interface posted on canvas and explain here how to run the testing script)

## Media

(optionally include any photos or videos of your design in action)

## (anything else)

If there is anything else you would like to document about your project such as background information, design space exploration, future ideas, verification details, references, etc etc. please add it here. This template is meant to be a guideline, not an exact format that you're required to follow.
