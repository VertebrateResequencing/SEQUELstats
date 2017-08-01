# SEQUELstats: Plots for PacBio SEQUEL QC

<br>

## Dependencies

**SEQUELstats** uses `samtools` (v1.4.1) for processing the SEQUEL BAM files. The pipeline itself is mainly written in `bash`, `awk`, `perl`, and `R`:

 * GNU bash (v4.2.25(1)-release)
 * GNU Awk (v3.1.8)
 * Perl (v5.16.2)
 * R (v3.0.0)

In addition, the R script makes use of the `RColorBrewer` package.

> **NOTE:**
> <br>
> _While the `SEQUELstats.sh` script makes use of **IBM Platform LSF Standard 9.1.3.0** for parallel processing of BAM files, the actual pipeline will run on any machine fulfilling the above-mentioned requirements. Hence, it is possible to generate the required folder structure and manually run the pipeline per SMRT cell._

<br>

## Introduction

**SEQUELstats** uses as input a set of PacBio BAM files (both, the **subreads** and **scraps** file per SMRTcell) as provided by the **SMRT-Link** software for **SEQUEL** sequencing runs.

The sequence header for those BAM files has to use the following format:

_**`^m\d+_\d+_\d+/\d+/\d+_\d+$`**_

_(e.g. "m54097\_170223\_195514/4784691/0\_7327")_

BAM files are provided as two "file-of-filenames" (one for **subreads** and one for **scraps**, each containing the absolute paths to the BAMs) that have to be in the same order (i.e. BAM files for each SMRTcell have to be on the same line in both files). The pipeline will then perform four steps per SMRTcell before generating the plots:

 * **_STEP_01_**: Extracts the necessary information for analysis from the **subreads** and **scraps** BAM file per SMRTcell
 * **_STEP_02_**: Preprocesses the extracted data and reconstructs the original ZMW read for each ZMW
 * **_STEP_03_**: Analyses the reconstructed ZMW reads and separates the reads into three data sets
 * **_STEP_04_**: Computes stats for the sets and generates analysis files for plotting in R

<br>

The three data sets generated for each SMRTcell are:

| Set                                                                      | Description                                                                             |
|:-------------------------------------------------------------------------|:----------------------------------------------------------------------------------------|
| **Hn**<br>("High quality region: **negative**")                          | Basecaller couldn't find a region in the ZMW read it would consider 'proper' sequence   |
| **HpSn**<br>("High quality region: **positive**; Subread: **negative**") | A good ZMW read interval was found but for some reason the sequence is considered 'bad' |
| **HpSp**<br>("High quality region: **positive**; Subread: **positive**") | Fully useful data                                                                       |

> _The first two types are classified by PacBio as useless and hence stored in the **scraps** file together with removed adapters and barcodes. For information about the content of the **scraps** file check [here](http://pacbiofileformats.readthedocs.io/en/3.0/BAM.html#how-to-annotate-scrap-reads "How to annotate scrap reads?")_

<br>

The generated stats output files are :

| File type    | Data set(s) | Description                                                                          |
|:-------------|:-----------:|:-------------------------------------------------------------------------------------|
| **\*.stats** | **[ALL]**   | No. of reads produced, No. of bases in ZR/PR/SR, Mean/Median/N50 for SR/PR, ZOR, PSR |
| **\*.hist**  | **HpSp**    | histogram of SR/PR length (LSR only )                                                |
| **\*.aCnt**  | **HpSp**    | List of LSRs (length per LSR) flanked by only one adapter                            |
| **\*.lFlg**  | **HpSp**    | List of LSRs (length per LSR) flanked by adapter on both sides                       |

> _**ZR**="ZMW read"_  
> _**PR**="Polymerase read"_  
> _**SR**/**LSR**="Subread"/"Longest subread"_  
> _**ZOR**="ZMW occupancy ratio" (i.e. how many of the ZMWs in the SMRTcell contained at least one DNA fragment for sequencing. Values >0.5 usually indicate overloading)_  
> _**PSR**="Polymerase read to Subread ratio" (for assebmly a PSR=1 would be ideal as in that case the fragment would have been read only once without reaching the end)_  

<br>

Based on these files seven plots are generated:

 * **"[SAMPLE_NAME].SMRT_cell.efficiency.png"**  
	PSR vs. ZOR plot (one dot/SMRTcell). All dots on the right border just underneath the 0.5 line would be optimal for assembly
 * **"[SAMPLE_NAME].SMRT_cell.raw_output.png"**  
	Read length stats ("Median"=red/white, "Mean"=black, "N50"=black/white) vs. SMRTcell yield (based on polymerase reads, one line per SMRTcell). PacBio advertises SEQUEL SMRTcells with 5-8GB of data with polymerase read N50 of >=20kb
 * **"[SAMPLE_NAME].SMRT_cell.processed_output.png"**  
	Read length stats vs. SMRTcell yield (same as above but this time using only the LSR)
 * **"[SAMPLE_NAME].seq_run.yield_and_efficiency.png"**  
	Amount of sequence per SMRTcell in Hn ("LQ"), HpSn ("MQ"), and HpSp ("HQ") sets. "HQS" = sum of PR in HQ, "LSR" = sum of LSR in HQ
 * **"[SAMPLE_NAME].Polymerase_and_subread.length_profiles.png"**  
	Histogram of polymerase reads and subreads per SMRTcell
 * **"[SAMPLE_NAME].estimated_lib_size_distribution.png"**  
	Fragment length distribution in library estimated from LSR flanked by adapters on both sides
 * **"[SAMPLE_NAME].estimated_lib_size_distribution.full_data.png"**  
	Same as above but also using LSRs with just one adapter

<br>

## Installation

Get the code by typing

```sh
git clone git@github.com:VertebrateResequencing/SEQUELstats.git
```

<br>

Before one can run the pipeline, two files in the **SEQUELstats** repository directory need to be edited:

* `SEQUELstats.sh`:

  * Set the **`$SEQUEL_RSCRIPT`** variable to the absolute path of the `Rscript` binary (needed to execute the R script)
  * Set the **`$SEQUEL_STATS_path`** variable to the location of the **SEQUELstats** repository directory (or any other directory that holds the **SEQUELstats** files).

* `SEQUEL_pipe.sh`:

  * Set the **`$SEQUEL_SAMTOOLS`** variable to the absolute path of the `samtools` binary
  * Set the **`$SEQUEL_STATS_path`** variable to the location of the **SEQUELstats** repository directory (or any other directory that holds the **SEQUELstats** files).

<br>

## Run

Once everything is installed and configured correctly, running the actual pipeline is very simple. All you need to specify are:

 * The abolute path to a "file-of-filenames" of SEQUEL **subread** BAM files
 * The abolute path to a "file-of-filenames" of SEQUEL **scraps** BAM files
 * A directory (absolute path) for the pipeline to work in
 * A sample name / species tag (e.g. "fAnaTes1")

For example:

```sh
./SEQUELstats.sh /my_bams/fAnaTes1/fAnaTes1.subread.BAM.fofn /my_bams/fAnaTes1/fAnaTes1.scraps.BAM.fofn /my_fastas/fAnaTes1/stats fAnaTes1
```
