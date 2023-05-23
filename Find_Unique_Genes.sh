#!/usr/bin/bash

# set the input file paths
file1="input1"
file2="input2"

# set the output file paths
diff1="diff1"
diff2="diff2"
common="common"

# compare the lists and output the differences to the respective files
comm -23 <(sort $file1) <(sort $file2) > $diff1
comm -13 <(sort $file1) <(sort $file2) > $diff2

# compare the differences to find the commonality
comm -12 <(sort $file1) <(sort $file2) > $common

# remove whitespaces
awk '{if (NF > 0) print}' $diff1 > $diff1.nowhitespace.txt
awk '{if (NF > 0) print}' $diff2 > $diff2.nowhitespace.txt
awk '{if (NF > 0) print}' $common > $common.nowhitespace.txt
