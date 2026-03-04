process DownloadReferenceGenome {
    output:
        tuple path("Homo_sapiens_assembly38.fasta"), path("Homo_sapiens_assembly38.fasta.fai")

    script:
        """
        wget -O Homo_sapiens_assembly38.fasta https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.fasta
        wget -O Homo_sapiens_assembly38.fasta.fai https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0/Homo_sapiens_assembly38.fasta.fai
        """
}