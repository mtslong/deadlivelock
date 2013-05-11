CC=ocamlc

CIL_INCLUDE=../cil-1.6.0/obj/x86_LINUX
SRC_DIR=./src
GRAPH=../ocamlgraph
GRAPH_SRC=../ocamlgraph/src
GRAPH_LIB=../ocamlgraph/lib
INCLUDE_VPATH=$(CIL_INCLUDE) $(GRAPH_SRC) $(GRAPH_LIB) $(GRAPH) $(SRC_DIR)
CCOPT_VPATH=$(CIL_INCLUDE) $(GRAPH_SRC) $(GRAPH_LIB) $(GRAPH) 
INCLUDE=$(addprefix -I , $(INCLUDE_VPATH))
CCOPT=$(addprefix -ccopt -L, $(CCOPT_VPATH))
EXE=main
LIBS=unix.cma str.cma nums.cma $(CIL_INCLUDE)/cil.cma $(GRAPH)/graph.cma 
OBJS= dlutil.cmo heuristic.cmo dlgraph.cmo dlthread.cmo lockset.cmo deadlivelock.cmo yicesgen.cmo main.cmo 
FLAG= -c

all: main

main: $(OBJS)
	ocamlc -o $(EXE) $(LIBS) $(addprefix $(SRC_DIR)/, $(OBJS))
	
dlutil.cmo : $(SRC_DIR)/dlutil.ml
	$(CC) $(INCLUDE) $(CCOPT) $(FLAG) $(SRC_DIR)/dlutil.ml
	
heuristic.cmo : $(SRC_DIR)/heuristic.ml
	$(CC) $(INCLUDE) $(CCOPT) $(FLAG) $(SRC_DIR)/heuristic.ml

dlgraph.cmo : $(SRC_DIR)/dlgraph.ml
	$(CC) $(INCLUDE) $(CCOPT) $(FLAG) $(SRC_DIR)/dlgraph.ml

dlthread.cmo : $(SRC_DIR)/dlthread.ml
	$(CC) $(INCLUDE) $(CCOPT) $(FLAG) $(SRC_DIR)/dlthread.ml

lockset.cmo : $(SRC_DIR)/lockset.ml
	$(CC) $(INCLUDE) $(CCOPT) $(FLAG) $(SRC_DIR)/lockset.ml
	
deadlivelock.cmo : $(SRC_DIR)/deadlivelock.ml
	$(CC) $(INCLUDE) $(CCOPT) $(FLAG) $(SRC_DIR)/deadlivelock.ml
	
yicesgen.cmo : $(SRC_DIR)/yicesgen.ml
	$(CC) $(INCLUDE) $(CCOPT) $(FLAG) $(SRC_DIR)/yicesgen.ml
	
main.cmo : $(SRC_DIR)/main.ml
	$(CC) $(INCLUDE) $(CCOPT) $(FLAG) $(SRC_DIR)/main.ml
	
.PHONY : example test1 test_ifthenelse1 test_ifthenelse2 test_while1 test_trylock_unlock_missing test_trylock_while_livelock

example : 
	cilly --save-temps -D HAPPY_MOOD example/simple/deadlock.c -lpthread

test1 : 
	cilly --save-temps -D HAPPY_MOOD example/simple/test1.c -lpthread
	
test_ifthenelse1 : 
	cilly --save-temps -D HAPPY_MOOD example/simple/test_ifthenelse1.c -lpthread

test_ifthenelse2 : 
	cilly --save-temps -D HAPPY_MOOD example/simple/test_ifthenelse2.c -lpthread
	
test_while1 : 
	cilly --save-temps -D HAPPY_MOOD example/simple/test_while1.c -lpthread

test_trylock_unlock_missing:
	cilly --save-temps -D HAPPY_MOOD example/simple/test_trylock_unlock_missing.c -lpthread

test_trylock_while_livelock:
	cilly --save-temps -D HAPPY_MOOD example/simple/test_trylock_while_livelock.c -lpthread