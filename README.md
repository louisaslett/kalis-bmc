# Sources and materials for paper:
## *kalis: A Modern Implementation of the Li & Stephens Model for Local Ancestry Inference in R*

**Abstract:**
> **Background**:
> Approximating the recent phylogeny of $N$ phased haplotypes at a set of variants along the genome is a core problem in modern population genomics and central to performing genome-wide screens for association, selection, introgression, and other signals.
> The Li & Stephens (LS) model provides a simple yet powerful hidden Markov model for inferring the recent ancestry at a given variant, represented as an $N \times N$ distance matrix based on posterior decodings.
> However, existing posterior decoding implementations for the LS model cannot scale to modern datasets with tens or hundreds of thousands of genomes.
>
> **Results**
> We provide a high-performance engine to compute the LS model, enabling users to rapidly develop a range of variant-specific ancestral inference pipelines on top, exposed via an easy to use package, kalis, in the statistical programming language R.
> kalis exploits both multi-core parallelism and modern CPU vector instruction sets to enable scaling to problem sizes that would previously have been prohibitively slow to work with.
> 
> **Conclusions**
> The resulting distance matrices accessible via kalis enable local ancestry, selection, and association studies in modern large scale genomic datasets.

This repository provides the sources and materials associated with the paper above, currently in submission at [BMC Bioinformatics](https://bmcbioinformatics.biomedcentral.com).
The paper describes the R package hosted in the repository [louisaslett/kalis](https://github.com/louisaslett/kalis).
See also the package website at [https://kalis.louisaslett.com/](https://kalis.louisaslett.com/).

- `benchmarks/` contains the full code used to build the system image and launch it on Amazon Web Services in order to produce the performance profiles shown in the paper.
  Note that it requires an AWS account and will need some manual setup of security groups and VPC to enable login to the server.
- `example/` contains the code used to provide the real world lactase persistence example, using the publicly available 1000 Genomes project data.
- `paper/` contains the LaTeX source code for the main paper, appendix (additional file 1), and user guide (additional file 2).
