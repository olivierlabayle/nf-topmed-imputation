process DownloadReferenceGenome {
    output:
        tuple path("Homo_sapiens_assembly38.fasta"), path("Homo_sapiens_assembly38.fasta.fai")

    script:
        """
        wget -O Homo_sapiens_assembly38.fasta https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta
        wget -O Homo_sapiens_assembly38.fasta.fai https://storage.googleapis.com/genomics-public-data/resources/broad/hg38/v0/Homo_sapiens_assembly38.fasta.fai
        """
}