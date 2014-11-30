function layout=cosmo_meeg_find_layout(ds, varargin)
    defaults.senstype=[];
    defaults.min_coverage=.2;
    opt=cosmo_structjoin(defaults, varargin);

    % get the sensor labels and channel types applicable to this dataset
    senstype2label=get_supported_senstypes(ds,opt);

    % get the single sensortype based on the input and available channels
    ds_senstype=get_base_senstype(senstype2label,opt);

    % find initial layout
    label=senstype2label.(ds_senstype);
    layout=find_layout(label);

    ds_label=get_dataset_channel_labels(ds);
    coverage=label_coverage(ds_label, layout.label(:));

    if coverage==0
        % no coverage, possibly planar channels for which the corresponding
        % layout is not available. try to get the corresponding
        % planar_combined layout and use its channel positions
        [layout,label]=infer_planar_from_combined(senstype2label, label);
        coverage=label_coverage(ds_label(:),layout.label(:));
    end

    % no coverage, throw an error
    if coverage<opt.min_coverage
        error('channel coverage %.1f%% < 100%% for %s', ...
                    100*coverage, ds_senstype);
    end

    % in case of planar channels with senstype set to
    % meg_combined_from_planar, add a parent layout that maps to the
    % original layout
    is_planar_layout=size(label,2)>1;
    if is_planar_layout && strcmp(opt.senstype,'meg_combined_from_planar')
        [parent_layout,parent_label]=find_combined_layout(...
                                        senstype2label);
        nlabels=numel(parent_layout.label);
        assert(nlabels==size(label,1));
        parent_layout.child_label=cell(nlabels,1);
        for k=1:nlabels
            i=find(cosmo_match(parent_label,parent_layout.label{k}));
            assert(numel(i)==1);
            parent_layout.child_label{k}=label(i,:);
        end

        layout.parent=parent_layout;
    end



function [layout,planar_labels]=infer_planar_from_combined(...
                                          senstype2label,layout_labels)

    combined_layout=find_combined_layout(senstype2label);
    nlabels=size(combined_layout.pos,1);
    assert(size(layout_labels,1)==nlabels);
    combined2planar_idxs=reshape(repmat(1:nlabels,2,1),[],1);
    layout=slice_layout(combined_layout,combined2planar_idxs);

    planar_labels=senstype2label.meg_planar;
    layout.label=reshape(planar_labels',[],1);


function [combined_layout,combined_labels]=find_combined_layout(...
                                senstype2label)
    key='meg_combined_from_planar';
    if ~isfield(senstype2label,key);
        error('could not infer planar from combined layout');
    end

    combined_labels=senstype2label.(key);

    % get layout
    combined_layout=find_layout(combined_labels);


function lay=find_layout(label)
    lay_coll=cosmo_meeg_layout_collection();
    lay_label=cellfun(@(x)x.label,lay_coll,'UniformOutput',false);
    %coverages=cellfun(@(x)mean(cosmo_match(label(:),x.label)),lay_coll);
    coverages=cosmo_overlap(lay_label,{label});
    [unused,i]=max(coverages);
    lay=lay_coll{i};

    % select only channels present in label
    m=cosmo_match(lay.label,label(:));
    lay=slice_layout(lay,m);

function lay=slice_layout(lay, to_select)
    name=lay.name;
    lay=rmfield(lay,'name');
    lay=cosmo_slice(lay,to_select,1,'struct');
    lay.name=name;

function c=label_coverage(x,y)
    c=mean(cosmo_match(x(:),y(:)));


function chan_labels=get_dataset_channel_labels(ds)
    if iscellstr(ds)
        chan_labels=ds;
    else
        [dim, index, attr_name, dim_name]=cosmo_dim_find(ds,'chan',true);
        chan_labels=ds.a.(dim_name).values{index};
    end


function senstype=get_base_senstype(senstype2label, opt)
    has_senstype=ischar(opt.senstype) && ~isempty(opt.senstype);
    senstypes=fieldnames(senstype2label);
    has_key=@(key)cosmo_match({key},senstypes);

    error_msg='';
    if has_senstype
        if strcmp(opt.senstype,'meg_combined_from_planar')
            if has_key('meg_planar')
                senstype='meg_planar';
            else
                error_msg=sprintf(['Cannot use senstype ''%s'' because'...
                                    'planar channels were not found'],...
                                        opt.senstype);
            end
        elseif ~has_key(opt.senstype);
            error_msg=sprintf('senstype ''%s'' is not supported',...
                                    opt.senstype);
        else
            senstype=opt.senstype;
        end
    else
        if numel(senstypes)>1
            error_msg=['''senstype'' argument is not provided, but '...
                        'multiple types are available'];
        else
            senstype=senstypes{1};
        end
    end

    if ~isempty(error_msg)
        error('%s. Set the ''senstype'' argument to one of: ''%s.''',...
                error_msg,cosmo_strjoin(senstypes, ''', '''));
    end


function senstype2label=get_supported_senstypes(ds,opt)
    [unused,senstype_mapping]=cosmo_meeg_chantype(ds);
    keys=fieldnames(senstype_mapping);

    % get all supported acquistion systems
    sens_db=cosmo_meeg_senstype_collection();

    senstype2label=struct();
    for k=1:numel(keys)
        key=keys{k};
        senstype2label.(key)=sens_db.(senstype_mapping.(key)).label;
    end

    % see if any senstype is of planar type
    i=find(cosmo_match(keys,{'meg_planar'}));
    has_planar=numel(i)>0;

    if ~has_planar
        return
    end

    % if there is a planar type, see if there is a matching
    % planar_combined type as well. If that is the case, add this to the
    % supported sensor types
    planar_key=senstype_mapping.(keys{i});
    combined_key=regexprep(planar_key,'planar$','planar_combined');
    if isfield(sens_db, combined_key)
        combined_label=sens_db.(combined_key).label;
        senstype2label.meg_combined_from_planar=combined_label;
    end






