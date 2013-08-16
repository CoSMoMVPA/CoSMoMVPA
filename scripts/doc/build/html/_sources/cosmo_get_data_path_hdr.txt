.. cosmo_get_data_path_hdr

cosmo get data path hdr
-----------------------
.. code-block:: matlab

    function data_path=cosmo_get_data_path(subject_id)
    % helper function to get the data path.
    % this function is to be extended to work on your machine, depending on
    % where you stored the test data
    % 
    % Inputs
    %   subject_id    optional subject id identifier. If provided it gives the
    %                 data directory for that subject
    %
    % Returns
    %  data_path      path where data is stored