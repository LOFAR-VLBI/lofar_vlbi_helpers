#!/bin/bash

# Input CSV file
input_file=$1

# Number of entries per chunk
chunk_size=10

# Output file prefix
output_prefix="chunk"

# Get the header from the input file
header=$(head -n 1 "$input_file")

# Initialize chunk counter
chunk_counter=1

# Initialize line counter
line_counter=0

# Create the first chunk file and add the header
output_file="${output_prefix}_${chunk_counter}.csv"
echo "$header" > "$output_file"

# Read the input file line by line, skipping the header
awk 'NR > 1 { print }' "$input_file" | while read -r line; do
  # Increment the line counter
  ((line_counter++))

  # If the line counter exceeds the chunk size, start a new chunk
  if ((line_counter > chunk_size)); then
    # Reset the line counter
    line_counter=1

    # Increment the chunk counter
    ((chunk_counter++))

    # Create a new chunk file and add the header
    output_file="${output_prefix}_${chunk_counter}.csv"
    echo "$header" > "$output_file"
  fi

  # Append the line to the current chunk file
  echo "$line" >> "$output_file"
done