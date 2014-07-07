function did_pass=cosmo_run_tests(varargin)
    did_pass=false;
    
    defaults=struct();
    defaults.verbose=true;
    defaults.output=1;
    
    opt=cosmo_structjoin(defaults,varargin{:});
    
    orig_pwd=pwd();
    
    mvpa_func='cosmo_fmri_dataset';
    test_subdir=fullfile('..','tests');

    mvpa_dir=fileparts(which(mvpa_func));
    test_dir=fullfile(mvpa_dir,test_subdir);
    
    do_open_output_file=~isnumeric(opt.output);
    
    try
        cd(test_dir);

        
        if do_open_output_file
            fid=fopen(opt.output,'w');
        else
            fid=opt.output;
        end
        
        suite=TestSuite.fromName(test_dir);
        fprintf(fid, 'Unit test suite: %d tests\n',suite.numTestCases);
        
        doc_suite=CosmoDocTestSuite(mvpa_dir);
        fprintf(fid, 'Doc test suite: %d tests\n',doc_suite.numTestCases);

        suite.add(doc_suite);

        if opt.verbose
            monitor_constructor=@VerboseTestRunDisplay;
        else
            monitor_constructor=@TestRunDisplay;
        end
        
        monitor = monitor_constructor(fid);
        did_pass=suite.run(monitor);
                
        if do_open_output_file
            fclose(fid);
        end
    catch ME
        cd(orig_pwd);
        
        try
            fclose(fid);
        catch
            % do nothing
        end
        
        rethrow(ME);
    end
    
    
    
    cd(orig_pwd);
    
    
    
    
