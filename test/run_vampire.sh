#!/bin/bash

VAMPIRE="/Users/kondylidou/Developer/Krympa/bin/vampire_mac"
INPUT_DIR="/Users/kondylidou/Developer/Taelja/test/input"
OUTPUT_DIR="/Users/kondylidou/Developer/Taelja/test/baseline"

mkdir -p "$OUTPUT_DIR"

for file in "$INPUT_DIR"/*.p; do
    [ -e "$file" ] || continue

    name="$(basename "$file" .p)"
    output="$OUTPUT_DIR/${name}.tstp"

    echo "Processing $name.p -> ${name}.tstp"

    "$VAMPIRE" \
        --proof tptp \
        --avatar off \
        "$file" \
        > "$output" 2>&1
done

echo "Done."