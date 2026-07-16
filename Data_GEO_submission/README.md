# GEO Data Submission Guide

Submit high-throughput sequencing data to NCBI Gene Expression Omnibus (GEO).

## Overview

GEO is a public repository for functional genomics data. Submitting to GEO provides:
- Stable accession numbers for publication
- Public data sharing for reproducibility
- Private holding until manuscript publication (up to 4 years)
- Anonymous reviewer access to private records

**Timeline:** GEO accession numbers are typically approved within 5 business days.

## When to Use

**Use GEO when submitting:**
- RNA-seq, miRNA-seq
- ChIP-seq, ATAC-seq, HiC-seq
- Methyl-seq, bisulfite-seq
- Single-cell RNA-seq, CITE-seq
- Visium spatial transcriptomics
- NanoString GeoMx DSP (with FASTQ raw data)

**Do NOT use GEO for:**
- Whole genome sequencing (use SRA directly)
- Metagenomics (use SRA directly)
- Human controlled-access data (use dbGaP)
- Mass spectrometry data (use PRIDE or other proteomics repos)
- Transcript assemblies, resequencing

## Supported Data Types

| Assay Type | Raw Data Format | Processed Data Format |
|------------|-----------------|----------------------|
| Bulk RNA-seq | FASTQ.gz | counts (raw, FPKM, TPM) |
| miRNA-seq | FASTQ.gz | counts |
| ChIP-seq | FASTQ.gz | bigWig, bedGraph, narrowPeak |
| ATAC-seq | FASTQ.gz | bigWig, bedGraph, peaks |
| scRNA-seq | FASTQ.gz | MEX, H5/HDF5, or RDS |
| CITE-seq | FASTQ.gz | MEX + feature_reference.csv |
| Spatial (Visium) | FASTQ.gz | MEX + spatial images |
| Methyl-seq | FASTQ.gz | average beta values |

## File Requirements

### Raw Data (FASTQ)

| Requirement | Details |
|-------------|---------|
| Format | FASTQ only |
| Compression | gzip (.gz) or bzip2 (.bz2) only - **NO ZIP archives** |
| Max file size | 100 GB per file |
| Filenames | Alphanumeric, hyphens, underscores only (no spaces or special characters) |
| Paired-end | Must include complete sets (R1, R2, I1, I2 when applicable) |
| Demultiplexing | Demultiplexed for bulk; multiplexed OK for single-cell |

**Filename examples:**
```
Good: Sample1_S1_L001_R1_001.fastq.gz
Good: patient-001_RNA_R1.fastq.gz
Bad:  Sample 1 (RNA).fastq.gz  # spaces and special chars
Bad:  sample1.fastq.zip        # ZIP not accepted
```

### Processed Data

| Requirement | Details |
|-------------|---------|
| Content | Quantitative data (counts, abundances) - NOT just DE gene lists |
| Completeness | All features and all samples |
| Format | CSV, TSV, or assay-specific formats (see table above) |
| Compression | Recommended (.gz) |
| Features | Must be traceable via accession numbers or coordinates |
| Reference | Include genome assembly information |

**NOT acceptable as processed data:** BAM, SAM, BED alignment files

## Step-by-Step Submission Process

### Step 1: Prepare Your Files

Organize files into a submission folder:

```
my_geo_submission/
├── raw/
│   ├── Sample1_R1.fastq.gz
│   ├── Sample1_R2.fastq.gz
│   ├── Sample2_R1.fastq.gz
│   └── Sample2_R2.fastq.gz
└── processed/
    ├── counts.csv.gz
    └── metadata.csv.gz
```

### Step 2: Generate MD5 Checksums

Generate checksums for all files (used for transfer verification):

```bash
# On macOS
cd my_geo_submission
find . -type f \( -name "*.gz" -o -name "*.csv" \) -exec md5 {} \; > md5_checksums.txt

# On Linux
find . -type f \( -name "*.gz" -o -name "*.csv" \) -exec md5sum {} \; > md5_checksums.txt
```

