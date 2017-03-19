.. #   For CoSMoMVPA's license terms and conditions, see   #
   #   the COPYING file distributed with CoSMoMVPA         #

.. _`ex_meeg_searchlight`:

MEEG Searchlights
=================

This exercise requires a separate dataset named `meg_obj6`; see :ref:`download <download>` section.
It also requires a working installation of FieldTrip_.

Before starting this exercise, please make sure you have read about:

- :ref:`matlab_octave_function_handles`
- :ref:`cosmomvpa_measure`
- :ref:`cosmomvpa_neighborhood`

Part 1: MEEG univariate contrast
++++++++++++++++++++++++++++++++
Load the MEEG obj6 data for subject `s00`. Read the README file to understand how the data is represented.
Use :ref:`cosmo_meeg_dataset` to convert the dataset to a CoSMoMVPA dataset structure. How many sensors, time points and trials are in this dataset? Then compute, for each time point and sensor, the difference between face and scene stimuli. Visualize the results in FieldTrip for the magnetometers.

Part 2: MEEG time-course searchlight with classifier and cross-validation
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Using the same data as above, define a `time` neighborhood for magnetometer sensors in the posterior part of the brain.
Then, for each time point, use a classifier with cross-validation discriminating the six categories using data for the selected sensors, and plot a classification accuracy time course.

Part 3: MEEG time-course searchlight with split-half correlation measure
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Using the same data as above, define `chan` (channel) and `time` neighborhoods; then cross these neighborhood for a *space-time* `chan`-by-`time` neighborhood. Using :ref:`cosmo_correlation_measure`, compute split-half correlation differences for each combination of time points and sensors.

Hint: :ref:`run_meeg_timelock_measures_skl`

Solution: :ref:`run_meeg_timelock_measures` / :pb:`meeg_timelock_measures`


Part 4: MEEG channel-time-frequency searchlight with Naive Bayes classifier
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

This exercise requires a separate dataset named `meg_20hz`, part of the full tutorial data; see :ref:`download <download>` section.

Certain questions in MEEG concern oscillations. For such analysis data is typically transformed into a time-frequency representation (for each channel) through a procedure called Fourier analysis. One question one can answer is whether power in a particular frequency band shows a different pattern across conditions.

In the exercise presented here, we use a dataset with somatosensorty stimulation of the hand versus no stimultation. To localize when in time, in which frequency band, and in which channel this shows a difference in the neural patterns, use a searchlight over channels, time points and frequency bands.

Hint: :ref:`run_meeg_timefreq_measures_skl`

Solution: :ref:`run_meeg_timefreq_measures` / :pb:`meeg_timefreq_measures`


.. include:: links.txt

