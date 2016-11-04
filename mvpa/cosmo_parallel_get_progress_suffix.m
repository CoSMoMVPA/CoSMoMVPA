function suffix=cosmo_parallel_get_progress_suffix(environment)
    switch environment
        case 'matlab'
            suffix=sprintf('\n');
        case 'octave'
            suffix='';
    end
