.. _contribute: 

============================
Information for contributors
============================

We would be very happy to receive contributions!

You don't have to be a Matlab_ programmer. Useful *code* contributions are very much appreciated, but improved documentation, ideas on how our web site can be made prettier, or other ideas are also valued highly.

If you are not a Matlab_ programmer but would to contribute or suggest improvements on the documentation or examples, please contact_ us (this assumes you are at least as uncomfortable using git_ as using Matlab_, which is a reasonable assumption if you are not a Matlab_ programmer).

.. contents::
    :depth: 2


.. _`file_locations_and_naming_conventions`:

Directory locations and naming conventions
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Meta - naming conventions in the documentation
++++++++++++++++++++++++++++++++++++++++++++++
- Path names are `Unix-like`_-based; ``/`` is the path separation character, rather than ``\`` used on Windows platforms.
- Directories have ``/`` as the last character, and are relative to the directory where ``CoSMoMVPA`` resides.
- Sometimes ``${a_name}`` is used, this indicates that `a_name` is a meta-syntactic variable. 


Setting the Matlab_ path
++++++++++++++++++++++++
To use ``CoSMoMVPA`` functionality, it is recommended to:

- add the ``mvpa/`` directory to the Matlab_ path.
- also add ``externals/`` and its subdirectories to the Matlab_ path.
- do *not* add ``examples/`` or ``tests`` to the Matlab_ path. 
    + To run examples, ``cd`` to ``examples/`` and run scripts from there.
    + To run unit tests, ``cd`` to ``tests/`` and run ``run_tests`` from there (this requires the xUnit_ framework).

Organization of files and directories
+++++++++++++++++++++++++++++++++++++

- Core ``CoSMoMVPA`` Matlab functions are in ``mvpa/``. File names should match the pattern ``cosmo_*.m``.
- Runnable Matlab example scripts are in ``examples/``. File names should match the pattern ``run_*.m`` or ``demo_*.m``.
- Unit tests are in ``tests/``. File names should match the pattern ``test_*.m`` for unit tests, and any other prefix for helper functionality.
- External libraries are in ``external/${library}/``.
- Documentation is in ``doc/source/``:
    + Documentation files have the ``.rst`` extension and are formatted as reStructuredText_.
    + Exercises have the prefix ``ex_``.
    + Other documentation files, unless automatically generated (see 'build system' below), should not have the prefix ``cosmo_`` or ``run_``, as running ``make clean`` in ``doc/`` will remove them.
    + Other file types, such as images, are stored in ``doc/source/_static/``.
    + Generated matlab output files, using the ``publish`` functionality in ``mvpa/cosmo_publish_run_scripts`` (for developers only), are stored in ``doc/source/_static/publish/``.
- Datasets will be stored in ``doc/source/_static/datasets/`` [TODO].

==========================================
Information for contributing *programmers*
==========================================

The remainder of this section is for those experienced in **programming**; it describes how others can make code contributions, explains how and where different parts of the toolbox are stored, and provides some developer guidelines. If in doubt, or if you have questions or comments, do not hesitate to contact_ us.

.. _contact: contact.html


.. _`code_development`:

Code development
^^^^^^^^^^^^^^^^

Contributing using git
++++++++++++++++++++++

The git_ distributed version control system is used for code development. It has several advantages over just downloading the `zip archive`_:
    + a distributed workflow: multiple people can work on the code simultaneously, and almost always their changes can be merged without conflicts. In the unlikely event of merge conflicts (when multiple people have changed the same code), these conflicts are resolved easly.
    + keeping track of individual contributions. Through git_ it is possible to see every change made, by anybody. It provides functionality similar to a time-machine, but then tagging: every change is annotated (see below). This allows one to see what was changed when, and undo unwanted changes back, if necessary.
    + code sharing on multiple computers: everyone has their own copy of the code, and can merge changes made by others.
    + maintaining multiple versions: through *branching* one can create multiple copies of the code, each which its own new features. This is very useful for new experimental features or bug-fixing without affecting the *prestine* master code. Once changes are considered ready for the master repository, they can be merged easily.

