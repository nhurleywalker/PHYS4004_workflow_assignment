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

seeds = Channel.of(5..25)
ncores = Channel.of(1,2)

// Create the "cross product" of our two channels into one channel of tuples
// if seeds/cores are (5,10) and (1,2) then this new channel should consist of
// (5,1), (5,2), (10,1), (10,2). Tip. Use input_ch.view() to print the channel
// contents before moving to the next step
//input_ch = 
input_ch = seeds.combine(ncores)

process find {

        input:
        tuple(val(seed), val(cores)) from input_ch
        // the following images are constant across all versions of this process
        // so just use a 'static' or 'ad hoc' channel
        path(image) from file(params.image)
        path(bkg) from file(params.bkg)
        path(rms) from file(params.rms)

        output:
        file('*.csv') into files_ch

        // indicate that this process should be allocated a specific number of cores
        cpus "${cores}"
        
        script:
        """
        aegean ${image} --background=${bkg} --noise=${rms} --table=out.csv --seedclip=${seed} --cores=${cores}
        mv out_comp.csv table_${seed}_${cores}.csv
        """
}

process count {

        input:
        // The input should be all the files provided by the 'find' process
        // path files from ? 
        path(files) from files_ch.collect()

        output:
        file('results.csv') into counted_ch

        // Since we are using bash variables a lot and no nextflow variables
        // we use "shell" instead of "script" so that bash variables don't have
        // to be escaped
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
        file('*.png') into final_ch

        cpus 4
        
        // currently this script creates a plot for cores=1
        // Write a bash script to identify what values of cores
        // exist in the input table, and then run the plotting
        // for each of these in parallel.
        // tail, tr, awk, uniq, xargs
        script:
        """
        tail -n+2 ${table} | tr ',' ' ' | awk '{print \$2}' | sort -u | xargs -n1 -I % -P4 \
        python ${baseDir}/plot_completeness.py --cores=% --infile=${table} --outfile=cores_%.png
        """
}