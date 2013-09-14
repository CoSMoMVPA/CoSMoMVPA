CoSMoMVPA
=========
A lightweight multi-variate pattern analysis (MVPA) toolbox in Matlab

Features
--------
- Matlab implementations of the most common types of Multi-Variate Pattern Analysis (MVPA) of functional magnetic resonance imaging (fMRI) data, including correlation analysis, classifiers, partitioning, cross-validation, representational similarity analysis, searchlights 
- Includes a variety of example scripts that show implementations of common MVP analyses.
- Comes with extended documentation and a variety of exercises showing how parts of common MVPA functions can be implemented.
- Free/Open Source Software (MIT License).

Requirements
------------
A working installation of Matlab

History
-----------
The CoSMoMVPA project was started as preparation for the 2013 [CoSMO workshop](http://www.compneurosci.com/CoSMo2013/) in Kingston, Ontario, Canada. 

Documentation
-------------
Documentation is hosted online (TODO).

For developers; building the documentation is currently only supported on Unix-like operating systems. To build the matlab output from the __/mvpa/run*.m__ files, run the __cosmo_publish_run_scripts__ script. To build the documentation in _/doc_, run _./build.sh_ html.

Installation instructions
-------------------------
The toolbox is avalaible from [github](https://github.com/CoSMoMVPA/CoSMoMVPA). Either clone the repository using git, or download and unzip the [zip archive](https://github.com/CoSMoMVPA/CoSMoMVPA/archive/master.zip). In Matlab, add the _/mvpa_ and _/externals_ folders (and their subfolders) to your path. 

To use the example data, download the [dataset archive]() (TODO) and put it in _/data_/.

Getting started
---------------
Please the documentation in _/doc_. To get an idea of the functionality of the toolbox, first download the example data, then have a look at the __mvpa/run*__ files.

Developers
----------
CoSMoMVPA is developed by:
- [Nikolaas N. Oosterhof](http://haxbylab.dartmouth.edu/ppl/nno.html).
- [Andrew C. Connolly](http://haxbylab.dartmouth.edu/ppl/andy.html).

Contact information is presented on our webpages.

Contribution guidelines
-----------------------
The preferred way to contribute is through github. More information will be added later.

Acknowledgements
----------------
- Gunnar Blohm and Sara Fabri: for the invitation to speak at the CoSMo 2013 workshop. This invitation formed the basis of this toolbox.
- Michael Hanke and Yaroslav Halchenko: for their work on PyMVPA, which inspired the semantics and data structure of datasets in CoSMoMVPA.

License
-------
The CoSMoMVPA Matlab code is available under the MIT License; documentation is available under the Creative Commons Attribution-ShareAlike 3.0 Unported license. . See the LICENSE file for details.
For licenses of external toolboxes, see the respective license files under _/externals/.

