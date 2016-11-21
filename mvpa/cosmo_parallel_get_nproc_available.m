function nproc_available=cosmo_parallel_get_nproc_available(varargin)
% get number of processes available from Matlab parallel processing pool
%
% nproc=cosmo_parallel_get_nproc_available()
%
% Input:
%   'nproc',nproc_wanted            Number of desired processes
%                                   default: Inf
%
% Output:
%   nproc_available                 Number of available parallel processes.
%                                   - On Matlab: this requires the parallel
%                                     computing toolbox
%                                   - On Octave: this requires the parallel
%                                     toolbox
%                                   If the required toolbox is not
%                                   available, then nproc_available=1.
%                                   If there are nproc_available processes
%                                   available and
%                                     nproc_available<nproc_wanted
%                                   then nproc=nproc_available.
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    default=struct();
    default.nproc=Inf;

    opt=cosmo_structjoin(default,varargin{:});
    check_inputs(opt);


    nproc_wanted=opt.nproc;
    wants_multithreaded = nproc_wanted>1;

    if wants_multithreaded
        if cosmo_wtf('is_matlab')
            nproc_available=get_nproc_available_matlab(nproc_wanted);

        elseif cosmo_wtf('is_octave')
            nproc_available=get_nproc_available_octave(nproc_wanted);

        else
            assert(false,'this should not happen');

        end

        nproc_available=min(nproc_available,nproc_wanted);

        if nproc_available==1
            cosmo_warning(['Parallel computing not available, using '...
                            'single thread']);
        end
    else
        nproc_available=1;
    end


function check_inputs(opt)
    assert(isfield(opt,'nproc'));
    nproc=opt.nproc;
    if ~(isnumeric(nproc) && ...
            isscalar(nproc) && ...
            nproc>=1 && ...
            round(nproc)==nproc)
        error('nproc must be a positive scalar');
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

            if nproc_wanted>nworkers && isfinite(nproc_wanted);
                cosmo_warning(['nproc=%d requested but only %d '...
                            'workers available; setting '...
                            'nproc=%d'],...
                            nproc_wanted,nworkers,nworkers);
            end

            nproc_available=nworkers;
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
        nworkers=nproc('overridable');

        if nproc_wanted>nworkers
                cosmo_warning(['nproc=%d requested but only %d '...
                            'workers available; setting '...
                            'nproc=%d'],...
                            nproc_wanted,nworkers);
        end

        nproc_available=nworkers;
    else
        nproc_available=1;
        if nproc_wanted>nproc_available && isfinite(nproc_wanted)
            cosmo_warning(['nproc=%d requested but parallel toolbox '...
                            'not available; setting nproc=%d'], ...
                            nproc_wanted, nproc_available);
        end
    end

function tf=platform_has_functions(function_names)
    tf=all(cellfun(@(x)~isempty(which(x)),function_names));
