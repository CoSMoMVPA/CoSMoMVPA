function s=cosmo_map2surface(ds, fn, varargin)
% maps a dataset structure to AFNI/SUMA NIML dset or BV SMP file
%
% s=cosmo_map2surface(ds, output, ...)
%
% Inputs:
%   ds                  dataset struct with surface-based data
%   output              String, indicating either the output format or the
%                       filename.
%                       - If output starts with a '-', then it must be one
%                         of:
%                           '-niml_dset'    AFNI NIML
%                           '-bv_smp'       BrainVoyager surface map
%                           '-gii'          GIFTI
%                       - otherwise it must be a string indicating a file
%                         name, and end with one of
%                           '.niml.dset'    AFNI NIML
%                           '.smp'          BrainVoyager surface map
%                           '.gii'          GIFTI
%  'encoding', e        Optional encoding for AFNI NIML or GIFTI. Depending
%                       on the output format, supported values for e are:
%                       - NIML:  'ascii', 'binary',
%                                'binary.lsbfirst', 'binary.msbfirst'
%                         (the 'binary' option uses the machine's native
%                         format with either the least or most significant
%                         byte first)
%                       - GIFTI: 'ASCII', 'Base64Binary',
%                                'GZipBase64Binary'
%                       The encoding argument is ignored for BrainVoyager
%                       output.
%
% Output:
%   s                   Structure containing the surface based data based
%                       on the output format; either a struct with
%                       NIML data, an xff object, or a GIFTI object.
%
% Examples:
%     ds=cosmo_synthetic_dataset('type','surface');
%     %
%     % convert to AFNIML NIML format
%     % (to store a file to disc, use a filename as the second argument)
%     niml=cosmo_map2surface(ds,'-niml_dset');
%     cosmo_disp(niml);
%     > .node_indices
%     >   [ 0         1         2         3         4         5 ]
%     > .data
%     >   [   2.03     0.584     -1.44    -0.518      1.19     -1.33
%     >     -0.892      1.84    -0.262      2.34    -0.204      2.72
%     >     -0.826      1.17     -1.92     0.441    -0.209     0.148
%     >       1.16    -0.848      3.09      1.86      1.76     0.502
%     >       1.16      3.49     -1.37     0.479    -0.955      3.41
%     >      -1.29    -0.199      1.73    0.0832     0.501     -0.48 ]
%
%     ds=cosmo_synthetic_dataset('type','surface');
%     % convert to bv smp xff struct
%     % (to store a file to disc, use a filename as the second argument)
%     bv_smp=cosmo_map2surface(ds,'-bv_smp')
%     >           FileVersion: 5
%     >          NrOfVertices: 6
%     >              NrOfMaps: 6
%     >     NameOfOriginalSRF: 'untitled.srf'
%     >                   Map: [1x6 struct]
%     >           RunTimeVars: [1x1 struct]
%
% Notes:
%   - this function is intended for datasets with surface data, i.e. with
%     one or more values associated with each surface node. It does not
%     support anatomical surface meshes that contain node coordinates and
%     faces. To read and write such anatomical meshes, consider the surfing
%     toolbox, github.com/nno/surfing
%   - To load surface datasets, use cosmo_surface_dataset
%
% Dependencies:
%   - for Brainvoyager files (.smp), it requires the NeuroElf
%     toolbox, available from: http://neuroelf.net
%   - for AFNI/SUMA NIML files (.niml.dset) it requires the AFNI
%     Matlab toolbox, available from: https://github.com/afni/AFNI
%
% See also: cosmo_surface_dataset
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    if ~ischar(fn)
        error('second argument must be a string');
    end

    defaults=struct();
    opt=cosmo_structjoin(defaults,varargin);

    cosmo_check_dataset(ds,'surface');

    formats=get_formats();

    sp=cosmo_strsplit(fn,'-');
    save_to_file=~isempty(sp{1});

    if save_to_file
        fmt=get_format(formats, fn);
    else
        if numel(sp)~=2
            error('expected -{FORMAT}');
        end
        fmt=sp{2};
    end

    if ~isfield(formats,fmt)
        error('Unsupported format %s', fmt);
    end

    format=formats.(fmt);
    externals=format.externals;
    cosmo_check_external(externals);

    builder=format.builder;
    s=builder(ds);

    if save_to_file
        writer=format.writer;
        writer(fn, s, opt);
    end

