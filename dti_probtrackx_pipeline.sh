#!/bin/bash

# ==============================================================================
# Script Name    : dti_probtrackx_pipeline.sh
# Description    : Automated pipeline for DTI preprocessing, bedpostx, and 
#                  probabilistic tractography using the AAL atlas.
# Author         : Jieru Liao (Ruby)
# Date           : 2022-02-19
# Version        : 1.0
# Usage          : bash dti_probtrackx_pipeline.sh
# ==============================================================================
# PREREQUISITES:
# 1. FSL (FMRIB Software Library) must be installed.
#    This script was developed and tested using FSL v6.0.6.
#    Installation guide: https://fsl.fmrib.ox.ac.uk/fsl/docs/install/linux.html
# INPUT DATA REQUIREMENTS:
# - Pre-processed DTI data in NIfTI format (.nii or .nii.gz).
# - **Crucial**: All input data must pass visual inspection for artifacts, 
#   signal dropout, or excessive head motion before running this script.
# - Required files per subject (e.g., sub001/DTI1/):
#   - data.nii.gz_FA.nii.gz : FA map.
#   - nodif_brain_mask.nii.gz: Brain mask in diffusion space.
#   - ../aal.nii.gz : AAL atlas in MNI standard space.
#
# OUTPUTS:
# - sub001/masks/        : Contains registration matrices (.mat), warp fields, 
#                          and 90 individual AAL seed/term masks in diffusion space.
# - sub001/DTI1.bedpostX/: Results from bedpostx fiber estimation.
# - sub001/DTI.probtrackx2.seedXXX/: Tracking results for each seed, including 
#                          fdt_paths and connectivity stats.
# ==============================================================================

# Ensure FSL is sourced (optional, depending on your cluster config)
# . /etc/fsl/fsl.sh

# Create directory for masks (storing seed points and registration files)
mkdir -p sub001/masks

# --- Step 1: Registration ---
# Perform one-step registration (MNI to Diffusion space)
# Note: Two-step registration via T1 structural image is also possible but requires skull-stripping.
flirt -ref $FSLDIR/data/standard/FSL_HCP1065_FA_1mm.nii.gz \
      -in sub001/DTI1/data.nii.gz_FA.nii.gz \
      -omat sub001/masks/diff2mni.mat

fnirt --in=sub001/DTI1/data.nii.gz_FA.nii.gz \
      --aff=sub001/masks/diff2mni.mat \
      --cout=sub001/masks/diff2mni_cwarp.nii.gz \
      --ref=$FSLDIR/data/standard/FSL_HCP1065_FA_1mm.nii.gz

# Invert the warp to transform from MNI to Diffusion space
invwarp -w sub001/masks/diff2mni_cwarp.nii.gz \
        -o sub001/masks/mni2diff_cwarp \
        -r sub001/DTI1/data.nii.gz_FA.nii.gz

# Apply the warp to the AAL atlas
applywarp -i ../aal.nii.gz \
          -r sub001/DTI1/data.nii.gz_FA.nii.gz \
          -o sub001/masks/aal_in_diff \
          -w sub001/masks/mni2diff_cwarp --interp=nn

# --- Step 2: Mask Preparation ---
# Split AAL atlas into 90 seed and term files (Example shown for the first ROI)
fslmaths sub001/masks/aal_in_diff.nii.gz -thr 1 -uthr 1 -bin sub001/masks/seed001
fslmaths sub001/masks/aal_in_diff.nii.gz -bin -sub sub001/masks/seed001 sub001/masks/term001

# Create a list of all seed files for target masks
ls sub001/masks/seed* > sub001/masks/Seed2Target.txt

# --- Step 3: BedpostX ---
# Check data integrity before running BedpostX
bedpostx_datacheck sub001/DTI1/ 
bedpostx_gpu sub001/DTI1/

# --- Step 4: Probabilistic Tractography ---
# Run probtrackx2 for seed001 (Parameters adapted from PANDA defaults)
probtrackx2_gpu -l -c 0.2 -S 1000 --steplength=0.5 -P 5000 \
    --stop=sub001/masks/term001.nii.gz \
    -x sub001/masks/seed001.nii.gz \
    --forcedir --opd --s2tastext \
    --targetmasks=sub001/masks/Seed2Target.txt \
    -s sub001/DTI1.bedpostX/merged \
    -m sub001/DTI1.bedpostX/nodif_brain_mask.nii.gz \
    --dir=sub001/DTI.probtrackx2.seed001

# --- Step 5: Post-processing & Results Organization ---
# Extract voxel counts and mean FDT values for connectivity matrix construction
fslstats sub001/masks/seed$f.nii.gz -V >> sub001/DTI.probtrackx2.seed$f/seed_Voxel_matrix.txt
fslstats -K sub001/masks/aal_in_diff.nii.gz \
         sub001/DTI.probtrackx2.seed$f/fdt_paths.nii.gz \
         -M -V > sub001/DTI.probtrackx2.seed$f/target_meanFDT_matrix.target_Voxel_matrix.txt

