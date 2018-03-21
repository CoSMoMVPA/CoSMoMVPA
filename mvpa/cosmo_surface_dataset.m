function ds=cosmo_surface_dataset(fn, varargin)
% Returns a dataset structure based on surface mesh data
%
% ds=cosmo_surface_dataset(filename, varargin)
%
% Inputs:
%   filename          filename of surface data to be loaded. Currently
%                     supported are '.niml.dset' (AFNI/SUMA NIML) and
%                     'smp' (BrainVoyager surface maps). Also supported are
%                     structs as provied by afni_niml_readsimple or xff
%   'targets', t      Px1 targets for P samples; these will be stored in
%                     the output as ds.sa.targets
%   'chunks', c       Px1 chunks for P samples; these will be stored in the
%                     the output as ds.sa.chunks
% Output:
%   ds                dataset struct
%
% Examples:
%     % (this example requires the surfing toolbox)
%     cosmo_skip_test_if_no_external('afni');
%     %
%     % construct AFNI NIML dataset struct
%     cosmo_check_external('afni');
%     niml=struct();
%     niml.data=[1 2; 3 4; 5 6];
%     niml.node_indices=[1 20 201];
%     niml.stats={'Ttest(10)','Zscore()'};
%     %
%     % make surface dataset
%     % (a filename of a NIML dataset in ASCII format is supported as well)
%     ds=cosmo_surface_dataset(niml);
%     cosmo_disp(ds)
%     %|| .samples
%     %||   [ 1         3         5
%     %||     2         4         6 ]
%     %|| .sa
%     %||   .stats
%     %||     { 'Ttest(10)'
%     %||       'Zscore()'  }
%     %|| .fa
%     %||   .node_indices
%     %||     [ 1         2         3 ]
%     %|| .a
%     %||   .fdim
%     %||     .labels
%     %||       { 'node_indices' }
%     %||     .values
%     %||       { [ 2 21 202 ] }
%
%
% Notes:
%   - this function is intended for datasets with surface data, i.e. with
%     one or more values associated with each surface node. It does not
%     support anatomical surface meshes that contain node coordinates and
%     faces. To read and write such anatomical meshes, consider the surfing
%     toolbox, github.com/nno/surfing
%   - data can be mapped back to a surface file format using
%     cosmo_map2surface
%
% Dependencies:
%   - for Brainvoyager files (.smp), it requires the NeuroElf
%     toolbox, available from: http://neuroelf.net
%   - for AFNI/SUMA NIML files (.niml.dset) it requires the AFNI
%     Matlab toolbox, available from: http://afni.nimh.nih.gov/afni/matlab/
%
% See also: cosmo_map2surface
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    defaults=struct();
    defaults.targets=[];
    defaults.chunks=[];

    params = cosmo_structjoin(defaults, varargin);

    ds=get_dataset(fn);

     % set targets and chunks
    ds=set_vec_sa(ds,'targets',params.targets);
    ds=set_vec_sa(ds,'chunks',params.chunks);

    % check consistency
    cosmo_check_dataset(ds,'surface');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% general helper functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ds=get_dataset(fn)
    obj_to_clean=[];
    % try to load from .mat file
    obj_from_mat=try_dataset_from_mat(fn);
    if isempty(obj_from_mat)
        obj=fn;
    else
        obj=obj_from_mat;
        obj_to_clean=obj;
    end

    % try to load from file
    if ischar(obj)
        obj=try_obj_from_file(obj);
        obj_to_clean=obj;
    end

    [ds,fmt]=try_dataset_from_obj(obj);

    if ~isempty(obj_to_clean)
        apply_cleaner(obj_to_clean,fmt);
    end

function obj=try_dataset_from_mat(fn)
    obj=[];
    if ischar(fn) && isempty(cosmo_strsplit(fn,'.mat',-1))
        obj=importdata(fn);
    end

function [obj,fmt]=try_obj_from_file(fn)
    assert(ischar(fn));
    [exts_cell,fmts]=get_format_attribute('exts');

    endswith=@(s,e) isempty(cosmo_strsplit(s,e,-1));
    endswith_any=@(s,ce) any(cellfun(@(x)endswith(s,x),ce));

    match=cellfun(@(x)endswith_any(fn,x), exts_cell);

    i=find_single_or_error(match, ...
                            @()sprintf('unknown extension for file %s',...
                                                fn));
    fmt=fmts{i};
    reader=fmt.reader;
    obj=reader(fn);


