function stat_repr=cosmo_statcode(ds, output_format)
% Convert statcode for different analysis packages
%
% stat_repr=cosmo_statcode(ds[, output_format])
%
% Inputs:
%   ds             dataset struct with N samples, or Nx1 cell with strings
%                  with statistic labels, or AFNI, BV or NIFTI header
%                  struct for N samples.
%   output_format  Optional; one of 'afni', 'bv', or 'nifti'; or empty.
%
% Returns:
%   stat_repr      - If output_format is empty or omitted: an Nx1 cell
%                    with a string representation of the statistic in each
%                    sample, e.g. 'Ftest(123,2)' or 'Zscore()' or empty.
%                  - If output_format=='afni': struct with field
%                    .BRICK_STATAUX.
%                  - If output_format=='bv': Nx1 cell with structs, each
%                    with fieldnames .name, .DF1 and .DF2.
%                  - If output_format=='nifti': struct with fieldnames
%                    .intent_code and .intent_p{1,2,3} if all stat codes
%                    are the same; empty otherwise (NIFTI does not support
%                    different stat codes for different samples).
%
% Notes:
%   - this function is intended for fmri datasets
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    if nargin<2, output_format=''; end

    % see what kind of input we got
    if iscellstr(ds)
        % string representation of stats
        stat_repr=ds(:);
    elseif isstruct(ds) && isfield(ds,'samples')
        % dataset struct
        if isfield(ds,'sa') && isfield(ds.sa,'stats')
            % get stat information
            stat_repr=ds.sa.stats;
        else
            % no stat information; return empty output
            stat_repr=[];
        end
    else
        % assume header from AFNI, BV or NIFTI; try to convert it to string
        % representation, or fail in hdr2strs if that's not the case
        stat_repr=hdr2strs(ds);
    end

    % convert to (name, df) pairs
    name_df=stat_strs2name_df(stat_repr);

    if isempty(output_format)
        % we're done
        return
    end

    % convert to package-specific header
    stat_repr=name_df2hdr(name_df, output_format);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% helper functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function name_df=stat_strs2name_df(stat_strs)
% converts string representations to name and degrees of freedom
    match_regexp_failed=@(res) isempty(res) || isempty(res.name);

    n=numel(stat_strs);

    name_df=cell(n,2);
    for k=1:n
        stat_str=stat_strs{k};
        if isempty(stat_str)
            name_df{k,1}='';
        else
            % try with parentheses: 'stat_name(df1,df2,df3)'
            names=regexp(stat_str,'^(?<name>\w+)\((?<df>[,\d]*)\)$',...
                                                        'names');
            if match_regexp_failed(names)
                % try without parentheses: 'stat_name'
                names=regexp(stat_str,'^(?<name>\w+)$','names');
                df=[];
            else
                df_split=cosmo_strsplit(names.df,',');
                if isequal(df_split,{''})
                    df=[];
                else
                    df=cellfun(@str2num,df_split);
                end
            end

            if match_regexp_failed(names)
                error('Unable to parse stat string %s', stat_str);
            end

            name_df{k,1}=names.name;
            name_df{k,2}=df;
        end
    end


