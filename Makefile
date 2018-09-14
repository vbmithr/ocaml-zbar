all:
	dune build @install test/test.exe

clean:
	dune clean
