function cval=cosmo_measure_clusters(sample,nbrhood_mat,cluster_stat,varargin)
% General cluster measure
%
% cval=cosmo_measure_clusters(sample,nbrhood_mat,method,['dh',dh|'threshold',t],...)
%
% Inputs:
%   sample              1xP data array for k features
%   nbrhood_mat         MxP neighborhood matrix, if each feature has at
%                       most M neighbors. nbrhood_mx(:,k) should contain
%                       the feature ids of the neighbors of feature k
%                       (values of zero indicate no neighbors)
%   cluster_stat        'tfce', 'max', 'maxsize', or 'maxsum'.
%   'dh',dh             when method is 'tfce', the integral step size
%   'threshold',t       if method is anything but 'tfce', the threshold
%                       level
%   'E', E              (optional) when method is 'tfce': the extent
%                       exponent, default E=0.5
%   'H', E              (optional) when method is 'tfce': the height
%                       exponent, default H=2
%   'feature_sizes', s  (optional) 1xP element size of each feature;
%                       default is a vector with all elements equal to 1.
%
% Output:
%   cval           1xP data array with cluster values.
%                  Define:
%                     cl_k(thr)       Feature ids that are connected
%                                     with feature k when sample is
%                                     thresholded at thr.
%                                     (with cl_k(thr)=[] if sample(k)<thr).
%                     e_k(thr)        The extent of the cluster for feature
%                                     k when thresholded at thr, i.e.
%                                       e_k=sum[i=cl_k(thr)] s(i)
%                     max0[x=xs]v(x)  the maximum value that v takes for
%                                     any value in xs, or zero if xs is
%                                     empty.
%                  The output for a feature k depends on cluster_stat:
%                  - 'tfce':
%                       cval(k)=sum[h=dh:dh:max(sample)] e_k(h)^E *h^H * dh
%                    i.e. a weighted sum of the extent and height of
%                    the cluster at different thresholds
%                  - 'max':
%                       cval(k)=max0[i=cl_k(thr)] samples(i))
%                    i.e. the maximum value in the cluster that contains k
%                  - 'maxsize'
%                       cval(k)=e_k(thr)
%                    i.e. the size of the cluster that contains k
%                  - 'maxsum'
%                       cval(k)=sum[i=cl_k(thr)] samples(i)
%                    i.e. the sum of the values in the cluster that
%                    contains k
%
% Examples:
%     % very simple one-dimensional 'line' example
%     samples=     [1 2 1 1 0 2 2];
%     nbrhood_mat= [1 1 2 3 4 5 6;...
%                   2 2 3 4 5 6 7;...
%                   0 3 4 5 6 7 0];
%     % illustrate TFCE cluster stat. Note that the results vary little
%     % as a function of dh, and that both features in clusters with a
%     % larger extent but less extreme value and features in clusters with
%     % smaller extent but more extreme values have larger values
%     cosmo_measure_clusters(samples,nbrhood_mat,'tfce','dh',.1)
%     > 0.7700    2.8550    0.7700    0.7700         0    3.4931    3.4931
%     %
%     cosmo_measure_clusters(samples,nbrhood_mat,'tfce','dh',.05)
%     > 0.6175    2.8763    0.6175    0.6175         0    3.6310    3.6310
%     %
%     % illustrate other cluster stats. Note that the results varies more
%     % as a function of the chosen threshold
%     cosmo_measure_clusters(samples,nbrhood_mat,'max','threshold',1)
%     >  2     2     2     2     0     2     2
%     %
%     cosmo_measure_clusters(samples,nbrhood_mat,'max','threshold',2)
%     >  0     2     0     0     0     2     2
%     %
%     cosmo_measure_clusters(samples,nbrhood_mat,'maxsize','threshold',1)
%     >  4     4     4     4     0     2     2
%     %
%     cosmo_measure_clusters(samples,nbrhood_mat,'maxsize','threshold',2)
%     >  0     1     0     0     0     2     2
%     %
%     cosmo_measure_clusters(samples,nbrhood_mat,'maxsum','threshold',1)
%     >  5     5     5     5     0     4     4
%     %
%     cosmo_measure_clusters(samples,nbrhood_mat,'maxsum','threshold',2)
%     >  0     2     0     0     0     4     4
%
% Notes:
%   - the 'method' argument is similar to FieldTrip's clusterstat method,
%     but does support 'tfce' and does not support 'wcm'
%   - unlike FieldTrip's clusterstat, a value is returned for each feature
%     (rather than each cluster).
%   - TFCE is advised in the general case, because it finds a compromise
%     between magnitude of values and extent of clusters.
%   - this function is used by cosmo_montecarlo_cluster_stat for
%     non-parametric cluster-based correction for multiple comparisons.
%
% References:
%   - Stephen M. Smith, Thomas E. Nichols (2009), Threshold-free
%     cluster enhancement: Addressing problems of smoothing, threshold
%     dependence and localisation in cluster inference, NeuroImage, Volume
%     44, 83-98.
%   - Maris, E., Oostenveld, R. Nonparametric statistical testing of EEG-
%     and MEG-data. Journal of Neuroscience Methods (2007).
%
% See also: cosmo_convert_neighborhood, cosmo_montecarlo_cluster_stat
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    persistent cached_varargin;
    persistent cached_opt;


    if isequal(varargin, cached_varargin)
        opt=cached_opt;
    else
        opt=cosmo_structjoin(varargin);
        cached_opt=opt;
        cached_varargin=varargin;
    end

    % used for TFCE
    defaults=struct();
    defaults.E=.5;
    defaults.H=2;

    % get size of each feature
    feature_sizes=get_feature_sizes(sample,opt);

    % check input size
    check_input_sizes(sample,nbrhood_mat);

    % set cluster parameters depending on method; outputs are:
    %   delta_thr      value by which the threshold is increased for every
    %                  iteration (in case of TFCE), or the threshold value
    %                  itself (for any other method)
    %   cluster_func   function handle which takes as inputs:
    %                    idxs       feature ids of elements in a cluster
    %                    sizes      size of each feature; same size as data
    %                    thr        threshold value
    %   nthr           number of thresholds (1 for any method except for
    %                  TFCE)

    [delta_thr,cluster_func,nthr,has_inf]=get_clustering_params(...
                                                          cluster_stat,...
                                                          sample,...
                                                          feature_sizes,...
                                                          opt,defaults);

    % initially all features survive the mask, except non-finite ones
    super_threshold_msk=~isnan(sample);
    infinity_msk=isinf(sample) & sample>0;

    % keep
    thr_counter=0;

    % cluster threshold variable. For TFCE this value is increased multiple
    % times in the while-loop below. For all other methods it is increased
    % just once
    thr=0;

    % allocate space for output
    cval=zeros(size(sample));

    while thr_counter<nthr
        % increase threshold
        thr=thr+delta_thr;

        % update mask of features above threshold
        super_threshold_msk=super_threshold_msk & sample>=thr;

        if has_inf
            % if output can contain infinity, break if all values are less
            % than the threshold or inifity
            if ~any(super_threshold_msk & ~infinity_msk)
                % no features surive, clustering is completed
                break;
            end
        else
            % if output cannot contain infinity, break if all values are
            % less than the threshold
            if ~any(super_threshold_msk)
                break;
            end
        end

        % apply clustering
        clusters=cosmo_clusterize(super_threshold_msk,nbrhood_mat);

        % process each cluster
        for k=1:numel(clusters)
            cluster=clusters{k};
            stat=cluster_func(cluster,thr);

            cval(cluster)=cval(cluster)+stat;
        end

        % increase the threshold counter. For all methods except tfce, the
        % while loop is quit after the first iteration
        thr_counter=thr_counter+1;
    end

    if has_inf
        cval(infinity_msk)=Inf;
    end

