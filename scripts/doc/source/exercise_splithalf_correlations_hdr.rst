.. exercise_splithalf_correlations_hdr

exercise splithalf correlations hdr
===================================
.. code-block:: matlab

    %% roi-based MVPA with group-analysis
    %
    % Load t-stat data from all subjects, apply 'ev' mask, compute difference
    % of (fisher-transformed) between on- and off diagonal split-half
    % correlation values, and perform a random effects analysis