Or use the provided script: `./scripts/generate_md5.sh /path/to/submission/folder`

### Step 3: Download and Fill Metadata Spreadsheet

1. Go to [GEO Submission Portal](https://www.ncbi.nlm.nih.gov/geo/info/seq.html)
2. Log in with NCBI account
3. Download the metadata spreadsheet template
4. Fill in all required fields (see Metadata Guide below)

A template is also available at [seq_template.xlsx](./seq_template.xlsx).

### Step 4: Upload Files via FTP

Get FTP credentials from the [GEO FTP page](https://www.ncbi.nlm.nih.gov/geo/info/submissionftp.html) (credentials change periodically).

**Using lftp (recommended):**

```bash
# Navigate to your local submission folder
cd /path/to/my_geo_submission

# Connect and upload
lftp ftp://geoftp:YOUR_PASSWORD@ftp-private.ncbi.nlm.nih.gov

# Inside lftp:
cd uploads/your.email@orcid_XXXXXX
mkdir my_submission
cd my_submission
mirror -R .
exit
```

**Using ncftp (Linux):**

```bash
ncftp -u geoftp -p YOUR_PASSWORD ftp-private.ncbi.nlm.nih.gov
set passive on
set so-bufsize 33554432
cd uploads/your.email@orcid_XXXXXX
put -R my_geo_submission
```

**Using FileZilla (GUI):**

1. Host: `ftp-private.ncbi.nlm.nih.gov`
2. Username: `geoftp`
3. Password: from GEO website
4. Navigate to `/uploads/your.email@orcid_XXXXXX`
5. Create folder and drag files

**Important:** Only upload raw and processed data files via FTP. Do NOT upload the metadata spreadsheet via FTP.

### Step 5: Submit Metadata via Web

1. Return to [GEO Submission Portal](https://www.ncbi.nlm.nih.gov/geo/info/seq.html)
2. Upload your completed metadata spreadsheet
3. Specify the FTP folder name where you uploaded files
4. Submit

### Step 6: Wait for Accession

- Expect response within 5 business days
- Check spam folder if no response
- GEO staff will email if corrections needed

## Metadata Spreadsheet Guide

### Key Sections

| Section | Required Fields |
|---------|-----------------|
| SERIES | Title, summary, overall design, contributors |
| SAMPLES | Sample name, organism, tissue/cell type, description |
| PROTOCOLS | Growth, treatment, extract, library construction |
| RAW FILES | Filename, file type, MD5 checksum |
| PROCESSED FILES | Filename, file type, genome build |

### Common Fields Explained

| Field | Description | Example |
|-------|-------------|---------|
| `title` | Descriptive name for the study | "RNA-seq of mouse liver under fasting" |
| `organism` | Species (use NCBI taxonomy) | Mus musculus |
| `molecule` | What was sequenced | total RNA, polyA RNA, genomic DNA |
| `library_strategy` | Sequencing method | RNA-Seq, ChIP-Seq, ATAC-seq |
| `library_source` | Source material | transcriptomic, genomic |
| `library_selection` | Selection method | cDNA, ChIP, CAGE |
| `instrument_model` | Sequencer used | Illumina NovaSeq 6000 |

### For Single-Cell Data

Additional requirements:
- `library_source`: "transcriptomic single cell"
- Cell-level processed data required
- For CITE-seq/multiome: include `feature_reference.csv`

### For Multi-omics (10X Genomics)

If submitting CITE-seq, Cell Hashing, or Multiome:
1. List each library type on separate rows (e.g., Sample1_GEX, Sample1_ADT)
2. Include `feature_reference.csv` with antibody/feature metadata:

```csv
id,name,read,pattern,sequence,feature_type
CD3,CD3_TotalSeqB,R2,5P(BC),AACAAGACCCTTGAG,Antibody Capture
CD4,CD4_TotalSeqB,R2,5P(BC),TGTTCCCGCTCAACT,Antibody Capture
```

## Pre-submission Checklist

Run through this checklist before uploading:

- [ ] All FASTQ files are gzip compressed (.fastq.gz)
- [ ] No ZIP archives (use gzip only)
- [ ] All filenames are alphanumeric (no spaces or special characters)
- [ ] Each file is under 100 GB
- [ ] Paired-end files have matching read counts
- [ ] MD5 checksums generated for all files
- [ ] Processed data includes all samples and features
- [ ] Processed data has gene/feature identifiers (not just row numbers)
- [ ] Metadata spreadsheet filenames match actual filenames exactly
- [ ] Reference genome/assembly specified
- [ ] For multi-omics: feature_reference.csv included

Use the validation script: `./scripts/validate_submission.sh /path/to/submission/folder`

## Troubleshooting

### Common Rejection Reasons

| Issue | Solution |
|-------|----------|
| ZIP file detected | Decompress and re-compress with gzip |
| Filename mismatch | Ensure spreadsheet names match exactly (case-sensitive) |
| Missing paired files | Include all R1/R2/I1/I2 files |
| Processed data incomplete | Include all samples, not just significant ones |
| Missing reference genome | Add genome build (e.g., GRCh38, mm10) to metadata |
| Duplicate filenames | Rename to unique names |
| Human data concerns | Ensure consent allows public release; otherwise use dbGaP |

### FTP Connection Issues

| Issue | Solution |
|-------|----------|
| Permission denied | Navigate to `/uploads/your_folder` first |
| Connection timeout | Enable passive mode; increase buffer size |
| Transfer fails | Check firewall settings; try different FTP client |

### No Response After 5 Days

1. Check spam/junk folder
2. Email geo@ncbi.nlm.nih.gov with your submission details
3. Do NOT cite accession numbers until officially approved

## Data Release Workflow

### Initial Submission

Data remains private by default. Specify a release date (up to 4 years from submission).

### Before Publication

- GEO sends reminder emails 10 days before scheduled release
- You can extend the hold date if needed

### After Publication

1. Log in to [GEO Submission Portal](https://www.ncbi.nlm.nih.gov/geo/submitter/)
2. Find your submission
3. Update release status to "Release immediately"
4. Add citation information (journal, DOI, PMID)

### Providing Reviewer Access

For anonymous reviewer access to private data:
1. Request a secure access token from GEO
2. Provide the token to the journal/reviewers
3. Reviewers can view data without logging in

## Directory Structure Example

```
my_geo_submission/
├── raw_data/
│   ├── Sample1_S1_L001_R1_001.fastq.gz
│   ├── Sample1_S1_L001_R2_001.fastq.gz
│   ├── Sample2_S1_L001_R1_001.fastq.gz
│   └── Sample2_S1_L001_R2_001.fastq.gz
├── processed_data/
│   ├── counts_raw.csv.gz
│   ├── counts_tpm.csv.gz
│   └── sample_metadata.csv.gz
└── md5_checksums.txt
```

![GEO Directory Structure](https://www.ncbi.nlm.nih.gov/geo/img/directory_structure_diagram.jpg)

## Useful Links

- [GEO Submission Portal](https://www.ncbi.nlm.nih.gov/geo/info/seq.html)
- [FTP Upload Instructions](https://www.ncbi.nlm.nih.gov/geo/info/submissionftp.html)
- [GEO FAQ](https://www.ncbi.nlm.nih.gov/geo/info/faq.html)
- [Update Existing Records](https://www.ncbi.nlm.nih.gov/geo/info/updating.html)
- [Human Subject Guidelines](https://www.ncbi.nlm.nih.gov/geo/info/human.html)

## Data Export Helper

For exporting Seurat scRNA-seq objects to GEO format, see [export_data.rmd](./export_data.rmd).

## Contact

- BMBL Lab: https://u.osu.edu/bmbl/
- Maintainer: Cankun Wang (cankun.wang@osumc.edu)
