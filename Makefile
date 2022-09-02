ALL	= 

objs	= 

.SUFFIXES:	.so .o .c .f

#.o.so:
#	${LD} ${LFLAGS} -o $@ $< ${LINK_LIB}

all: ${ALL}


.PHONY: clean test test2 doc
clean:
	$(RM) bin/*~

## You may need RUBYLIB=`pwd`/lib:$RUBYLIB
#  If the first test fails, the second test is not run. If you want to run the second test only
test:
	(rake test && rake test all_required=t) || (stat=$$?; echo "WARNING: Second test was not run. To separately test the second only: make test2" >&2; exit $$stat)

test2:
	rake test all_required=t

doc:
	yard doc; [[ -x ".github" && ( "README.ja.rdoc" -nt ".github/README.md" ) ]] && ( ruby -r rdoc -e 'puts RDoc::Markup::ToMarkdown.new.convert ARGF.read' < README.ja.rdoc > .github/README.md ; echo ".github/README.md is updated." ) || exit 0

