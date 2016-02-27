function test_suite = test_surficial_io_niml_dset
% tests for AFNI NIML input/output
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #

    initTestSuite;


function test_niml_dset_dataset_io()
    if cosmo_skip_test_if_no_external('afni')
        return;
    end

    ds=get_niml_dataset();
    fn=cosmo_make_temp_filename('_tmp','.niml.dset');
    cleaner=onCleanup(@()delete(fn));

    formats={'ascii','binary','binary.lsbfirst','binary.msbfirst'};

    n_formats=numel(formats);

    for k=1:n_formats
        format=formats{k};
        niml_str=get_niml_dset_string(format);

        fid=fopen(fn,'w');
        fwrite(fid,niml_str);
        fclose(fid);
        ds2=cosmo_surface_dataset(fn);
        assert_dataset_equal(ds,ds2);

        cosmo_map2surface(ds,fn,'encoding',format);
        ds3=cosmo_surface_dataset(fn);
        assert_dataset_equal(ds,ds3);

        % try mapping using functionality in AFNI Matlab library
        s=struct();
        s.data=ds.samples';
        s.node_indices=ds.a.fdim.values{1}(ds.fa.node_indices)-1;
        s.stats=ds.sa.stats;
        s.labels=ds.sa.labels;

        afni_niml_writesimple(s, fn, format);
        ds4=cosmo_surface_dataset(fn);
        assert_dataset_equal(ds,ds4);

        % ensure that mapping to struct works
        s2=cosmo_map2surface(ds,'-niml_dset','encoding',format);
        assertEqual(s2,s);

    end


function assert_dataset_equal(x,y)
    assertElementsAlmostEqual(x.samples,y.samples,'absolute',1e-4);
    assertEqual(sort(fieldnames(x)),sort(fieldnames(y)));
    assertEqual(x.fa,y.fa);
    assertEqual(x.sa,y.sa);
    assertEqual(x.a,y.a);



function ds=get_niml_dataset()
    ds=cosmo_synthetic_dataset('ntargets',2,'nchunks',1,...
                        'type','surface');
    ds.a.fdim.values{1}=1+[1 4 7 8 5 3];
    ds.sa=struct();
    ds.sa.stats={'Ftest(3,4)';'Zscore()'};
    % TODO: use these complicated labels
    % ds.sa.labels={'label1<>"&''';'label2'};
    ds.sa.labels={'label1';'label2'};



function string=get_niml_dset_string(format)
    string=[...
            get_niml_dset_header() ...
            get_niml_dset_data(format) ...
            get_niml_dset_footer()
            ];


function string=get_niml_dset_header()
    string=bytes_printf([...
            '<AFNI_dataset\n' ...
            '  dset_type="Node_Bucket"\n' ...
            '  self_idcode="XYZ_QJCWHYMMSUIUXCMBUZJASSJT"\n' ...
            '  filename="data.niml.dset"\n' ...
            '  label="data.niml.dset"\n' ...
            '  ni_form="ni_group" >\n' ...
            ]);

function string=get_niml_dset_footer()
    string=bytes_printf([...
            '<AFNI_atr\n' ...
            '  atr_name="COLMS_RANGE"\n' ...
            '  ni_type="String"\n' ...
            '  ni_dimen="1" >\n' ...
            '"-3.6849477 2.0316862 1 0;-1.3264908 2.3386572 2 4"'...
                        '</AFNI_atr>\n' ...
            '<AFNI_atr\n' ...
            '  atr_name="COLMS_LABS"\n' ...
            '  ni_type="String"\n' ...
            '  ni_dimen="1" >\n' ...
            '"label1;label2"</AFNI_atr>\n' ...
            '<AFNI_atr\n' ...
            '  atr_name="COLMS_TYPE"\n' ...
            '  ni_type="String"\n' ...
            '  ni_dimen="1" >\n' ...
            '"Generic_Float;Generic_Float"</AFNI_atr>\n' ...
            '<AFNI_atr\n' ...
            '  atr_name="COLMS_STATSYM"\n' ...
            '  ni_type="String"\n' ...
            '  ni_dimen="1" >\n' ...
            '"Ftest(3,4);Zscore()"</AFNI_atr>\n' ...
            '</AFNI_dataset>\n' ...
            ]);
    % TODO: use these complicated labels:
    % '"label1&lt;&gt;&quot;&amp;&apos;;label2"</AFNI_atr>\n' ...


function bytes=get_niml_dset_data(format)

    ds=get_niml_dataset();
    data=ds.samples;
    nodes_base0=ds.a.fdim.values{1}(ds.fa.node_indices)-1;

    [nrows,ncols]=size(data);

    row_sep=sprintf('\n');
    col_sep=' ';


    switch lower(format)
        case 'ascii'
            data_pat=[repmat(['%.6f' col_sep],1,nrows) row_sep];
            bucket_data=sprintf(data_pat,data);

            node_pat=['%d' row_sep];
            node_data=uint8(sprintf(node_pat,nodes_base0));
            ni_form=uint8([]);

        case {'binary','binary.lsbfirst','binary.msbfirst'};
            data_single=single(data(:)');
            node_int=int32(nodes_base0(:)');

            [unused,unused,endian]=computer();
            computer_format=sprintf('binary.%ssbfirst',lower(endian));

            do_swap=~strcmp(format,'binary') && ...
                            ~strcmp(format, computer_format);

            if do_swap
                if cosmo_wtf('is_octave')
                    % Octave 3.8 does not support byteswap for single
                    data_single_int=typecast(data_single,'int32');
                    data_single_int_swap=swapbytes(data_single_int);
                    data_single=typecast(data_single_int_swap,'single');
                else
                    data_single=swapbytes(data_single);
                end
                node_int=swapbytes(node_int);
            end

            if strcmp(format,'binary')
                ni_form_format=computer_format;
            else
                ni_form_format=format;
            end

            bucket_data=typecast(data_single,'uint8');
            node_data=typecast(node_int,'uint8');

            ni_form=sprintf('  ni_form="%s"\n',ni_form_format);

        otherwise
            error('unsupported format %s', format);
    end

    bytes=[...
            bytes_printf([...
                '<SPARSE_DATA\n' ...
                '  data_type="Node_Bucket_data"\n' ...
                '  ni_type="2*float"\n' ...
                ni_form ...
                '  ni_dimen="6" >' ])...
            bucket_data ...
            bytes_printf([...
                '</SPARSE_DATA>\n' ...
                '<INDEX_LIST\n' ...
                '  data_type="Node_Bucket_node_indices"\n' ...
                '  sorted_node_def="No"\n' ...
                '  COLMS_RANGE="1 8 0 3"\n' ...
                '  COLMS_LABS="Node Indices"\n' ...
                '  COLMS_TYPE="Node_Index"\n' ...
                '  ni_type="int"\n' ...
                ni_form ...
                '  ni_dimen="6" >']) ...
            node_data ...
            bytes_printf([...
                '</INDEX_LIST>\n' ])...
            ];



function b=bytes_printf(varargin)
    b=uint8(sprintf(varargin{:}));
