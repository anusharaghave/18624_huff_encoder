#!/bin/csh -f

cd /afs/ece.cmu.edu/usr/araghave/18624/huff_man/18624_huff_encoder/src

#This ENV is used to avoid overriding current script in next vcselab run 
setenv SNPS_VCSELAB_SCRIPT_NO_OVERRIDE  1

/afs/ece/support/synopsys/synopsys.release/T-Foundation/vcs/T-2022.06/linux64/bin/vcselab $* \
    -o \
    simv \
    -nobanner \

cd -