function hdr=name_df2hdr(name_df, output_format)
% converts statistic name and df to package-specific header
%
% hdr=name_df2hdr(name_df, output_format)
%
% Inputs:
%   name_df:        Kx2 cell with name and degrees of freedom, for K
%                   samples
%   output_format   'afni', 'bv', or 'nifti'
%
% Returns:
%   hdr             Part of the package-specific header containing the
%                   statistical information
    codes=get_codes(output_format);
    nsamples=size(name_df,1);

    stat_idxs=zeros(nsamples,1);
    names=codes(:,1);
    for k=1:nsamples
        name=name_df{k,1};
        if isempty(name)
            continue;
        end
        idx=find(cosmo_match(names, name));
        if numel(idx)==1
            % ignore if not found or multiple matches
            stat_idxs(k)=idx;
        elseif ~strcmp(name,'none')
            cosmo_warning('Unrecognized stat name %s at sample %d',name,k);
        end
    end

    switch output_format
        case 'afni'
            hdr=struct();

            % space for each sample
            auxs=cell(1,nsamples);

            % build BRICK_STATAUX struct
            for k=1:nsamples
                stat_idx=stat_idxs(k);
                if stat_idx==0
                    continue;
                end
                df=name_df{k,2};
                auxs{k}=[(k-1) stat_idx numel(df) df];
            end

            % concatenate information for all samples
            hdr.BRICK_STATAUX=[auxs{:}];

        case 'bv'
            maps=cell(nsamples,1);
            for k=1:nsamples
                map=struct();
                stat_idx=stat_idxs(k);
                map.Type=stat_idx;

                if stat_idx~=0
                    df=name_df{k,2};

                    if numel(df)>=1, map.DF1=df(1); end
                    if numel(df)>=2, map.DF2=df(2); end
                end

                maps{k}=map;
            end

            hdr=maps; % return a cell with maps

        case 'nifti'
            hdr=struct();

            if isempty(stat_idxs)
                return
            end

            unq_stat_idx=unique(stat_idxs);
            df=name_df(:,2);
            n=numel(df);
            ndf=cellfun(@numel,df);
            max_ndf=max(ndf);
            df_matrix=zeros(n, max_ndf);


            for k=1:n
                dfk=df{k};
                n_dfk=numel(dfk);
                if n_dfk>0
                    df_matrix(k,1:n_dfk)=dfk;
                end
            end

            unq_df=unique(df_matrix,'rows');

            if numel(unq_stat_idx)>1 || numel(unique(ndf))>1 || ...
                            size(unq_df,1)>1
                cosmo_warning(['Multiple stat codes found, unsupported '...
                                    'by nifti']);
                return
            end

            hdr.intent_code=unq_stat_idx;

            df=zeros(1,3);
            if ~isempty(unq_df)
                df(1:numel(unq_df))=unq_df;
            end
            hdr.intent_p1=df(1);
            hdr.intent_p2=df(2);
            hdr.intent_p3=df(3);

        otherwise
            assert(false,'should never come here');
    end


function stat_strs=hdr2strs(hdr)
% Converts package-specific header to stat string representation
%
% stat_strs=hdr2strs(hdr)
%
% Inputs:
%   hdr         AFNI, BV vmp, or NIFTI header
%
% Returns:
%   stat_strs   Kx1

    if isfield(hdr, 'Map') && (isfield(hdr,'VMRDimX') ||...
                                isfield(hdr,'NrOfVertices'))
        % bv vmp or smp
        codes=get_codes('bv');
        nsamples=numel(hdr.Map);
        stat_strs=cell(nsamples,1);

        for k=1:nsamples
            map=hdr.Map(k);
            tp=map.Type;
            df=[map.DF1 map.DF2];
            stat_strs{k}=stat_code2str(codes, tp, df);
        end

    elseif isstruct(hdr) && isfield(hdr,'DATASET_RANK')
        % afni
        nsamples=hdr.DATASET_RANK(2);
        stat_strs=repmat({''},nsamples,1);

        if isfield(hdr,'BRICK_STATAUX')
            codes=get_codes('afni');
            aux=hdr.BRICK_STATAUX;
            naux=numel(aux);
            pos=0;
            while (pos+2)<naux
                pos=pos+1;
                brik_idx=aux(pos)+1; % base0 => base1
                stat_code=aux(pos+1); % stat code
                n_df=aux(pos+2); % # of df
                if naux<pos+2+n_df
                    break;
                end
                df=aux(pos+2+(1:n_df)); % get dfs
                stat_strs{brik_idx}=stat_code2str(codes, stat_code, df);
                pos=pos+2+n_df;
            end

            % sanity check
            if pos~=naux
                error('Not all elements were processed in STATAUX %s',...
                            sprintf('%d ', aux));
            end
        end

    elseif isstruct(hdr) && isfield(hdr,'dime') && isfield(hdr.dime,'dim')
        % nifti
        codes=get_codes('nifti');

        dime=hdr.dime;
        % deal with potential data in >4th dimension
        % (AFNI-NIFTI conversion syndrome)
        nsamples=max(prod(dime.dim(5:end)),dime.dim(5));

        % get stat codes
        stat_code=dime.intent_code;
        stat_df=[dime.intent_p1 dime.intent_p2 dime.intent_p3];
        stat_str=stat_code2str(codes,stat_code,stat_df);

        % repeat for as many samples as there are in the dataset
        stat_strs=repmat({stat_str},nsamples,1);
    else
        error('Unsupported input');
    end


