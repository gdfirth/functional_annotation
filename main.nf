#!/usr/bin/env nextflow
nextflow.enable.dsl=2
// nextflow run main.nf --bed "../K-PDS/Marsico_OQs_K_PDS_combined_v10.bed" --gff "../TriTrypDB-64_TbruceiLister427_2018.gff" --tss "../mapped_features_TSS.gff" --genome "../tb427.genome"
workflow {
    if ( !params.gff || !params.bed || !params.tss || !params.genome ) {
        log.error "❌ You must provide an input GFF, BED, TSS, and genome file with --gff, --bed, --tss, and --genome"
        exit 1
    }

    gff_ch = Channel.fromPath(params.gff)
    bed_ch = Channel.fromPath(params.bed)
    tss_ch = Channel.fromPath(params.tss)
    genome_ch = Channel.fromPath(params.genome)

    // Annotate original peaks
    orig_anno = FUNC_ANNO(gff_ch, bed_ch, tss_ch)

    // Randomise peaks three times
    rand_peaks = RANDOMISE_PEAKS(bed_ch, genome_ch, gff_ch, tss_ch)


    // Collect all annotated peak files for fold enrichment
    FOLD_ENRICH(
        gff_ch,
        bed_ch,
        tss_ch,
        orig_anno.annotated_peaks,
        rand_peaks
    )
}

process RANDOMISE_PEAKS {
    tag "Randomise Peaks"
    conda "envs/env.yml"

    input:
    path(bed)
    path(genome)
    path(gff)
    path(tss)

    output:
    tuple path("annotated_random_peaks_1.bed"), path("annotated_random_peaks_2.bed"), path("annotated_random_peaks_3.bed"), emit: rand_peaks

    script:
    """
    bedtools shuffle -i ${bed} -g ${genome} > random_peaks_1.bed
    Rscript ${projectDir}/scripts/peak_annotate.R ${gff} ${tss} random_peaks_1.bed
    mv annotated_peaks.bed annotated_random_peaks_1.bed
    bedtools shuffle -i ${bed} -g ${genome} > random_peaks_2.bed
    Rscript ${projectDir}/scripts/peak_annotate.R ${gff} ${tss} random_peaks_2.bed
    mv annotated_peaks.bed annotated_random_peaks_2.bed
    bedtools shuffle -i ${bed} -g ${genome} > random_peaks_3.bed
    Rscript ${projectDir}/scripts/peak_annotate.R ${gff} ${tss} random_peaks_3.bed
    mv annotated_peaks.bed annotated_random_peaks_3.bed
    """
}

process FUNC_ANNO {
    tag "Functional Annotation - Original"
    conda "envs/env.yml"

    input:
    path gff
    path bed
    path tss

    output:
    path "annotated_peaks.bed", emit: annotated_peaks

    script:
    """
    Rscript ${projectDir}/scripts/peak_annotate.R ${gff} ${tss} ${bed}
    """
}

process FUNC_ANNO_RAND {
    tag "Functional Annotation - Random"
    conda "envs/env.yml"

    input:
    path(gff)
    tuple path(rand_bed1), path(rand_bed2), path(rand_bed3)
    path(tss)

    output:
    path "annotated_peaks_${rand_bed1.baseName}.bed", emit: annotated_peaks
    path "annotation_summary_${rand_bed1.baseName}.txt", emit: annotated_summary

    script:
    """
    """
}

process FOLD_ENRICH {
    tag "Fold Enrichment Calculation"
    conda "envs/env.yml"
    publishDir "${params.outdir ?: 'results'}", mode: 'copy'

    input:
    path gff
    path bed
    path tss
    path orig_annotated_peaks
    tuple path(rand_annotated_peaks1), path(rand_annotated_peaks2), path(rand_annotated_peaks3)

    output:
    path "fold_enrichment_results.txt", emit: fold_enrichment_results
    

    script:
    """
    #cat ${rand_annotated_peaks1}
    #cat ${rand_annotated_peaks2}
    #cat ${rand_annotated_peaks3}
    #cat ${orig_annotated_peaks}
    #awk '{print \$4}' ${orig_annotated_peaks} | sort | uniq -c | sort -nr > "actual_peaks.txt"
    #awk '{print \$4}' ${rand_annotated_peaks1} | sort | uniq -c | sort -nr > "random_peaks1.txt"
    #awk '{print \$4}' ${rand_annotated_peaks2} | sort | uniq -c | sort -nr > "random_peaks2.txt"
    #awk '{print \$4}' ${rand_annotated_peaks3} | sort | uniq -c | sort -nr > "random_peaks3.txt"
    python ${projectDir}/scripts/fold_enrichment.py ${orig_annotated_peaks} ${rand_annotated_peaks1} ${rand_annotated_peaks2} ${rand_annotated_peaks3}
    """
}