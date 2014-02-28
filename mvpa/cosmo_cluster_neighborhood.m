function cluster_nbrhood=cosmo_cluster_neighborhood(ds, nbrhood)
% Returns a neighborhood for a dataset suitable for cluster-based analysis.
%
% nbrhood=cosmo_cluster_neighborhood(ds, nbrhood)
%
% Inputs:
%   ds               dataset struct
%   nbrhood          One of the following:
%                    - if a single number:
%                      * if ds is an fmri dataset:
%                        nbrhood indicates along how many dimensions 
%                        distances of neighbors can differ; 1=sharing side; 
%                        2=sharing edge; and 3=sharing corner (default: 3).
%                      * if ds is an MEEG dataset:
%                        nbrhood indicates the size of the neighborhood
%                        along the channel dimension (if present).
%                        See cosmo_meeg_chan_neighborhood. All other
%                        dimensions (e.g. 'freq' and 'time') are connected
%                        by order-1 neighborhood (sharing side).
%                        (default: NaN, i.e. Delauney triangulation).
%                    - a neighborhood struct, for example from
%                      cosmo_neighborhood. In this case it should be
%                      compatible with ds in the .a field and in the
%                      fieldnames of .fa.
%   
%   cluster_nbrhood  Neighborhood struct with fields .neighbors, .a. and 
%                    .fa.
%
% Examples:
%   - % ds is an fmri dataset
%     >> nbrhood=cosmo_cluster_neighborhood(ds,2) % voxels sharing edge
%  
%   - % exactly the same thing
%     >> sph_nbrhood=cosmo_spherical_neighborhood(ds, 1.5);
%     >> nbrhood=cosmo_cluster_neighborhood(ds, sph_nbrhood);
%   
%   - % ds is an MEEG dataset with 'chan', 'freq', time' dimensions
%     % connect channels using Delauney triangulation, freq and time
%     % by matching sides (implicit).
%     >> nbrhood=cosmo_cluster_neighborhood(ds,NaN) % 
%
%     % connect channels over maximum distance of 10, freq and time
%     % by matching sides (implicit).
%     >> nbrhood=cosmo_cluster_neighborhood(ds,10) % 
%
%     % connect channels based on nearest 10 channels, freq and time
%     % by matching sides (implicit).
%     >> nbrhood=cosmo_cluster_neighborhood(ds,-10) % 
%
%     % connect channels using Delauney triangulation, only connect time
%     % but not frequency. This requires a bit more work.
%     >> chan_nbrhood=cosmo_meeg_chan_neighborhood(ds,NaN);
%     >> time_nbrhood=cosmo_interval_neighborhood(ds,'time',1);
%     >> chan_time_nbrhood=cosmo_neighborhood(chan_nbrhood, time_nbrhood);
%     >> nbrhood=cosmo_cluster_neighborhood(chan_time_nbrhood)
%
% See also: cosmo_meeg_chan_neighborhood, cosmo_spherical_neighborhood, 
%           cosmo_interval_neighborhood, cosmo_neighborhood.
%
% NNO Oct 2013

    if nargin<2 || ~isstruct(nbrhood)
        if cosmo_check_dataset(ds,'fmri',false)
            % fMRI dataset
            switch nargin
                case 1
                    nbrhood_size=3;
                case 2
                    nbrhood_size=nbrhood;
                otherwise
                    error('Need single radius for fMRI dataset');
            end

            radius=sqrt(nbrhood_size)+.01; % pythagoras
            nbrhood=cosmo_spherical_neighborhood(ds, radius);
        elseif cosmo_check_dataset(ds,'meeg',false)
            % MEEG dataset

            % set channel neighborhood size
            dim_labels=ds.a.dim.labels;
            chan_dim=find(cosmo_match(dim_labels,'chan'));
            has_chan=~isempty(chan_dim);
            switch nargin
                case 1
                    chan_nbrhood_size=NaN; % Default: delauney triangulation
                case 2
                    if ~has_chan
                        error('No channel dimension, cannot specify size');
                    end
                    chan_nbrhood_size=nbrhood;
                otherwise
                    error('Need %d arguments for MEEG neighborhood size',...
                                has_chan);
            end

            % determine neighborhoods for all dimensions
            ndim=numel(dim_labels);
            nhoods=cell(1,ndim);
            for dim=1:ndim
                if dim==chan_dim
                    % chan is a special case
                    nhood=cosmo_meeg_chan_neighborhood(ds,...
                                                chan_nbrhood_size); 
                else 
                    % all other dimensions
                    nhood=cosmo_interval_neighborhood(ds,...
                                            dim_labels{dim},1);
                end
                nhoods{dim}=nhood;
            end

            % join the neighborhoods
            nbrhood=cosmo_neighborhood(ds,nhoods{:});
        else
            error('unsupported input');
        end
    end

    % check the input
    if ~isequal(ds.a.dim.labels, nbrhood.a.dim.labels)
        error(['Dimension label mismatch between neighborhood (%s) and '...
               'dataset (%s)'],cosmo_strjoin(nbrhood.a.dim.labels,', '),...
                                cosmo_strjoin(ds.a.dim.labels,', '));
    end

    if ~isequal(ds.a, nbrhood.a)
        error('dataset attribute mismatch between neighborhood and dataset');
    end

    % find mapping from nbrrood fa indices to ds fa indices
    labels=ds.a.dim.labels;
    ndim=numel(labels);
    dim_sizes=cellfun(@numel,ds.a.dim.values);

    % store fa indices
    ds_fa=cell(1,ndim);
    nbrhood_fa=cell(1,ndim);
    for dim=1:ndim
        ds_fa{dim}=ds.fa.(labels{dim});
        nbrhood_fa{dim}=nbrhood.fa.(labels{dim});
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
    full2nbrhood=zeros(1,n);
    full2nbrhood(nbrhood_lin)=1:numel(nbrhood_lin);

    % ensure that nbrhood has no features not in ds
    ds2nbrhood=full2nbrhood(ds_lin);
    if any(ds2nbrhood==0)
        idx=find(ds2nbrhood==0,1);
        error('Missing neighborhood in dataset feature #%d',idx);
    end

    % slice nbrhood to match feature attributes
    cluster_nbrhood.neighbors=nbrhood.neighbors(ds2nbrhood);
    cluster_nbrhood.fa=cosmo_slice(nbrhood.fa,ds2nbrhood,2,'struct');
    cluster_nbrhood.a=ds.a;
