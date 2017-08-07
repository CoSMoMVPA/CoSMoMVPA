function ds_stacked=cosmo_stack(ds_cell,varargin)
% stacks multiple datasets to yield a single dataset
%
% ds_stacked=cosmo_stack(datasets[,dim,merge])
%
% Inputs
%   datasets     cell with input datasets. Each input dataset must be a
%                struct and have a field .samples
%   dim          dimension over which data is stacked. This should be
%                either 1 (stack .samples and .sa) or 2 (stack features
%                and .fa).
%                The default is 1.
%   merge        Merge strategy for the dimension other than which is
%                stacked (i.e. .fa if dim==1 and .sa if dim==2), as well as
%                the dataset attributes (.a). Must be one of:
%                - 'drop'            drop all elements
%                - 'drop_nonunique'  elements differing are dropped
%                - 'unique'          raise an exception if elements differ
%                - I                 integer; use data from datasets{I}
%                The default is 'unique'
%   check        Boolean indicating whether to check for the proper size of
%                the input datasets. The default is true; setting this to
%                false makes this function run faster but, if the input
%                dataset do not have proper sizes, will result in less
%                informative error messages (if any). Use this option only
%                if you are sure that the inputs have proper dimensions.
%
% Ouput:
%   ds_stacked   Stacked dataset. If dim==1 [or dim==2] and the K-th
%                dataset has .samples with size M_K x N_K, then it is
%                required that all N_* [M_*] are the same, and the output
%                has size sum(M_*) x N_1 [M_1 x sum(N_*)].
%                It is also required that
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
%     > .chunks
%     >   [ 1
%     >     1
%     >     1
%     >     2
%     >     2
%     >     2 ]
%     > .targets
%     >   [ 1
%     >     2
%     >     3
%     >     1
%     >     2
%     >     3 ]
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
%   - This function is like the inverse of cosmo_split, i.e. if
%         ds_splits=cosmo_split(ds, split_by, dim),
%     produces output (i.e., does not throw an error), then using
%         ds_humpty_dumpty=cosmo_stack(ds_splits,dim)
%     means that ds and ds_humpty_dumpty contain the same data, except that
%     the order of the data (in the rows [or columns] of .samples, and
%     values in .sa [.fa]) may be in different order if dim==1 [dim==2].
%
% See also: cosmo_split
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #


    [dim, merge_method, check]=process_parameters(ds_cell, varargin{:});


    n=numel(ds_cell);

    if n==0
        error('empty cell input');
    elseif n==1
        ds_stacked=ds_cell{1};
        return;
    end

    sample_values=get_struct_values(ds_cell, 'samples');
    if isempty(sample_values)
        error('missing field .samples');
    end
    if check
        sample_sizes=get_dimension_sizes(dim, sample_values);
    else
        sample_sizes=[];
    end
    ds_stacked.samples=stack_values(dim, sample_values, '.samples', check);

    % set the field names for the dimension to be stacked, and the other
    % one
    attrs_keys={'sa','fa'};
    stack_key=attrs_keys{dim};

    to_stack_attr=get_struct_values(ds_cell, stack_key);
    if ~isempty(to_stack_attr)

        ds_stacked.(stack_key)=stack_structs(dim,to_stack_attr,...
                                                sample_sizes,...
                                                ['.' stack_key]);
    end

    other_dim=3-dim; % the other dimension
    merge_key=attrs_keys{other_dim};

    to_merge_attr=get_struct_values(ds_cell, merge_key);
    if ~isempty(to_merge_attr)
        ds_stacked.(merge_key)=merge_structs(to_merge_attr,merge_method,...
                                    ['.' merge_key]);
    end



    to_merge_a=get_struct_values(ds_cell, 'a');
    if ~isempty(to_merge_a)
        ds_stacked.a=merge_structs(to_merge_a,merge_method,'.a');
    end



function [dim, merge, check]=process_parameters(ds_cell, varargin)
    narg=numel(varargin);
    if narg<1 || isempty(varargin{1})
        dim=1;
    else
        dim=varargin{1};
        if ~(isequal(dim,1) || isequal(dim,2))
            error('second argument must be 1 or 2');
        end
    end

    if narg<2 || isempty(varargin{2})
        merge='unique';
    else
        merge=varargin{2};
        if ~isnumeric(merge) && ...
                ~cosmo_match({merge},{'drop','drop_nonunique','unique'})
            error('illegal value for third argument ''merge''');
        end
    end

    if narg<3 || isempty(varargin)
        check=true;
    else
        check=varargin{3};

        if ~(islogical(check) && isscalar(check))
            error('fourth argument ''check'' must be a scalar boolean');
        end

    end

    if ~iscell(ds_cell)
        error('expected cell input');
    end




