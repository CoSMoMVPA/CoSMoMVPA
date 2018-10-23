function result=cosmo_parcellfun(nproc,func,arg_cell,varargin)
% applies a function to elements in a cell in parallel
%
% result=cosmo_parcellfun(nproc,func,arg_cell,...)
%
% Inputs:
%   nproc                   Maximum number of processes to run in parallel
%   func                    Function handle that takes a single input
%                           argument and gives a single output
%   arg_cell                Cell with arguments to be given to func
%   'UniformOutput',o_u     If false, then the output is converted to a
%                           numeric or logical array. Default: true
%
% Output:
%   result                  Cell with the same size as arg_cell, with
%                               result{i}=func(arg_cell{i})
%                           If o_u is true, then result is converted to a
%                           numeric or logical array, assuming that each
%                           output is a scalar. If any output is not a
%                           scalar while o_u is true, an exception is
%                           thrown.
%

    default=struct();
    default.UniformOutput=true;

    opt=cosmo_structjoin(default,varargin{:});

    check_input(nproc,func,arg_cell,opt);

    % see how many processes to use
    narg_cell=numel(arg_cell);

    if narg_cell==1
        nproc_to_use=1;
    else
        nproc_available=cosmo_parallel_get_nproc_available(opt);
        nproc_to_use=min([nproc,narg_cell,nproc_available]);
    end

    if nproc_to_use<=1
        helper_func=@run_single_thread;
    else
        is_matlab=cosmo_wtf('is_matlab');
        if is_matlab
            helper_func=@run_parallel_matlab;
        else
            helper_func=@run_parallel_octave;
        end
    end

    result=helper_func(nproc_to_use,func,arg_cell,opt);


function args=get_extra_builtin_cellfun_args(opt)
    if opt.UniformOutput
        args={};
    else
        args={'UniformOutput',false};
    end


function result=run_single_thread(nproc,func,arg_cell,opt)
% single thread, Matlab of Octave --- redirect to cellfun
    result_cell=cellfun(func,arg_cell,'UniformOutput',false);
    result=convert_to_uniform_output_if_necessary(result_cell,opt);


function result=run_parallel_matlab(nproc,func,arg_cell,opt)
% multi-thread, Matlab
    narg_cell=numel(arg_cell);
    result_cell=cell(size(arg_cell));

    parfor (i=1:narg_cell, nproc)
        result_cell{i}=func(arg_cell{i});
    end

    result=convert_to_uniform_output_if_necessary(result_cell,opt);

function result=convert_to_uniform_output_if_necessary(result_cell,opt)
    if opt.UniformOutput
        is_uniform_func=@(x)isequal(size(x),[1 1]);
        is_uniform_mask=cellfun(is_uniform_func, result_cell);
        if ~all(is_uniform_mask)
            error(['Not all outputs are scalar. Use\n'...
                    '    ''UniformOutput'',false\n'...
                    'to return cell output']);
        end

        % concatenate and put in original shape
        result=reshape(cat(1,result_cell{:}),size(result_cell));
    else
        result=result_cell;
    end

function result=run_parallel_octave(nproc,func,arg_cell,opt)
% multi-thread, Octave
    extra_octave_args={'VerboseLevel',0};

    cellfun_args=get_extra_builtin_cellfun_args(opt);
    result=parcellfun(nproc,func,arg_cell,...
                                cellfun_args{:},...
                                extra_octave_args{:});



function check_input(nproc,func,arg_cell,opt)
    if ~(isnumeric(nproc) && ...
            isscalar(nproc) && ...
            round(nproc)==nproc && ...
            nproc>0)
        error(['nproc must be a positive integer. Use nproc=inf to use '...
                'as many processes as there are cores available']);
    end

    if ~isa(func,'function_handle')
        error('second argument must be a function handle');
    end

    if ~iscell(arg_cell)
        error('third argument must be a cell');
    end

    if ~(islogical(opt.UniformOutput) && ...
                isscalar(opt.UniformOutput))
        error('option ''UniformOutput'' must be scalar boolean');
    end



