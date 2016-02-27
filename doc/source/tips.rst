.. #   For CoSMoMVPA's license terms and conditions, see   #
   #   the COPYING file distributed with CoSMoMVPA         #


.. _tips:

===============
Tips and tricks
===============

.. contents::
    :depth: 2

Advanced Matlab / Octave concepts
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. _`matlab_octave_logical_masking`:


Logical masking
+++++++++++++++
A logical mask is an array of type ``logical``, and can only contain values ``true`` and ``false``.

For example,

    .. code-block:: matlab

        my_arr=[false, true,  true; ...
                true,  false, false];

is an ``2x3`` array, and values in this array can be indexed as other (e.g. numeric, cell) arrays. For example,

    .. code-block:: matlab

        my_arr(:,3)

returns the array in the third colum, that is the ``2x1`` column vector ``[true; false]``. Note that when showing a logical array, Matlab / Octave do not show ``false`` or ``true`` values, but ``0`` and ``1`` respectively. To see whether a variable ``a`` is a logical array, run ``whos a``.


A logical array ``a`` can be used to index another array ``b``, where the result of indexing is an array ``c`` that contains the elements of ``b`` only where ``a`` is equal to ``true``. Thus, in this example

    .. code-block:: matlab

        my_mask=[false,true,true,false,true,false];
        my_data=11:16;

        my_masked_data=my_data(my_mask);

the contents of ``my_masked_data`` is contains the elements of my_data at positions ``2``, ``3`` and ``5``, i.e. ``my_masked_data=[12,13,15]``. Although it would be equivalent to use (what some may find more intuitive) ``my_mask_data=my_data(find(my_mask))``, this expression is longer to write and takes a longer time to execute.

Logical arrays can be constructed with the comparison operators ``<``, ``<=``, ``==``, ``~=``, ``>``, and ``>=``; for example,

    .. code-block:: matlab

        my_data=[11:16, 13:15 9]
        mask_at_least_12=my_data>12;
        mask_equal_13=my_data==13;

returns logical masks of the same size as ``my_data`` with values ``true`` where ``my_data`` is at least ``12`` (``[false, false, true, true, true, true, true, true, true, true, false]``)  and equal to ``13`` (``[false, false, true, false, false, false, true, false, false, false]``), respectively.

Finally, the logical operators ``~`` (negation), ``&`` (element-wise logical-and) ``|`` can be used as operators on two logical masks. Thus, in

    .. code-block:: matlab

        a=[false, true, false, true];
        b=[false, false, true, true];

the expressions:

    - ``~a`` has the value ``true`` where-ever the corresponding value in ``a`` is false: ``[true, false, true, false]``.
    - ``a & b`` has the value ``true`` where-ever the corresponding values in ``a`` and ``b`` are both ``true``: ``[false, false, false, true]``.
    - ``a | b`` has the value ``true`` where-ever at least one of the corresponding values in ``a`` and ``b`` is ``true``: ``[false, true, true, true]``.


When using the logical operators ``a & b`` and ``a | b``, it is required that ``a`` and ``b`` are of the same size.


.. _`matlab_octave_function_handles`:

Function handles
++++++++++++++++
CoSMoMVPA_ uses the *function handle* construct for improved modularity when using :ref:`classifiers <cosmomvpa_classifier>` and :ref:`measures <cosmomvpa_measure>`. These are references to functions which can be assigned to a variable. The function can be called by calling the name of the variable with parentheses.

For example,

    .. code-block:: matlab

        do_magic = @sin;

means that

    .. code-block:: matlab

        y=do_magic(x)

is equivalent to

    .. code-block:: matlab

        y=sin(x)

When using this for measures,

    .. code-block:: matlab

        measure=@cosmo_crossvalidation_measure;

allows using different measures (i.e. functions) by just changing one line of code, for example to

    .. code-block:: matlab

        measure=@my_funky_new_measuer_no_one_knows;

which allows reusing code for future analyses and analysis methods. This concept is key not only for :ref:`measures <cosmomvpa_measure>` but also for :ref:`searchlight analyses <searchlight>`.

For more information about function handles, run in Matlab: ``help function_handle``








General tips and tricks
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Here is a short list of tips and tricks that may make life easier when using CoSMoMVPA_.

- Use :ref:`cosmo_disp` to show the contents of a dataset structure (or any other data structure)

- Use ``help cosmo_function`` to view the help contents of a function. Most functions have an ``example`` section which shows how the function can be used.

- Use :ref:`cosmo_check_dataset` when manually changing contents of a dataset structure. It will catch basic errors in dataset

- Use :ref:`cosmo_check_partitions` when manually creating partitions.

- When slicing datasets, often :ref:`cosmo_match` can be used to get logical masks that match a (array of) numbers of strings.
- For feature selection in MEEG datasets (in particular, selection over time), consider :ref:`cosmo_dim_match` and :ref:`cosmo_dim_prune`.

.. include:: links.txt



