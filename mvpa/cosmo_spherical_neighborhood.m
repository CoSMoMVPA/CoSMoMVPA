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
%                         when ds.fa has the field .pos. In this case, the
%                         features must have positions that can be
%                         converted to a grid.
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
%     .neighbors        Px1 cell so that center2neighbors{k}==nbrs contains
%                       the feature ids of the neighbors of feature k
%                       If the dataset has a field ds.fa.inside, then
%                       features that are not inside are not included as
%                       neighbors in the output
%     .origin           Has fields .a and .fa from input dataset
%
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
%     > .origin
%     >   .a
%     >     .fdim
%     >       .labels
%     >         { 'i'
%     >           'j'
%     >           'k' }
%     >       .values
%     >         { [ 1         2         3 ]
%     >           [ 1         2 ]
%     >           [ 1 ]                     }
%     >     .vol
%     >       .mat
%     >         [ 2         0         0        -3
%     >           0         2         0        -3
%     >           0         0         2        -3
%     >           0         0         0         1 ]
%     >       .dim
%     >         [ 3         2         1 ]
%     >       .xform
%     >         'scanner_anat'
%     >   .fa
%     >     .i
%     >       [ 1         2         3         1         2         3 ]
%     >     .j
%     >       [ 1         1         1         2         2         2 ]
%     >     .k
%     >       [ 1         1         1         1         1         1 ]
%
%
% Notes:
%   - this function can return neighborhoods with either a fixed number of
%     features, or a fixed radius. When used with a searchlight, the
%     former has the advantage that the number of features is less
%     variable (especially near edges of the brain, in an fmri dataset),
%     which can make it easier to compare result in different regions as
%     the number of features can affect
%     pattern discriminablity. The latter has the advantage that the
%     smoothness of the output maps under the null hypothesis can be more
%     uniformly smooth.
%
% See also: cosmo_fmri_dataset, cosmo_meeg_dataset, cosmo_searchlight
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    check_input(varargin{:});

    defaults=struct();
    defaults.progress=1000;
    opt=cosmo_structjoin(defaults,varargin);

    [use_fixed_radius,radius,voxel_count]=get_selection_params(opt);
    cosmo_check_dataset(ds);

    % ensure not too many features are requested
    feature_mask=get_features_mask(ds);
    nfeatures=sum(feature_mask);
    if nfeatures<voxel_count
        error('Cannot select %d features: only %d are present',...
                    voxel_count, nfeatures);
    end

    % get attributes for output dataset, and the positions and dimension of
    % the grid
    [fdim,fa,pos,grid_dim]=get_spherical_attributes(ds,feature_mask);

    % compute voxel offsets relative to origin
    [sphere_offsets, distances]=get_sphere_offsets(radius);

    % get mapping from linear ids to feature ids
    lin2feature_ids=get_lin2feature_ids(grid_dim,pos,feature_mask);

    % number of features associated with each linear id
    feature_id_count=cellfun(@numel,lin2feature_ids);

    show_progress=opt.progress>0;

    if show_progress
        clock_start=clock();
        prev_progress_msg='';
    end

    % a position may occur at multiple features; only consider unique
    % positions
    pos(:,~feature_mask)=Inf;
    [center_idxs,unq_pos]=cosmo_index_unique(pos');
    keep_unq_pos=~any(isinf(unq_pos),2);
    center_idxs=center_idxs(keep_unq_pos);
    unq_pos=unq_pos(keep_unq_pos,:);
    nunq_centers=numel(center_idxs);

    % allocate space for output
    ncenters=nunq_centers;
    neighbors=cell(ncenters,1);
    nvoxels=zeros(1,ncenters);
    final_radius=zeros(1,ncenters);
    visited=false(1,ncenters);
    center_ids=zeros(1,ncenters);

    % go over all features
    for k=1:nunq_centers
        variable_radius=NaN;
        if voxel_count==0
            feature_ids=zeros(1,0);
        else
            center_pos=unq_pos(k,:)';

            % - in case of a variable radius, keep growing sphere_offsets
            %   until there are enough voxels selected. This new radius is
            %   kept for every subsequent iteration.
            % - in case of a fixed radius this loop is left after the first
            %   iteration.
            while true
                % add offsets to center
                all_around_pos=bsxfun(@plus, center_pos', sphere_offsets);

                % see which ones are outside the volume
                outside_msk=all_around_pos<=0 | ...
                                bsxfun(@minus,grid_dim,all_around_pos)<0;

                % collapse over 3 dimensions
                feature_outside_msk=any(outside_msk,2);

                % get rid of those outside the volume
                around_pos=all_around_pos(~feature_outside_msk,:);


                % convert to linear indices
                around_lin=fast_sub2ind(grid_dim,around_pos(:,1), ...
                                            around_pos(:,2), ...
                                            around_pos(:,3));

                % convert linear to feature ids


                feature_ids=[lin2feature_ids{around_lin}];

                if use_fixed_radius
                    break; % we're done selecting voxels
                elseif numel(feature_ids)<voxel_count
                    % the current radius is too small.
                    % increase the radius by half a voxel and recompute new
                    % offsets, then try again in the next iteration.
                    radius=radius+.5;
                    [sphere_offsets,distances]=get_sphere_offsets(radius);
                    continue
                end


                % if using variable radius, compute distance of each linear
                % index
                center_distances=distances(~feature_outside_msk);

                % get distance for each feature
                feature_distances=get_distances(center_distances,...
                                            feature_id_count(around_lin));

                % coming here, the radius is variable and enough features
                % were selected. Now decide which voxels to keep,
                % and also compute the metric radius, then leave the while
                % loop.

                nselect=boundary_at_approx(feature_ids,...
                                            feature_distances,voxel_count);
                feature_ids=feature_ids(1:nselect);

                variable_radius=feature_distances(nselect);
                break; % we're done
            end
        end


        % store results
        id=center_idxs{k}(1);


        neighbors{k}=feature_ids(:)';
        nvoxels(k)=numel(feature_ids);
        if use_fixed_radius
            final_radius(k)=radius;
        else
            final_radius(k)=variable_radius;
        end

        visited(k)=true;
        assert(center_ids(k)==0);
        center_ids(k)=id;

        if show_progress && (k==1 || k==nunq_centers || ...
                                        mod(k,opt.progress)==0)
            mean_size=mean(nvoxels(visited));
            msg=sprintf('mean size %.1f', mean_size);
            prev_progress_msg=cosmo_show_progress(clock_start, ...
                                   k/nunq_centers, msg, prev_progress_msg);
        end
    end

    not_visited_ids=find(~visited);
    assert(all(cellfun(@numel,neighbors(not_visited_ids))==0));
    neighbors(not_visited_ids)=repmat({zeros(1,0)},...
                                        1,numel(not_visited_ids));


    % set the dataset and feature attributes
    nbrhood=struct();
    nbrhood.a=ds.a;
    nbrhood.a.fdim=fdim;

    % remove sample dimension if present
    if isfield(nbrhood.a,'sdim')
        nbrhood.a=rmfield(nbrhood.a,'sdim');
    end


    fa_full=cosmo_slice(fa,center_ids,2,'struct');
    nbrhood.fa=cosmo_structjoin('nvoxels',nvoxels,...
                                'radius',final_radius,...
                                'center_ids',center_ids(:)',...
                                fa_full);

    nbrhood.neighbors=neighbors;

    nbrhood=align_nbrhood_to_ds_if_possible(ds,nbrhood);
    origin=struct();
    origin.a=ds.a;
    origin.fa=ds.fa;
    nbrhood.origin=origin;

    cosmo_check_neighborhood(nbrhood,ds);



function nbrhood=align_nbrhood_to_ds_if_possible(ds,nbrhood)
   labels=get_dim_label(ds);

   ds_fa=get_spherical_fa_cell(ds.fa,labels);
   nbrhood_fa=get_spherical_fa_cell(nbrhood.fa,labels);

   [unq_ds,idx_ds]=cosmo_index_unique(ds_fa);
   [unq_nbrhood,idx_nbrhood]=cosmo_index_unique(nbrhood_fa);

   if all(cellfun(@numel,unq_ds)==1) && ...
           isequal(sort(cell2mat(unq_ds)),sort(cell2mat(unq_nbrhood)))
       mp=cosmo_align(nbrhood_fa,ds_fa);

       nbrhood.neighbors=nbrhood.neighbors(mp);
       nbrhood.fa=cosmo_slice(nbrhood.fa,mp,2,'struct');
   end


function feature_distances=get_distances(center_distances,feature_id_count)
    % get distances based on selected features
    n=numel(center_distances);
    assert(n==numel(feature_id_count));

    m=max(feature_id_count);
    if m<=1
        % optimization
        feature_distances=center_distances(feature_id_count==1);
        return
    end

    ds=NaN(m,n);

    for k=1:m
        msk=feature_id_count>=k;
        ds(k,msk)=center_distances(msk);
    end

    feature_distances=ds(~isnan(ds));


function lin2feature_ids=get_lin2feature_ids(grid_dim, ...
                                            all_pos,center_mask)
    % returns a function that maps linear ids to feature ids
    % the function takes as input linear ids and the distance for each
    % linear id, and returns the feature ids and their corresponding
    % distances

    orig_nvoxels=prod(grid_dim);

    ijk=all_pos(:,center_mask);

    lin_ids=fast_sub2ind(grid_dim, ijk(1,:), ijk(2,:), ijk(3,:));
    [idxs,unq_lin_ids]=cosmo_index_unique(lin_ids');

    mask2full=find(center_mask);
    % lin2feature_ids{k}={i1,...,iN} means that the linear voxel index k
    % corresponds to features i1,...iN
    lin2feature_ids=cell(orig_nvoxels,1);
    for k=1:numel(unq_lin_ids)
        lin_id=unq_lin_ids(k);
        idx=idxs{k}(:)';
        lin2feature_ids{lin_id}=mask2full(idx);
    end


function feature_mask=get_features_mask(ds)
    % use .fa.inside if it is present, otherwise an array with only true
    % values
    nfeatures=size(ds.samples,2);

    if cosmo_isfield(ds,'fa.inside')
        inside=ds.fa.inside;

        if ~isrow(inside)
            error('field .fa.inside must be a row vector');
        end

        if ~islogical(inside)
            error('field .fa.inside must be logical');
        end

        feature_mask=inside;
    else
        feature_mask=true(1,nfeatures);
    end


function lin=fast_sub2ind(sz, i, j, k)
    lin=sz(1)*(sz(2)*(k-1)+(j-1))+i;

function pos=boundary_at_approx(ids, distances, voxel_count)
    % pseudo-random selection of approximatly voxel_count elements
    if voxel_count<=0
        pos=0;
        return
    end

    assert(issorted(distances));

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

    assert(first==1 || distances(first-1)<distances(first));
    assert(last==numel(distances) || distances(last+1)>distances(first));


function [fdim,fa,ijk,orig_dim]=get_spherical_attributes(ds, center_mask)
    % returns fdim, fa, and ijk positions for dataset
    labels=get_dim_label(ds);

    fdim=get_spherical_fdim(ds,labels);
    fa=get_spherical_fa(ds.fa,labels);

    if cosmo_isfield(ds,'fa.inside')
        fa.inside=center_mask;
    end

    small_ds=cosmo_slice(ds,[],1);
    small_ds_vol=cosmo_vol_grid_convert(small_ds, 'tovol');

    ijk=[small_ds_vol.fa.i;small_ds_vol.fa.j;small_ds_vol.fa.k];

    ijk_labels={'i','j','k'};
    [unused,index]=has_fdim_label(small_ds_vol,ijk_labels);

    orig_dim=cellfun(@numel,small_ds_vol.a.fdim.values(index));
    orig_dim=orig_dim(:)';


function [tf,index]=has_fdim_label(ds, label)
    [two,index]=cosmo_dim_find(ds,label,false);
    tf=~isempty(two) && two==2;


function [labels,index]=get_dim_label(ds)
    % get either pos or i, j, and k labels
    possible_labels={{'pos'},{'i';'j';'k'}};
    for j=1:numel(possible_labels)
        labels=possible_labels{j};
        [has_label,index]=has_fdim_label(ds, labels);
        if has_label
            return
        end
    end

    error(['Unable to find dimension labels, either ''pos'' '...
                    'or ''i'', ''j'', and ''k''']);


function fdim=get_spherical_fdim(ds, target_labels)
    first_target_label=target_labels{1};
    [two, index]=cosmo_dim_find(ds,first_target_label,true);

    if two~=2
        error('dimension ''%s'' must be a feature dimension');
    end
    cosmo_isfield(ds,'a.fdim.labels',true);

    dim_labels=ds.a.fdim.labels(:);
    dim_values=ds.a.fdim.values(:);

    nlabels=numel(target_labels);
    idx_labels=(index+(0:(nlabels-1)))';
    if numel(dim_labels)<index+(nlabels-1) || ...
            ~isequal(dim_labels(idx_labels),target_labels)
        error('expected labels %s in .a.fdim.labels(%d:%d)',...
                  cosmo_strjoin(target_labels,', '),idx_labels([1 end]));
    end

    fdim=struct();
    fdim.labels=dim_labels(idx_labels);
    fdim.values=dim_values(idx_labels);

    fdim=ensure_row_vector_or_3d_matrix(fdim);

function fdim=ensure_row_vector_or_3d_matrix(fdim)
    labels=fdim.labels;
    nlabels=numel(labels);

    keys={'labels','values'};
    nkeys=numel(keys);
    for k=1:nlabels
        label=labels{k};
        for j=1:nkeys
            key=keys{j};
            value=fdim.(key){k};

            if strcmp(label,'pos') && strcmp(key,'values')
                if size(value,1)~=3
                    error(['''pos'' attribute in .a.fdim.values '...
                                'must be 3xM']);
                end
            else
                if ~isvector(value)
                    error(['''%s'' attribute in .a.fdim.%s must '...
                            'be a vector'],labels,key);
                end
                fdim.(key){k}=value(:)';
            end
        end
    end







function fa=get_spherical_fa(ds_fa, target_labels)
    fa_cell=get_spherical_fa_cell(ds_fa, target_labels);
    fa=cell2struct(fa_cell,target_labels,2);


function fa_cell=get_spherical_fa_cell(ds_fa, target_labels)
    nlabels=numel(target_labels);
    fa_cell=cell(1,nlabels);
    for j=1:nlabels
        label=target_labels{j};
        fa_cell{j}=ds_fa.(label);
    end


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


