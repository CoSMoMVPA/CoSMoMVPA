function nbrhood=cosmo_cluster_neighborhood(ds,varargin)
% define neighborhood suitable for cluster-based analysis
%
% nbrhood=cosmo_cluster_neighborhood(ds,...)
%
% Inputs:
%     ds            dataset struct
%     'fmri',fnn    Optional connectivity for voxels, if ds is an
%                   fmri dataset. Use fnn=1, 2 or 3 to let two voxels be
%                   neighbors if they share at least a a side, edge
%                   or vertex (respectively).
%                   Default: 3
%     'source',snn  Optional connectivity for grid positions, if ds is an
%                   meeg source dataset. Use snn=1, 2 or 3 to let two
%                   source positions be neighbors if they share at least a,
%                   side, edge or vertex (respectively). If ds.fa has a
%                   field 'inside', then any feature that is false for
%                   ds.fa.inside will not have any neighbors, nor will it
%                   be the neighbor of any other feature.
%                   Default: 3
%     'chan',c      Optional connectivity for channels, if ds is an MEEG
%                   dataset with channels. c=true makes channels neighbors
%                   if their Delaunay triangulation (as computed by
%                   cosmo_meeg_chan_neighors) has them share an edge.
%                   c=false means that a channel is only neighbor of
%                   itself.
%                   Default: true
%     'surface',s   Optional connectivity for nodes, if ds is a
%                   surface-based dataset. s=true makes channels neighbors
%                   if they share an edge on the surface.
%                   c=false means that a channel is only neighbor of itself
%                   Default: true
%     'vertices',v  } vertices (Px3) and faces (Qx3) of the surface;
%     'faces',f     } only required for a surface-based dataset
%     k,t           Any other feature dimension and its connectivity, e.g.
%                   k can be 'chan' or 'freq'. t indicates whether
%                   neighboring points (in time, freq, ...) are neighbors.
%                   Default: true (for any dimension not mentioned above)
%
%  Output:
%     nbrhood       Neighborhood struct
%       .neighbors  .neighbors{k}==idxs means that feature k in ds has
%                   neighbors with feature indices idxs
%       .fa         identical to ds.fa, except that a field .sizes
%                   is added indicating the size of each feature
%                   - for surfaces, this is the area of each node
%                   - in all other cases, it is set to a vector of ones.
%       .a          identical to ds.a
%
%  Examples:
%     % get neighbors in very tiny synthetic fmri dataset (only 6 voxels)
%     ds_fmri=cosmo_synthetic_dataset('type','fmri');
%     % by default use NN=3 connectivity (voxels sharing a vertex is
%     % sufficient to be neighbors)
%     nh_fmri=cosmo_cluster_neighborhood(ds_fmri,'progress',false);
%     % each voxel has 4 or 6 neighbors
%     cosmo_disp(nh_fmri.neighbors);
%     > { [ 1         2         4         5 ]
%     >   [ 1         2         3         4         5         6 ]
%     >   [ 2         3         5         6 ]
%     >   [ 1         2         4         5 ]
%     >   [ 1         2         3         4         5         6 ]
%     >   [ 2         3         5         6 ]                     }
%
%     % get neighbors in time-lock MEEG dataset from the neuromag306
%     % system (subset of channels), with combined planar and
%     % axial channels
%     ds_meg=cosmo_synthetic_dataset('type','meeg',...
%                          'size','normal',...
%                          'sens','neuromag306_planar_combined+axial');
%     nh_meg=cosmo_cluster_neighborhood(ds_meg,'progress',false);
%     % neighbors are seperate for axial channels (odd features)
%     % and planar_combined channels (even features)
%     cosmo_disp(nh_meg.neighbors)
%     > { [ 1         3         4         6 ]
%     >   [ 2         5 ]
%     >   [ 1         3         4         6 ]
%     >   [ 1         3         4         6 ]
%     >   [ 2         5 ]
%     >   [ 1         3         4         6 ] }
%     %
%     % get neighbors in EEG dataset, either with clustering over all
%     % feature dimensions (channels x time x freq) or with all feature
%     % dimensions except for channels (i.e., time x freq)
%     ds_eeg=cosmo_synthetic_dataset('type','timefreq',...
%                               'size','normal',...
%                               'sens','eeg1005');
%     % neighborhood with clustering over chan x time x freq
%     nh_eeg_full=cosmo_cluster_neighborhood(ds_eeg,'progress',false);
%     % each feature has up to 18 neighbors
%     cosmo_disp(nh_eeg_full.neighbors)
%     > { [ 1         2         3  ...  10       11       12 ]@1x12
%     >   [ 1         2         3  ...  10       11       12 ]@1x12
%     >   [ 1         2         3  ...  10       11       12 ]@1x12
%     >                                :
%     >   [ 19        20        21  ...  28       29       30 ]@1x12
%     >   [ 19        20        21  ...  28       29       30 ]@1x12
%     >   [ 19        20        21  ...  28       29       30 ]@1x12 }@30x1
%     %
%     % neighborhood with clustering over time x freq (not over chan)
%     nh_eeg_tf=cosmo_cluster_neighborhood(ds_eeg,'progress',false,...
%                                                 'chan',false);
%     % each feature has at most 6 neighbors
%     cosmo_disp(nh_eeg_tf.neighbors)
%     > { [ 1         4         7        10 ]
%     >   [ 2         5         8        11 ]
%     >   [ 3         6         9        12 ]
%     >                    :
%     >   [ 19        22        25        28 ]
%     >   [ 20        23        26        29 ]
%     >   [ 21        24        27        30 ] }@30x1
%
%
% Notes:
%   - This function uses cosmo_cross_neighborhoods internally so that
%     clusters can be formed across different dimensions.
%   - The output from this function can be used with
%     cosmo_montecarlo_cluster_stat for multiple comparison correction
%   - each dimension argument (such as 'fmri', 'source', 'chan', 'freq',
%     'time', 'surface') can be followed by a custom neighborhood, if it is
%     desired to override the neighborhoods generated by this function.
%     For most use cases this is recommended; it should only be used if you
%     really know what you are doing.
%   - To avoid making clusters along a particular dimension d, use
%     cosmo_cluster_neighborhood (...,d,false). For example, an MEEG
%     time-by-chan dataset ds could be clustered using:
%         1a) nh1a=cosmo_cluster_neighborhood(ds);
%         1b) nh1b=cosmo_cluster_neighborhood(ds,'time',true);
%         2)  nh2 =cosmo_cluster_neighborhood(ds,'time',false);
%     where 1a and 1b are equivalent, and both different from 2.
%     When used with cosmo_montecarlo_cluster_stat to correct for multiple
%     comparisons, the interpretation of any surviving cluster depends on
%     which approach was used:
%     * In approach 2, clusters are not connected by neighboring time
%        points; each cluster spans a single time point. For example, if a
%        cluster is  found at 200ms relative to stimulus onset, one can
%        infer a significant effect at 200 ms.
%     * In approach 1, clusters are connected over neighboring time points,
%       and each cluster can span multiple time points. If a cluster is
%       found spanning a time interval between 200 and 300ms, one *cannot*
%       infer a significant effect at 200 ms. One *can* infer a significant
%       effect for the time interval between 200 and 300 ms.
%     (Note that in both approaches clusters, are connected over
%     neighboring channels; spatial inferences over individual channels
%     cannot be made in either approach).
%     To summarize: in approach 1, the threshold to pass significance is
%     lower, but less strong inferences can be made than with approach 2.
%
% See also: cosmo_montecarlo_cluster_stat
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    % set defaults
    default=struct();
    default.progress=1000;
    opt=cosmo_structjoin(default,varargin{:});

    % check dataset
    cosmo_check_dataset(ds);

    % get neighborhoods for each individual dimension
    nbrhoods=get_dimension_neighborhoods(ds,opt);

    % cross the neighborhoods to get full neighborhood
    full_nbrhood=cosmo_cross_neighborhood(ds,nbrhoods,opt);

    % determine mapping from all feature attributes to only those in the
    % dataset
    ds2nbrhood=get_dataset2neighborhood_mapping(ds, full_nbrhood);

    % slice nbrhood to match feature attributes
    nbrhood=struct();
    nbrhood.neighbors=full_nbrhood.neighbors(ds2nbrhood);
    nbrhood.fa=cosmo_slice(full_nbrhood.fa,ds2nbrhood,2,'struct');
    nbrhood.a=full_nbrhood.a;

    origin=struct();
    origin.a=ds.a;
    origin.fa=ds.fa;
    nbrhood.origin=origin;

    nbrhood=set_feature_sizes(nbrhood);
    cosmo_check_neighborhood(nbrhood,ds);



