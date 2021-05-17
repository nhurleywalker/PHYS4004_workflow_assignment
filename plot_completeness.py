#! /usr/bin/env python


import matplotlib
from matplotlib import pyplot
import argparse
import sys


def plot(infile, outfile,
         cores=1):
    """
    Read and input file and plot a completeness curve.
    A completeness curve is number of sources as a function of seed signal to noise ratio

    parameters
    ----------
    infile : str
        Filename to read input data from. Assumes format is csv with columns of seed,cores,nsrc
        And a single row which is a header

    outfile : str
        Output file name for saving the plot. eg plot.png

    cores : int
        The number of cores for which this plot is created.

    returns
    -------
    None
    """

    seed = []
    nsrc = []
    # read the csv file
    # select only the rows that have the required number of cores
    # remember that the first line a header line and should be skipped
    for line in open(infile).readlines():
        # extract the required data
        pass
    # sort the data as there is no guarantee that the rows are in order of 'seed'

    fig = pyplot.figure(figsize=(8,5))
    ax = fig.add_subplot(1,1,1)
    ## create a plot with x=seed, y=nsrc
    # ax.plot(x,y)
    ## put appropriate labels on the plot
    # ax.set_xlabel()
    # ax.set_ylabel()

    pyplot.savefig(outfile)
    return


if __name__=="__main__":
    # setup a nice user interface by using argparse
    parser = argparse.ArgumentParser(prefix_chars='-')
    group1 = parser.add_argument_group('Configuration Options')
    group1.add_argument('--infile', dest='infile',
                        help='Input file (csv format)')
    group1.add_argument("--outfile", dest='outfile', type=str,
                        help="Output file name.")
    group1.add_argument('--cores', dest='cores', type=int, default=1,
                        help='Number of cores for which the plot is made. Default=1.')

    params = parser.parse_args()

    # check that the input and output are both defined, and print help if not
    if None in (params.infile, params.outfile):
        parser.print_help()
        sys.exit()

    # do the plot
    plot(params.infile, params.outfile, params.cores)
