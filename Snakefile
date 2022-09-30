pepfile: "pep/pepconfig.yaml"
pepschema: "http://schema.databio.org/pep/2.1.0.yaml"

rule all:
    input:
        "results/py.done",
        "results/r.done"

rule py_rule:
    params:
        sample_table=pep.sample_table
    output:
        touch("results/py.done")
    script:
        "scripts/test-script.py"

rule r_rule:
    params:
        sample_table=pep.sample_table.to_dict(orient="list")        
    output:
        touch("results/r.done")
    script:
        "scripts/test-script.R"