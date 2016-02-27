.. #   For CoSMoMVPA's license terms and conditions, see   #
   #   the COPYING file distributed with CoSMoMVPA         #

.. _`matlab_experience`:

=================
Matlab experience
=================

CoSMoMVPA_ is written with simplicity in mind, and therefore does not require one to be a Matlab expert. However, some minimal knowledge is required. To assess your knowledge of Matlab, below we describe some (subjectively chosen) criteria.

Using these criteria, we would argue that *using* CoSMoMVPA to analyze your data requires at least the *advanced beginner* level.

In order to understand implementations, and/or contribute code, the *competent* level would be required and the *proficient* level is preferable.

Advanced beginner
+++++++++++++++++
The advanced beginner should know be familiar with:

- starting and exiting Matlab.
- modifying the Matlab path.
- using the Matlab editor.
- ``array``, ``cell`` and ``struct`` data objects, and how to store data in and retrieve data from these.
- the difference between a ``numeric``, ``char`` and ``logical`` data type.
- the concepts of a scalar, row vector, column vector, and matrix.
- difference between a ``script`` and a ``function``.
- using a ``function``, and see the ``help`` documentation associated with a function.
- be familiar with ``for`` and ``while`` loops.
- understand the ``if`` statement.

Competent user
++++++++++++++
In addition, the *competent* user should be familiar with:

- using function handles.
- allocating memory for data.
- difference between using a binary mask and indices to access values in a ``cell`` or ``struct``.
- linear and subscripts to access values in a ``cell`` or ``struct``.
- ``varargin`` and ``nargin``.
- perform basic string manipulations.

Proficient user
+++++++++++++++
In addition, the *proficient* user should be familar with:

- nested function handles and Currying.
- ``bsxfun`` and ``cellfun``.
- recursion.
- the debugging mode and using break points.
- space- and time complexity.
- data structures.
- basic linear algebra.
- linear- and sub-indexing.
- modular design of functions.
- namespaces and closures.
- profiling.
- unit testing.
- ``git``.

(Some other advanced concepts include exceptions and object-oriented programming, but these are, by deliberate decision, not used in CoSMoMVPA_).


We have no idea what an *expert* user should be able to do, because we don't consider ourselves in that category.

.. include:: links.txt
