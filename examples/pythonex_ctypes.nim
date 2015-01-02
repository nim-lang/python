# Example to embed Python into your application 
# and use ctypes from within Python
#
# This example shows
# - Generating python code dynamically with values from Nim
# - Accessing python modules/namespaces from within Nim (__main__ module)
# - Setting python variables from within Nim and using the
#   value within the Python code (the from_nim variable)
# - Using python modules that interact with C code (ctypes module)
# - Retrieving python variables from within Nim and using
#   the value within the Nim code (the text_len variable)
#
# TODO
# - check return code of PyRun_SimpleString and show error info
#   if it does not return 0(success)
# - access Nim functions from within the Python code
#   I think that requires exporting the Nim function with .exportc pragma
#   but I'm not sure if ctypes can call it unless we compile the Nim
#   side as a dynamic library

import python, strutils

# IMPORTANT: Python on Windows does not like CR characters, so
# we use only \L here.

when defined(windows):
  const libcName = "msvcrt"
else:
  const libcName = "libc.so.6"

const pycode = """
import ctypes

libc = ctypes.cdll.LoadLibrary("$1")

print "The variable set from within Nim [%s]" % from_nim
text_len = libc.printf("%s, the answer is %d\n", from_nim, 42)

""" % libcName

Py_Initialize()
var mainModule = PyImport_ImportModule("__main__")
var mainDict   = PyModule_GetDict(mainModule)
var pyString   = PyString_FromString("This is from Nim")
discard PyDict_SetItemString(main_dict, "from_nim", pyString)

discard PyRun_SimpleString(pycode)

var pyVariable = PyMapping_GetItemString(mainDict, "text_len")
var pyNumber   = PyInt_AsLong(pyVariable)

Py_XDECREF(mainModule)
# mainDict is a borrowed reference, no decref is needed
Py_XDECREF(pyString)
Py_XDECREF(pyVariable)

echo("Printf output " & $pyNumber & " characters")

Py_Finalize()