To get started with git:
    + set up a working installation of git_ (see `installing git`_).
    + make an account on github_, if you have not done so.
    + on the github_ project page, `fork the repository`_, and follow the instructions there. 
    + get a local copy of your forked repository: run ``git clone https://github.com/${your_name}/CoSMoMVPA.git``.
    + change to the directory: ``cd CoSMoMVPA``.
    + tell git about the `offical` release: ``git remote add official https://github.com/CoSMoMVPA/CoSMoMVPA.git``.
    + to update your repository with the latest official code, first make sure you are on master (``git checkout master``), then run ``git pull official master``.s
    + to add a new feature or provide a bugfix:

        - start a new branch: ``git checkout -b _tent/${new_feature}`` or ``git checkout -b _bf/${bugfix}``. 
        - make the desired changes, then commit them. `See below for details`.
        - push these changes to *your* github_ account: ``git push origin _tent/${new_feature}`` or ``git push origin _bf/${bugfix}``.
        -  on the github page, send a pull request against the master of ``CoSMoMVPA/CoSMoMVPA``. We'll get back to you to review and discuss the code. Once the code is ready for the official master it will be merged. You should receive notifications by email when the code is discussed or merged.
        - if you want go back to using code from the original master, run ``git checkout master``.

      Keep in mind that your master is supposed to contain working, runnable code. Branching in ``git`` is cheap; for experimentation please use this feature.

There are many great resources on using git_ on the web; a detailed explanation is beyond the scope of this documentation. 

.. _`installing git`: http://git-scm.com/book/en/Getting-Started-Installing-Git
.. _`fork the repository`: https://help.github.com/articles/fork-a-repo


Notes on committing
+++++++++++++++++++
- Please review your changes before commiting them. Useful commands are ``git status`` and ``git diff``.
- Do *not* use ``git -a``; instead manually add the (changes to) files individually. Preferably commits should be atomic, that is change just one feature.  For example if you changed a file at two places by (1) improving the documentation and (2) refactoring code used internally, then preferably you should make two commits. Using the tags below these could be ``DOC: ...`` and ``RF: ...``.
    + To add a new file, run ``git add ${filename}``.
    + To commit changes to a file, run ``git add -i``, then press 'p' (for 'patch'), indicate which files to patch, and press 'y' or 'n' for each meaningful 'atomic' change.- To view the history of commits, ``gitk`` is useful.
- Use the following tags (inspired by PyMVPA_) for commits:

    + ``BF``: Bugfix. Preferably this comes also with a unit test (i.e., ``BF+TST``) that checks whether the bug was indeed fixed.
    + ``BK``: Breaks existing functionality, or the signature of functions (changes in the number, or the meaning, of input and output arguments).
    + ``BLD``: Changes in the build system.
    + ``BIG``: Major change. Please use together with another tag.
    + ``CLN``: Code cleanup. ``SML`` can be omitted.
    + ``CTB``: Contribution from someone else who did not use ``git`` (for example, sent an email to the developers with new functionality that was considered useful). If someone using ``git`` uses this contribution, please also add a text like '``based on contribution from Jon Doe (jon@doe.org)``'.
    + ``STD``: Change to adhere better to coding standards. ``SML`` can be omitted.
    + ``DOC``: Change in documentation *of matlab code* (in ``examples/``, ``mvpa/``, ``tests/``).
    + ``EXC``: Change in exercises. This could go together with ``WEB`` or ``DOC``, and/or ``RUN``.
    + ``LNC``: Indicates that the contributor permits distribution of his changes using the applicable license(s) of CoSMoMVPA. Only needed for a person's first contribution; after the first contribution this permission is assumed. If you made several commits but the first did not contain this tag, just make a new commit containing the text '``LNC: applies to previous commits``'.
    + ``LZY``: 'Apologies for being lazy here but cannot be bothered to describe the changes in detail'. Acceptable in exceptional cases, including after *n* hours of continuous coding, when *n* is large; or when presenting a workshop on CoSMoMVPA_ the very next day (these are not mutually exclusive). If you know what your are doing this can go together with the ``-a`` option in ``git``.
    + ``MSC``: Miscellaneous changes, not covered by any of the other tags.     
    + ``NF``: New feature.
    + ``OPT``: Optimalization. It should be used when the new code runs faster or uses less memory.
    + ``RF``: Refactoring (changes in functions that do not affect their external behaviour).
    + ``RUN``: Change in runnable example scripts (in ``examples/``).
    + ``SML``: Minor change. Can be without an explanation of what was changed.  Please use together with another tag.

    + ``TST``: Change in test functions (in ``test/``).
    + ``WEB``: Changes affecting web site content (either documentation in ``.rst`` files, or other files such as images).

    Using these tags allows others to quickly see what *kind of* changes were made, and to generate summary reports on the kind of changes.

    Please describe what changes you made. The tags don't have to name which files were changed, as git_ takes care of that.

    Tags can be combined, as it may occur that multiple tags apply; use the ``+``-character to concatenate them.

    Examples:
    
    + ``git commit -m 'ENH: support two-dimensional cell arrays as feature attributes'``
    + ``git commit -m 'RF: build a lookup table mapping all voxels to those in the dataset``
    + ``git commit -m 'BF+TST: throw an error if partitions are not balanced; added unit test'``
    + ``git commit -m 'DOC+SML: fixed a typo'``
    + ``git commit -am LZY`` [others can see you were lazy; *to be used in special circumstances only*]

