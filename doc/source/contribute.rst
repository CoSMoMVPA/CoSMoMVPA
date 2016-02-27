.. #   For CoSMoMVPA's license terms and conditions, see   #
   #   the COPYING file distributed with CoSMoMVPA         #

.. _contribute:

============================
Information for contributors
============================

We would be very happy to receive contributions!

You don't have to be a Matlab_ / Octave_ programmer. Useful *code* contributions are very much appreciated, but improved documentation, ideas on how our web site can be made prettier, or other ideas are also valued highly.

If you are not a Matlab_ / Octave_ programmer but would like to contribute or suggest improvements on the documentation or examples, please contact_ us directly.

For programmers, the preferred way to contribute is using git_ and github_. If you would like to contribute code in another way, also please contact_ us directly.

.. contents::
    :depth: 2


.. _`file_locations_and_naming_conventions`:

Directory locations and naming conventions
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Meta - naming conventions in the documentation
++++++++++++++++++++++++++++++++++++++++++++++

In what follows we use the following naming conventions.
- Path names are `Unix-like`_-based; ``/`` is the path separation character, rather than ``\`` used on Windows platforms.
- Directories have ``/`` as the last character, and are relative to the root directory where CoSMoMVPA_ resides. For example, if CoSMoMVPA is located in ``/Users/karen/git/CoSMoMVPA``, then ``mvpa/`` refers to ``/Users/karen/git/CoSMoMVPA/mvpa``.


Setting the Matlab_ path
++++++++++++++++++++++++
To use ``CoSMoMVPA`` functionality, it is recommended to set the path using :ref:`cosmo_set_path`. Optionally run ``savepath`` afterwards if you want to store the new path, so that it is set the next time Matlab or Octave is started.

Alternatively the path can be set manually as follows:

- add the ``mvpa/`` directory to the Matlab_ path.
- also add ``externals/`` and its subdirectories to the Matlab_ path.
- do *not* add ``examples/`` or ``tests`` to the Matlab_ path.
    + To run examples, ``cd`` to ``examples/`` and run scripts from there.
    + To run unit tests, run ``cosmo_run_tests`` (this requires the xUnit_ or MOxUnit_ testing frameworks).

Organization of files and directories
+++++++++++++++++++++++++++++++++++++

- Core ``CoSMoMVPA`` Matlab functions are in ``mvpa/``. File names should match the pattern ``cosmo_*.m``.
- Runnable Matlab example scripts are in ``examples/``. File names should match the pattern ``run_*.m`` or ``demo_*.m``.
- Unit tests are in ``tests/``. File names should match the pattern ``test_*.m`` for unit tests, and any other prefix for helper functionality.
- External libraries are in ``external``.
- Documentation is in ``doc/source/``:
    + Documentation files have the ``.rst`` extension and are formatted as reStructuredText_.
    + Exercises have the prefix ``ex_``.
    + Other documentation files, unless automatically generated (see 'build system' below), should not have the prefix ``cosmo_`` or ``run_``, as running ``make clean`` in ``doc/`` will remove them.
    + Other file types, such as images, are stored in ``doc/source/_static/``.
    + Generated matlab output files, using the ``publish`` functionality in ``mvpa/cosmo_publish_run_scripts`` (for developers only), are stored in ``doc/source/_static/publish/``.
- Example data is stored separately.

.. _`building the documentation`:

Setting up the documentation build system
+++++++++++++++++++++++++++++++++++++++++
The documentation is built using Sphinx_, Python_, `sphinxcontrib-matlabdomain`_, `sphinxcontrib-bibtex` and customly written Python_ code. Currently only Unix-like systems are supported; we have tested it on Linux and Mac OS. Python_ is a required dependency; we have tested with with version 2.7. Building requires using a shell, for example ``bash``.

Installation is easiest using `easy_install`_. To install as root::

    easy_install sphinx
    easy_install -U sphinxcontrib-matlabdomain
    easy_install -U sphinxcontrib-bibtex


Installation as non-root requires creating a local directory in which the Python_ packages are stored. To install these in ``~/python-lib``, for example::

    cd
    mkdir python-lib
    cd python-lib
    export PYTHONPATH=${PYTHONPATH}:`pwd`
    export PATH=${PATH}:`pwd`
    easy_install --install-dir . sphinx
    easy_install --install-dir . -U sphinxcontrib-matlabdomain
    easy_install --install-dir . -U sphinxcontrib-bibtex