function [ds,fmt]=try_dataset_from_obj(obj)
    if cosmo_check_dataset(obj,'surface',false)
        % it is already a valid dataset
        ds=obj;
        fmt='';
        return;
    end

    [matcher_cell,fmts]=get_format_attribute('matcher');

    match=cellfun(@(f) f(obj),matcher_cell);
    i=find_single_or_error(match, ...
                            @()sprintf('unknown object of type %s',...
                                                class(obj)));

    fmt=fmts{i};
    ds=build_dataset(obj,fmt);


function ds=build_dataset(obj,fmt)
    builder=fmt.builder;
    [data,node_indices,sa]=builder(obj);
    nfeatures=size(data,2);
    if nfeatures~=numel(node_indices)
        error(['The number of features (%d) does not match the number '...
                'of node indices (%d)'],nfeatures,numel(node_indices));
    end

    ds=struct();
    ds.samples=data;

    % set sample attributes
    ds.sa=sa;

    % set feature attributes
    ds.fa.node_indices=1:nfeatures;

    % set dataset attributes
    fdim=struct();
    fdim.labels={'node_indices'};
    fdim.values={node_indices(:)'};
    ds.a.fdim=fdim;

function apply_cleaner(obj,fmt)
    if ~isempty(fmt) && isfield(fmt,'cleaner')
        cleaner=fmt.cleaner;
        cleaner(obj);
    end

function i=find_single_or_error(m, error_text_func)
    i=find(m);
    switch numel(i)
        case 0
            error(error_text_func());

        case 1
            % ok

        otherwise
            assert(false,'this should not happen');
    end

function [elems,fmts]=get_format_attribute(fmt_key)
    img_formats=get_img_formats();
    keys=fieldnames(img_formats);
    n_fmts=numel(keys);

    elems=cell(n_fmts,1);
    fmts=cell(n_fmts,1);

    for k=1:n_fmts
        key=keys{k};

        fmt=img_formats.(key);
        elems{k}=fmt.(fmt_key);
        fmts{k}=fmt;
    end



function ds=read_surface_dataset(fn)
    [data,node_indices,sa]=read(fn);
    nfeatures=size(data,2);
    if nfeatures~=numel(node_indices)
        error(['The number of features (%d) does not match the number '...
                'of node indices (%d)'],nfeatures,numel(node_indices));
    end

    ds=struct();
    ds.samples=data;

    % set sample attributes
    ds.sa=sa;

    % set feature attributes
    ds.fa.node_indices=1:nfeatures;

    % set dataset attributes
    fdim=struct();
    fdim.labels={'node_indices'};
    fdim.values={node_indices(:)'};
    ds.a.fdim=fdim;


function ds=set_vec_sa(ds, label, values)
    if isempty(values)
        return;
    end
    if numel(values)==1
        nsamples=size(ds.samples,1);
        values=repmat(values,nsamples,1);
    end
    ds.sa.(label)=values(:);



function [data,node_indices,sa]=read(fn)
    img_formats=get_img_formats();

    endswith=@(s,e) isempty(cosmo_strsplit(s,e,-1));

    names=fieldnames(img_formats);
    n=numel(names);

    for k=1:n
        name=names{k};
        img_format=img_formats.(name);

        matcher=img_format.matcher;
        builder=img_format.builder;

        if matcher(fn)
            [data,node_indices,sa]=builder(fn);
            return
        elseif ischar(fn)
            exts=img_format.exts;
            reader=img_format.reader;
            for j=1:numel(exts)
                if endswith(fn,exts{j})
                    cosmo_check_external(img_format.externals);
                    s=reader(fn);

                    if ~matcher(s)
                        error(['Could read file ''%s'', but the data '...
                                'is not matching the expected contents '...
                                'for a dataset of type %s'],...
                                fn, name);
                    end

                    [data,node_indices,sa]=builder(s);
                    return
                end
            end
        end
    end

    if ischar(fn)
        error('Unsupported extension in filename %s', fn);
    else
        error('Unsupported input of type %s', class(fn));
    end


function img_formats=get_img_formats()

    % define which formats are supports
    % .exts indicates the extensions
    % .matcher says whether a struct is of the type
    % .reader should read a filaname and return a struct
    % .externals are fed to cosmo_check_externals
    img_formats=struct();

    img_formats.niml_dset.exts={'.niml.dset'};
    img_formats.niml_dset.matcher=@isa_niml_dset;
    img_formats.niml_dset.reader=@read_niml_dset;
    img_formats.niml_dset.builder=@build_niml_dset;
    img_formats.niml_dset.externals={'afni'};

    img_formats.bv_smp.exts={'.smp'};
    img_formats.bv_smp.matcher=@isa_bv_smp;
    img_formats.bv_smp.reader=@read_bv_smp;
    img_formats.bv_smp.builder=@build_bv_smp;
    img_formats.bv_smp.cleaner=@(x)x.ClearObject();
    img_formats.bv_smp.externals={'neuroelf'};

    img_formats.gii.exts={'.gii'};
    img_formats.gii.matcher=@isa_gii;
    img_formats.gii.reader=@read_gii;
    img_formats.gii.builder=@build_gii;
    img_formats.gii.externals={'gifti'};

    img_formats.pymvpa.exts={};
    img_formats.pymvpa.matcher=@isa_pymvpa;
    img_formats.pymvpa.reader=@read_pymvpa;
    img_formats.pymvpa.builder=@build_pymvpa;
    img_formats.pymvpa.externals={};


function b=isa_pymvpa(x)
    b=isstruct(x) && ...
            isfield(x,'samples') && ...
            isfield(x,'fa') && ...
            any(cosmo_isfield(x.fa, pymvpa_get_node_indices_fields()));

function b=read_pymvpa(fn)
    assert(false,'this function should not have been called');

function [data,node_indices,sa]=build_pymvpa(s)
    data=s.samples;
    index_fields=pymvpa_get_node_indices_fields();
    common_fields=intersect(index_fields,fieldnames(s.fa));

    assert(~isempty(common_fields));
    first_field=common_fields{1};
    node_indice_base0=s.fa.(first_field);
    node_indices=double(node_indice_base0)+1;

    sa=struct();
    if isfield(s,'sa')
        sa=convert_struct_with_3d_string_array_to_cellstr(s.sa,1);
    end


function c=convert_3d_string_array_to_cellstr(arr,dim)
    sz=size(arr);
    assert(numel(sz)==3);
    if dim==1
        new_sz_idxs=[1 3];
    else
        new_sz_idxs=[2 3];
    end

    arr_2d=reshape(arr,sz(new_sz_idxs));
    c=cellstr(arr_2d);

    if dim==2
        c=c';
    end

function s=convert_struct_with_3d_string_array_to_cellstr(s,dim)
    % deal with scipy's character arrays that represent 2d cell strings
    fns=fieldnames(s);
    for k=1:numel(fns)
        fn=fns{k};
        value=s.(fn);
        if ischar(value) && numel(size(value))==3
            s.(fn)=convert_3d_string_array_to_cellstr(value,dim);
        end
    end


function fields=pymvpa_get_node_indices_fields()
    fields={'node_indices','center_ids'};

function b=isa_gii(x)
    b=isa(x,'gifti') && isfield(x,'cdata');

function s=read_gii(fn)
    s=gifti(fn);

function [data,node_indices,sa]=build_gii(s)
    data=s.cdata';

    if ~isa(data,'double')
        data=double(data);
    end

    if isfield(s,'indices')
        node_indices=double(s.indices);
    else
        nv=size(data,2);
        node_indices=1:nv;
    end

    sa=struct();


function b=isa_niml_dset(x)
    b=isstruct(x) && isfield(x,'data');

function s=read_niml_dset(fn)
    s=afni_niml_readsimple(fn);

function [data,node_indices,sa]=build_niml_dset(s)
    data=s.data';

    if ~isa(data,'double')
        data=double(data);
    end

    if isfield(s,'node_indices')
        node_indices=s.node_indices+1; % base0 -> base1
    else
        nv=size(data,2);
        node_indices=1:nv;
    end

    sa=struct();
    if isfield(s,'stats')
        sa.stats=cosmo_statcode(s.stats);
    end
    if isfield(s,'labels')
        sa.labels=s.labels(:);
    end

function b=isa_bv_smp(x)
    b=isa(x,'xff') && isfield(x,'NrOfVertices') && isfield(x,'Map');

function s=read_bv_smp(fn)
    s=xff(fn);
    neuroelf_bless_wrapper(s);

function [data,node_indices,sa]=build_bv_smp(s)
    nsamples=s.NrOfMaps;
    nfeatures=s.NrOfVertices;

    data=zeros(nsamples,nfeatures);
    node_indices=1:nfeatures;
    labels=cell(nsamples,1);

    for k=1:nsamples
        map=s.Map(k);
        data(k,:)=map.SMPData(:);
        labels{k}=map.Name;
    end

    sa=struct();
    sa.labels=labels;
    sa.stats=cosmo_statcode(s);


function result=neuroelf_bless_wrapper(arg)
    % deals with recent neuroelf (>v1.1), where bless is deprecated
    s=warning('off','neuroelf:xff:deprecated');
    resetter=onCleanup(@()warning(s));

    result=bless(arg);

