.PHONY: help \
        install-matlab install-octave install \
        uninstall-matlab uninstall-octave uninstall \
        test-matlab test-octave test \
        html clean-html website \
		html-archive-dir html-zip-archive html-targz-archive

MATLAB?=matlab
OCTAVE?=octave

TESTDIR=$(CURDIR)/tests
ROOTDIR=$(CURDIR)
MVPADIR=$(ROOTDIR)/mvpa
DOCDIR=$(CURDIR)/doc
DOCBUILDDIR=$(DOCDIR)/build
HTMLDOCBUILDDIR=$(DOCBUILDDIR)/html
WEBSITEROOT=db:~/web
WEBSITESTATIC=$(WEBSITEROOT)/_static
DOCUMENTATION_HTML_PREFIX=CoSMoMVPA_documentation_html
DOCARCHIVEDIR=$(DOCBUILDDIR)/$(DOCUMENTATION_HTML_PREFIX)
DOCUMENTATION_FILES_TO_ARCHIVE=AUTHOR copyright README.rst

RUNTESTS_ARGS?='-verbose'
	
ifdef JUNIT_XML
	RUNTESTS_ARGS +=,'-junit_xml','$(JUNIT_XML)'
endif

ifdef WITH_COVERAGE
	ifndef COVER
		#$(error COVER variable must be set when using WITH_COVERAGE)
	endif
	RUNTESTS_ARGS+=,'-with_coverage','-cover','$(COVER)'
	export COVER

	ifdef COVER_XML_FILE
		 RUNTESTS_ARGS+=,'-cover_xml_file','$(COVER_XML_FILE)'
		 export COVER_XML_FILE
	endif

	ifdef COVER_HTML_DIR
		 RUNTESTS_ARGS+=,'-cover_html_dir','$(COVER_HTML_DIR)'
		 export COVER_HTML_DIR
	endif

	ifdef COVER_JSON_FILE
		 RUNTESTS_ARGS+=,'-cover_json_file','$(COVER_JSON_FILE)'
		 export COVER_JSON_FILE
	endif

	ifdef JUNIT_XML_FILE
		 RUNTESTS_ARGS+=,'-junit_xml_file','$(JUNIT_XML_FILE)'
		 export JUNIT_XML_FILE
	endif
endif
		
	
export RUNTESTS_ARGS


ADDPATH="cd('$(MVPADIR)');cosmo_set_path()"
RMPATH="cd('$(MVPADIR)'); \
		ds=cosmo_strsplit(genpath('$(ROOTDIR)'),pathsep()); \
		msk=cosmo_match(ds,path()); \
		rmpath(cosmo_strjoin(ds(msk),pathsep()))"
SAVEPATH="savepath();exit(0)"

INSTALL=$(ADDPATH)";"$(SAVEPATH)
UNINSTALL=$(RMPATH)";"$(SAVEPATH)
TEST=$(ADDPATH)"; \
     cd('$(TESTDIR)'); \
     success=cosmo_run_tests($(RUNTESTS_ARGS)); \
     exit(~success);"

help:
	@echo "Usage: make <target>, where <target> is one of:"
	@echo "------------------------------------------------------------------"
	@echo "  install            to add CoSMoMVPA to the Matlab and GNU Octave"
	@echo "                     search paths, using whichever is present"
	@echo "  uninstall          to remove CoSMoMVPA from the Matlab and GNU"
	@echo "                     Octave search paths, using whichever is"
	@echo "                     present"
	@echo "  uninstall          to run tests using from the Matlab and GNU"
	@echo "                     Octave search paths, using whichever is"
	@echo "                     present"
	@echo "  html 				build HTML documentation"
	@echo " "
	@echo "  install-matlab     to add CoSMoMVPA to the Matlab search path"
	@echo "  install-octave     to add CoSMoMVPA to the GNU Octave search path"
	@echo "  uninstall-matlab   to remove CoSMoMVPA from the Matlab search path"
	@echo "  uninstall-octave   to remove CoSMoMVPA from the GNU Octave search"
	@echo "                     path"
	@echo "  test-matlab        to run tests using Matlab"
	@echo "  test-octave        to run tests using GNU Octave"
	@echo " "
	@echo ""