function check_matching_fa(ds,nbrhood)
    % ensure that all dimension values in fa match between ds and nbrhood
    labels=ds.a.fdim.labels;
    for k=1:numel(labels)
        label=labels{k};
        assert(isequal(ds.fa.(label),nbrhood.fa.(label)));
    end

function nbrhood=set_feature_sizes(nbrhood)
    % set feature sizes if not set
    if ~isfield(nbrhood.fa,'sizes')
        nfeatures=numel(nbrhood.neighbors);
        nbrhood.fa.sizes=ones(1,nfeatures);
    end

function ds2nbrhood=get_dataset2neighborhood_mapping(ds, nbrhood)
    % ensure matching .fa for ds and nbrhood
    assert(isequal(nbrhood.a.fdim.labels(:),ds.a.fdim.labels(:)));

    dim_labels=ds.a.fdim.labels;
    dim_sizes=cellfun(@numel,ds.a.fdim.values(:))';
    ndim=numel(dim_labels);

    % store fa indices
    ds_fa=cell(1,ndim);
    nbrhood_fa=cell(1,ndim);
    for dim=1:ndim
        ds_fa{dim}=ds.fa.(dim_labels{dim});
        nbrhood_fa{dim}=nbrhood.fa.(dim_labels{dim});
    end

    % convert to linear indices
    if ndim==1
        % trivial case
        ds_lin=ds_fa{1};
        nbrhood_lin=nbrhood_fa{1};
    else
        ds_lin=sub2ind(dim_sizes, ds_fa{:});
        nbrhood_lin=sub2ind(dim_sizes, nbrhood_fa{:});
    end

    % total number of features in cross product
    n=prod(dim_sizes);

    % mapping from all features to those in nbrhood
    full2nbrhood=zeros(n,1);
    full2nbrhood(nbrhood_lin)=1:numel(nbrhood_lin);

    % ensure that nbrhood has no features not in ds
    ds2nbrhood=full2nbrhood(ds_lin);
    if any(ds2nbrhood==0)
        idx=find(ds2nbrhood==0,1);
        error('Missing neighborhood in dataset feature #%d',idx);
    end


