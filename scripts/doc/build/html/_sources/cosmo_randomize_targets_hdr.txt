.. cosmo_randomize_targets_hdr

cosmo randomize targets hdr
---------------------------
.. code-block:: matlab

    function randomized_targets=cosmo_randmize_targets(targets, chunks)
    % provides randomized target labels
    %
    % randomized_targets=cosmo_randmize_targets(count, targets, chunks)
    %
    % Inputs
    %   targets:  Px1 target (class) labels
    %   chunks:   Px1 chunk indices
    %
    % Returns
    %   randomized_targets    P x 1 with randomized targets
    %                         Each chunk in each row is randomized seperately
    %
    % NNO Aug 2013