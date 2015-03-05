function nbrhood=cosmo_spherical_neighborhood(ds, varargin)
% computes neighbors for a spherical searchlight
%
% nbrhood=cosmo_spherical_neighborhood(ds, opt)
%
% Inputs
%   ds                  a dataset struct, either:
%                       - in fmri form (from cosmo_fmri_dataset), when
%                         ds.fa has the fields .i, .j and .k
%                       - in meeg source form (from cosmo_meeg_dataset),
%                         when ds.fa has the field .pos
%   'radius', r         } either use a radius of r, or select
%   'count', c          } approximately c voxels per searchlight
%                       Notes:
%                       - These two options are mutually exclusive
%                       - When using this option for an fmri dataset, the
%                         radius r is expressed in voxel units; for an meeg
%                         source dataset, the radius r is in whatever units
%                         the source dataset uses for the positions
%   'progress', p       show progress every p features (default: 1000)
%
% Outputs
%   nbrhood             dataset-like struct without .sa or .samples, with:
%     .a                dataset attributes, from dataset.a
%     .fa               feature attributes with the same fields as fs.fa,
%                       and in addition the fields:
%       .nvoxels        1xP number of voxels in each searchlight
%       .radius         1xP radius in voxel units
%       .center_ids     1xP feature center id
%     .neighbors         Px1 cell so that center2neighbors{k}==nbrs contains
%                       the feature ids of the neighbors of feature k
%
% Example:
%     ds=cosmo_synthetic_dataset('type','fmri');
%     radius=1; % radius=3 is typical for 'real-world' searchlights
%     nbrhood=cosmo_spherical_neighborhood(ds,'radius',radius,...
%                                             'progress',false);
%     cosmo_disp(nbrhood)
%     > .a
%     >   .fdim
%     >     .labels
%     >       { 'i'  'j'  'k' }
%     >     .values
%     >       { [ 1         2         3 ]  [ 1         2 ]  [ 1 ] }
%     >   .vol
%     >     .mat
%     >       [ 2         0         0        -3
%     >         0         2         0        -3
%     >         0         0         2        -3
%     >         0         0         0         1 ]
%     >     .dim
%     >       [ 3         2         1 ]
%     >     .xform
%     >       'scanner_anat'
%     > .fa
%     >   .nvoxels
%     >     [ 3         4         3         3         4         3 ]
%     >   .radius
%     >     [ 1         1         1         1         1         1 ]
%     >   .center_ids
%     >     [ 1         2         3         4         5         6 ]
%     >   .i
%     >     [ 1         2         3         1         2         3 ]
%     >   .j
%     >     [ 1         1         1         2         2         2 ]
%     >   .k
%     >     [ 1         1         1         1         1         1 ]
%     > .neighbors
%     >   { [ 1         4         2 ]
%     >     [ 2         1         5         3 ]
%     >     [ 3         2         6 ]
%     >     [ 4         1         5 ]
%     >     [ 5         4         2         6 ]
%     >     [ 6         5         3 ]           }
%
%
% See also: cosmo_fmri_dataset, cosmo_meeg_dataset
%
% NNO Aug 2013

    check_input(varargin{:});

    defaults=struct();
    defaults.progress=1000;
    opt=cosmo_structjoin(defaults,varargin);

    [use_fixed_radius,radius,voxel_count]=get_selection_params(opt);
    cosmo_check_dataset(ds);

    nfeatures=size(ds.samples,2);
    if nfeatures<voxel_count
        error('Cannot select %d features: only %d are present',...
                    voxel_count, nfeatures);
    end

    use_grid=ds_has_pos_in_grid(ds);

    if use_grid
        [fdim, fa_ordered, pos, grid_dim, lin2feature_ids]=get_linear_mapping(ds);
    else
        [fdim, fa_ordered, pos]=get_pos_attributes(ds);
    end

    % compute voxel offsets relative to origin
    [sphere_offsets, o_distances]=get_sphere_offsets(radius);

    % allocate space for output
    center_ids=1:nfeatures;
    ncenters=numel(center_ids);
    neighbors=cell(ncenters,1);
    nvoxels=zeros(1,ncenters);
    final_radius=zeros(1,ncenters);

    show_progress=opt.progress>0;

    if show_progress
        if opt.progress<1
            opt.progress=ceil(ncenters/opt.progress);
        end
        clock_start=clock();
        prev_progress_msg='';
    end

    % go over all features
    for k=1:ncenters
        center_id=center_ids(k);
        center_pos=pos(:,center_id);

        % - in case of a variable radius, keep growing sphere_offsets until
        %   there are enough voxels selected. This new radius is kept
        %   for every subsequent iteration.
        % - in case of a fixed radius this loop is left after the first
        %   iteration.
        while true
            if use_grid
                % add offsets to center
                all_around_pos=bsxfun(@plus, center_pos', sphere_offsets);

                % see which ones are outside the volume
                outside_msk=all_around_pos<=0 | ...
                                bsxfun(@minus,grid_dim,all_around_pos)<0;

                % collapse over 3 dimensions
                feature_outside_msk=any(outside_msk,2);

                % get rid of those outside the volume
                around_pos=all_around_pos(~feature_outside_msk,:);

                % if using variable radius, keep track of those
                if ~use_fixed_radius
                    center_distances=o_distances(~feature_outside_msk);
                end

                % convert to linear indices
                around_lin=fast_sub2ind(grid_dim,around_pos(:,1), ...
                                            around_pos(:,2), ...
                                            around_pos(:,3));

                % convert linear to feature ids
                around_feature_ids=[lin2feature_ids{around_lin}];
            else
                [around_feature_ids,center_distances]=eucl_neighbors(...
                                                            center_pos,...
                                                            pos,radius);
            end

            % also exclude those that were not mapped (outside the mask)
            feature_mask=around_feature_ids>0;
            around_feature_ids=around_feature_ids(feature_mask);


            if use_fixed_radius
                break; % we're done selecting voxels
            elseif numel(around_feature_ids)<voxel_count
                % the current radius is too small.
                % increase the radius by half a voxel and recompute new
                % offsets, then try again in the next iteration.
                radius=radius+.5;
                [sphere_offsets, o_distances]=get_sphere_offsets(radius);
                continue
            end

            % apply the feature_id mask to distances
            center_distances=center_distances(feature_mask);

            % coming here, the radius is variable and enough features
            % were selected. Now decide which voxels to keep,
            % and also compute the metric radius, then leave the while
            % loop.

            nselect=with_approx(around_feature_ids,...
                                                center_distances,voxel_count);
            around_feature_ids=around_feature_ids(1:nselect);

            if nselect>0
                variable_radius=center_distances(nselect);
            else
                variable_radius=NaN;
            end
            break; % we're done
        end


        % store results
        neighbors{k}=around_feature_ids(:)';
        nvoxels(k)=numel(around_feature_ids);
        if use_fixed_radius
            final_radius(k)=radius;
        else
            final_radius(k)=variable_radius;
        end

        if show_progress && (k==1 || k==ncenters || mod(k,opt.progress)==0)
            mean_size=mean(nvoxels(1:k));
            msg=sprintf('mean size %.1f', mean_size);
            prev_progress_msg=cosmo_show_progress(clock_start, ...
                                       k/ncenters, msg, prev_progress_msg);
        end
    end

    % set the dataset and feature attributes
    nbrhood=struct();
    nbrhood.a=ds.a;
    nbrhood.a.fdim=fdim;

    fa_ordered=cosmo_slice(fa_ordered,center_ids,2,'struct');
    nbrhood.fa=cosmo_structjoin('nvoxels',nvoxels,...
                                'radius',final_radius,...
                                'center_ids',center_ids(:)',...
                                fa_ordered);

    nbrhood.neighbors=neighbors;

    cosmo_check_neighborhood(nbrhood);


function [feature_ids,distances]=eucl_neighbors(center_pos,pos,radius)
    eucl_distances=sum(bsxfun(@minus,center_pos,pos).^2,1).^.5;

    within_distance_mask=eucl_distances<=radius;
    unsorted_feature_ids=find(within_distance_mask);
    unsorted_distances=eucl_distances(unsorted_feature_ids);

    [distances,i]=sort(unsorted_distances);
    feature_ids=unsorted_feature_ids(i);




function tf=ds_has_pos_in_grid(ds)
    tf=cosmo_isfield(ds,'a.fdim.labels') && ...
                all(cosmo_match({'i','j','k'},ds.a.fdim.labels));

function lin=fast_sub2ind(sz, i, j, k)
    lin=sz(1)*(sz(2)*(k-1)+(j-1))+i;

function pos=with_approx(ids, distances, voxel_count)
    if voxel_count<=0
        pos=0;
        return
    end

    max_distance=distances(voxel_count);
    first=find(distances<max_distance,1,'last')+1;
    last=find(distances>max_distance,1,'first')-1;

    if isempty(first)
        first=1;
    end

    if isempty(last)
        last=numel(distances);
    end

    delta_first=voxel_count-first;
    delta_last=last-voxel_count;

    if delta_first==delta_last
        % select pseudo-randomly
        if delta_first==0 || mod(sum(ids)+numel(distances),2)==0
            pos=first;
        else
            pos=last;
        end
    elseif delta_first<delta_last
        pos=first;
    else
        pos=last;
    end

function [fdim, fa, pos]=get_pos_attributes(ds)
    [two,index]=cosmo_dim_find(ds,'pos',true);
    if two~=2
        error('dimension ''pos'' must be a feature dimension');
    end

    fdim=struct();
    fdim.labels=ds.a.fdim.labels(index);
    fdim.values=ds.a.fdim.values(index);

    if size(fdim.values{1},1)~=3
        error('dimension ''pos'' must be 3xN');
    end

    fa=struct();
    fa.pos=ds.fa.pos;

    pos=fdim.values{1}(:,fa.pos);


function [fdim, fa, ijk, orig_dim, lin2feature_ids]=get_linear_mapping(ds)
    [two, index]=cosmo_dim_find(ds,'i',true);
    if two~=2
        error('dimension ''i'' must be a feature dimension');
    end
    [fdim,fa,ijk]=get_spherical_fdim_from_ijk(ds, index);

    orig_dim=cellfun(@numel,ds.a.fdim.values(index+(0:2)));
    orig_dim=orig_dim(:)'; % ensure row vector
    orig_nvoxels=prod(orig_dim);

    % mapping from all linear voxel indices to feature indices
    lin_ids=fast_sub2ind(orig_dim, ijk(1,:), ijk(2,:), ijk(3,:));
    [idxs,unq_lin_ids_cell]=cosmo_index_unique({lin_ids});
    unq_lin_ids=unq_lin_ids_cell{1};

    % lin2feature_ids{k}={i1,...,iN} means that the linear voxel index k
    % corresponds to features i1,...iN
    lin2feature_ids=cell(orig_nvoxels,1);
    for k=1:numel(unq_lin_ids)
        lin_id=unq_lin_ids(k);
        lin2feature_ids{lin_id}=idxs{k}(:)';

    end


function [fdim,fa,ijk]=get_spherical_fdim_from_ijk(ds, index)
    cosmo_isfield(ds,'a.fdim.labels',true);

    dim_labels=ds.a.fdim.labels(:);
    dim_values=ds.a.fdim.values(:);

    ijk_labels={'i';'j';'k'};
    nlabels=numel(ijk_labels);
    idx_labels=index+(0:(nlabels-1));
    if numel(dim_labels)<index+(nlabels-1) || ...
            ~isequal(dim_labels(idx_labels),ijk_labels)
        error('expected labels %s in .a.fdim.labels(%d:%d)',...
                    cosmo_strjoin(ijk_labels,', '),index,index+nlabels-1);
    end

    fdim=struct();
    fdim.labels=dim_labels(idx_labels);
    fdim.values=cellfun(@(x)x(:)',dim_values(idx_labels),...
                        'UniformOutput',false);

    ijk_cell=cell(1,nlabels);
    fa=struct();
    for j=1:nlabels
        label=ijk_labels{j};
        fa_value=ds.fa.(label);
        fa.(label)=fa_value;
        ijk_cell{j}=fdim.values{j}(fa_value);
    end
    ijk=cat(1,ijk_cell{:});








function [sphere_offsets, o_distances]=get_sphere_offsets(radius)
    % return offsets and euclidean (and a bit manhattan) distance
    % from origin
    [sphere_offsets, norm2_distances]=cosmo_sphere_offsets(radius);

    % compute manhattan distance
    norm1_distances=sum(abs(sphere_offsets),2);

    % add a tiny bit of manhattan to make distances more varied
    norm12_distances=norm2_distances+1e-5*norm1_distances;

    % ensure distances are sorted
    [o_distances,i]=sort(norm12_distances);
    sphere_offsets=sphere_offsets(i,:);


function check_input(varargin)
    if numel(varargin)<1 || isscalar(varargin{1})
        % change in parameters
        raise_parameter_error();
    end

function [use_fixed_radius,radius,voxel_count]=get_selection_params(opt)
    if isfield(opt,'radius')
        if isfield(opt,'count')
            raise_parameter_error();
        elseif isscalar(opt.radius) && opt.radius>=0
            use_fixed_radius=true;
            radius=opt.radius;
            voxel_count=NaN;
            return
        end
    elseif isfield(opt,'count') && isscalar(opt.count) && ...
                opt.count>=0 && round(opt.count)==opt.count
        use_fixed_radius=false;
        radius=1; % starting point
        voxel_count=opt.count;
        return;
    end

    raise_parameter_error();



function raise_parameter_error()
    name=mfilename();
    error(['Illegal parameters, use one of:\n',...
        '- %s(...,''radius'',r) to use a radius of r voxels\n',...
        '- %s(...,''count'',c) to select c voxels per searchlight\n',...
        '(As of January 2014 the syntax of this function has changed)'],...
            name,name);