function format=get_format(formats,fn)
    endswith=@(s,e) isempty(cosmo_strsplit(s,e,-1));

    names=fieldnames(formats);
    for k=1:numel(names)
        name=names{k};
        exts=formats.(name).exts;
        for j=1:numel(exts)
            if endswith(fn,exts{j})
                format=name;
                return
            end
        end
    end

    error('Unsupported extension in %s', fn);


function formats=get_formats()
    formats=struct();
    formats.niml_dset.exts={'.niml.dset'};
    formats.niml_dset.builder=@build_niml_dset;
    formats.niml_dset.writer=@write_niml_dset;
    formats.niml_dset.externals={'afni'};

    formats.bv_smp.exts={'.smp'};
    formats.bv_smp.builder=@build_bv_smp;
    formats.bv_smp.writer=@write_bv_smp;
    formats.bv_smp.externals={'neuroelf'};

    formats.gii.exts={'.gii'};
    formats.gii.builder=@build_gifti;
    formats.gii.writer=@write_gifti;
    formats.gii.externals={'gifti'};


function [data, node_indices]=get_surface_data_and_node_indices(ds)
    [data, dim_labels, dim_values]=cosmo_unflatten(ds);
    if ~isequal(dim_labels,{'node_indices'})
        error('.a.fdim.labels must be {''node_indices''}');
    end

    node_indices=dim_values{1}(:)';




function g=build_gifti(ds)
    s=struct();

    [data, node_indices]=get_surface_data_and_node_indices(ds);

    s.indices=node_indices(:);
    s.cdata=data';

    g=gifti(s);

function write_gifti(fn,g,opt)
    if isfield(opt,'encoding')
        args={opt.encoding};
    else
        args={};
    end

    save(g,fn,args{:});




function s=build_niml_dset(ds)
    [data, node_indices]=get_surface_data_and_node_indices(ds);

    s=struct();
    s.node_indices=node_indices-1; % base 1 -> base 0
    s.data=data';

    if isfield(ds,'sa')
        if isfield(ds.sa,'labels');
            s.labels=ds.sa.labels;
        end

        if isfield(ds.sa,'stats');
            s.stats=ds.sa.stats;
        end
    end

function write_niml_dset(fn,s,opt)
    if isfield(opt, 'encoding')
        args={opt.encoding};
    else
        args={};
    end
    afni_niml_writesimple(s, fn, args{:});


function s=build_bv_smp(ds)
    s=xff('new:smp');

    [nsamples,nfeatures]=size(ds.samples);
    [data, node_indices]=get_surface_data_and_node_indices(ds);
    if ~isequal(node_indices,1:nfeatures)
        error(['BrainVoyager smp only support data with all node '...
                'present and with .a.fdim.values{1}=1:N, where N '...
                'is the number of nodes']);
    end

    stats=cosmo_statcode(ds,'bv');

    maps=cell(1,nsamples);
    for k=1:nsamples
        t=xff('new:smp');
        map=t.Map;
        map.SMPData=data(k,:);

        if k==1
            % store the number of features
            % note: unlike the niml_dset implementation, data is stored
            % for all nodes, even if some node indices did not have a value
            % originally
            nfeatures=numel(map.SMPData);
        end

        if isfield(ds,'sa')
            if isfield(ds.sa,'labels')
                map.Name=ds.sa.labels{k};
            end

            if ~isempty(stats) && ~isempty(stats{k})
                map=cosmo_structjoin(map, stats{k});
            end
        end

        if ~isempty(stats) && ~isempty(stats{k})
            map=cosmo_structjoin(map, stats{k});
        end

        map.BonferroniValue=nfeatures;

        maps{k}=map;
    end

    s.Map=cat(2,maps{:});
    s.NrOfMaps=nsamples;
    s.NrOfVertices=nfeatures;

    bless(s);

function write_bv_smp(fn,s,opt)
    s.SaveAs(fn);
    s.ClearObject();














