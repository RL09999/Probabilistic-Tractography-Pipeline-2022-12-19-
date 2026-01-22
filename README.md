# Probabilistic-Tractography-Pipeline-2022-12-19-

This repository contains a streamlined pipeline for DTI (Diffusion Tensor Imaging) data processing, focusing on registration and probabilistic tractography using the **AAL atlas**.

---

## 🛠 Prerequisites

* **System**: Linux/Unix environment.
* **FSL**: [FSL v6.0.6](https://fsl.fmrib.ox.ac.uk/fsl/docs/install/linux.html) or higher.
* **Hardware**: A CUDA-capable GPU (required for `bedpostx_gpu` and `probtrackx2_gpu` acceleration).

---

## 📂 Data Requirements

Before running the scripts, ensure your data folder (e.g., `sub001/DTI1/`) contains the following files:

1. **DTI Data**: `data.nii.gz` (Pre-processed and **visually inspected** for artifacts/motion).
2. **FA Map**: `data.nii.gz_FA.nii.gz` (used for registration).
3. **Brain Mask**: `nodif_brain_mask.nii.gz` (diffusion space).
4. **Atlas**: `aal.nii.gz` (MNI standard space).

---

## 🚀 How to Use

### 1. Run the Processing Pipeline
The Bash script handles registration, mask creation, bedpostx estimation, and tractography.
```bash
# Give execution permission (if needed)
chmod +x dti_probtrackx_pipeline.sh

# Run the script
./dti_probtrackx_pipeline.sh
```

**Key outputs:**
* `masks/`: Contains registration matrices (.mat), warp fields, and AAL masks in diffusion space.
* `DTI.probtrackx2.seedXXX/`: Contains tracking results and connectivity stats for each of the 90 AAL regions.

### 2. Generate the Connectivity Matrix
Once the Bash script completes, use the MATLAB script to consolidate the results into a single connectivity matrix.

1. **Open MATALB** in the project directory.
2. **Run the script**: Execute ```generate_connectivity_matrix.m```
3. **Final Result**: ```ProbabilisticMatrix.txt``` (A 90x90 asymmetric matrix where rows represent seeds and columns represent targets). See ```Example of result figure.png```


