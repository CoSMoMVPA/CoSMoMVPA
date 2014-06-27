function s=cosmo_map2surface(ds, fn)
% maps a dataset structure to AFNI/SUMA NIML dset or BV SMP file
% 
% Usage 1: s=cosmo_map2surface(ds, '-{FMT}) returns a struct s
% Usage 2: cosmo_map2surface(ds, fn) saves a dataset to a file.
%
% In Usage 1, {FMT} can be one of 'niml_dset' or 'smp'
% In Usage 2, fn should end with '.niml.dset' or '.smp'
%
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
        writer(fn, s);
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
    
function s=build_niml_dset(ds)
    if ~isequal(ds.a.dim.labels,{'node_indices'})
        error('Expected a.dim.labels={''node_indices''}');
    end
    
    s=struct();
    s.node_indices=(ds.a.dim.values{1}(ds.fa.node_indices))-1;
    s.data=ds.samples';
    
    if isfield(ds,'sa')
        if isfield(ds.sa,'labels');
            s.labels=ds.sa.labels;
        end

        if isfield(ds.sa,'stats');
            s.stats=ds.sa.stats;
        end
    end
    
function write_niml_dset(fn,s)
    afni_niml_writesimple(s,fn);
    
    
function s=build_bv_smp(ds)
    s=xff('new:smp');
    
    nsamples=size(ds.samples,1);
    stats=cosmo_statcode(ds,'bv');
    
    maps=cell(1,nsamples);
    for k=1:nsamples
        t=xff('new:smp');
        map=t.Map;
        map.SMPData=cosmo_unflatten(cosmo_slice(ds,k));
        
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
        
        map.BonferroniValue=nfeatures;
        
        maps{k}=map;
    end
    
    s.Map=cat(2,maps{:});
    s.NrOfMaps=nsamples;
    s.NrOfVertices=nfeatures;
    
function write_bv_smp(fn,s)
    s.SaveAs(fn);
    
    
    
        
        
        
        
        
        
    
    
        
    
    