MATLAB_BIN=$(shell which $(MATLAB))
OCTAVE_BIN=$(shell which $(OCTAVE))

ifeq ($(MATLAB_BIN),)
	# for Apple OSX, try to locate Matlab elsewhere if not found
    MATLAB_BIN=$(shell ls /Applications/MATLAB_R20*/bin/${MATLAB} 2>/dev/null | tail -1)
endif

MATLAB_RUN_CLI=$(MATLAB_BIN) -nojvm -nodisplay -nosplash -r
OCTAVE_RUN_CLI=$(OCTAVE_BIN) --no-gui --quiet --eval


install-matlab:
	@if [ -n "$(MATLAB_BIN)" ]; then \
		$(MATLAB_RUN_CLI) $(INSTALL); \
	else \
		echo "matlab binary could not be found, skipping"; \
	fi;

install-octave:
	@if [ -n "$(OCTAVE_BIN)" ]; then \
		$(OCTAVE_RUN_CLI) $(INSTALL); \
	else \
		echo "octave binary could not be found, skipping"; \
	fi;

install:
	@if [ -z "$(MATLAB_BIN)$(OCTAVE_BIN)" ]; then \
		@echo "Neither matlab binary nor octave binary could be found" \
		exit 1; \
	fi;
	$(MAKE) install-matlab
	$(MAKE) install-octave


uninstall-matlab:
	@if [ -n "$(MATLAB_BIN)" ]; then \
		$(MATLAB_RUN_CLI) $(UNINSTALL); \
	else \
		echo "matlab binary could not be found, skipping"; \
	fi;

uninstall-octave:
	@if [ -n "$(OCTAVE_BIN)" ]; then \
		$(OCTAVE_RUN_CLI) $(UNINSTALL); \
	else \
		echo "octave binary could not be found, skipping"; \
	fi;

uninstall:
	@if [ -z "$(MATLAB_BIN)$(OCTAVE_BIN)" ]; then \
		@echo "Neither matlab binary nor octave binary could be found" \
		exit 1; \
	fi;
	$(MAKE) uninstall-matlab
	$(MAKE) uninstall-octave


test-matlab:
	if [ -n "$(MATLAB_BIN)" ]; then \
		$(MATLAB_RUN_CLI) $(TEST); \
	else \
		echo "matlab binary could not be found, skipping"; \
	fi;

test-octave:
	if [ -n "$(OCTAVE_BIN)" ]; then \
		$(OCTAVE_RUN_CLI) $(TEST); \
	else \
		echo "octave binary could not be found, skipping"; \
	fi;

test:
	@if [ -z "$(MATLAB_BIN)$(OCTAVE_BIN)" ]; then \
		@echo "Neither matlab binary nor octave binary could be found" \
		exit 1; \
	fi;
	$(MAKE) test-matlab
	$(MAKE) test-octave

html:
	@cd $(DOCDIR) && $(MAKE) html

clean-html:
	@cd $(DOCDIR) && $(MAKE) clean


html-archive-dir: html
	@if [ ! -d "$(DOCARCHIVEDIR)" ]; then \
		mkdir -p $(DOCARCHIVEDIR); \
	fi
	@ln -fs $(HTMLDOCBUILDDIR) $(DOCARCHIVEDIR)
	@for fn in $(DOCUMENTATION_FILES_TO_ARCHIVE); do \
		ln -fs $(CURDIR)/$$fn $(DOCARCHIVEDIR)/$$fn; \
	done


html-zip-archive: html-archive-dir
	@cd $(DOCBUILDDIR); \
	zip -qr $(DOCUMENTATION_HTML_PREFIX).zip \
				$(DOCUMENTATION_HTML_PREFIX)

html-targz-archive: html-archive-dir
	@cd  $(DOCBUILDDIR); \
	tar -zchf $(DOCUMENTATION_HTML_PREFIX).tar.gz \
			$(DOCUMENTATION_HTML_PREFIX)


website: html html-zip-archive html-targz-archive
	@rsync -vrcu $(HTMLDOCBUILDDIR)/* $(WEBSITEROOT)/
	@rsync -vcru $(addprefix $(DOCBUILDDIR)/$(DOCUMENTATION_HTML_PREFIX),.zip .tar.gz) \
				 $(WEBSITESTATIC)/

