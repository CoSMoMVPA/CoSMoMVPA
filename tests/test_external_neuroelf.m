function test_suite=test_external_neuroelf()
% regression tests for external "neuroelf" toolbox
%
% #   For CoSMoMVPA's copyright information and license terms,   #
% #   see the COPYING file distributed with CoSMoMVPA.           #
    try % assignment of 'localfunctions' is necessary in Matlab >= 2016
        test_functions=localfunctions();
    catch % no problem; early Matlab versions can use initTestSuite fine
    end
    initTestSuite;

function test_xff_map2fmri_map_no_increased_memory_usage()
    helper_test_xff_no_increased_memory_usage('map');


function test_xff_fmri_io_no_increased_memory_usage()
    helper_test_xff_no_increased_memory_usage('file');

function test_xff_map2fmri_object_no_increased_memory_usage()
    helper_test_xff_no_increased_memory_usage('object');


function helper_test_xff_no_increased_memory_usage(method)

    if cosmo_skip_test_if_no_external('neuroelf')
        return;
    end

    n_orig=helper_count_xff_objects();

    ds=cosmo_synthetic_dataset();

    ext='vmp';
    switch method
        case 'file'
            fn=sprintf('%s.%s',tempname(),ext);
            cleaner=onCleanup(@()delete(fn));
            cosmo_map2fmri(ds,fn);

            n_new=helper_count_xff_objects();
            assert(n_new==n_orig,sprintf('count increased by %d',...
                                n_new-n_orig));

            ds_again=cosmo_fmri_dataset(fn);
            assertElementsAlmostEqual(sort(ds.samples(:)),...
                                        sort(ds_again.samples(:)),1e-5);
        case 'map'
            cosmo_map2fmri(ds,['-bv_' ext]);

        case 'object'
            obj=cosmo_map2fmri(ds,['-bv_' ext]);
            ds_again=cosmo_fmri_dataset(obj);

            % obj should not be cleared when mapping it
            assert(isfield(obj,'XStart'));

            % cleanup
            clear ds_again;
            obj.ClearObject();
            clear obj


        otherwise
            assert(false)
    end

    n_new=helper_count_xff_objects();
    assert(n_new==n_orig,sprintf('count increased by %d', n_new-n_orig));


function count=helper_count_xff_objects
    if cosmo_skip_test_if_no_external('!evalc')
        return;
    end

    xff_str=evalc('xff()');
    lines=cosmo_strsplit(xff_str,'\n');

    pre_idx=strmatch('   # | Type  | ',lines);
    line_idxs=strmatch('------------------',lines);

    if isempty(pre_idx)
        % Neuroelf < v1.1, no objects
        assert(isempty(line_idxs));
        count=0;
        return;
    end

    post_idx=line_idxs(line_idxs>(pre_idx+2));

    assert(numel(pre_idx)==1);

    if numel(post_idx)==0
        count=0;
        return;
    end

    assert(numel(post_idx)==1);

    offset=2;
    count=post_idx-pre_idx-offset;