function nbrhoods=get_dimension_neighborhoods(ds,opt)
    % get neighborhoods for each feature dimension

    dim_labels=ds.a.fdim.labels;
    n=numel(dim_labels);

    % keep track of which dimension labels have a neighborhood associated
    % with them
    visited=false(n,1);
    nbrhoods=cell(n,1);

    while true
        i=find(~visited,1);

        if isempty(i)
            % all done
            break;
        end

        dim_label=dim_labels{i};
        other_dim_labels={};
        switch dim_label
            case 'i'
                dim_type='fmri';
                neighborhood_func=@fmri_neighborhood;
                other_dim_labels={'j','k'};
            case 'pos'
                dim_type='source';
                neighborhood_func=@source_neighborhood;
            case 'node_indices'
                dim_type='surface';
                neighborhood_func=@surface_neighborhood;
            case 'chan'
                dim_type='chan';
                neighborhood_func=@chan_neighborhood;

            case 'mom'
                dim_type='mom';
                neighborhood_func=@mom_neighborhood;

            otherwise
                % typically for 'time' and 'freq'
                dim_type=dim_label;
                neighborhood_func=@interval_neighborhood;
        end

        % see if option is specified for this dimension label
        has_dim_opt=isfield(opt,dim_type);
        if has_dim_opt
            dim_opt=opt.(dim_type);
        else
            dim_opt=[];
        end

        if isstruct(dim_opt)
            % neighborhood struct, use directly
            cosmo_check_neighborhood(dim_opt,ds);
            nbrhood=dim_opt;
        else
            % compute neighborhood
            radius=dim_opt;
            if ~(isempty(radius) || (isscalar(radius) && radius>=0))
                error('radius for %s must be non-negative scalar',...
                        dim_type);
            end
            nbrhood=neighborhood_func(ds,i,radius,opt);
        end

        nbrhoods{i}=nbrhood;

        visited_dim_labels=[{dim_label} other_dim_labels];
        visited(cosmo_match(dim_labels,visited_dim_labels))=true;
    end

    msk=~cellfun(@isempty,nbrhoods);
    nbrhoods=nbrhoods(msk);


function nbrhood=fmri_neighborhood(ds,dim_pos,connectivity,opt)
    labels={'i','j','k'};
    nbrhood=spherical_neighborhood(ds,dim_pos,connectivity,labels,opt);


