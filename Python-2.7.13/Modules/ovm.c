/* Minimal main program -- everything is loaded from the library */

#include "Python.h"

#ifdef __FreeBSD__
#include <fenv.h>
#endif

int
main(int argc, char **argv)
{
	/* 754 requires that FP exceptions run in "no stop" mode by default,
	 * and until C vendors implement C99's ways to control FP exceptions,
	 * Python requires non-stop mode.  Alas, some platforms enable FP
	 * exceptions by default.  Here we disable them.
	 */
#ifdef __FreeBSD__
	fedisableexcept(FE_OVERFLOW);
#endif

#ifdef OIL_MAIN
  printf("Oil!\n");
  // from Python/pythonrun.c
  // This needs a module dict though
  //run_pyc_file();

	return Py_Main(argc, argv);
#else
	return Py_Main(argc, argv);
#endif
}
