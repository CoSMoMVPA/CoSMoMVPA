function nh=cosmo_singleton_neighborhood(ds)
% return neighborhood where each feature is only neighbor of itself
%
% nh=cosmo_singleton_neighborhood(ds)
%
% Input:
%   ds                      dataset strucut
%
% Output:
%   nh                      neighborhood structure where each feature is
%                           only neighbor of itself.
%
%
% Example:
%     % This example shows how to run group analysis with multiple
%     % comparison correction using a clustering neighborhood defined
%     % by cosmo_singleton_neighborhood with cosmo_montecarlo_cluster_stat
%     %
%     nsubjects=10;
%     nrois=4;
%     ds=struct();
%     ds.a=struct();
%     ds.fa=struct();
%     % set random data for 10 participants and 4 ROIs
%     ds.samples=randn(nsubjects,nrois);
%     %
%     % set chunks and targets for one-sample t-test
%     ds.sa.chunks=(1:nsubjects)';
%     ds.sa.targets=ones(nsubjects,1);
%     %
%     nh=cosmo_singleton_neighborhood(ds);
%     cosmo_disp(nh);
%     %|| .origin
%     %||   .a
%     %||     struct (empty)
%     %||   .fa
%     %||     struct (empty)
%     %|| .fa
%     %||   .sizes
%     %||     [ 1         1         1         1 ]
%     %|| .a
%     %||   struct (empty)
%     %|| .neighbors
%     %||   { [ 1 ]
%     %||     [ 2 ]
%     %||     [ 3 ]
%     %||     [ 4 ] }
%     %||
%     %
%     opt=struct();
%     opt.progress=false;
%     %
%     % t-test against mean=0
%     opt.h0_mean=0;
%     %
%     % make this a fast example.
%     % usually one uses opt.niter=1000; even better is opt.niter=10000
%     opt.niter=10; % use 10000 for publication quality
%     %
%     tfce_z_scores=cosmo_montecarlo_cluster_stat(ds,nh,opt);
%     %
%     % output contains one z-score per ROI
%     cosmo_disp(size(tfce_z_scores.samples))
%     %|| [1, 4]
%
%
% Notes:
% - this function can be used for ROI group analysis with multiple
%   comparison correction using cosmo_montecarlo_cluster_stat.
%   To do so, each column in
%     ds.samples
%   should correspond to values in one ROI.
%

    cosmo_check_dataset(ds);

    nh=struct();
    nh.origin=struct();
    nh.fa=struct();
    nh.a=struct();

    if isfield(ds,'a')
        a=ds.a;

        nh.a=a;
        nh.origin.a=a;
    end

    if isfield(ds,'fa')
        fa=ds.fa;

        nh.fa=fa;
        nh.origin.fa=fa;
    end

    nfeatures=size(ds.samples,2);
    nh.fa.sizes=ones(1,nfeatures);

    nh.neighbors=num2cell((1:nfeatures)');
