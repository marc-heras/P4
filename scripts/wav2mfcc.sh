#!/bin/bash

# Make pipeline return code the last non-zero one or zero if all the commands return zero.
set -o pipefail

## \file
## \TODO This file implements a very trivial feature extraction; use it as a template for other front ends.
## 
## Please, read SPTK documentation and some papers in order to implement more advanced front ends.

# Base name for temporary files
base=/tmp/$(basename $0).$$ 

# Ensure cleanup of temporary files on exit
trap cleanup EXIT
cleanup() {
   \rm -f $base.*
}

if [[ $# != 8 ]]; then
   echo "$0 lpc_order cepstrum_order input.wav output.mfcc"
   exit 1
fi

mfcc_order=$1
channel_order=$2
window_type=$3
prem_coef=$4
sampling_rate=$5
lift_coef=$6
inputfile=$7
outputfile=$8

UBUNTU_SPTK=1
if [[ $UBUNTU_SPTK == 1 ]]; then
   # In case you install SPTK using debian package (apt-get)
   X2X="sptk x2x"
   FRAME="sptk frame"
   WINDOW="sptk window"
   LPC="sptk lpc"
   LPC2C="sptk lpc2c"
   MFCC="sptk mfcc"
else
   # or install SPTK building it from its source
   X2X="x2x"
   FRAME="frame"
   WINDOW="window"
   LPC="lpc"
   LPC2C="lpc2c"
   MFCC="mfcc"
fi

# Main command for feature extration
sox $inputfile -t raw -e signed -b 16 - | $X2X +sf | $FRAME -l 240 -p 80 | $WINDOW -l 240 -L 240 |
	$MFCC -l 180 -m $mfcc_order -n $channel_order -w $window_type -a $prem_coef -s $sampling_rate -c $lift_coef > $base.mfcc || exit 1
   

# Our array files need a header with the number of cols and rows:
ncol=$((mfcc_order)) #mfcc p --> mc(1) mc(2) ... mc(p)
nrow=`$X2X +fa < $base.mfcc | wc -l | perl -ne 'print $_/'$ncol', "\n";'`

# Build fmatrix file by placing nrow and ncol in front, and the data after them
echo $nrow $ncol | $X2X +aI > $outputfile
cat $base.mfcc >> $outputfile