function [delta_thr,cluster_func,nthr,has_inf]=get_clustering_params(...
                                                      method,...
                                                      sample,sizes,...
                                                      opt,defaults)
    switch method
        case 'tfce'
            delta_thr=get_tfce_threshold_height(opt);
            cluster_func=get_tfce_cluster_func(sizes,delta_thr,...
                                                opt,defaults);
            nthr=Inf;
            has_inf=true;

        case 'max'
            cluster_func=@(idxs,thr) max(sample(idxs));
            delta_thr=get_fixed_threshold_height(opt);
            nthr=1;
            has_inf=true;

        case 'maxsize'
            cluster_func=@(idxs,thr) sum(sizes(idxs));
            delta_thr=get_fixed_threshold_height(opt);
            nthr=1;
            has_inf=false;

        case 'maxsum'
            cluster_func=@(idxs,thr) sum(sample(idxs));
            delta_thr=get_fixed_threshold_height(opt);
            nthr=1;
            has_inf=true;

        otherwise
            error('illegal method ''%s''', method);
    end


function feature_sizes=get_feature_sizes(sample,opt)
    nfeatures=size(sample,2);

    if isfield(opt,'feature_sizes')
        % if given as option, use those
        feature_sizes=opt.feature_sizes;
        % ensure it is a row vector
        if ~isrow(feature_sizes) || size(feature_sizes,2) ~= nfeatures
            error('feature sizes must be of size 1x%d', nfeatures);
        end
    else
        feature_sizes=ones(1,nfeatures);
    end