function values=get_struct_values(struct_cell, key)
    n=numel(struct_cell);
    values=cell(n,1);
    has_values=false;
    for k=1:n
        s=struct_cell{k};
        if isfield(s,key)
            has_values=true;
            values{k}=s.(key);
        end
    end

    if ~has_values
        values=[];
    end


function keys=get_struct_keys(struct_cell)
    n=numel(struct_cell);
    keys=cell(n,1);
    for k=1:n
        keys{k}=fieldnames(struct_cell{k});
    end


function s=merge_structs(vs, merge_method, where)
    if strcmp(merge_method,'drop')
        s=struct();
        return;
    elseif isnumeric(merge_method)
        if ~isscalar(merge_method) || merge_method<1 || ...
                merge_method>numel(vs) || round(merge_method)~=merge_method
            error(['''merge'' parameter, when an integer, must be in'...
                        'the range 1:%d'],numel(vs));
        end
        s=vs{merge_method};
        return;
    elseif ~cosmo_match({merge_method},{'drop_nonunique','unique'})
        error('illegal value for ''merge'' parameter');
    end


    all_keys_cell=get_struct_keys(vs);

    keys=unique(cat(1,all_keys_cell{:}));
    nkeys=numel(keys);

    s=struct();

    for k=1:nkeys
        key=keys{k};
        values=get_struct_values(vs, key);

        [has_unique_elem, unique_elem]=get_single_unique_element(values);

        if ~has_unique_elem
            switch merge_method
                case 'drop_nonunique'
                    % do not store values
                    continue;

                case 'unique'
                    error('non-unique elements in %s.%s',...
                            where, key);

                otherwise
                    error('illegal value for merge: %s', merge_method);
            end
        end

        s.(key)=unique_elem;
    end

function [has_unique_elem, unique_elem]=get_single_unique_element(vs)
    n=numel(vs);

    has_elem=false;
    unique_elem=[];

    for k=1:n
        v=vs{k};
        if isempty(v)
            continue;
        end

        if has_elem
            if ~isequaln(v, unique_elem)
                has_unique_elem=false;
                return;
            end
        else
            has_elem=true;
            unique_elem=v;
        end
    end

    has_unique_elem=true;



function s=stack_structs(dim, structs, expected_sizes, where)
    check=~isempty(expected_sizes);
    n=numel(structs);

    for k=1:n
        s=structs{k};

        if ~isstruct(s)
            error('%d-th input is not a struct', k);
        end

        keys=sort(fieldnames(s));

        if k==1
            nkeys=numel(keys);

            stack_args=cell(n, nkeys);

            % keep track of the keys in the first input,
            % and how many values it has along the other dimension
            first_keys=keys;

        elseif ~isequal(keys, first_keys)
            delta=setxor(keys, first_keys);
            error(['key mismatch between 1st and %d-th input in %s ' ...
                        'for key ''%s'''], k, where, delta{1});
        end

        for j=1:nkeys
            key=keys{j};
            v=s.(key);

            if check && size(v,dim)~=expected_sizes(k)
                error(['size mismatch in %d-th input: size(%s.%s,%d)=%d'...
                        ', but size(.samples,%d)=%d'],...
                            k, where, key, dim, size(v,dim), ...
                            dim, expected_sizes(k));
            end

            stack_args{k,j}=v;
        end
    end

    % allocate space for output
    s=struct();

    for j=1:nkeys
        key=keys{j};
        s.(key)=stack_values(dim, stack_args(:,j), where, check);
    end

function sizes=get_dimension_sizes(dim, vs)
    n=numel(vs);
    sizes=zeros(n,1);
    for k=1:n
        sizes(k)=size(vs{k},dim);
    end

function ensure_same_size_along_dim(dim, vs, where)
    % throw an error if element sizes along vs is not the same

    sizes=get_dimension_sizes(dim, vs);
    if numel(sizes)>1
        m=sizes(1)~=sizes(2:end);
        if any(m)
            i=find(m,1)+1;
            error(['size mismatch along dimension %d between 1st '...
                        'and %-dth input for %s'], dim, i, where);
        end
    end


function c=stack_values(dim, vs, where, check)
    % stacks the contents of vs along dimension dim, or throw an error
    % if sizes are not compatible
    if check
        other_dim=3-dim;
        ensure_same_size_along_dim(other_dim, vs, where);
    end

    c=cat(dim, vs{:});

