#!/bin/bash

if [ $# -ne 4 ]; then
    echo "Usage: $0 <parent_vcf> <complite_vcf> <parent_sample_to_exclude> <output_folder>"
    exit 1
fi

PARENT_VCF="$1"
complite_VCF="$2"
PARENT_EXCLUDE="$3"
OUTDIR="$4"

mkdir -p "$OUTDIR"

total_steps=9
current_step=0

update_progress() {
    current_step=$((current_step + 1))
    percent=$(( (100 * current_step) / total_steps ))
    bars=$(( (current_step * 50) / total_steps ))
    bar=$(printf "%0.s#" $(seq 1 $bars))
    spaces=$(printf "%0.s-" $(seq 1 $((50 - bars))))
    echo "Progress: [${bar}${spaces}] ${percent}% - $1"
}

bcftools filter -i 'GT="1/1"' "$PARENT_VCF" -o "$OUTDIR/parent1_parent2_hom.vcf"
update_progress "Filtered parental VCF for sites with GT 1/1."

bgzip -c "$OUTDIR/parent1_parent2_hom.vcf" > "$OUTDIR/parent1_parent2_hom.vcf.gz"
tabix -p vcf "$OUTDIR/parent1_parent2_hom.vcf.gz"
update_progress "Compressed and indexed the filtered parental VCF."

bcftools query -f '%CHROM\t%POS\t%REF,%ALT[\t%SAMPLE=%GT]\n' "$OUTDIR/parent1_parent2_hom.vcf.gz" > "$OUTDIR/selected_columns_parent1_parent2_hom.txt"
update_progress "Extracted selected columns from the filtered parental VCF."

python3 - << EOF
import os
infile = os.path.join("$OUTDIR", "selected_columns_parent1_parent2_hom.txt")
outfile = os.path.join("$OUTDIR", "positions_to_keep_parent1_parent2_hom.txt")
with open(infile, 'r') as fin, open(outfile, 'w') as fout:
    for line in fin:
        chrom, pos, alleles, sample1, sample2 = line.strip().split('\t')
        _, g1 = sample1.split('=')
        _, g2 = sample2.split('=')
        if not ((g1 == "1/1" and g2 == "1/1") or
                (g1 == "1/1" and (g2 == "0/1" or g2 == "1/0")) or
                (g2 == "1/1" and (g1 == "0/1" or g1 == "1/0"))):
            fout.write(f"{chrom}:{pos}\n")
EOF
update_progress "Generated list of positions to keep using Python."

awk 'BEGIN {FS=":"; OFS="\t"} {print $1, $2-1, $2}' "$OUTDIR/positions_to_keep_parent1_parent2_hom.txt" > "$OUTDIR/positions_to_keep_parent1_parent2_hom.bed"
update_progress "Created BED file from positions list."

bcftools view -R "$OUTDIR/positions_to_keep_parent1_parent2_hom.bed" "$OUTDIR/parent1_parent2_hom.vcf.gz" -o "$OUTDIR/parent1_parent2_hom_filtered.vcf.gz"
update_progress "Filtered VCF using BED file."

bgzip -c "$complite_VCF" > "$OUTDIR/complite.vcf.gz"
tabix -p vcf "$OUTDIR/complite.vcf.gz"
tabix -p vcf "$OUTDIR/parent1_parent2_hom_filtered.vcf.gz"
update_progress "Compressed and indexed the complite VCF and the parental VCF."

bcftools isec -n=+2 -p "$OUTDIR/intersecting_vcfs" "$OUTDIR/parent1_parent2_hom_filtered.vcf.gz" "$OUTDIR/complite.vcf.gz"
update_progress "Intersected filtered parental VCF with complite VCF."

bcftools view -Oz -s ^"${PARENT_EXCLUDE}" "$OUTDIR/intersecting_vcfs/0001.vcf" -o "$OUTDIR/parent2_pool1_pool2.vcf"
update_progress "Excluded parental sample from intersecting VCF."

echo "Pipeline complete. All output files are located in: $OUTDIR"