function func=get_tfce_cluster_func(sizes,threshold_height,opt,defaults)
    % helper to get the cluster function for TFCE, using either supplied or
    % default values for the E and H paramters
    persistent cached_opt;
    persistent cached_defaults;
    persistent cached_opt_all;

    if isequal(opt,cached_opt) && isequal(defaults, cached_defaults)
        opt_all=cached_opt_all;
    else
        opt_all=cosmo_structjoin(defaults,opt);
        cached_opt_all=opt_all;

        cached_opt=opt;
        cached_defaults=defaults;
    end

    tfce_E=opt_all.E;
    tfce_H=opt_all.H;

    check_positive_scalar(tfce_E,'E');
    check_positive_scalar(tfce_H,'H');

    func=@(idxs,thr) sum(sizes(idxs))^tfce_E ...
                                          * thr^tfce_H * threshold_height;


function dh=get_fixed_threshold_height(opt)
    % for everything except TFCE
    if ~isfield(opt,'threshold')
        error('missing option ''threshold''');
    end

    if any(cosmo_isfield(opt,{'E','B','dh'}))
        error(['options ''dh'', ''E'' or ''B'' are not allowed '...
            'for this method']);
    end

    dh=opt.threshold;
    if ~isscalar(dh) || ~isfinite(dh)
        error('option ''threshold'' must be a finite scalar');
    end


function dh=get_tfce_threshold_height(opt)
    if isfield(opt,'threshold')
        error('option ''threshold'' is not allowed for this method');
    end

    if ~isfield(opt,'dh')
        error('missing option ''dh'' for ''tfce'' method');
    end

    dh=opt.dh;
    check_positive_scalar(dh,'dh');


function check_positive_scalar(value, name)
    if ~isscalar(value) || ~isfinite(value) || value<=0
        error('option ''%s'' must be a positive scalar', name);
    end

function check_input_sizes(sample,nbrhood_mx)
    if ~isrow(sample)
        error('sample input must be a row vector');
    end

    if ~isnumeric(sample) && ~islogical(sample)
        error('sample input must be numeric or logical');
    end

    if numel(size(nbrhood_mx))~=2
        error(['neighborhood matrix must be a matrix '...
                '(use cosmo_convert_neighborhood to convert a '...
                'neighborhood struct to matrix representation']);
    end

    if ~isnumeric(nbrhood_mx)
        error('neighborhood matrix must be numeric');
    end

    % ensure they have matching size
    if numel(sample)~=size(nbrhood_mx,2)
        error(['size mismatch between data (%d elements) '...
                'and neighborhood (%d elements)'],...
                    numel(sample),size(nbrhood_mx,2));
    end

