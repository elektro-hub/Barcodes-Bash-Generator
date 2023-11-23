#!/bin/bash

# Function to generate EAN barcode and add SKU as text
generate_barcode_with_sku() {
    # Generate EAN barcode with high resolution
    echo "$1" | barcode -e ean -u mm -g 160x80 -S -o "$1.ps"

    # Convert the barcode to a high-resolution PNG
    convert -density 1200 "$1.ps" -trim +repage -background white -gravity center "$1.temp.png"

    # Calculate the length of the SKU text
    sku_length=${#2}

    # Determine the appropriate font size based on the length of the SKU text
    if [ "$sku_length" -lt 10 ]; then
        pointsize=45
    elif [ "$sku_length" -lt 20 ]; then
        pointsize=40
    else
        pointsize=35
    fi

    # Add the SKU text directly below the barcode with the dynamically determined font size
    convert "$1.temp.png" -resize 300x \
            -background white -gravity north -extent 750x209 -geometry +0-500 \
            -fill black -gravity south -pointsize $pointsize -annotate +0+10 "$2" \
            "$1.png"

    convert "$1.png" -resize 1500x417 \
            -background white -gravity center -extent 1500x417 \
            "$1.final.png"
    
    # Clean up temporary files
    rm "$1.ps" "$1.temp.png"
}

# Create "single" and "side-by-side" folders
mkdir -p single
mkdir -p side-by-side

# Check if required commands are available
if ! command -v barcode &> /dev/null || ! command -v convert &> /dev/null; then
    echo "Error: barcode and ImageMagick must be installed."
    exit 1
fi

# Function to process a single EAN code and SKU pair
process_code_pair() {
    ean_code=$1
    sku_code=$2

    # Generate barcode with EAN and SKU
    generate_barcode_with_sku "$ean_code" "$sku_code"

    # Move and process images
    mv "$ean_code.final.png" single/
    convert "single/$ean_code.final.png" -bordercolor black -border 2x0 "single/$ean_code.final_with_border.png"
    convert "single/$ean_code.final_with_border.png" "single/$ean_code.final.png" +append "side-by-side/$ean_code.sidebyside.png"

    # Clean up remaining files
    rm "$ean_code.png"
    rm "single/$ean_code.final_with_border.png"

    echo "Bilder für $ean_code erfolgreich erstellt."
}

# Main loop
while true; do
    # Get EAN codes
    read -p "EAN Codes eingeben: " ean_input
    if [[ "$ean_input" == "exit" ]]; then
        break
    fi
    IFS=',' read -ra EAN_CODES <<< "$ean_input"

    # Get SKU codes
    read -p "SKU Codes eingeben: " sku_input
    IFS=',' read -ra SKU_CODES <<< "$sku_input"

    # Check if the number of EAN codes and SKU codes match
    if [ ${#EAN_CODES[@]} -ne ${#SKU_CODES[@]} ]; then
        echo "Error: EANS und SKUS stimmen nicht überein."
        continue
    fi

    # Process each EAN and SKU pair
    for (( i=0; i<${#EAN_CODES[@]}; i++ )); do
        process_code_pair "${EAN_CODES[$i]}" "${SKU_CODES[$i]}"
    done
done

echo "Exiting script."
