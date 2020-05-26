#!/bin/bash

rm -rf output
mkdir -p output

# Create black dice from white dice
for color in black; do
    rm -rf dice_in/${color}/no_border
    mkdir -p dice_in/${color}/no_border
    find dice_in/${color}/no_border -name '*.png' -printf '%P\n' | xargs -I{} convert dice_in/${color}/no_border/{} -negate png24:dice_in/${color}/no_border/{}
done

# Create bordered dice from black and white dice
for color in black white; do
    rm -rf dice_in/${color}/border
    mkdir -p dice_in/${color}/border
    find dice_in/${color}/no_border -name '*.png' -printf '%P\n' | xargs -I{} convert dice_in/${color}/no_border/{} -fuzz 10% -fill ${color} -opaque "#FF0000" png24:dice_in/${color}/border/{}
done

for color in black white; do
    for border in border no_border; do
        rm -rf dice_out/${color}/${border}
        mkdir -p dice_out/${color}/${border}
        metapixel-prepare -width=15 -height=15 dice_in/${color}/${border} dice_out/${color}/${border}
    done
done

exit
# metapixel-prepare -width=15 -height=15 -recurse dice_in/ dice_out/black_and_white

DICE_WIDTH=$1
DICE_HEIGHT=$1

PIXEL_WIDTH=15
PIXEL_HEIGHT=15

WIDTH=$(echo "${DICE_WIDTH} * ${PIXEL_WIDTH}" | bc)
HEIGHT=$(echo "${DICE_HEIGHT} * ${PIXEL_HEIGHT}" | bc)

convert input.png -resize ${WIDTH}x${HEIGHT} png24:output/original.png

convert input.png -resize ${DICE_WIDTH}x${DICE_HEIGHT} png24:input-tiny.png
convert input-tiny.png -alpha off -colorspace sRGB +matte -scale 1500% -negate dpat_symbols.gif -virtual-pixel tile -fx 'u[floor(17.9999*u)+1]' output/magic.png

METAPIXEL_FLAGS="-i=0 -q=0 --distance=0 --width=15 --height=15"

metapixel --library=dice_out/white --metapixel ${METAPIXEL_FLAGS} --metric=wavelet output/original.png output/wave_white.png
metapixel --library=dice_out/white --metapixel ${METAPIXEL_FLAGS} --metric=subpixel output/original.png output/subpixel_white.png

metapixel --library=dice_out/black --metapixel ${METAPIXEL_FLAGS} --metric=wavelet output/original.png output/wave_black.png
metapixel --library=dice_out/black --metapixel ${METAPIXEL_FLAGS} --metric=subpixel output/original.png output/subpixel_black.png

metapixel --library=dice_out/black_and_white --metapixel ${METAPIXEL_FLAGS} --metric=wavelet output/original.png output/wave_black_and_white.png
metapixel --library=dice_out/black_and_white --metapixel ${METAPIXEL_FLAGS} --metric=subpixel output/original.png output/subpixel_black_and_white.png
