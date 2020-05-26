#!/bin/bash

WORK_FOLDER=$(mktemp -d)
echo "Workfolder created: ${WORK_FOLDER}"
echo ""

#######################
# Generate white dice #
#######################
gen_dice() {
    DICE_STRING=$1
    OUTPUT_FOLDER=$2
    TMPFILE=$3
    FILENAME=$(echo "${OUTPUT_FOLDER}/${DICE_STRING}.pbm")

    rm -f ${TMPFILE}
    while IFS= read -n1 ID; do
        if [ -z $ID ]; then
            continue
        fi
        echo "0 0 0 0 0" >> ${TMPFILE}
        for i in {1..3}; do
            echo "0 $ID $ID $ID 0" >> ${TMPFILE}
        done
        echo "0 0 0 0 0" >> ${TMPFILE}
    done <<< "${DICE_STRING}"

    echo "P1" > ${FILENAME}
    echo "15 15" >> ${FILENAME}
    cat ${TMPFILE} | pr -3ts' ' >> ${FILENAME}
}

# The binary strings define which part of the dice is marked
# x0 x3 x6
# x1 x4 x7
# x2 x5 x8
DICE="
# Ordinary dice
000010000 # 1
001000100 # 2
001010100 # 3
101000101 # 4
101010101 # 5
111000111 # 6
# Flipped dice
100000001 # 2
100010001 # 3
101101101 # 6
"
# Remove comments and empty lines
DICE=$(echo "${DICE}" | grep -o '^[0-1]*' | sed '/^$/d')

gen_all() {
    OUTPUT_FOLDER=$1
    # Start generating dice
    TMPFILE=$(mktemp)
    while IFS= read -r DICE_STRING; do
        echo -e "- Generating $DICE_STRING... \c"
        gen_dice "$DICE_STRING" $OUTPUT_FOLDER $TMPFILE
        echo "OK"
    done <<< "$DICE"
    rm -f $TMPFILE
}

WHITE_PBM=${WORK_FOLDER}/pbm/white/
mkdir -p ${WHITE_PBM}
echo "Generating (white) .PBM dice to '${WHITE_PBM}'"
gen_all ${WHITE_PBM}
echo ""

############################
# Generate white dice PNGs #
############################
WHITE_PNG=${WORK_FOLDER}/png/white/
mkdir -p ${WHITE_PNG}
echo "Generating (white) .PNG dice to '${WHITE_PNG}'"
find ${WHITE_PBM} -printf '%P\n' | sed 's/\.[^.]*$//' | xargs -I{} convert ${WHITE_PBM}/{}.pbm png24:${WHITE_PNG}/{}.png
echo ""

############################
# Generate black dice PNGs #
############################
BLACK_PNG=${WORK_FOLDER}/png/black/
mkdir -p ${BLACK_PNG}
echo "Generating (black) .PNG dice to '${BLACK_PNG}'"
find ${WHITE_PNG} -printf '%P\n' | xargs -I{} convert ${WHITE_PNG}/{} -negate png24:${BLACK_PNG}/{}
echo ""

#######################
# Generate metapixels #
#######################
for color in white black; do
    METAPIXEL=${WORK_FOLDER}/metapixel/${color}/
    mkdir -p ${METAPIXEL}
    echo "Generating (${color}) metapixel to '${METAPIXEL}'"
    metapixel-prepare -width=15 -height=15 ${WORK_FOLDER}/png/${color} ${METAPIXEL}
    echo ""
    echo ""
done

METAPIXEL=${WORK_FOLDER}/metapixel/mixed/
mkdir -p ${METAPIXEL}
echo "Generating (mixed) metapixel to '${METAPIXEL}'"
metapixel-prepare -width=15 -height=15 --recurse ${WORK_FOLDER}/png/ ${METAPIXEL}
echo ""
echo ""

##########################
# Processing input image #
##########################
PIXEL_WIDTH=15
PIXEL_HEIGHT=15

INPUT_IMAGE=$1

DICE_WIDTH=$2
DICE_HEIGHT=$2

OUTPUT_FOLDER=$3

WIDTH=$(echo "${DICE_WIDTH} * ${PIXEL_WIDTH}" | bc)
HEIGHT=$(echo "${DICE_HEIGHT} * ${PIXEL_HEIGHT}" | bc)

mkdir -p ${OUTPUT_FOLDER}

echo "Generating scaled original to '${OUTPUT_FOLDER}/original.png'"
convert ${INPUT_IMAGE} -resize ${WIDTH}x${HEIGHT} png24:${OUTPUT_FOLDER}/original.png
echo ""

#################
# Run metapixel #
#################

METAPIXEL_FLAGS="--distance=0 --width=15 --height=15"
for color in black white mixed; do
    for metric in wavelet subpixel; do
        OUTPUT_NAME=${OUTPUT_FOLDER}/${color}_${metric}.png
        OUTPUT_GRID_NAME=${OUTPUT_FOLDER}/x_${color}_${metric}.png
        echo "Generating mosaic to '${OUTPUT_NAME}'"
        metapixel --library=${WORK_FOLDER}/metapixel/${color} --metapixel ${METAPIXEL_FLAGS} --metric=${metric} ${OUTPUT_FOLDER}/original.png ${OUTPUT_NAME}
        echo ""

        echo "Overlaying grid to '${OUTPUT_GRID_NAME}'"
        convert ${OUTPUT_NAME} -background yellow -crop ${PIXEL_WIDTH}x0 -splice 1x0 +append +repage -crop 0x${PIXEL_HEIGHT} -splice 0x1 -append -gravity south -splice 0x1 -gravity east -splice 1x0 ${OUTPUT_GRID_NAME}
        echo ""
    done
done

rm -rf ${WORK_FOLDER}
