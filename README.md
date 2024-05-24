# PHYS4004 workflow assignment 2024

For this assignment you will be constructing a workflow using Nextflow. Some of the work has already been done for you, so please use the templates in this repository as a starting point.


## The task

We want to create a workflow that will test the "completeness" or "recovery rate" of a program called [aegean](https://github.com/PaulHancock/Aegean).
To do this we have some simulated image of the sky (`synthetic_test.fits`), as well as a background (`synthetic_test_bkg.fits`) and noise (`synthetic_test_rms.fits`) map.
The *aegean* program will take the input image and compute the signal to noise of each pixel using: `SNR = (image - background)/noise`.
The user can then define regions of interest by setting a *seed* SNR, so that all pixels that are above the limit will be labeled as *signal* and all others will be considered *noise*.
Contiguous groups of signal pixels are called *islands* and each island is modeled as one or more 2D Gaussians, which are refered to as *sources*.
Once all the fitting has been completed *aegean* will output a table that lists the location and properties of each of the *sources* that were found.

On of the tests for *aegean* is to make sure that it finds all the expected number of sources, and that it will find the same number of sources no matter how many proccesses are being used in the fitting.
The workflow that we are making for this assignment will complete this test for us. 
In order to be thorough we will test many different combinations of seed SNR level and the number of cores used.
The simulated images include sources with an SNR of between 5 and 100. 


## Assignment work


### Part 1 - Initialisation
Normally we would run Nextflow from one of the head nodes (or login nodes) of Setonix, and let Nextflow submit jobs to the SLURM scheduler to manage system resources.
In order to provide a fast development loop for you, the tasks that are to be run are fairly light weight (few cores, low RAM, and run times of a few mins or less).
Due to the short amount of time taken to run most of these tasks we will be running Nextflow directly from a compute node.
To do this you should run:
```
> salloc -p work --account=courses0100 -t 6:00:00
salloc: Granted job allocation <jobid>
salloc: Waiting for resource configuration
salloc: Nodes <nid> are ready for job
> module load singularity/3.11.4-slurm
> module load nextflow/23.10.0
```
which will give you a 6hour interactive job on Setonix.
The workflow (when complete) should run start to finish in around 10 minutes.
[Remember to `logut` (or Ctrl+D) when you are done with the node to return the resources back to the pool].

To run Nextflow use the 'hpc' profile so that you run the various python codes within a container:
```
> nextflow -C nextflow.config run main.nf -profile hpc
```


1. Customise `main.nf` to use your own name/version/date,
2. Add a `workflow` wrapper to the initial part of the code, to call processes as you need them.
3. There are two initial channels defined, one for the number of cores, and one for the seed SNR ratio.
Create a new channel which combines these two using the "outer" product.
That is, if `a=[0,1]` and `b=[2,3]` the outer product of a and b would be `aXb = [[0,2],[0,3],[1,2],[1,3]]` (but not neccessarily in that order).
Hint: Look at the `combining operators` section of the [Nextflow documentation](https://www.nextflow.io/docs/latest/).
- Use `input_ch.view()` to check that your new channel contains the desired entries (note that the *order* isn't important, just the content).

### Part 2 - Interpretation

The first stage of the workflow is a process called `find` which will run the *aegean* source finding program on the simulated data.
The inputs to this process are the *seed* and *cores* that are to be used, as well as the images and background/noise files.
The seed/cores combination is passed via the `input_ch` stream that you created in Part 1.
The images and background files that we require are always the same but we still need to indicate to Nextflow that they need to be staged into the temporary working area.
Therefore we need to use a static or *ad hoc* channel for these.
1. Make sure your workflow process is sending the locations to the files to the `find` process so that the image/background/noise files are staged correctly.

    Once *aegean* has been run with each of the *seed*/*cores* combinations the resulting output files are collected together into one large file.
In order that we may work with only the data required, the `count` process produces some summary stats for later processing.

1. Complete the input statement for the `count` process so that instead of operating on a single file at a time, it will run a single instance of `count` using all the items in `files_ch`.

1. Inspect the `count` process and understand how the `shell` section works. You can do this by running Nextflow, moving into the relevant work directory and then looking at the (hidden) file `.command.sh`, and running the commands by hand in an interactive job.
Explain what the following Bash commands are doing:
    1. The `>` in `echo "seed,ncores,nsrc" > results.csv`
    1. The `>>` in `echo "${seed},${cores},${nsrc}" >> results.csv`
    1. The `|` in `cat ${f}  | wc -l`
    1. The difference between `$(<command>)` and `($(<command>))`
    1. `$(ls table*.csv)`
    1. `echo ${f}`
    1. `tr '_.' ' '`
    1. `awk '{print $2 " " $3}'`
    1. `cat ${f}`
    1. `wc -l`
    1. `echo "$(cat ${f}  | wc -l)-1" | bc -l`

### Part 3 - Development

1. Complete the final process called *plot*.
This process takes only one input (`results.csv`) and generates a plot of number of sources found as a function of the seed signal to noise ratio.
The script `plot_completeness.py` can do the plotting for you.
For this part of the assignment you should create the plot just for the case `cores=1`.
1. Once you have a version of the *plot* process will create plots for the case `cores=1`, expand this to create a new plot for each of the different cores values that are within the `results.csv` file.
The values for `cores` should be obtained by inspecting the `results.csv` file.
To avoid creating many small jobs we will do multiple plots within this one job in two ways:
   1. A bash `for` loop, to do the work in serial;
   1. The `xargs` command to run up to 4 copies of the plotting script at once.

### Part 4 - Execution
Now that you have a completed workflow that produces a few basic plots, we will now do a "full run".
Indicate that this is the final run by changing the tag for this run.
Eg: `nextflow run -C nextflow.confing main.nf -profile hpc --params.tag=final`
1. Modify the seed/cores channels so that they include many more values. Seed should run from 5 to 95 in steps of 5.
This can be done using `seed=Channel.from(5..95).filter{it%5==0}`. Cores should be `(1,2,4,7)`.

Note that before you do a full run you should make sure you have a "clean" work space so you might want to delete all the subdirectories within the `work/` directory.
Careful not to delete all your files in the process!

### Part 5 - Reporting
1. Create a `.zip` or `.tar` archive of the following files:
   - `main.nf`
   - `nextflow.config`
   - `final_report.html`
   - `final_timeline.html`
   - `results/results.csv`
   - `results/*.png`
   - The report requested below (.pdf format)

1. Please write a report based on the following template
   1. Interpretation: A **short** description of what each of the tasks do from 2.2.[i-xi]
   1. Development: A code snippet for the two versions of the plot script, one using a for loop, and one using xargs.
   1. Execution: 
      - A plot that was generated by your code for `cores=1` and a note about whether you saw any difference between the plots generated for the different number of cores.
      - A graph of the workflow (`final_dag.png`) to demonstrate that the workflow is being executed as intended.
   1. Analysis:
      - Review the `final_report.html` and comment on the resource usage for the three different tasks. What areas of improvement can you identify?
      
1. Submit your solutions via Blackboard.
 
