function ds=cosmo_dim_rename(ds, old_name, new_name, raise)

if nargin<4
    raise=true;
end

found=false;


for infix='sf'
    if cosmo_isfield(ds, ['a.' infix 'dim.labels'])
        labels=ds.a.([infix 'dim']).labels;
        msk=cosmo_match(labels, old_name);
        if any(msk)
            found=true;
            ds.a.([infix 'dim']).labels(msk)={new_name};

            attr=[infix 'a'];
            cosmo_isfield(ds,[attr '.' old_name],true);
            v=ds.(attr).(old_name);
            ds.(attr)=rmfield(ds.(attr),old_name);
            ds.(attr).(new_name)=v;
        end
    end
end

if ~found && raise
    error('Not found: dimension with name ''%s''', old_name);
end
