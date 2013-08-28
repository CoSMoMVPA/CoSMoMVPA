function randomized_targets=cosmo_randmize_targets(targets, chunks)
% provides randomized target labels
%
% randomized_targets=cosmo_randmize_targets(count, targets, chunks)
%
% Inputs
%   targets:  Px1 target (class) labels
%   chunks:   Px1 chunk indices
%
% Returns
%   randomized_targets    P x 1 with randomized targets
%                         Each chunk in each row is randomized seperately
%
% NNO Aug 2013

if isstruct(targets)
    if isfield(targets,'sa') && isfield(targets.sa,'targets') 
        if isfield(targets.sa,'chunks') && nargin<3
            chunks=targets.sa.chunks;
        end
        targets=targets.sa.targets;
    else
        error('illegal input')
    end
end

ntargets=numel(targets);
randomized_targets=zeros(ntargets, 1); %space for output

unq=unique(chunks);
nchunks=numel(unq);

% << permute the target labels randomly, seperately for each chunk
for j=1:nchunks
    msk=chunks==unq(j);
    rp=randperm(sum(msk));
    masked_targets=targets(msk);
    randomized_targets(msk)=masked_targets(rp);
end
% <<