In this case, it is useful to add the ``export``-commands to ``~/.bash_profile`` so that the paths are set automatically upon login.

To build the documentation:
    + (optionally) in Matlab_, ``cd`` to the     ``mvpa/`` directory, then run ``cosmo_publish_run_scripts``. This generates the matlab output of the scripts in ``examples/``.
    + On the terminal, ``cd`` to ``doc/``, then run ``make html``. (To clean previously built documentation, run ``make clean`` first).


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
    + keeping track of individual contributions. Through git_ it is possible to see every change made, by anybody. It provides functionality similar to a time-machine, but with some kind of tagging: every change is annotated (see below). This allows anyone to see what was changed, when this happended, and by who.
    + code sharing on multiple computers: everyone has their own copy of the code, and can merge changes made by others.
    + maintaining multiple versions: through *branching* one can create multiple copies of the code, each which its own new features. This is very useful for new experimental features or bug-fixing without affecting the *prestine* master code. Once changes are considered ready for the master repository, they can be merged easily.

The instructions below assume a unix-like platform, and the command below should be run on the terminal (for example in bash).

.. _initial_git_setup:

Initial git_ / github_ setup
----------------------------

To get started with git_ and github_ to allow for code contributions to CoSMoMVPA:

    + set up a working installation of git_ (see `installing git`_).
    + tell git about your name and email address::

        git config --global user.name "Your full name"
        git config --global user.email "your_email@the_domain.com"

      By setting these options, all commits you make will have this information, so that everybody can identify who changed what.

    + make an account on github_, if you have not done so.
    + on the github_ project page, `fork the repository`_, and follow the instructions there.
    + get a local copy of your forked repository: run::

        git clone https://github.com/karen/CoSMoMVPA.git

      if ``karen`` is your github user name.

    + change to the directory just created::

        cd CoSMoMVPA

    + tell git about the `offical` release, which we call ``upstream``::

        git remote add upstream https://github.com/CoSMoMVPA/CoSMoMVPA.git


