function ds_stacked=cosmo_stack(datasets,dim,check_)
% stacks multiple datasets to yield a single dataset
%
% ds_stacked=cosmo_stack(datasets[,dim])
%
% Inputs
%   datasets     Nx1 cell with input datasets
%   dim          dimension over which data is stacked. This should be
%                either 1 (stack samples) or 2 (stack features).
%                The default is 1.
%
% Ouput:
%   ds_stacked   Stacked dataset. If dim==1 [or dim==2] and the K-th
%                dataset has size M_K x N_K, then it is required that all
%                N_* [M_*] are the same, and the output has size
%                sum(M_*) x N_1 [M_1 x sum(N_*)]. It is also required that
%                all input datasets have the same values across all
%                the feature [sample] attributes.
%
% Example:
%     % Build example data for split-half analysis
%     % Normally, half1 and half2 could be from real brain data
%     % that is imported using, e.g., cosmo_fmri_dataset
%     ds=cosmo_synthetic_dataset('nchunks',2,'ntargets',3);
%     half1=cosmo_slice(ds,ds.sa.chunks==1); % .samples is 3x6
%     half2=cosmo_slice(ds,ds.sa.chunks==2); % .samples is 3x6
%     %
%     % join the data in the two halves, over samples.
%     % stacking makes .samples a (3+3)x6 matrix
%     merged=cosmo_stack({half1,half2});
%     cosmo_disp(merged.samples)
%     > [  2.03    -0.892    -0.826     -1.08       3.4     -1.29
%     >   0.584      1.84      1.17    -0.848      1.25      2.04
%     >   -3.68    -0.262     0.321     0.844     -1.37      1.73
%     >    1.72    0.0975     0.441      1.86     0.479    0.0832
%     >   -1.05      2.04    -0.209    -0.486    -0.955      2.74
%     >   -1.33     0.482      2.39     0.502      1.17     -0.48 ]
%     cosmo_disp(merged.sa)
%     > .targets
%     >   [ 1
%     >     2
%     >     3
%     >     1
%     >     2
%     >     3 ]
%     > .chunks
%     >   [ 1
%     >     1
%     >     1
%     >     2
%     >     2
%     >     2 ]
%     %
%     % data can also be merged over features, by using dim=2
%     % here generated data simulates two (tiny) regions of interest
%     roi1=cosmo_slice(ds,[1 3],2);    % .samples is 6x2
%     roi2=cosmo_slice(ds,[2 4 5],2);  % .samples is 6x3
%     % stacking makes .samples a 6x(2+3) matrix
%     roi_both=cosmo_stack({roi1,roi2},2);
%     cosmo_disp(roi_both.samples)
%     > [  2.03    -0.826    -0.892     -1.08       3.4
%     >   0.584      1.17      1.84    -0.848      1.25
%     >   -3.68     0.321    -0.262     0.844     -1.37
%     >    1.72     0.441    0.0975      1.86     0.479
%     >   -1.05    -0.209      2.04    -0.486    -0.955
%     >   -1.33      2.39     0.482     0.502      1.17 ]
%     cosmo_disp(roi_both.fa)
%     > .i
%     >   [ 1         3         2         1         2 ]
%     > .j
%     >   [ 1         1         1         2         2 ]
%     > .k
%     >   [ 1         1         1         1         1 ]
%     %
%     % stacking incompatible datasets gives an error
%     cosmo_stack({roi1,half1})
%     > error('value mismatch: .fa.i')
%     cosmo_stack({roi1,half1},2)
%     > error('value mismatch: .sa.targets')
%
% Note:
%   this function is like the inverse of cosmo_split, in the sense that if
%       ds_splits=cosmo_split(ds, split_by, dim),
%   produces output (i.e., does not throw an error), then using
%       ds_humpty_dumpty=cosmo_stack(ds_splits,dim)
%   means that ds and ds_humpty_dumpty contain the same data, except that
%   the order of the data (in the rows [or columns] of .samples, and values
%   in .sa [.fa]) may be in different order if dim==1 [dim==2].
%
% See also: cosmo_split
%
% NNO Sep 2013


    if nargin<2,
        dim=1;
    end

    if nargin<3
        check_=true;
    end

    if ~iscell(datasets)
        error('expected cell input');
    end

    n=numel(datasets);
    if n==0
        error('empty cell input')
    end

    ds_stacked=datasets{1}; % take first dataset as starting point for output

    if all(dim~=[1 2])
        error('dim should be 1 or 2');
    end

    % set the field names for the dimension to be stacked, and the other
    % one
    attrs_fns={'sa','fa'};
    stack_fn=attrs_fns{dim};

    other_dim=3-dim; % the other dimension
    merge_fn=attrs_fns{other_dim};

    % stack attributes over dim
    if isfield(ds_stacked, stack_fn)
        fns=fieldnames(ds_stacked.(stack_fn));
        nfn=numel(fns);

        for k=1:nfn
            % check k-th fieldname
            fn=fns{k};
            vs=cell(n,1);
            for j=1:n
                ds=datasets{j};

                % check presence of fieldname
                if ~isfield(ds.(stack_fn),fn)
                    error('field name missing for %d-th input: .%s.%s', ...
                                        j, stack_fn, fn);
                end

                v=ds.(stack_fn).(fn);

                v_size=size(v, other_dim);
                if j==1
                    v_size_expected=v_size;
                elseif v_size_expected~=v_size;
                    error('input %d has %d values in dimension %d, ',...
                            'for %s.%s, first input has %d values',...
                            j, v_size, other_dim, ...
                            stack_fn, fn, v_size_expected);
                end

                vs{j}=v;
            end

            ds_stacked.(stack_fn).(fn)=cat_values(dim,vs);
        end
    end

    if check_
        % for the other dim, just make sure that the attributes are identical
        if isfield(ds_stacked, merge_fn)
            fns=fieldnames(ds_stacked.(merge_fn));
            nfn=numel(fns);

            for k=1:nfn
                % check k-th fieldname
                fn=fns{k};
                for j=1:n
                    ds=datasets{j};
                    % require that the fieldname is present
                    if ~isfield(ds.(merge_fn),fn)
                        error('field name not found for %d-th input: .%s.%s', ...
                                            j, merge_fn, fn);
                    end
                    % if different throw an error
                    if ~isequal(ds.(merge_fn).(fn), ds_stacked.(merge_fn).(fn))
                        error('value mismatch: .%s.%s', merge_fn, fn);
                    end
                end
            end
        end
    end




    % we're good for the attributes - let's stack the sample data
    vs=cell(1,n);
    other_dim_sizes=zeros(1,n);
    for k=1:n
        samples=datasets{k}.samples;
        vs{k}=samples;
        other_dim_sizes=size(samples,other_dim);
    end

    if ~all(other_dim_sizes==other_dim_sizes(1))
        i=find(other_dim_sizes~=other_dim_sizes(1));
        error(['size mismatch between elements #%d (%d) and %%d (%d) ' ...
                    'in dimension %d'], ...
                    1, dim_sizes(1), i, dim_sizes(i), otherdim);
    end

    ds_stacked.samples=cat(dim,vs{:});

    if check_
        cosmo_check_dataset(ds_stacked);
    end


function c=cat_values(dim, vs)
    if iscell(vs) && ~isempty(vs) && ischar(vs{1})
        transpose=dim==2;

        vcat=cat(1,vs{:});
        c=cellstr(vcat);

        if transpose
            c=c';
        end
    else
        c=cat(dim, vs{:});
    end
