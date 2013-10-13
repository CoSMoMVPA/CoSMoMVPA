function bal_partitions=cosmo_balance_partitions(partitions, targets, nsets)

if nargin<3, nsets=1; end

if isstruct(targets) && isfield(targets,'sa') && ...
                isfield(targets.sa,'targets')
    targets=targets.sa.targets;
end
    

npar=numel(partitions.train_indices);

nbalpar=npar*nsets;

% allocate space for output
bal_partitions=struct();

fns={'train_indices','test_indices'};


for m=1:numel(fns)
    fn=fns{m};
    pos=0;
        
    par=partitions.(fn);
    bal_par=cell(nsets*npar,1);
    for k=1:nsets
        for j=1:npar
            pos=pos+1;

            parj=par{j};
            parj_targ=targets(parj,:);
            
            unq_targ=unique(parj_targ);
            h=histc(parj_targ, unq_targ);
            mn=min(h);

            nunq=numel(unq_targ);
            balparj=zeros(nunq*mn,1);
            for u=1:nunq
                unqidxs=find(parj_targ==unq_targ(u));
                rp=randperm(numel(unqidxs));
                pidxs=(u-1)*mn+(1:mn);
                balparj(pidxs)=parj(unqidxs(1:mn));
            end

            bal_par{pos}=balparj;
        end
    end
    bal_partitions.(fn)=bal_par;
end





        
    


