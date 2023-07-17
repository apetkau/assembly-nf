params.reads = "$baseDir/data/reads/*_{1,2}.fastq.gz"
params.outdir = "results"

process FASTP {
    publishDir params.outdir, mode:'copy', pattern: "*-fastp.html"

    input:
    tuple val(sample_id), path(reads)

    conda "bioconda::fastp=0.23.4"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastp:0.23.4--hadf994f_1' :
        'quay.io/biocontainers/fastp:0.23.4--hadf994f_1' }"

    output:
    tuple val(sample_id), path("cleaned_{1,2}.fastq"), emit: reads
    path("*-fastp.html"), emit: report_html

    script:
    """
    fastp --detect_adapter_for_pe --in1 ${reads[0]} --in2 ${reads[1]} --html ${sample_id}-fastp.html --out1 cleaned_1.fastq --out2 cleaned_2.fastq
    """
}

process MEGAHIT {
    publishDir params.outdir, mode:'copy', pattern: "*-contigs.fasta"

    conda "bioconda::megahit=1.2.9"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/megahit:1.2.9--h43eeafb_4' :
        'quay.io/biocontainers/megahit:1.2.9--h43eeafb_4' }"

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("${sample_id}-contigs.fasta"), emit: contigs

    script:
    """
    megahit -t $task.cpus -1 ${reads[0]} -2 ${reads[1]} -o megahit_out && cp megahit_out/final.contigs.fa ${sample_id}-contigs.fasta
    """
}

process QUAST {
    publishDir params.outdir, mode:'copy'

    conda "bioconda::quast=5.2.0"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/quast:5.2.0--py310pl5321h6cc9453_3' :
        'quay.io/biocontainers/quast:5.2.0--py310pl5321h6cc9453_3' }"

    input:
    tuple val(sample_id), path(contigs)

    output:
    path("${sample_id}-quast_results"), emit: quast_results

    script:
    """
    quast -t $task.cpus $contigs && mv quast_results ${sample_id}-quast_results
    """
}

workflow {
    def reads_ch = Channel.fromFilePairs(params.reads)

    FASTP  ( reads_ch)

    MEGAHIT( FASTP.out.reads)

    QUAST  ( MEGAHIT.out.contigs)
}
