# SNP filtering based on genetics of the trait

This script performs the following steps:
  1. Filters the parental VCF leaving the sites where at least one of the parents has GT "1/1".
  2. Compresses and indexes the filtered VCF.
  3. Extracts selected columns from the filtered VCF.
  4. Uses an embedded Python snippet to generate a list of positions to keep: both parents should be homozygous and different from each other.
  5. Converts these positions to BED format.
  6. Filters the VCF based on these positions.
  7. Compresses and indexes the complite VCF.
  8. Intersects the filtered parental VCF with the complite VCF.
  9. Excludes the specified parental sample from one of the intersecting VCFs. For running Qtlplot you need a vcf with the following structure: parent1-pool1-pool2
 10. (Optional) A qtlplot command is provided but commented out.

Usage: `./vcf_filtering_pipeline.sh <parent_vcf> <complite_vcf> <parent_sample_to_exclude> <output_folder>`

Example: `./vcf_filtering_pipeline.sh /path/to/parent1_parent2.vcf /path/to/complite.vcf parent1.bam /path/to/output_folder`

To run this script you will need two multisample VCFs: 
1. parent1-parent2 VCF (parent1_parent2.vcf)
2. parent1-parent2-pool1-pool2 VCF (complite.vcf)

The whole pipeline is aimed to prepare a suitable file for QtlSeq (https://github.com/YuSugihara/QTL-seq).
In the end you obtain a filtered parent1-pool1-pool2.vcf or a parent2-pool1-pool2.vcf file - this depends on your decision which parent to keep for the Qtl-plots.
Working with parental vcf file and then intersecting its filtered version with the full parent1-parent2-pool1-pool2 file is redundant.
It would be preferable to apply all filtering steps to the single parent1-parent2-pool1-pool2 file, but the current redundant workflow turned to be technically easier.

Do not forget to filter your files by quality and coverage of SNPs before you use this script.
