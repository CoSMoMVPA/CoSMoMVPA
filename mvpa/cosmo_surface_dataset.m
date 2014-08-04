function ds=cosmo_surface_dataset(fn, varargin)
% Returns a dataset structure based on surface mesh data
%
% ds=cosmo_meeg_dataset(filename, varargin)
%
% Inputs:
%   filename          filename of surface data to be loaded. Currently
%                     supported are '.niml.dset' (AFNI/SUMA NIML) and
%                     'smp' (BrainVoyager surface maps)
%   'targets', t      Px1 targets for P samples; these will be stored in
%                     the output as ds.sa.targets
%   'chunks', c       Px1 chunks for P samples; these will be stored in the
%                     the output as ds.sa.chunks
% Notes:
%   - this function is intended for datasets with surface data, i.e. with
%     one or more values associated with each surface node. It does not
%     support anatomical surface meshes that contain node coordinates and
%     faces. To read and write such anatomical meshes, consider the surfing
%     toolbox, github.com/nno/surfing
%
% Dependencies:
%   - for Brainvoyager files (.smp), it requires the NeuroElf
%     toolbox, available from: http://neuroelf.net
%   - for AFNI/SUMA NIML files (.niml.dset) it requires the AFNI
%     Matlab toolbox, available from: http://afni.nimh.nih.gov/afni/matlab/
%
% NNO May 2014

    defaults=struct();
    defaults.targets=[];
    defaults.chunks=[];

    params = cosmo_structjoin('!', defaults, varargin);

    if cosmo_check_dataset(fn,'surface',false)
        % it is already a dataset, so return it
        ds=fn;
        return
    end


    [data,node_indices,sa]=read(fn);
    [nsamples, nfeatures]=size(data);
    assert(nfeatures==numel(node_indices));

    ds=struct();
    ds.samples=data;

    % set sample attributes
    ds.sa=sa;

    % set feature attributes
    ds.fa.node_indices=1:nfeatures;

    % set dataset attributes
    dim.labels={'node_indices'};
    dim.values={node_indices(:)};
    ds.a.dim=dim;

     % set targets and chunks
    ds=set_vec_sa(ds,'targets',params.targets);
    ds=set_vec_sa(ds,'chunks',params.chunks);

    % check consistency
    cosmo_check_dataset(ds,'surface');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% general helper functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
                    [data,node_indices,sa]=builder(s);
                    return
                end
            end
        end
    end

    if ischar(fn)
        error('Unsupported extension in filename %s', fn);
    else
        error('Unsupported input');
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
    img_formats.bv_smp.externals={'neuroelf'};

function b=isa_niml_dset(x)
    b=isstruct(x) && isfield(x,'data') && isfield(x,'node_indices');

function s=read_niml_dset(fn)
    s=afni_niml_readsimple(fn);

function [data,node_indices,sa]=build_niml_dset(s)
    data=s.data';

    sa=struct();
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