function str=stat_code2str(codes, stat_code, df)
% give string representation of stat code with degrees of freedom

% (df can have more elements than required; superfluous ones are ignored.)
    if stat_code==0
        str='';
        return
    end

    name=codes{stat_code,1};

    if isempty(name)
        error('Illegal stat_code: %d', stat_code);
    end

    % build string representation of df
    df_count=codes{stat_code,2};
    df_str=cellfun(@(x) sprintf('%d',x),num2cell(df(1:df_count)),...
                        'UniformOutput',false);

    % join with stat name
    str=sprintf('%s(%s)',name,cosmo_strjoin(df_str,','));



function codes=get_codes(package)
% get names and number of degrees of freedom for an analysis package
%
% codes=get_codes(package)
%
% Inputs:
%   package      'nifti', 'afni' or 'bv'.
%
% Returns:
%   codes        Px2 cell, with codes{k,1} the name of the k-th stat
%                and codes{k,2} the number of degrees of freedom


    switch package
        case 'nifti'
            % http://nifti.nimh.nih.gov/nifti-1/documentation/...
            %                 nifti_stats.pdf
            codes={'',0;... % not defined
                    'Correl',1;... % first one starts at 2
                    'Ttest',1;...
                    'Ftest',2;...
                    'Zscore',0;...
                    'Chisq',1;...
                    'Beta',2;...
                    'Binom',2;...
                    'Gamma',2;...
                    'Poisson',1;...
                    'Normal',2,;...
                    'Ftest_Nonc',3;...
                    'Chisq_Nonc',2;...
                    'Logistic',2;...
                    'Laplace',2;...
                    'Uniform',2;...
                    'Ttest_Nonc',2;...
                    'Weibull',3;...
                    'Chi',1;...
                    'Invgauss',2;...
                    'Extval',2;...
                    'Pval',0;...
                    'Logpval',0;...
                    'Log10pval',0};


        case 'afni'
            % http://afni.nimh.nih.gov/pub/dist/doc/program_help/...
            %                README.attributes.html
            % AFNI uses a subset of NIFTI.
            nifti_codes=get_codes('nifti'); % recursive call
            codes=nifti_codes(1:10,:);


        case 'bv'
            % http://support.brainvoyager.com/documents/Available_Tools/...
            %              Available_Plugins/niftiplugin_manual_v12.pdf
            % why follow a standard (like NIFTI) if one can
            % come up with something incompatible too?
            codes={'Ttest',1;...      % 1
                      'Correl',1;...  % 2  correlation
                      'Correl',1;...  % 3 "cross-correlation"
                      'Ftest',2;...   % 4
                      'Zscore',0;...  % 5
                      '',0;...        % 6 [lots of undefined codes here]
                      '',0;...        % 7
                      '',0;...        % 8
                      '',0;...        % 9
                      '',0;...        % 10
                      '',0;...        % 11 "percent signal change" ignored
                      '',0;...        % 12 "ICA" ignored
                      '',0;...        % 13
                      'Chisq',1;...   % 14
                      'Beta',2;...    % 15
                      'Pval',0};      % 16
        otherwise
            error('Unsupported analysis package %s', package);
    end


