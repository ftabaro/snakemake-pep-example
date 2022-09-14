pepfile: "pep/pepconfig.yaml"
pepschema: "http://schema.databio.org/pep/2.1.0.yaml"

rule all:
    input:
        "results/all.done"

rule intermediate:
    params:
        sample_table=pep.sample_table
    output:
        touch("results/first.done")
    script:
        "scripts/test-script.py"

rule final:
    input:
        "results/first.done"
    params:
        sample_table=pep.sample_table.to_dict(orient="list")
    output:
        touch("results/all.done")
    script:
        "scripts/test-script.R"