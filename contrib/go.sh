#!/bin/bash

URL=http://1stpreschurch.org/
START=`cat START`
WORKDIR=w
ALLFILES=files.txt

echo Serial Number Start: $START

cd $WORKDIR || exit

. ../geom

# clean
rm -f qr.png qr[0-9].png foo.png $ALLFILES

# exit on any error
set -e
set -x

# pages:
i=20

while [ $i -gt 0 ] ; do
    j=6
    while [ $j -gt 0 ] ; do
        n=$((START+j))
        rm -f qr.png
        qrencode -o qr.png ${n}:${URL}
        convert -resize 200x200 qr.png qr${j}.png
        rm -f qr.png
        j=$((j-1))
    done

    SERIAL1=$((START+1))
    SERIAL2=$((START+2))
    SERIAL3=$((START+3))
    SERIAL4=$((START+4))
    SERIAL5=$((START+5))
    SERIAL6=$((START+6))

    convert ../wed_dinner_voucher.png -pointsize 45 -gravity NorthWest \
        -annotate $SG1 $SERIAL1 \
        -annotate $SG2 $SERIAL2 \
        -annotate $SG3 $SERIAL3 \
        -annotate $SG4 $SERIAL4 \
        -annotate $SG5 $SERIAL5 \
        -annotate $SG6 $SERIAL6 foo.png
    convert foo.png -gravity NorthWest \
        -draw "image Over $QRG1 0,0 qr1.png" \
        -draw "image Over $QRG2 0,0 qr2.png" \
        -draw "image Over $QRG3 0,0 qr3.png" \
        -draw "image Over $QRG4 0,0 qr4.png" \
        -draw "image Over $QRG5 0,0 qr5.png" \
        -draw "image Over $QRG6 0,0 qr6.png" ${SERIAL1}.png

    START=$((START+6))

    pngtopnm ${SERIAL1}.png | pnmtops | ps2pdf - ${SERIAL1}.pdf
    echo ${SERIAL1}.pdf >> $ALLFILES

    # clean
    rm -f qr.png qr[0-9].png foo.png

    i=$((i-1))
done

echo -n $START > START
pdfmerge `cat $ALLFILES` > tickets.pdf
