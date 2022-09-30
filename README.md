# How to use the Portable Encapsulated Project standard in a Snakemake pipeline

The Portable Encapsulated Project (PEP) is an attempt to standardise sample sheets magament. From their [website](http://pep.databio.org/en/latest/):

> PEP, or Portable Encapsulated Projects, is a community effort to make sample metadata reusable.

Snakemake offers out-of-the-box support for this standard. This repo aims at showcasing PEP usage in a Snakemake pipeline.

## Step 1 - PEP configuration

PEP configuration is given in YAML format. The only other required piece of information is a sample sheet in CSV format.

```yaml
pep_version: 2.1.0
sample_table: "samples.csv"
```

The only mandatory column in the `samples.csv` file is `sample_name`.

```csv
sample_name
lane1Sample10_sequence.txt.gz
lane1Sample11_sequence.txt.gz
lane1Sample12_sequence.txt.gz
...
```
In this version the sample sheet is not very useful. In general we tend to have more columns, reporting useful information about samples. For example:

```csv
Type,sample_name,Read Type,Instrument Model,Barcode
single-end fastq,lane1Sample10_sequence.txt.gz,read_1,Illumina MiSeq,AGCCTATC
single-end fastq,lane1Sample11_sequence.txt.gz,read_1,Illumina MiSeq,TCATCTCC
single-end fastq,lane1Sample12_sequence.txt.gz,read_1,Illumina MiSeq,CCAGTATC
...
```
Above, in the example, the sample sheet is reporting that our three samples are generated from a Illumina MiSeq sequencer using single-end sequencing protocol and that each file represent the read 1. For each sample a barcode sequence is also reported. In addition, the sample sheet is reporting the same sample name exactly like the first example above.

### Amendments

A core feature of the PEP standard is represented by amendments. In the PEP config file, one can define a list of operations to be performed on the columns of the sample sheet. For example, one can build paths to input files or can define new columns deriving sample attributes from other column values:

```yaml
pep_version: 2.1.0
sample_table: "samples.csv"

sample_modifiers:
  append:
    file_path: reads
  derive:
    attributes: ["file_path"]
    sources:
      reads: "/some/custom/path/{sample_name}"
```

In the example above I am adding a new column to the sample sheet called `file_path` with a placeholder value (here `reads`), then I am deriving the the actual path by prepending `/some/custom/path` to the value of the `sample_name` column. The final sample sheet will look something like:

```csv
Type,sample_name,Read Type,Instrument Model,Barcode,file_path
single-end fastq,lane1Sample10_sequence.txt.gz,read_1,Illumina MiSeq,AGCCTATC,/some/custom/path/lane1Sample10_sequence.txt.gz
single-end fastq,lane1Sample11_sequence.txt.gz,read_1,Illumina MiSeq,TCATCTCC,/some/custom/path/lane1Sample11_sequence.txt.gz
single-end fastq,lane1Sample12_sequence.txt.gz,read_1,Illumina MiSeq,CCAGTATC,/some/custom/path/lane1Sample12_sequence.txt.gz
...
```
### PEP config validation

The PEP community provides tools to validate the PEP config file. Here I will use the `eido` command line tool to showcase this:

```bash
$ eido validate pepconfig.yaml -s http://schema.databio.org/pep/2.1.0.yaml
Detecting duplicate sample names ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100% 0:00:00
Validation successful
```

## Step 2 - Subsample sheets

It is quite commont to have to handle samples collected over multiple experiments either coming from different sources or time points. PEP can automatically merge them into a unique sample sheet, provided their format is consistent. In the PEP config file, one can add the `subsample_table` directive and specify a list of CSV files reporting info about samples. 

```yaml
pep_version: 2.1.0
sample_table: "samples.csv"
subsample_table: ["dataset1.csv", "dataset2.csv"]
```
Where `dataset1.csv` is:

```csv
Type,sample_name,Read Type,Instrument Model,Barcode
single-end fastq,lane1Sample19_sequence.txt.gz,read_1,Illumina MiSeq,CTGTACCA
single-end fastq,lane1Sample4_sequence.txt.gz,read_1,Illumina MiSeq,TACGGTCT
single-end fastq,lane1Sample6_sequence.txt.gz,read_1,Illumina MiSeq,CAGGTTCA
...
```

And `dataset2.csv` is:

```csv
Type,sample_name,Read Type,Instrument Model,Barcode
single-end fastq,lane159_sequence.txt.gz,read_1,Illumina MiSeq,TCCGATGG
single-end fastq,lane151_sequence.txt.gz,read_1,Illumina MiSeq,TCACTAAC
single-end fastq,lane155_sequence.txt.gz,read_1,Illumina MiSeq,ACAACCAA
...
```

In this case, the `samples.csv` file still have to report all the samples for the analysis, but one can resort to the minimal example given above (the first box). In other words, `samples.csv.` just has to report the `sample_names` of all the samples to analyse:

```csv
sample_name
lane1Sample10_sequence.txt.gz
lane1Sample11_sequence.txt.gz
lane1Sample12_sequence.txt.gz
...
lane122_sequence.txt.gz
lane141_sequence.txt.gz
lane142_sequence.txt.gz
...
```

One can assess the final sample sheet as computed by PEP with the `eido` command:

```bash
$ eido convert -f csv pepconfig.yaml 
Detecting duplicate sample names ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100% 0:00:00
Running plugin csv
sample_name,file_path,Type,Read Type,Instrument Model,Barcode
lane1Sample10_sequence.txt.gz,/some/custom/path/lane1Sample10_sequence.txt.gz,single-end fastq,read_1,Illumina MiSeq,AGCCTATC
lane1Sample11_sequence.txt.gz,/some/custom/path/lane1Sample11_sequence.txt.gz,single-end fastq,read_1,Illumina MiSeq,TCATCTCC
lane1Sample12_sequence.txt.gz,/some/custom/path/lane1Sample12_sequence.txt.
...
lane122_sequence.txt.gz,/some/custom/path/lane122_sequence.txt.gz,single-end fastq,read_1,Illumina MiSeq,ACTTCTGC
lane141_sequence.txt.gz,/some/custom/path/lane141_sequence.txt.gz,single-end fastq,read_1,Illumina MiSeq,TTAAGCAG
lane142_sequence.txt.gz,/some/custom/path/lane142_sequence.txt.gz,
...
Conversion successful
```

## Step 3 - Bring PEP into Snakemake

Next step is to use this sample sheet in a Snakemake pipeline. We will need to install two extra dependencies to have the PEP integration working:

```bash
# conda activate snakemake
pip install peppy eido
```

These two dependencies will allow Snakemake to perform the two operations showcased above: PEP validation and conversion.

With all these bits in place, we will need two directives in our Snakefile to trigger the PEP validation and conversion:

```yaml
# At the beginning of the Snakefile
pepfile: "pep/pepconfig.yaml"
pepschema: "http://schema.databio.org/pep/2.1.0.yaml"
```

At this point a new global object named `pep` will be available in our pipeline; `pep.sample_table` will contain a Pandas DataFrame holding the results of the conversion and all the metadata for all samples.

```python
# Snakefile
pepfile: "pep/pepconfig.yaml"
pepschema: "http://schema.databio.org/pep/2.1.0.yaml"

print(pep.sample_table)
```

will produce something like:

```bash
$ snakemake -j1
Detecting duplicate sample names ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 100% 0:00:00
                                                 sample_name  ... subsample_name
sample_name                                                   ...               
lane1Sample10_sequence.txt.gz  lane1Sample10_sequence.txt.gz  ...           [20]
lane1Sample11_sequence.txt.gz  lane1Sample11_sequence.txt.gz  ...           [28]
lane1Sample12_sequence.txt.gz  lane1Sample12_sequence.txt.gz  ...           [18]
lane1Sample13_sequence.txt.gz  lane1Sample13_sequence.txt.gz  ...           [23]
lane1Sample14_sequence.txt.gz  lane1Sample14_sequence.txt.gz  ...           [36]
...                                                      ...  ...            ...
lane176_sequence.txt.gz              lane176_sequence.txt.gz  ...            [4]
lane177_sequence.txt.gz              lane177_sequence.txt.gz  ...           [25]
lane178_sequence.txt.gz              lane178_sequence.txt.gz  ...            [7]
lane179_sequence.txt.gz              lane179_sequence.txt.gz  ...            [5]
lane180_sequence.txt.gz              lane180_sequence.txt.gz  ...           [39]

[78 rows x 7 columns]
```

## Step 4 - Consume PEP sample sheet in rules

Next step, of course, is to use this sample sheet in a Snakemake rule. The idea is to pass the Pandas DataFrame (or a subset of it) to rules via the `params` directive.

### Python

With Python-based rules this comes very natural:

```python
rule py_rule:
    params:
        sample_table=pep.sample_table
    output:
        touch("results/py.done")
    script:
        "scripts/test-script.py"
```

Where `scripts/test-script.py` is a silly script:

```python
print(snakemake.params.sample_table)
```

### R

Sharing a Pandas DataFrame to a R script is slightly more involved because there is no direct conversion method between DataFrame objects and R data.frame. Therefore, we need to resort to an intermediate object before being able to consume the sample sheet in a R script. Let's break this down. The Snakemake rule:

```python
rule r_rule:
    params:
        sample_table=pep.sample_table.to_dict(orient="list")        
    output:
        touch("results/r.done")
    script:
        "scripts/test-script.R"
```

Here, in the `params` section, we are using the `Pandas.DataFrame.to_dict` method to cast the sample sheet to a Python dictionary. The `orient` parameter tells to convert each column to a list. The result of this operation will look something like this:

```python
{'Barcode': [['AGCCTATC'],
             ['TCATCTCC'],
             ['CCAGTATC'], ....],
 'Instrument Model': [['Illumina MiSeq'],
                      ['Illumina MiSeq'],
                      ['Illumina MiSeq'], ...],
 'Read Type': [['read_1'],
               ['read_1'],
               ['read_1'], ... ],
 'Type': [['single-end fastq'],
          ['single-end fastq'],
          ['single-end fastq'], ... ],
 'file_path': ['/some/custom/path/lane1Sample10_sequence.txt.gz',
               '/some/custom/path/lane1Sample11_sequence.txt.gz',
               '/some/custom/path/lane1Sample12_sequence.txt.gz', ... ],
 'sample_name': ['lane1Sample10_sequence.txt.gz',
                 'lane1Sample11_sequence.txt.gz',
                 'lane1Sample12_sequence.txt.gz', ... ],
 'subsample_name': [['20'],
                    ['28'],
                    ['18'], ... ]}
```

In the example above, the `pep.sample_table` DataFrame was converted to a dictionary with each column name as key, each column value collected in a list and stored as dictionary value. This object can be passed into a R script as-is and casted back to a data.frame like so:

```R
sample_table <- as.data.frame(snakemake@params[["sample_table"]]
```
Which produces something like:
```
                    sample_name                                       file_path
1 lane1Sample10_sequence.txt.gz /some/custom/path/lane1Sample10_sequence.txt.gz
2 lane1Sample11_sequence.txt.gz /some/custom/path/lane1Sample11_sequence.txt.gz
3 lane1Sample12_sequence.txt.gz /some/custom/path/lane1Sample12_sequence.txt.gz
4 lane1Sample13_sequence.txt.gz /some/custom/path/lane1Sample13_sequence.txt.gz
5 lane1Sample14_sequence.txt.gz /some/custom/path/lane1Sample14_sequence.txt.gz
6 lane1Sample15_sequence.txt.gz /some/custom/path/lane1Sample15_sequence.txt.gz
              Type Read.Type Instrument.Model  Barcode subsample_name
1 single-end fastq    read_1   Illumina MiSeq AGCCTATC             20
2 single-end fastq    read_1   Illumina MiSeq TCATCTCC             28
3 single-end fastq    read_1   Illumina MiSeq CCAGTATC             18
4 single-end fastq    read_1   Illumina MiSeq TTGCGAGA             23
5 single-end fastq    read_1   Illumina MiSeq GAACGAAG             36
6 single-end fastq    read_1   Illumina MiSeq CGAATTGC             26

```

## Conclusion

The Portable Encapsulated Project is a powerful method to standardize experimental metadata. It provides a simple API to edit sample sheets on the fly. From the analysis pipelines perspective it provides a complete separation of concerns between metadata management and analysis. This is useful to isolate the two scopes and increases portability.

Here I showcased the setup and utilization of PEP in Snakemake and how to pass the resulting object into Python and R scripts. I also showed a few basic PEP amendments, the PEP validation operation and command line converstion to CSV.