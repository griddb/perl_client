SWIG = swig -DSWIGWORDSIZE64
CXX = g++

ARCH = $(shell arch)
LDFLAGS = -Llibs -lpthread -lrt -lgridstore

CPPFLAGS = -fPIC -std=c++0x -g -O2
INCLUDES = -Iinclude -Isrc
INCLUDES_PERL = $(INCLUDES)	\
			  -I.						\
			  -I/usr/lib64/perl5/CORE/ -Dbool=char

CPPFLAGS_PERL  = $(CPPFLAGS) $(INCLUDES_PERL)

PROGRAM = griddb_perl.so

SOURCES = 	  src/TimeSeriesProperties.cpp	\
		  src/AggregationResult.cpp	\
		  src/ContainerInfo.cpp			\
		  src/Container.cpp			\
		  src/Store.cpp			\
		  src/StoreFactory.cpp	\
		  src/PartitionController.cpp	\
		  src/Query.cpp				\
		  src/Row.cpp				\
		  src/QueryAnalysisEntry.cpp			\
		  src/RowKeyPredicate.cpp	\
		  src/RowSet.cpp			\
		  src/TimestampUtils.cpp			\


all: $(PROGRAM)

SWIG_DEF = src/griddb.i

SWIG_PERL_SOURCES    = src/griddb_perl.cxx

OBJS = $(SOURCES:.cpp=.o)
SWIG_PERL_OBJS = $(SWIG_PERL_SOURCES:.cxx=.o)

$(SWIG_PERL_SOURCES) : $(SWIG_DEF)
	$(SWIG) -outdir . -o $@ -c++ -perl5 $<


.cpp.o:
	$(CXX) $(CPPFLAGS) -c -o $@ $(INCLUDES) $<

$(SWIG_PERL_OBJS): $(SWIG_PERL_SOURCES)
	$(CXX) $(CPPFLAGS_PERL) -c -o $@ $(INCLUDES_PERL) $<

griddb_perl.so: $(OBJS) $(SWIG_PERL_OBJS)
	$(CXX) -shared  -o $@ $(OBJS) $(SWIG_PERL_OBJS) $(LDFLAGS)

clean:
	rm -rf $(OBJS) $(SWIG_PERL_OBJS)
	rm -rf $(SWIG_PERL_SOURCES)
	rm -rf $(PROGRAM)
