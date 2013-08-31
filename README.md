CoSMoMVPA
=========

A lightweight multi-variate pattern analysis (MVPA) toolbox in Matlab

Description
-----------
CoSMOMVPA is a lightweight toolbox for Multi-Variate Pattern Analysis (MVPA) implemented in Matlab. In its current state it is mostly aimed at analysis of functional magnetic resonance imaging (fMRI) data. Features include dataset loading and writing from and to the NIFTI format, split-half correlation analysis, several classifiers, partitioning and cross-validation, representational analysis, and searchlights.

It has also an educational component: apart from providing the tools to do MVPA, it also provides a wide range of Matlab scripts that show runnable examples of particular analyses. It also comes with a series of exercises where users are challenged to (re-)implement parts of the current code, together with skeleton code ('fill in the missing lines') and full solutions. Running these examples requires an example [dataset](FIXME) used in a study by [Connolly et al](http://haxbylab.dartmouth.edu/publications/CGG+12.pdf).

The CoSMoMVPA project was started as preparation for the 2013 [CoSMO workshop](http://www.compneurosci.com/CoSMo2013/). It uses dataset semantics inspired by [PyMVPA](http://www.pymvpa.org).

Installation instructions
-------------------------
The toolbox is avalaible from [github](https://github.com/CoSMoMVPA/CoSMoMVPA). Either clone the repository using git, or download and unzip the [zip archive](https://github.com/CoSMoMVPA/CoSMoMVPA/archive/master.zip). In Matlab, add the _/mvpa_ and _/externals_ folders (and their subfolders) to your path. 

To use the example data, download the [dataset archive](FIXME) and put it in _/data_/.

Building the documentation is currently only supported on Unix-like operating systems. To build the matlab output from the __/mvpa/run*.m__ files, run the __cosmo_publish_run_scripts__ script. To build the documentation in _/doc_, run _./build.sh_ html.

Getting started
---------------
Please the documentation in _/doc_. To get an idea of the functionality of the toolbox, first download the example data, then have a look at the __mvpa/run*__ files.

Developers
----------
CoSMoMVPA was developed by:
- [Nikolaas N. Oosterhof](http://haxbylab.dartmouth.edu/ppl/nno.html).
- [Andrew C. Connolly](http://haxbylab.dartmouth.edu/ppl/andy.html).

Contact information is presented on our webpages.

Contribution guidelines
-----------------------
The preferred way to contribute is through github: clone the CoSMoMVPA repository using git, make your contributions (preferably in a new branch), then send us a pull request. Alternatively contact us by email.

(TODO: add more details on preferred matlab coding guidelines.)

Relation to other projects
--------------------------
- [PyMVPA](http://www.pymvpa.org) provided inspiration for the dataset structure and semantics. Our toolbox implements a small part of its functionality.
- [PRoNTo](http://www.mlnl.cs.ucl.ac.uk/pronto) is another Matlab MVPA toolbox, much wider in scope and provides a GUI. In contrast, our toolbox is more minimal and bare-bones, which we hope makes it easier to understand and modify. We also provide a range of examples and exerices for those who want to learn how typical MVP analyses are implemented.
- [Searchmight](http://minerva.csbmb.princeton.edu/searchmight) is aimed at searchlight analyses. Our toolbox does support such analyses, but also other types of analyses not covered by Searchmight.
- [Princeton MVPA toolbox](http://code.google.com/p/princeton-mvpa-toolbox/) is a sophisticated toolbox but (we think) harder to use, and is currently not under active development.

License
-------
The CoSMoMVPA code is available under the MIT License. See the License file for details.
For licenses of external toolboxes, see the respective license files under _/externals/.




