#!/bin/bash

################
# Prepare dice #
################

# Create black dice from white dice
rm -rf dice_in/black
mkdir -p dice_in/black
find dice_in/white -name '*.png' -printf '%P\n' | xargs -I{} convert dice_in/white/{} -negate png24:dice_in/black/{}

######################
# Prepare metapixels #
######################
PIXEL_WIDTH=15
PIXEL_HEIGHT=15

# Create metapixel sets for black and white
for color in black white; do
    rm -rf dice_out/${color}
    mkdir -p dice_out/${color}
    metapixel-prepare -width=15 -height=15 dice_in/${color} dice_out/${color}
done

# Create metapixel sets for mixed
rm -rf dice_out/mixed
mkdir -p dice_out/mixed
metapixel-prepare -width=15 -height=15 dice_in --recurse dice_out/mixed

#################
# Prepare input #
#################
INPUT_IMAGE=$1

DICE_WIDTH=$2
DICE_HEIGHT=$2

WIDTH=$(echo "${DICE_WIDTH} * ${PIXEL_WIDTH}" | bc)
HEIGHT=$(echo "${DICE_HEIGHT} * ${PIXEL_HEIGHT}" | bc)

rm -rf output
mkdir -p output

convert ${INPUT_IMAGE} -resize ${WIDTH}x${HEIGHT} png24:output/original.png

#################
# Run metapixel #
#################

METAPIXEL_FLAGS="-i=0 -q=0 --distance=0 --width=15 --height=15"
for color in black white mixed; do
    for metric in wavelet subpixel; do
        metapixel --library=dice_out/${color} --metapixel ${METAPIXEL_FLAGS} --metric=${metric} output/original.png output/${color}_${metric}.png
        convert output/${color}_${metric}.png -background yellow -crop ${PIXEL_WIDTH}x0 -splice 1x0 +append +repage -crop 0x${PIXEL_HEIGHT} -splice 0x1 -append -gravity south -splice 0x1 -gravity east -splice 1x0 output/x_${color}_${metric}.png
    done
done

