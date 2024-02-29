include { validateParameters; fromSamplesheet } from 'plugin/nf-validation'

process FASTP {
    publishDir params.outdir, mode:'copy', pattern: "*-fastp.html"

    input:
    tuple val(meta), path(reads)

    conda "bioconda::fastp=0.23.4"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastp:0.23.4--hadf994f_1' :
        'quay.io/biocontainers/fastp:0.23.4--hadf994f_1' }"

    output:
    tuple val(meta), path("${meta.id}-cleaned_{1,2}.fastq"), emit: reads
    tuple val(meta), path("*-fastp.html"), emit: report_html

    script:
    """
    fastp --detect_adapter_for_pe -l ${params.fastp_length} --in1 ${reads[0]} --in2 ${reads[1]} --html ${meta.id}-fastp.html --out1 ${meta.id}-cleaned_1.fastq --out2 ${meta.id}-cleaned_2.fastq
    """
}

process MEGAHIT {
    publishDir params.outdir, mode:'copy', pattern: "*-contigs.fasta"

    conda "bioconda::megahit=1.2.9"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/megahit:1.2.9--h43eeafb_4' :
        'quay.io/biocontainers/megahit:1.2.9--h43eeafb_4' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}-contigs.fasta"), emit: contigs

    script:
    """
    megahit -t $task.cpus -1 ${reads[0]} -2 ${reads[1]} -o megahit_out && cp megahit_out/final.contigs.fa ${meta.id}-contigs.fasta
    """
}

process QUAST {
    publishDir params.outdir, mode:'copy'

    conda "bioconda::quast=5.2.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/quast:5.2.0--py310pl5321h6cc9453_3' :
        'quay.io/biocontainers/quast:5.2.0--py310pl5321h6cc9453_3' }"

    input:
    tuple val(meta), path(contigs)

    output:
    tuple val(meta), path("${meta.id}-quast_results"), emit: quast_results

    script:
    """
    quast -t $task.cpus $contigs && mv quast_results ${meta.id}-quast_results
    """
}

workflow {
    validateParameters()

    Channel.fromSamplesheet("input")
           .map {meta, fastq_1, fastq_2 -> [meta, [fastq_1, fastq_2]]}
           .set { reads_ch }

    FASTP  ( reads_ch)

    MEGAHIT( FASTP.out.reads)

    QUAST  ( MEGAHIT.out.contigs)
}
