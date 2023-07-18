# Assembly Nextflow

This is an example pipeline for assembling a genome in nextflow. This pipeline makes use of the software **fastp**, **megahit**, and **quast**.

# Installation

To install this pipeline, please make sure you have nextflow installed. This can be accomplished with:

```bash
conda create --name nextflow nextflow
conda activate nextflow
```

Now, you can clone this repository:

```bash
git clone https://github.com/apetkau/assembly-nf.git
cd assembly-nf
```

# Running

To run the pipeline, please run:

```bash
nextflow run main.nf -profile singularity
```

Output files should be in `results/`.
