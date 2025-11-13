process DownloadReferenceGenome {
    output:
        tuple path("Homo_sapiens_assembly38.fasta"), path("Homo_sapiens_assembly38.fasta.fai")

    script:
        """
        wget -O Homo_sapiens_assembly38.fasta https://console.cloud.google.com/storage/browser/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta
        samtools faidx Homo_sapiens_assembly38.fasta
        """
}