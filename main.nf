#! /usr/bin/env nextflow

version='0.1'
date='today'
author="Paul Hancock" // Change to your name

log.info """\
         PHYS4004 workflow assignment
         ============================
         version      : ${version} - ${date}
         author       : ${author}
         --
         run as       : ${workflow.commandLine}
         config files : ${workflow.configFiles}
         container    : ${workflow.containerEngine}:${workflow.container}
         """
         .stripIndent()

seeds = Channel.of(5,10)
ncores = Channel.of(1,2)

// Create the "cross product" of our two channels
input_ch = seeds.combine(ncores)

process find {

        input:
        tuple(val(seed), val(cores)) from input_ch
        path(image) from file(params.image)
        path(bkg) from file(params.bkg)
        path(rms) from file(params.rms)

        output:
        file('*.csv') into files_ch

        echo true

        cpus "${cores}"
        
        script:
        """
        aegean ${image} --background=${bkg} --noise=${rms} --table=out.csv --seedclip=${seed} --cores=${cores}
        mv out_comp.csv table_${seed}_${cores}.csv
        """
}

process count {
        input:
        path(files) from files_ch.collect()

        output:
        file('results.csv') into counted_ch

        echo true
        
        shell:
        '''
        echo "seed,ncores,nsrc" > results.csv
        for f in $(ls table*.csv); do
          seed_cores=($(echo ${f} | tr '_.' ' ' | awk '{print $2 " " $3}'))
          seed=${seed_cores[0]}
          cores=${seed_cores[1]}
          nsrc=$(echo "$(cat ${f}  | wc -l)-1" | bc -l)
          echo "${seed},${cores},${nsrc}" >> results.csv
        done
        '''
}


process plot {
        input:
        path(table) from counted_ch

        output:
        file('plot.png') into final_ch

        script:
        """
        python plot_completeness.py --cores=1 --infile=${table} --outfile=plot.png
        """
}