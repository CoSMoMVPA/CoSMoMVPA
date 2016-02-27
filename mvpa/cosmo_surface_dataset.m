function ds=cosmo_surface_dataset(fn, varargin)
% Returns a dataset structure based on surface mesh data
%
% ds=cosmo_meeg_dataset(filename, varargin)
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
%     > .samples
%     >   [ 1         3         5
%     >     2         4         6 ]
%     > .sa
%     >   .stats
%     >     { 'Ttest(10)'
%     >       'Zscore()'  }
%     > .fa
%     >   .node_indices
%     >     [ 1         2         3 ]
%     > .a
%     >   .fdim
%     >     .labels
%     >       { 'node_indices' }
%     >     .values
%     >       { [ 2 21 202 ] }
%
%     % construct BrainVoyager surface map
%     cosmo_check_external('neuroelf');
%     smp=xff('new:smp');
%     %
%     % make surface dataset
%     % (a filename of a .smp file is supported as well)
%     ds=cosmo_surface_dataset(smp);
%     cosmo_disp(ds)
%     > .samples
%     >   [ 0         0         0  ...  0         0         0 ]@1x40962
%     > .sa
%     >   .labels
%     >     { 'New Map' }
%     >   .stats
%     >     { 'Ttest(249)' }
%     > .fa
%     >   .node_indices
%     >     [ 1 2 3  ...  4.1e+04   4.1e+04   4.1e+04 ]@1x40962
%     > .a
%     >   .fdim
%     >     .labels
%     >       { 'node_indices' }
%     >     .values
%     >       { [ 1 2 3  ...  4.1e+04   4.1e+04   4.1e+04 ]@1x40962 }
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

    if cosmo_check_dataset(fn,'surface',false)
        ds=fn;
    else
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
    end

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

    img_formats.gii.exts={'.gii'};
    img_formats.gii.matcher=@isa_gii;
    img_formats.gii.reader=@read_gii;
    img_formats.gii.builder=@build_gii;
    img_formats.gii.externals={'gifti'};


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
    s=bless(s);

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






