#!/bin/bash

# Create directory for paper images
imgdir="out/img/paper_images"
mkdir -p $imgdir

# Copy images for paper
# Mode I images
cp out/mode-i_BBMaterial/post/view_1/plot_000399.png $imgdir/mode-i_BB.png
cp out/mode-i_OSBMaterial/post/view_1/plot_000399.png $imgdir/mode-i_OSB.png
cp out/mode-i_CRMaterial_ZEMSilling10/post/view_1/plot_000399.png $imgdir/mode-i_C_Silling10.png
cp out/mode-i_CRMaterial_ZEMSilling100/post/view_1/plot_000399.png $imgdir/mode-i_C_Silling100.png
cp out/mode-i_CRMaterial_ZEMWan/post/view_1/plot_000399.png $imgdir/mode-i_C_Wan.png
cp out/mode-i_RKCRMaterial/post/view_1/plot_000399.png $imgdir/mode-i_RKC.png
# BTT images
cp out/btt_BBMaterial/post/view_1/plot_000084.png $imgdir/btt_BB.png
cp out/btt_CRMaterial-ZEMSilling/post/view_1/plot_000076.png $imgdir/btt_C_Silling.png
cp out/btt_CRMaterial-ZEMWan/post/view_1/plot_000076.png $imgdir/btt_C_Wan.png
cp out/btt_RKCRMaterial/post/view_1/plot_000076.png $imgdir/btt_RKC.png