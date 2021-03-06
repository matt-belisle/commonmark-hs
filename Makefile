DATE=$(shell date +%Y-%m-%d-%H%M)
LOGS=log
ifdef PATTERN
  TESTARGS?='-p "$(PATTERN)" --hide-successes'
  BENCHARGS?='--output $(LOGS)/benchmark-$(DATE).html --time-limit=2 --match=pattern "$(PATTERN)"'
else
  TESTARGS?="--hide-successes"
  BENCHARGS?="--output $(LOGS)/benchmark-$(DATE).html --time-limit=2"
endif
SOURCEFILES?=$(shell find commonmark/src commonmark-cli/src commonmark-pandoc/src -name '*.hs')
GHC_OPTS=-Wall -fno-warn-unused-do-bind -Wnoncanonical-monad-instances -Wnoncanonical-monadfail-instances -Wincomplete-uni-patterns -Werror=missing-home-modules -Widentities -Wcpp-undef -fhide-source-paths

all:
	stack install --ghc-options="$(GHC_OPTS)" --test --test-arguments=--hide-successes --bench --no-run-benchmarks

quick:
	stack install --test --no-run-tests --fast

test:
	stack test --test-arguments=$(TESTARGS)

haddock:
	stack haddock

prof:
	stack install --profile
	# commonmark +RTS -pj -RTS ../pandoc/MANUAL.txt >/dev/null
	# cat commonmark.prof | ghc-prof-aeson-flamegraph | flamegraph.pl > prof.svg
	# open -a Safari prof.svg

$(LOGS):
	mkdir -p $(LOGS)

bench: $(LOGS)
	stack bench --benchmark-arguments=$(BENCHARGS) commonmark 2>&1 \
	    | tee $(LOGS)/benchmark-$(DATE).out

ghci:
	stack ghci --ghci-options "-XOverloadedStrings" commonmark
#	stack ghci --ghci-options "-interactive-print=Text.Pretty.Simple.pPrint -XOverloadedStrings" --package pretty-simple

reformat:
	for f in $(SOURCEFILES); do echo $$f; stylish-haskell -i $$f ; done

lint:
	for f in $(SOURCEFILES); do echo $$f; hlint --verbose --cpp-simple --refactor --refactor-options='-i -s' $$f; done

clean:
	stack clean

pathologicaltest:
	python3 test/pathological_tests.py --prog commonmark

.PHONY: quick ghci spectest pathologicaltest test bench prof clean all reformat lint haddock