Proposing a change in the code (a.k.a. submitting a Pull Request (PR)
---------------------------------------------------------------------

    + to update your repository to the latest official code, first make sure you are on the master branch, then pull the current code::

        git checkout master
        git pull upstream master

      (This assumes that added the remote ``upstream`` as described in the :ref:`previous section<initial_git_setup>`.)

    + to add a new feature or provide a bugfix, start a new branch::

        git checkout -b my_awesome_new_feature


    + make the desired changes, then commit them. :ref:`See below for details <committing_notes>`.
    + push these changes to *your* github_ account::

        git push origin my_awesome_new_feature

    + go to your own github page, i.e. ``https://github.com/karen/CoSMoMVPA`` if your git user name is ``karen``. Typically the github_ webpage already mentions that a new branch was pushed, so just click on `create pull request`. Otherwise click `pull requests` in the right-hand bar, then click `New pull request`. Add a description to the pull request, and then submit it.

      We'll get back to you to review and discuss the code. Once the code is ready for the official master it will be merged. You should receive notifications by email when the code is discussed or merged.

    + if you want go back to using code from the ``master`` branch (the `official` code), run::

        git checkout master

      Keep in mind that the ``master`` branch is supposed to contain working, runnable code. Proposed changes, including experimental code and bug-fixes, should preferably be submitted in separate branches.

There are many great resources on using git_ on the web; a detailed explanation is beyond the scope of this documentation.

.. _`installing git`: http://git-scm.com/book/en/Getting-Started-Installing-Git
.. _`fork the repository`: https://help.github.com/articles/fork-a-repo

.. _committing_notes:

Notes on committing
-------------------
- Please review your changes before commiting them. Useful commands are ``git status`` and ``git diff``.
- Do *not* use ``git -a``; instead manually add the (changes to) files individually. Preferably commits should be atomic, that is change just one feature.  For example if you changed a file at two places by (1) improving the documentation and (2) refactoring code used internally, then preferably you should make two commits. Using the tags below these could be ``DOC: ...`` and ``RF: ...``.
  - To add a new file ``my_new_file.m``, run::

        git add my_new_file.m

  - To commit changes to a file, run::

        git add -i

    then press ``p`` (for 'patch'), indicate which files to patch, and press ``y`` or ``n`` for each meaningful 'atomic' change, and ``q`` to quit. (Usually followed by ``git commit ...``).

  - To view the history of previous commits, ``gitk`` is useful.
  - Use the following tags (inspired by PyMVPA_) for commits:

    + ``ACK``: Acknowledge someone else. Acknowledgees should be placed between ``#`` characters, so that the build system can generate acknowledgements on the web page. If the acknowledgement includes code or documentation (not a bug report or question), use ``CTB`` as well.
    + ``BF``: Bugfix. Preferably this comes also with a unit test (i.e., ``BF+TST``) that checks whether the bug was indeed fixed.
    + ``BK``: Breaks existing functionality, or the signature of functions (changes in the number, or the meaning, of input and output arguments).
    + ``BLD``: Changes in the build system.
    + ``BIG``: Major change. Please use together with another tag.
    + ``CLN``: Code cleanup. ``SML`` can be omitted.
    + ``CTB``: Code contribution from someone else who did not use ``git`` (for example, sent an email to the developers with new functionality that was considered useful). Use together with ``ACK``. If someone using ``git`` uses this contribution, please also add a text like '``based on contribution from Jon Doe (jon@doe.org)``'.
    + ``DOC``: Change in documentation *of matlab code* (in ``examples/``, ``mvpa/``, ``tests/``).
    + ``EXC``: Change in exercises. This could go together with ``WEB`` or ``DOC``, and/or ``RUN``.
    + ``MSC``: Miscellaneous changes, not covered by any of the other tags.
    + ``NF``: New feature or functionality.
    + ``OCTV``: Change in GNU Octave compatibility.
    + ``OPT``: Optimalization. It should be used when the new code runs faster or uses less memory.
    + ``RF``: Refactoring (changes in functions that do not affect their external behaviour).
    + ``RUN``: Change in runnable example scripts (in ``examples/``).
    + ``SML``: Minor change. Can be without an explanation of what was changed.  Please use together with another tag.
    + ``STD``: Change to adhere better to coding standards. ``SML`` can be omitted.
    + ``TST``: Change in test functions (functions in ``tests/``, or documentation tests).
    + ``WEB``: Changes affecting web site content (either documentation in ``.rst`` files, or other files such as images).

    Using these tags:

    + allows others to quickly see what *kind of* changes were made
    + the web page build system to generate summary reports on the kind of changes automatically.
    + generate statistics on types of changes over type.

    Please describe what changes you made. The tags don't have to name which files were changed, as git_ takes care of that.

    Tags can be combined, as it may occur that multiple tags apply; use the ``+``-character to concatenate them.

    Examples:

    + ``git commit -m 'ENH: support two-dimensional cell arrays as feature attributes'``
    + ``git commit -m 'RF: build a lookup table mapping all voxels to those in the dataset``
    + ``git commit -m 'BF+TST: throw an error if partitions are not balanced; added unit test'``
    + ``git commit -m 'DOC+SML: fixed a typo'``
    + ``git commit -m 'BF+ACK: show error message when negative radius is provided. Thanks to #John Doe# and #Jane Doe# for bringing up this use case``.


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
    + the ``Makefile`` in ``source/``, when used through ``make html``, uses ``mat2rst.py`` to generate reStructuredText_ Matlab files and then uses Sphinx_ to convert these files to html.
- The ``build.sh`` script builds the documentation and datasets.

**Note:** building the documentation, as described in the previous points, is currently supported on `Unix-like`_ systems only, and requires additional dependencies (see download_).

.. _download: download.html

- The  ``mvpa/cosmo_publish_run_scripts.m`` function generates the output from all the runnable examples in ``examples/`` as html files and puts them in ``doc/source/_static/publish/``. This function is used to produce output for the web site.

.. _`matlab code guidelines`:

Matlab code guidelines
^^^^^^^^^^^^^^^^^^^^^^
The following are guidelines, intended to improve:

+ consistency in code layout across contributers, so that the final result is more consistent.
+ readability, so that less time is spent in understanding how the code works or what it does.
+ performance, so that execution time or memory usage is reduced.


.. contents::
    :depth: 1
    :local:


**Note**: None of these guidelines are set in stone. Try to use common sense when considering not to follow them. Indeed, for each guideline there may be a good reason to deviate from it.

Maximum line length is 75 characters
++++++++++++++++++++++++++++++++++++

Try to keep line lengths limited to 75 characters, so that files can be viewed in a standard terminal window, possibly with scroll bars, without line breaks. (The Matlab editor shows a vertical line after the 75-th character). Use line continuation (``...`` at the very end of the line) followed by indentation for the continued lines.

- An exception to this rule is including URLs in documentation, because they allow for copy-pasting the URL directly.

- If a binary operator is used together with line continuation, put the operator before the line continuation.

- Lines should not end with whitespace.

    **bad:**

    .. code-block:: matlab

        my_output_data=my_awesome_function(first_argument, second_argument, third_argument, fourth_argument, fifth_argument, sixth_argument);

        apply_mask=user_has_supplied_mask ...
                        && ~isempty(user_mask) ...
                        && sum(user_mask)>0

        my_string='Nick was right (as he usually is) in stating that although the use of long expressions may sometimes seem unavoidable, the use of line continuations hardly ever is.';


    **good:**

    .. code-block:: matlab

        my_output_data=my_awesome_function(first_argument, second_argument,...
                                           third_argument, fourth_argument,...
                                           fifth_argument, sixth_argument);

        apply_mask=user_has_supplied_mask && ...
                        ~isempty(user_mask) && ...
                        sum(user_mask)>0

        my_string=['Nick was right (as he usually is) in stating that '...
                    'although the use of long expressions may sometimes '...
                    'seem unavoidable, the use of line continuations '...
                    'hardly ever is.'];

    (Yes, we break this rule occasionely.)


Indentation is 4 spaces (no tabs)
+++++++++++++++++++++++++++++++++

Indentation should be used for `if-else-end`, `while` and `function` blocks. Expressions of the form ``if expr``, ``else``, ``elseif expr``, ``var=function(var)``, ``while expr``, and ``end`` should be on a single line, except for very short statements that either set a default value for an input argument or raise an exception.

If this guideline and the previous one do not give you enough room to express yourself, then most likely you are overcomplicating things; consider rewriting the code and/or use subfunctions.

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


Use lower-case letters for variable names
+++++++++++++++++++++++++++++++++++++++++

Use underscores (``_``) to separate words.
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

Throw an (informative) error early
++++++++++++++++++++++++++++++++++

Throw an error as soon as something seems out of order. When doing so, try to provide an informative error message.

    **bad:**

    .. code-block:: matlab

        error('What do you mean?');

    This is bad because the user has no idea why an error was thrown.

    .. code-block:: matlab

        if ntemplate~=nsamples
            % this is bad because the friggofrag analysis is invalid.
            % Telling the user that they provided wrong input could harm their
            % self-esteem however, so let's just make up some data that,
            % although completely meaningless, will ensure that the script
            % does not crash.
            samples=randn(ntemplate);
        end

    This is very bad because instead of reporting that data was of incorrect
    shape, the code generates new (random) data, which the user most likely neither expects or desires.

    **good:**

    .. code-block:: matlab

        error('targets have size %d x %d, expected %d % d', ...
                     target_size, expected_target_size);

    .. code-block:: matlab

        if strcmp(caught_exception.identifier,...
                            'stats:svmtrain:NoConvergence');
            error(['SVM training did not converge. Your options are:\n'...
                   ' 1) increase ''boxconstraint''\n'...
                   ' 2) increase ''tolkkt''\n'...
                   ' 3) set ''kktviolationlevel'' to a positive value\n'...
                   ' 4) use a different classifier\n'...
                   'If you do not have a strong preference for '...
                   'either option, you are advised to try option (4) '...
                   'using cosmo_classify_lda'],'');
        else
            rethrow(caught_exception);
        end

Do not repeat yourself
++++++++++++++++++++++

If the same expression is evaluated multiple times, evaluate it once and assign its result to a variable.

    **bad:**

    .. code-block:: matlab

        if nfeatures>nsamples
            delta=nfeatures-nsamples
        else
            delta=0;
        end

        aggregate_size=[nfeatures,nsamples,delta];

        if nsamples<=nfeatures
            cosmo_warning('%d samples < %d features', nsamples, nfeatures);
        end

    **good**

    .. code-block:: matlab

        has_more_features_than_samples=nfeatures>nsamples

        if has_more_features_than_samples
            delta=nfeatures-nsamples
        else
            delta=0;
        end

        aggregate_size=[nfeatures,nsamples,delta];

        if has_more_features_than_samples
            cosmo_warning('%d samples < %d features', nsamples, nfeatures);
        end

Write in normal, understandable english
+++++++++++++++++++++++++++++++++++++++
Avoid using capital letters in the documentation, unless you want others to PERCEIVE YOUR MESSAGE AS SHOUTING, normal spelling dictates this (start of a sentence, proper names), tag code, or to refer to variable names. Avoid capital letters for variable names. If possible, give informative error messages.

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

        if show_progress
            fprintf('Starting analysis - please be patient...\n');
        end

Document functions
++++++++++++++++++

When writing function definitions:
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


Pre-allocate space for data
+++++++++++++++++++++++++++
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

Use vectorization
+++++++++++++++++
When possible use vectorization rather than a ``for`` or ``while`` loop.
    + Many functions support vectorized functions, where the same function is applied to elements in arrays.
    + Vectorization reduces the number of lines of code.
    + Vectorization typically reduces execution time.


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


Use clear variable names
++++++++++++++++++++++++
The aim is to find a good balance between length and readability. Short variable names are fine if their use is clear (e.g., ``i``, ``j``, ``k`` for loop variables; ``n`` for number of elements, ``f`` for a function). It is recommended to document what a statement does if this cannot be deduced easily from the variable/function names.

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

    .. code-block:: matlab

        [nsamples, nfeatures]=size(ds.samples);


Avoid side effects
++++++++++++++++++

Generally try to avoid side effects, and if that is not possible, indicate such effects clearly in the function name.

    **very bad:**

    .. code-block:: matlab

        function init_my_toolbox()

            restoredefaultpath();
            addpath('my_functions');

    The above is bad because:

         - The function name ``init_my_toolbox`` does something one would not expect based on its name, namely it resets the Matlab path.
         - Functions that were accessible before are not longer in the Matlab path. In particular, any other external toolboxes or code not part of the Matlab installation becomes unavailable.

    It is acceptable to add something to the Matlab path, if the function name clearly indicates that it does so:


    **acceptable:**

     .. code-block:: matlab

        function my_toolbox_set_path()

            addpath('my_functions');

    Along the same lines, in general functions should not change the current working directory, the path, or the warning state. Sometimes this cannot be avoided, but in that case these changes should be undone when leaving the function.

    **bad:**

    .. code-block:: matlab

        function do_computation()

            addpath('my_functions');
            original_dir=pwd();
            cd('other_functions/private');
            warning('off');

            do_stuff();

            rmpath('my_functions');
            cd(original_dir);
            warning('on');

    The above is bad, because:

        - the user may have added ``my_functions`` to the path themselves; after calling this function, it is removed from the path.
        - the user may have set the warning state themselves to ``off``; this is undone after calling this funciton
        - the current working directory and the path are not restored when execution is interrupted because of an error or a user interrupt (``ctrl+C``).

    **acceptable:**

    .. code-block:: matlab

         function do_computation()

            original_path=path();
            original_working_dir=pwd();
            original_warning_state=warning();

            path_resetter=onCleanup(@()cd(original_path));
            working_dir_resetter=onCleanup(@()path(original_working_dir));
            warning_state_resetter=onCleanup(@()warning(original_warning_state));

            addpath('my_functions');
            warning('off');

            cd('other_functions/private');

            do_stuff();

            % (the path, working directory, and warning state are reset when
            %  execution of the code in the function body is completed or
            %  interrupted.)

Tests should not require user interaction
+++++++++++++++++++++++++++++++++++++++++
When implementing unit tests (in the ``tests``) directory, functions should run automatically without any user interaction. If a test were to require user interaction, one of the main advantages of the test suite (fully automated testing) is lost.

Do not use global variables
+++++++++++++++++++++++++++
Global variables can have nasty and unpredictable side effects. In almost all cases it is preferable that output of a function should depend on the input only; there are some exceptions, such as :ref:`cosmo_warning` which by default shows each warning only once. If necessary (e.g. for caching), use persistent variables.

Avoid long and complicated expressions
++++++++++++++++++++++++++++++++++++++

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


Use ``sprintf`` or ``fprint`` when formatting strings
+++++++++++++++++++++++++++++++++++++++++++++++++++++
- When formatting strings use ``sprintf`` or ``fprintf``, rather than ``num2str`` and string concatenation. Avoid using disp when printing strings; use ``fprintf`` instead.

    **bad:**

    .. code-block:: matlab

        disp(['Accuracy for ' label ' is ' num2str(mean_value) ' +/-' ...
                    num2str(std_value)]);

    **good:**

    .. code-block:: matlab

        fprintf('Accuracy for %s is %.3f +/- %.3f\n', label, mean_value, std_value);


    *Note*: newer Matlab versions provide ``strjoin``, but for compatibility reasons with older versions, an alternative implementation is provided as ``cosmo_strjoin``.


Avoid using ``eval``
++++++++++++++++++++
Statements with ``eval`` can obfuscates the code considerably, and also make refactoring (such as changing variable names) more difficult. In almost all cases code can rewritten that avoids eval. If necessary use function handles

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

        This is bad because it uses ``eval`` and does not pre-allocate space for data.

    **bad:**

    .. code-block:: matlab

        % for even samples apply f_even, for odd ones f_odd
        results=zeros(nsamples,1);
        f_names={'f_odd','f_even'};
        for k=1:nsamples
            f_index=mod(k+1,2)+1);
            f_name=f_names{f_index};
            eval(sprintf('results(%d)=%s(data(%d));', k, f_name, k));
        end

        This is bad because it uses ``eval``.

    **good:**

    .. code-block:: matlab

        % for even samples apply f_even, for odd ones f_odd
        results=zeros(nsamples,1);
        f_handles={@f_odd, @f_even};
        for k=1:nsamples
            f_index=mod(k+1,2)+1;
            f_handle=f_handles{f_index};
            f_data=f_handle(data(k));
        end

