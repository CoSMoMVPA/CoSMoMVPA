function [feature_ids,scores]=cosmo_find_local_extrema(ds, nbrhood, varargin)
% find local extrema in a dataset using a neighborhood
%
% [feature_ids,scores]=cosmo_find_local_extrema(ds, nbrhood, ...)
%
% Inputs:
%   ds              dataset struct with one sample, i.e. size(ds.samples,1)
%                   must be 1. NaN values ds.samples are ignored.
%   nbrhood         neighborhood structure corresponding with dataset, with
%                   a field .neighbors so that .neighbors{k} contains the
%                   feature ids of neighbors of feature k.
%   'fitness', f    optional function handle so that [score,id]=f(x)
%                   returns the index with the maximum 'feature score'.
%                   The default is @(x)max(x,[],2), i.e. a function that
%                   returns the maximum value and the index of the maximum
%                   value of the input.
%   'count', c      optional number of elements to select. The default is
%                   Inf.
%
% Output:
%   feature_ids     1xN vector with feature ids.
%   scores          1xN vector with fitness scores. It holds for all I and
%                   J in 1:N that, if I<J, then:
%                   - fitness(ds.samples(I))>fitness(ds.samples(J))
%                   - intersect(nbrhood.neighbors{I},nbrhood.neighbors{J})
%                       is empty
%                   - if I_N=setdiff(nbrhood.neighbors{I},I), then
%                     fitness(ds.samples(I_N))<=fitness(ds.samples(I))
%
%
% Example:
%     % generate tiny dataset with 6 voxels
%     ds=cosmo_synthetic_dataset('ntargets',1,'nchunks',1);
%     cosmo_disp(ds.samples)
%     > [ 2.03     0.584     -1.44    -0.518      1.19     -1.33 ]
%     %
%     % show unflattened shape
%     squeeze(cosmo_unflatten(ds))
%     >     2.0317   -0.5177
%     >     0.5838    1.1908
%     >    -1.4437   -1.3265
%     %
%     nh=cosmo_spherical_neighborhood(ds,'radius',1,'progress',false);
%     % find local maxima within neighborhood of 1 voxel radius
%     [feature_ids,scores]=cosmo_find_local_extrema(ds,nh)
%     > feature_ids =  1         5         3
%     > scores      =  2.0317    1.1908   -1.4437
%     %
%     % only return two feature ids
%     [feature_ids,scores]=cosmo_find_local_extrema(ds,nh,'count',2)
%     > feature_ids =  1         5
%     > scores      =  2.0317    1.1908
%     %
%     % use another fitness function, namely local minima
%     [feature_ids,scores]=cosmo_find_local_extrema(ds,nh,'fitness',@min)
%     > feature_ids =  3         4
%     > scores      = -1.4437   -0.5177
%     %
%     % find local maxima within neighborhood of 2 voxel radius
%     nh=cosmo_spherical_neighborhood(ds,'radius',2,'progress',false);
%     [feature_ids,scores]=cosmo_find_local_extrema(ds,nh)
%     > feature_ids =   1         6
%     > scores      =   2.0317   -1.3265
%
%
% Notes:
%   - this function can be used to define regions of interest in a
%     reproducible and objective manner.
%   - to ignore particular features, set their value to NaN
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    defaults=struct();
    defaults.count=Inf;
    defaults.fitness=@(x)max(x,[],2);
    opt=cosmo_structjoin(defaults,varargin{:});

    % check sanity of input
    cosmo_check_dataset(ds);
    check_compatibility(ds,nbrhood);

    [nsamples,nfeatures]=size(ds.samples);

    if nsamples~=1
        error('dataset must have exactly 1 sample, found %d', nsamples);
    end

    % keep track of which features were visited
    visited=false(1,nfeatures);

    fitness_func=opt.fitness;

    % go over features iteratively
    counter=0;
    feature_ids=zeros(1,10);
    scores=zeros(1,10);
    while true
        if counter>=opt.count
            break;
        end

        ids_to_consider=find(~visited);

        if isempty(ids_to_consider)
            break;
        end

        [score,i]=fitness_func(ds.samples(:,ids_to_consider));

        if isnan(score)
            break;
        end

        id=ids_to_consider(i);
        around_ids=nbrhood.neighbors{id};

        if any(cosmo_match(feature_ids(1:counter),around_ids))
            % in the unlikely case of an assymetric neighborhood, where
            % a previous id did not have the current id as a neighbor but
            % the current id has a previous id as neighbor, still skip the
            % current feature id
            visited(id)=true;
            continue;
        end

        counter=counter+1;
        if counter>numel(feature_ids)
            % allocate more space
            % this should be done at most log2(nfeatures) times
            feature_ids(2*counter)=0;
            scores(2*counter)=0;
        end

        feature_ids(counter)=id;
        scores(counter)=score;
        around_ids=nbrhood.neighbors{id};
        visited(around_ids)=true;
    end

    feature_ids=feature_ids(1:counter);
    scores=scores(1:counter);


function check_compatibility(ds,nbrhood)
    cosmo_check_neighborhood(nbrhood,ds);

