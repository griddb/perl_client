GridDB Perl Client

## Overview

GridDB Perl Client is developed using GridDB C Client and [SWIG](http://www.swig.org/) (Simplified Wrapper and Interface Generator).  

## Operating environment

Building of the library and execution of the sample programs have been checked in the following environment.

    OS:              CentOS 6.9(x64)
    SWIG:            3.0.12
    GCC:             4.4.7
    Perl:            5.26
    GridDB Server and C Client:   4.0 CE

## QuickStart
### Preparations

Install SWIG as below.

    $ wget https://sourceforge.net/projects/pcre/files/pcre/8.39/pcre-8.39.tar.gz
    $ tar xvfz pcre-8.39.tar.gz
    $ cd pcre-8.39
    $ ./configure
    $ make
    $ make install

    $ wget https://prdownloads.sourceforge.net/swig/swig-3.0.12.tar.gz
    $ tar xvfz swig-3.0.12.tar.gz
    $ cd swig-3.0.12
    $ ./configure
    $ make
    $ make install

If required, change INCLUDES_PERL path in Makefile.

Set LIBRARY_PATH. 

    export LIBRARY_PATH=$LIBRARY_PATH:<C client library file directory path>

### Build and Run 

    1. Execute the command on project directory.

    $ make

    2. Insert "use griddb_perl" in Perl.

### How to run sample

GridDB Server need to be started in advance.

    1. Set LD_LIBRARY_PATH and PERL5LIB

        export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:<C client library file directory path>

        export PERL5LIB=<installed directory path>

    2. The command to run sample

        $ perl sample/sample1.pl <GridDB notification address> <GridDB notification port>
            <GridDB cluster name> <GridDB user> <GridDB password>
          -->
          $VAR1 = [
              'name02',
              0,
              2,
              'ABCDEFGHIJ'
          ];

## Function

(available)
- STRING, BOOL, BYTE, SHORT, INTEGER, LONG, FLOAT, DOUBLE, TIMESTAMP, BLOB type for GridDB
- put single row, get row with key
- normal query, aggregation with TQL

(not available)
- Multi-Put/Get/Query (batch processing)
- GEOMETRY, Array type for GridDB
- timeseries compression
- timeseries-specific function like gsAggregateTimeSeries, gsQueryByTimeSeriesSampling in C client
- trigger, affinity

Please refer to the following files for more detailed information.  
- [Perl Client API Reference](https://griddb.github.io/perl_client/PerlAPIReference.htm)

Note:
1. The current API might be changed in the next version. e.g. ContainerInfo->new()

## Community

  * Issues  
    Use the GitHub issue function if you have any requests, questions, or bug reports. 
  * PullRequest  
    Use the GitHub pull request function if you want to contribute code.
    You'll need to agree GridDB Contributor License Agreement(CLA_rev1.1.pdf).
    By using the GitHub pull request function, you shall be deemed to have agreed to GridDB Contributor License Agreement.

## License
  
  GridDB Perl Client source license is Apache License, version 2.0.
