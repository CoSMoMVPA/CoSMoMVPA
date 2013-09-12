function results_map = cosmo_searchlight(dataset, measure, varargin)
%  Generic searchlight function returns a map of results computed at each
%  searchlight location 
%   
%   results_map=cosmo_searchlight(dataset, measure, ['args',args]['radius',radius],['center_ids',center_ids])
%
%   Inputs
%       dataset: an instance of a cosmo_fmri_dataset
%       measure: a function handle to a dataset measure. A dataset measure has
%               the function signature: output = measure(dataset, args)
%       args:   a struct that contains all the fields necessary to the dataset
%               measure. args get passed directly to the dataset measure.
%       radius: searchlight radius in voxels. If provided, the mapping from
%               center2neighbors is computed using this radius and the
%               cosmo_spherical_voxel_selection function
%       center_ids:      vector indicating center ids to be used as a 
%                        searchlight center. By default all feature ids are
%                        used
%       center2neighbors: Px1 cell, if the dataset has P features, so that 
%                         center2neighbors{K} contains the features that 
%                         are in the neighborhood of the k-th feature.
%                         This option is mutually exclusive with radius.
%       
%
%   Returns
%       results_map:    an instance of a cosmo_fmri_dataset where the samples
%                       contain the results of the searchlight analysis.
% 
%   Example: Using the searchlight to compute a full-brain nearest neighbor
%               classification searchlight with n-fold cross validation:
%
%       ds = cosmo_fmri_dataset('data.nii','mask','brain_mask.nii', ...
%                                'targets',targets,'chunks',chunks);
%       m = @cosmo_cross_validation_accuracy_measure;
%       m_args = struct();
%       m_args.classifier = @cosmo_classify_nn;
%       m_args.partitions = cosmo_nfold_partitioner(ds);
%       results = cosmo_searchlight(ds,m,'args',m_args,'radius',3);
% See also: cosmo_spherical_voxel_selection       
%
% ACC Aug 2013, modified from run_voxel_selection_searchlight by NN0
    
    nfeatures=size(dataset.samples,2);

    parser = inputParser;
    addOptional(parser,'radius',[]);
    addOptional(parser,'center_ids',1:nfeatures);
    addOptional(parser,'args',struct());
    addOptional(parser,'center2neighbors',[]);
    addOptional(parser,'progress',1/50);
    parse(parser,varargin{:});
    p = parser.Results;
    radius = p.radius;
    args = p.args;
    center_ids=p.center_ids;
    center2neighbors=p.center2neighbors;

    % use voxel selection function
    if ~xor(isempty(radius), isempty(center2neighbors))
        error('need either radius or center2neighbors, exclusively');
    elseif isempty(center2neighbors)
        center2neighbors=cosmo_spherical_voxel_selection(dataset, radius, center_ids);
    else
        center2neighbors={center2neighbors{center_ids}};
    end

    % space for output, we will leave res empty for now because we can't know
    % yet the size of the array returned by our dtaset measure. Instead 
    % space will be allocated after the first times the measure is used. 
    ncenters=numel(center_ids);
    res=[];

    % see if progress is to be reported
    show_progress=~isempty(p.progress);
    if show_progress
        progress_step=p.progress;
        if progress_step<1
            progress_step=ceil(ncenters*progress_step);
        end
        prev_progress_msg='';
        clock_start=clock();
    end
    
    
    % go over all features; for each feature, apply the measure and 
    % store its output.
    % >>
    for k=1:ncenters
        center_id=center_ids(k);
        sphere_feature_ids=center2neighbors{center_id};

        sphere_ds=cosmo_dataset_slice(dataset, sphere_feature_ids, 2);

        % Call the dataset measure
        m = measure(sphere_ds, args);

        % Since a dataset measure may return an array of any length, we can
        % check the measures length on the first iteration and allocated the
        % appropriate amount of space for the results.
        if isempty(res) 
            [x,y] = size(m);
            if y>1 error('Dataset measure must return N x 1 array'); end
            res = zeros(x,ncenters);
        else
            [xx,yy]=size(m);
            if yy>1 || xx~=x
                error(['size mismatch for center id %d: expected ' ...
                        '%d x %d but found %d x %d'], center_id,x,y,xx,yy);
            end
        end             

        % Store the results
        res(:,k)=m;

        if show_progress && (k==1 || mod(k,progress_step)==0 || k==nfeatures)
            msg=sprintf('mean %.3f',mean(mean(res(:,1:k))));
            prev_progress_msg=cosmo_show_progress(clock_start, ...
                            k/ncenters, msg, prev_progress_msg);
        end
    end
    % <<

    % store the output in a dataset
    results_map=cosmo_dataset_slice(dataset, center_ids, 2);
    results_map.samples=res;
    
    