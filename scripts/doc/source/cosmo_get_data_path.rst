.. cosmo_get_data_path

cosmo get data path
===================
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
    if isunix()
        [p, n]=unix('uname -n'); % get the hostname
        n=strtrim(n);
        if p~=0
            error('Could not find hostname');
        end
        switch n
            case 'nicks-MacBook-Pro.local'
                data_path='/Users/nick/organized/_datasets/cosmo/data/small';
            
            % add more cases here for other machines
            
            
            otherwise
                error('do not know %s', n);
        end
        
        % optionally add an else statement for windows machines
    end
    
    if nargin>=1
        data_path=fullfile(data_path, subject_id, 'stats', '');
    end
    
    if ~exist(data_path,'file')
        error('%s does not exist. Did you adjust %s?', data_path, mfilename());
    end