.. _`build_system`:

Build system
^^^^^^^^^^^^
The build system is used to generate documentation for the web site (or local use). 

- Matlab files do not require building.
- Documentation is built as follows:
    + all Matlab files in ``mvpa/`` and ``examples/`` are converted to reStructuredText_ format using the Python_ script ``matlab2rst.py`` in ``source/``. This script generates three reStructuredText_  versions of all Matlab functions and example scripts:
        - Full contents (no suffix), containing the full source code.
        - Header contents (suffix ``_hdr``), containing only the header (i.e. the first line and every subsequent line until the first line that does not start with ``%`` (note: line continuation, explained below, is currently *not* supported).
        - Skeleton contents (suffix ``_skl``), containing a skeleton of the source code. In the skeleton version, lines between a starting line ``% >@@>`` and ending line ``% <@@<`` is replaced by a text saying ``%%%% Your code comes here %%%%``. Skeleton files are intended for exercises.  
    + Both ``.txt`` files (with the raw contents preceded by an ``include`` statement) and ``.rst`` files (with a title and label) are generated; the latter contain ``include`` statements to include the former. 
    + the ``Makefile`` in ``source/``, when used through ``make html``, uses the ``mat2rst.py`` to generate reStructuredText_ Matlab files and then uses Sphinx_ to convert these files to html.
- The ``build.sh`` script builds the documentation and datasets.

**Note:** building the documentation, as described in the previous points, is currently supported on `Unix-like`_ systems only, and require additional dependencies (see download_).

.. _download: download.html

- The  ``mvpa/cosmo_publish_run_scripts.m`` function generates the output from all the runnable examples in ``examples/`` as html files and puts them in ``doc/source/_static/publish/``. This function is used to produce output for the web site. 

.. _`matlab code guidelines`:

Matlab code guidelines
^^^^^^^^^^^^^^^^^^^^^^
The following are guidelines, intended to improve:

+ consistency in code layout across contributers, so that the final result is more consistent.
+ readability, so that less time is spent in understanding how the code works or what it does. 
+ performance, so that execution time or memory usage is reduced.

**Note**: None of these guidelines are set in stone. Try to use common sense when considering not to follow them. Indeed, for each guideline there may be a good reason to deviate from it.

- Try to keep line lengths limited to 80 characters. Use line continuation (``...`` at the very end of the line) to spread a long expression over multiple lines.
    **bad:**

    .. code-block:: matlab

        my_output_data=my_awesome_function(first_argument, second_argument, third_argument, fourth_argument, fifth_argument, sixth_argument);

    **good:**

    .. code-block:: matlab

        my_output_data=my_awesome_function(first_argument, second_argument,...
                                           third_argument, fourth_argument,...
                                           fifth_argument, sixth_argument);

    (Yes, we break this rule occasionely.)


- Indentation is 4 spaces, and should be used for `if-else-end`, `while` and `function` blocks. Expressions of the form ``if expr``, ``else``, ``elseif expr``, ``var=function(var)``, ``while expr``, and ``end`` should be on a single line, except for very short statements that either set a default value for an input argument or raise an exception. 
    **bad:**

    .. code-block:: matlab

        if a>0
        if b>0, c=1;
                else
            d=1; end
        end

    .. code-block:: matlab

       function y=plus_two(x)
        y=x+2;

    .. code-block:: matlab

        if my_awesome_function(some_input, more_input)>100, the_array_value(:)=42; else other_array_value(:)=31; end

    **acceptable:**

    .. code-block:: matlab
    
        if nargin<2 || isempty(more_input), more_input=42; end

    .. code-block:: matlab
        
        if nsamples~=ntrain, error('Size mismatch: %d ~= %d', nsamples, ntrain); end

    **good:**

    .. code-block:: matlab    

        if my_awesome_function(some_input, more_input)>100
            the_array_value(:)=42; 
        else 
            other_array_value(:)=31; 
        end

    .. code-block:: matlab

        if a>0
            if b>0
                c=1;
            else
                d=1;
            end
        end

    .. code-block:: matlab

      function y=plus_two(x)
            % this function adds two the input and returns the result.
            y=x+2;

        
- Use lower-case letters for variable names, with underscores (``_``) to separate words.
    **bad:**

    .. code-block:: matlab    
        
        myVar=0;
   
    .. code-block:: matlab

        MyVar=0;

    .. code-block:: matlab

        My_Var=0;

    **good:**

    .. code-block:: matlab  

        my_var=0;

- Crash early, and when doing so, provide informative error messages.  

    **bad:**

    .. code-block:: matlab
        
        error('What do you mean?');

    .. code-block:: matlab

        if ntemplate~=nsamples
            % this is bad because the friggofrag analysis is invalid.
            % Telling the user that they provided wrong input could harm their self-esteem 
            % however, so let's just make up some data that, although completely meaningless,
            % will ensure that the script does not crash.
            samples=randn(ntemplate);

    **good:**

    .. code-block:: matlab 

        error('targets have size %d x %d, expected %d % d', targ_size, exp_size);


- Avoid using capital letters in the documentation, unless you want others to PERCEIVE YOUR MESSAGE AS SHOUTING, normal spelling dictates this (start of a sentence, proper names), tag code, or to refer to variable names. Avoid capital letters for variable names. If possible, give informative error messages.
    **bad:**

    .. code-block:: matlab 

        % NOW RUN THE CROSS-VALIDATION

    .. code-block:: matlab

        error('YOU SERIOUSLY MESSED UP THE INPUT - ARE YOU CRAZY???');

    .. code-block:: matlab

        fprintf('STARTING ANALYSIS... PLEASE BE PATIENT!!!\n');

    .. code-block:: matlab
        
        error('What do you mean?');

 
    **acceptable:**

    .. code-block:: matlab 

        % Note: this function is EXPERIMENTAL.

    **good:**

    .. code-block:: matlab 

        % Note: this function is *** experimental ***.

    .. code-block:: matlab 

        % The function Y=abs(X), where X is NxQ, returns an array Y of size NxQ 
        % so that, assuming that all elements in X are real, Y==X.*sign(X);

    .. code-block:: matlab 

        % NNO Sep 2013

    .. code-block:: matlab 

        % TODO: support more than two different chunks.        

    .. code-block:: matlab 

        % Now run the cross-validation

    .. code-block:: matlab 

       fprintf('Starting analysis - please be patient...\n');

- When writing function definitions:
    + start with a short sentence (one line) describing its purpose.
    + describe the signature of the function (input and output arguments)
    + describe the input parameters
    + describe the output parameters
    + whenever appropriate, add examples, notes, and references.

    **bad:**

    .. code-block:: matlab 

        function [winners,classes]=cosmo_winner_indices(pred)
        % uses a pretty cool hack using bsxfun to decide about the winners!

    **good:**

    .. include:: matlab/cosmo_winner_indices_hdr.txt

- Allocate space for output or intermediate results beforehand, rather than let arrays grow in a ``for`` or ``while`` loop.
    + This can greatly improve performance. Growing an array requires reallocating memory, which slows down code execution.
    + It also indicates what the size of the output is, which can help in understanding what code does.
    + This guideline is especially important when large arrays of data are used. 

    **bad:**

    .. code-block:: matlab 
        
        ndata=size(data,1);
        accs=[]; % start with empty array, then let it grow
        for k=1:ndata;
            acc=a_func(data(k,:)) % compute accuracy
            accs=[acss acc];
        end

    **good:**
        
    .. code-block:: matlab 

        ndata=size(data,1);
        accs=zeros(1,ndata); % allocate space for output
        for k=1:ndata
            acc=a_func(data(k,:)) % compute accuracy
            accs(k)=acc;
        end
        
- When possible use vectorization rather than a ``for`` or ``while`` loop.
    + Many functions support vectorized functions, where the same function is applied to elements in arrays.
    + Vectorization reduces the number of lines of code.
    + Vectorization reduces execution time.


    **really bad:** (see previous guideline)

    .. code-block:: matlab 

        [nrows,ncols]=size(data);
    
        abs_data=[]; % start with empty array, then let it grow
        for k=1:nrows
            row_abs_data=[]; % absolute data for the k-th row
            for j=1:ncols
                row_abs_data=[row_abs_data, abs(data(k,j))];
            end
            abs_data=[abs_data; row_abs_data]; % add this row to the output
        end

    **bad:**

    .. code-block:: matlab 

        [nrows,ncols]=size(data);

        abs_data=zeros(nrows,ncols); % allocate space for output

        % compute absolute value for each value in data
        for k=1:nrows
            for j=1:ncols
                abs_data(k,j)=abs(data(k,j));
            end
        end

    **good:**
        
    .. code-block:: matlab 

        abs_data=abs(data);
       
- Use clear variable names, aimed at finding a good balance between length and readability. Short variable names are fine if their use is clear (e.g., ``i``, ``j``, ``k`` for loop variables; ``n`` for number of elements, ``f`` for a function). It is recommended to document what a statement does if this cannot be deduced easily from the variable/function names.

    *Note:* ``i`` and ``j`` are used in Matlab to indicate the imagery unit (for which it holds that ``i^2==-1``), but for functions that do not use complex numbers (currently all of them) their use as a loop variable is acceptable.

    **bad:**

    .. code-block:: matlab 

        msxs = find(sm)

    .. code-block:: matlab 

        hkrw8ingmuch = max([v,vv,vvv])

    .. code-block:: matlab 

        my_very_long_variable_name_that_describes_something_i_forgot = ...
            apply_function_work(with_a_very_long_argument_name,...
                                and_another_long_argument_name);

    
    **borderline acceptable:**
    
    .. code-block:: matlab 
        
        % get the indices of the sample mask
        msxs = find(sm)

    .. code-block:: matlab

        [ns, nf]=size(ds.samples);
  

    **good:**
        
    .. code-block:: matlab 

        mask_indices=find(sample_mask);

    .. code-block:: matlab 

        max_dimen=max([x_dim, y_dim, z_dim]);

    .. code-block:: matlab 

        sliced_ds=cosmo_dataset(ds, mask_indices);
    
    .. code-block:: matlab 

        n=size(data,1); % number of samples
        for k=1:n
            data_result(k)=f(data(k,:));
        end

- Do not use global variables: these can have nasty and unpredictable side effects. In other words: use functions really as *functions*, where the output should depend on the input only (with the exception of the state of the random number generator).

- Avoid long expressions with many nested parentheses; rather use multiple lines in which variables (with informative names) are assigned in succession. Although this carries a minor speed penalty in Matlab, it improves readability.

    **borderline acceptable:**

    .. code-block:: matlab 

        for j=1:npartitions
            test_indices{j}=find(chunk_idx2count(combis(j,:)));
        end

    **good:**

    .. code-block:: matlab 
    
        for j=1:npartitions
            combi=combis(j,:);
            sample_count=chunk_idx2count(combi);
            test_indices{j}=find(sample_count);
        end

- When formatting strings use ``sprintf`` or ``fprintf``, rather than ``num2str`` and string concatenation. Avoid using disp when printing strings; use ``fprintf`` instead.
    
    **bad:**
    
    .. code-block:: matlab 

        disp(['Accuracy for ' label ' is ' num2str(mean_value) ' +/-' ...
                    num2str(std_value)]);

    **good:**

    .. code-block:: matlab 

        fprintf('Accuracy for %s is %.3f +/- %.3f\n', label, mean_value, std_value);

   
    *Note*: newer Matlab versions provide ``strjoin``, but for compatibility reasons an alternative implementation is provided as ``cosmo_strjoin``.

    
- Avoid using ``eval``, unless absolutely necessary. Not only do these carry a space penalty, but it obfuscates the code considerably. In almost all cases code can rewritten that avoids eval. If necessary use function handles

    **very bad:**

    .. code-block:: matlab 

        % for even samples apply f_even, for odd ones f_odd
        results=[];
        for k=1:nsamples
            if mod(k,2)==0
                eval(['results=[results; f_even(data(' num2str(k) '))];']);
            else
                eval(['results=[results; f_odd(data(' num2str(k) '))];']);
            end
        end

    **bad:**
        
    .. code-block:: matlab 

        % for even samples apply f_even, for odd ones f_odd
        results=zeros(nsamples,1);
        f_names={'f_odd','f_even'};
        for k=1:nsamples
            f_name=f_names(mod(k+1,2)+1);
            eval(sprintf('results(%d)=%s(data(%d));', k, f_name, k));
        end
            
    **good:**
        
    .. code-block:: matlab 

        % for even samples apply f_even, for odd ones f_odd
        results=zeros(nsamples,1);
        f_handles={@f_odd, @f_even};
        for k=1:nsamples
            f_handle=f_handles{mod(k+1,2)+1};
            f_data=f_handle(data(k));
        end

- [possibly subject to change]: The use ``try`` and ``catch`` statements is generally avoided; rather throw an exception when the input to a function is wrong. Consider that the code is code aimed for use in a Mars rover, that should never crash even in unexcepted circumstances; instead the code is aimed at analysis of neuroscience data, where getting correct results is more important than requiring someone to modify a script because the inputs were wrong and and error was raised. (Currently the only exception is ``cosmo_publish_run_scripts``, that builds the Matlab_ output from the scripts in ``examples/``).

- Note on checking consistency of input arguments: there is a subjective component in deciding how much should be checked, or when an error should be thrown. Checking more means less concise code and longer execution times, but can also prevent the user from making mistakes that would otherwise go undetected. For example, the current implementation does not check for *double dipping* for partitions in general, but does raise an error when using ``cosmo_splithalf_correlation_measure``. Similarly, ``cosmo_dataset_slice`` checks for the proper size of feature or sample attributes, but such a check is not done in some other functions.




CoSMoMPVA-specific guidelines
+++++++++++++++++++++++++++++

+ To indicate that a code block is an exercise, place a line containing ``% >@@>`` before the block and one containing ``% <@@<`` after the block. When using the build system (see above), this will replace the corresponding block by a message saying ``%%%% Your code comes here %%%%`` in the online documentation.

    **example:**

    .. code-block:: matlab

        % set the training and test indices for each chunk
        for k=1:nchunks
            % >@@>
            test_msk=unq(k)==chunks;
            train_indices{k}=find(~test_msk)';
            test_indices{k}=find(test_msk)';
            % <@@<
        end

Unit tests
^^^^^^^^^^
Unit tests are aimed at maintaining or improving the quality of the code, and to check whether refactoring code does not introduce undesired effects. They are located in ``tests/`` and use the xUnit_ framework. For existing or new features, more tests are very much welcomed.

.. include:: links.txt