Minimize using ``try`` and ``catch``
++++++++++++++++++++++++++++++++++++
The use ``try`` and ``catch`` statements is generally avoided; we aim to throw an exception when the input to a function is wrong. Consider that code for use in a Mars rover should never crash even in unexcepted circumstances, whereas in CoSMoMVPA_ the code is aimed at analysis of neuroscience data, where getting correct results is very important (and knowing that something is wrong is important too). Some current exceptions are:

    + :ref:`cosmo_publish_run_scripts`, that builds the Matlab_ output from the scripts in ``examples/``. We don't want that function to crash if any of the scripts it is publishing crashes.
    + :ref:`cosmo_classify_libsvm` and :ref:`cosmo_classify_matlabsvm`, that check whether the required externals are present if they fail, as that is a likely scenarion. In that case, even though the error is caught initially, always a subsequent error is thrown.
    + :ref:`cosmo_searchlight`, which if an error is thrown by the `measure` function handle, prefixes the error message with the feature id that caused the error, and then throws a new error.


Check input arguments
+++++++++++++++++++++
Generally it is good to check the input arguments, although there is a subjective component in deciding how much should be checked, or when an error should be thrown. Checking more means less concise code and longer execution times, but can also prevent the user from making mistakes that would otherwise go undetected.

CoSMoMPVA-specific guidelines
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Writing exercises
+++++++++++++++++
To indicate that a code block is an exercise, place a line containing ``% >@@>`` before the block and one containing ``% <@@<`` after the block. When using the build system (see above), this will replace the corresponding block by a message saying ``%%%% Your code comes here %%%%`` in the online documentation.

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