function nbrhood=source_neighborhood(ds,dim_pos,connectivity,opt)
    labels={'pos'};
    nbrhood=spherical_neighborhood(ds,dim_pos,connectivity,labels,opt);

function nbrhood=mom_neighborhood(ds,dim_pos,connectivity,opt)
    dim_values=ds.a.fdim.values{dim_pos};
    if numel(dim_values)~=1
        error(['When using a dataset with a .mom field, it can only '...
                'have a single value, because clustering for '...
                'datasets with multiple orientations of dipole '...
                'fields is (to the best knowledge of the CoSMoMVPA '...
                'developers) not properly defined. (If you have an '...
                'idea how such clustering can be defined meaningfully, '...
                'please do not hesitate to contact them']);
    end
    nbrhood=cosmo_interval_neighborhood(ds,'mom','radius',1);


function nbrhood=spherical_neighborhood(ds,dim_pos,connectivity,labels,opt)
    % for fmri and meeg-source datasets
    % labels is either {'i','j','k'} or {'pos'}
    if isempty(connectivity)
        connectivity=3; % NN=3 connectivity
    end

    if ~isscalar(connectivity) || ~isnumeric(connectivity) || ...
                ~any(connectivity==1:3)
        error('argument for connectivity must be 1, 2 or 3');
    end

    radius=sqrt(connectivity)+.001;

    dim_labels=ds.a.fdim.labels;
    nlabels=numel(dim_labels);

    label_pos=dim_pos+(0:numel(labels)-1)';

    if numel(dim_labels)>(dim_pos+nlabels-1) || ...
                ~isequal(dim_labels(label_pos),labels(:))
        error(['expected dataset with .a.fdim.labels([%d:%d])='...
                '{''%s''}. \n'...
                '- If this is an fMRI dataset or source dataset, it '...
                'seems messed up\n'...
                '- Otherwise, ''%s'' is an illegal a dimension label'],...
                dim_pos+[0 (nlabels-1)],...
                cosmo_strjoin(labels,''', '''),...
                dim_labels{1});
    end


    nbrhood=cosmo_spherical_neighborhood(ds,'radius',radius,opt);

    keep_labels=[labels {'inside'}];

    % only keep feature attributes in labels
    remove_fa_keys=setdiff(fieldnames(nbrhood.fa),keep_labels);
    nbrhood.fa=rmfield(nbrhood.fa,remove_fa_keys);


function nbrhood=chan_neighborhood(ds,dim_pos,arg,unused)
    do_connect=get_default_connect(arg);

    assert(isequal(ds.a.fdim.labels{dim_pos},'chan'));
    nbrhood=cosmo_meeg_chan_neighborhood(ds,'chantype','all',...
                                            'label','dataset',...
                                            'delaunay',do_connect);


function nbrhood=surface_neighborhood(ds,dim_pos,arg,opt)
    do_connect=get_default_connect(arg,'surface');

    assert(isequal(ds.a.fdim.labels{dim_pos},'node_indices'));

    if ~all(cosmo_isfield(opt,{'vertices','faces'}))
        error(['for surfaces, use the syntax\n\n',...
                '  %s(''vertices'',v,''faces'',f)\n' ,...
                'to specify the coordinates v and the faces f'],...
                mfilename());
    end

    surf_def={opt.vertices,opt.faces};
    cosmo_check_external('surfing');
    nbrhood=cosmo_surficial_neighborhood(ds,surf_def,...
                                    'direct',do_connect,...
                                    'metric','dijkstra',opt);


    node_area_surf=surfing_surfacearea(opt.vertices,opt.faces);
    feature_ids=ds.a.fdim.values{dim_pos}(nbrhood.fa.node_indices);
    node_area_ds=node_area_surf(feature_ids);

    nbrhood.fa.sizes=node_area_ds';


function nbrhood=interval_neighborhood(ds,dim_pos,arg,unused)
    dim_label=ds.a.fdim.labels{dim_pos};
    do_connect=get_default_connect(arg,dim_label);

    nbrhood=cosmo_interval_neighborhood(ds,dim_label,'radius',do_connect);


function do_connect=get_default_connect(arg, label)
    % helper, returns true by default. requires arg to be logical to
    % override
    if isempty(arg)
        % delaunay
        do_connect=true;
    else
        if ~islogical(arg)
            error('argument for ''%s'' must be logical', label);
        end
        do_connect=arg;
    end












