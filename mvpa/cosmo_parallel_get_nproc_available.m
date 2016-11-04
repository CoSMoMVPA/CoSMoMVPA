function nproc=cosmo_parallel_get_nproc_available(sl_opt, environment)
% get number of processes available from Matlab parallel processing pool.
% return nproc=1 if no parallel processing pool available
    nproc_wanted=sl_opt.nproc;

    wants_multithreaded = nproc_wanted>1;
    if wants_multithreaded
        switch environment
            case 'matlab'
                nproc_available=get_nproc_available_matlab(nproc_wanted);

            case 'octave'
                nproc_available=get_nproc_available_octave(nproc_wanted);

            otherwise
                assert(false);

        end

        nproc=nproc_available;

        if nproc_available==1
            cosmo_warning(['Parallel computing not available, using '...
                            'single thread']);
            nproc=1;
        end
    else
        nproc=1;
    end

function nproc_available=get_nproc_available_matlab(nproc_wanted)
    matlab_parallel_functions={'gcp','parpool'};

    if usejava('jvm') && platform_has_functions(matlab_parallel_functions)
        pool = gcp();

        if isempty(pool)
            cosmo_warning(['Parallel toolbox is available, but '...
                            'unable to open pool; using nproc=1']);
            nproc_available=1;
        else
            nworkers=pool.NumWorkers();

            if nproc_wanted>nworkers
                cosmo_warning(['nproc=%d requested but only %d '...
                            'workers available; recommended '...
                            'usage is nproc=%d'],...
                            nproc_wanted,nworkers,nworkers);
            end

            nproc_available=nproc_wanted;
        end
    else
        nproc_available=1;
        if nproc_wanted>nproc_available
            cosmo_warning(['nproc=%d requested but parallel toolbox '...
                            'or java not available; using nproc=%d'], ...
                            nproc_wanted, nproc_available);
        end
    end

function nproc_available=get_nproc_available_octave(nproc_wanted)
% return nproc_wanted if the Octave 'parallel' package is available, or 1
% otherwise
% (the parallel package does not support returning the number
% of CPUs available)
    if cosmo_check_external('octave_pkg_parallel',false)
        nworkers=nproc('all');

        if nproc_wanted>nworkers
                cosmo_warning(['nproc=%d requested but only %d '...
                            'workers available; recommended '...
                            'usage is nproc=%d'],...
                            nproc_wanted,nworkers);
        end

        nproc_available=nproc_wanted;
    else
        nproc_available=1;
        if nproc_wanted>nproc_available
            cosmo_warning(['nproc=%d requested but parallel toolbox '...
                            'not available; setting nproc=%d'], ...
                            nproc_wanted, nproc_available);
        end
    end

function tf=platform_has_functions(function_names)
    tf=all(cellfun(@(x)~isempty(which(x)),function_names));