Documentation tests
+++++++++++++++++++
When providing examples it is a good idea to write them in the shape of examples, so that running :ref:`cosmo_run_tests` will actually test whether the code runs as advertised. Many `modules <modindex.html>`_ have such doctests; you can spot them in the ``Examples:`` section of the help info, where the expected output is preceded by ``>``. For example:

    .. include:: matlab/cosmo_strsplit_hdr.txt

Compatibility notes
+++++++++++++++++++
CoSMoMVPA_ aims to be compatible with GNU Octave 3.8 and later, and with Matlab versions from at least 2010b onwards. Features not supported by these platforms should not be used.


Test suite
^^^^^^^^^^
CoSMoMVPA_ uses a test suite, which can automatically test most of the code. This helps in maintaining or improving the quality of the code, and to check whether refactoring code does not introduce undesired effects (such as bugs). They are located in ``tests/`` and use the xUnit_ or MOxUnit_ framework. To run them, either:

    - run :ref:`cosmo_run_tests`: when using xUnit_. Only supported on the Matlab platform.
    - run ``moxunit_run_tests`` in the ``tests`` directory: when using MOxUnit_. Supported on the Matlab and Octave platform. Documentation tests are not supported yet, because Octave does not support ``eval`` (as of May 2015).

Currently we use `travis-ci`_ for continuous integration testing. If you have a github_ account and a CoSMoMVPA_ fork, you can also use it to test new branches. To do so:

    - Make an account on `travis-ci`.
    - Link it to your github_ account.
    - Now, after every 'push' to github, the test suite is run automatically using ``moxunit_run_testa`` on Octave.
    - If any tests fails, or passes if it failed before, you will be notified by email.

For existing or new features, more tests are very much welcomed.

.. include:: links.txt

