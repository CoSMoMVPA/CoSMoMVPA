function clusters=cosmo_clusterize(sample,nbrhood_mat)
% fast depth-first clustering based on equal values of neighbors
%
% clusters=cosmo_clusterize(ds,nbrhood,sizes)
%
% Inputs:
%   ds        A vector of size 1xN, or a dataset struct with a field
%             .samples of size 1xN.
%   nbrhood   PxN neighborhood definition, if each feature has P
%             neighbors at most. Values of zero can be used as
%             fillers if a feature has less than P neighbors.
%
% Output:
%   clusters  1xQ cell with cluster indices, if Q clusters are found.
%             C{k} denotes the indices in ds that belong to the k-th
%             cluster. Each value in C{k} is in the range 1:N.
%
% Example:
%     % generate tiny fmri dataset with 6 voxels
%     ds=cosmo_synthetic_dataset('ntargets',1,'nchunks',1);
%     % compute neighborhood over voxels, so that two voxels are neighbors
%     % if they share a vertex
%     nh=cosmo_cluster_neighborhood(ds,'progress',false);
%     %
%     % set the data to be, when unflatten, a 2D matrix:
%     % [-1  0 -1]
%     %  3  0 -1]
%     % with three clusters:
%     % - linear index 1         (matrix element (1,1)) with element -1
%     % - linear index 4         (matrix element (2,1)) with element 3
%     % - linear indices 3 and 6 (matrix elments (:,3)) with element -1
%     % Note that elements with indices:
%     % - 1 and 4 are not neighbors because they have different values
%     % - 1 and 3 are not neighbors because they are not connected, as the
%     % neighborhood definition
%     %
%     ds.samples=[2 0 -1 3 0 -1];
%     %
%     % convert neighborhood definition to matrix form
%     nh_mat=cosmo_convert_neighborhood(nh,'matrix');
%     %
%     % clusterize the data
%     cl=cosmo_clusterize(ds.samples,nh_mat);
%     %
%     % show cluster indices
%     cosmo_disp(cl)
%     > { [ 1 ]  [ 3    [ 4 ]
%     >            6 ]        }
%
% Notes:
%   - Two features j and k are in the same cluster if:
%     * their values ds(j) and ds(k) are the same (ds(j)==ds(k)),
%     * features j and k are connected.
%     Features j and k are connected if:
%     * j==k, or
%     % j and k are neigbors, or
%     * there is a feature m, so that j and m are connected, and m and k
%       are connected
%   - Values of zero and NaN in ds are ignored for clusters.
%
% See also: cosmo_cluster_neighborhood, cosmo_convert_neighborhood
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    check_input_sizes(sample,nbrhood_mat);

    nfeatures=size(sample,2);
    [maxnbrs,nfeatures_matrix]=size(nbrhood_mat);

    assert(nfeatures==nfeatures_matrix);

    queue=zeros(nfeatures,1); % queue of nodes to add to current cluster
    queue_end=0; % last position where a value in q was stored
    queue_next=1; % first free position

    cl_start=zeros(nfeatures+1,1); % start index of i-th cluster.
                                  % one bigger for ease in setting output
    cl_count=0; % total number of clusters found so far
    cl_idxs=zeros(nfeatures,1); % label for each cluster
    in_queue=false(nfeatures,1); % indicates if an element is in the queue

    data_pos=1; % first non-visited node

    % go over all nodes from 1 to n. xpos is the candidate node for a new
    % cluster, and we add its neighbours in a breadth-first search
    while data_pos<=nfeatures
        if cl_idxs(data_pos)>0 % is already part of a cluster, continue
            data_pos=data_pos+1;
            continue;
        end

        data_val=sample(data_pos); % value of candidate cluster

        if data_val~=0 && ~isnan(data_val)
            % found an element for a new cluster

            queue(queue_next)=data_pos; % first element in the queue
            queue_end=queue_next; % last element of the queue
            cl_count=cl_count+1; % number of clusters
            cl_start(cl_count)=queue_next; % first index of this cluster
            cl_idx=cl_count; % index for current clustter

            in_queue(data_pos)=true;

            % now visit all neighbours of q(qnext),
            % iteratively, until the queue is exhausted
            while true
                qpos=queue(queue_next); % position in queue
                cl_idxs(qpos)=cl_idx; % assign cluster index

                for j=1:maxnbrs
                    nbr=nbrhood_mat(j,qpos);
                    % neighbour should have positive index, not queued yet,
                    % and have the same value as the first element of the
                    % current cluster
                    if nbr>0 && ~in_queue(nbr) && sample(nbr)==data_val
                        % add to queue of nodes to be visited
                        queue_end=queue_end+1;
                        queue(queue_end)=nbr; %

                        % mark it as queued, so it will not be added
                        % to the queue multiple times
                        in_queue(nbr)=true;
                    end
                end

                % get ready for next element in queue
                queue_next=queue_next+1;

                % if queue is exhausted, break out and find next cluster
                if queue_next>queue_end
                    break;
                end
            end
        end
        data_pos=data_pos+1;
    end

    % allocate space for output
    clusters=cell(1,cl_count); % cluster index

    % set extra boundary for last cluster
    cl_start(cl_count+1)=queue_end+1;

    % assign cluster index, size, and value
    for k=1:cl_count
        clusters{k}=queue(cl_start(k):(cl_start(k+1)-1));
    end



function check_input_sizes(sample,nbrhood_mat)
    if ~isrow(sample)
        error('sample input must be a row vector');
    end

    if ~isnumeric(sample) && ~islogical(sample)
        error('sample input must be numeric or logical');
    end

    if numel(size(nbrhood_mat))~=2
        error('neighborhood matrix must be a matrix');
    end

    if ~isnumeric(nbrhood_mat)
        error('neighborhood matrix must be numeric');
    end

    % ensure they have matching size
    if numel(sample)~=size(nbrhood_mat,2)
        error(['size mismatch between data (%d elements) '...
                'and neighborhood (%d elements)'],...
                    numel(sample),size(nbrhood_mat,2));
    end
