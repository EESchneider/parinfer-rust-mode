export EMACS ?= emacs
EMACSFLAGS = -Q -L .
CASK = cask
VERSION = $(shell git describe --tags --abbrev=0 | sed 's/^v//')
PKG = parinfer-rust-mode
FILTER_FILES =  $(PKG)-autoloads.el test-helper.el run-tests.el generate-tests.el
ELS_ALL = $(wildcard *.el)
ELS = $(filter-out $(FILTER_FILES),$(ELS_ALL))
OBJECTS = $(ELS:.el=.elc)
RAW_OS = $(shell uname | tr '[:upper:]' '[:lower:]')
OS = $(RAW_OS:mingw%=windows)
.PHONY: elpa build version download test lint clean elpaclean run-$(PKG)

all: build

-include .depend

elpa-$(EMACS):
	$(CASK) install
	$(CASK) update
	touch $@

elpa: elpa-$(EMACS)

build: version elpa
	$(CASK) build

version:
	$(EMACS) --version

~/.emacs.d/parinfer-rust/parinfer-rust-%.so ~/.emacs.d/parinfer-rust/parinfer-rust-%.dll:
	echo "downloading libraries for $*"
	mkdir -p "$(HOME)/.emacs.d/parinfer-rust"
	curl -fL "https://github.com/justinbarclay/parinfer-rust-emacs/releases/download/v0.4.6/parinfer-rust-$*$(suffix $@)" -o "$@"

ifeq (windows, $(OS))
download: ~/.emacs.d/parinfer-rust/parinfer-rust-$(OS).dll
else
download: ~/.emacs.d/parinfer-rust/parinfer-rust-$(OS).so
endif

test: clean elpa version download build
	$(CASK) exec ert-runner test/**.el --quiet

lint: version elpa
	$(CASK) exec $(EMACS) -Q --batch \
		--eval "(setq enable-local-variables :safe)" \
		-l elisp-lint.el -f elisp-lint-files-batch \
		$(ELS)

test-all: lint test

clean:
	rm -f .depend $(OBJECTS) $(PKG)-autoloads.el

elpaclean: clean
	rm -f elpa*
	rm -rf .cask # Clean packages installed for development
