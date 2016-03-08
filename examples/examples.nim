
## Various Python 2 examples

import python2
import os, strutils


## Very high level python binding examples
proc Example1() =
  ## Run an interactive Python interpreter in a Nim console application
  let
    applicationName = os.getAppFilename()
    arguments = os.commandLineParams()
  var
    cArgumentList: seq[cstring] = newSeq[cstring](0)
    returnValue: int
  # Convert the arguments into C strings
  cArgumentList.add(cstring(applicationName))
  for arg in arguments:
    cArgumentList.add(cstring(arg))
  # Run the interpreter by passing it the application arguments
  returnValue = Py_Main(cArgumentList.len, addr(cArgumentList[0]))
  if returnValue == 1:
    echo("Exception occured!")
  elif returnValue == 2:
    echo("Invalid parameter list passed to the Python interpreter!")

proc Example2() =
  ## Executing a python script from a file
  var
    fileName: string = "script_example1.py"
  # Set program name in python (recommended)
  Py_SetProgramName("Example 2 ŽĆČŠĐ ŁĄŻĘĆŃŚŹ ЯБГДЖЙ ÄäÜüß")
  # Initialize the Python interpreter
  Py_Initialize()
  # Execute the script
  if PyRun_AnyFile(fileName) == -1:
    echo("Exception occured in Python script!")
  # Display program name
  echo Py_GetProgramName()
  # Close and delete the Python interpreter
  Py_Finalize()

proc Example3() =
  ## Executing a python script from a string
  # Setup the string variable with some python code
  var pythonString = "import time\nprint('Today is ', time.ctime(time.time()))"
  # Initialize the Python interpreter
  Py_Initialize()
  # Execute the string script
  if PyRun_SimpleString(pythonString) == -1:
    echo("Exception occured in Python script!")
  # Close and delete the Python interpreter
  Py_Finalize()

proc Example4() =
  ## Simple example of an Exception in a python script
  # Initialize the Python interpreter
  Py_Initialize()
  # Variable Initialization
  var
    pythonString: cstring = "import time\nd=\nprint('Today is ', time.ctime(time.time()))"
    pyGlobals: PyObjectPtr = PyModule_GetDict(PyImport_AddModule("__main__"))
    pyLocals: PyObjectPtr = pyGlobals
  # Check globals, locals dictionaries and run the python string
  if pyGlobals == nil or pyLocals == nil:
    echo("Error creating globals and locals dictionaries")
  elif PyRun_String(pythonString, pyFileInput, pyGlobals, pyLocals) == nil:
    echo("Exception occured in Python script!")
  # Close and delete the Python interpreter
  Py_Finalize()

## Pure Embedding (C example translation)
##https://docs.python.org/2/extending/embedding.html#pure-embedding
proc Example5() =
  ## Import a python module from a file and execute a function from it.
  ## How to run the example: 
  ##   - compile this file
  ##   - run in console: $ python_example example_module multiply 2 3
  ##   - make sure that the example_module.py file is in the same directory as the executable
  # Application parameters
  let
    applicationName = os.getAppFilename()
    arguments = os.commandLineParams()
    argumentCount = os.paramCount()
  # Variables
  var
    pName, pModule, pDict, pFunc, pArgs, pValue: PyObjectPtr
  # Check command line arguments
  if len(arguments) < 2:
    quit "Usage: call pythonfile funcname [args]"
  # Initialize the Python interpreter
  Py_Initialize()
  # Get the app name into a python object
  pName = PyString_FromString(arguments[0]) # Error checking of pName left out
  #echo PyBytes_AsString(PyUnicode_AsASCIIString(pName))
  pModule = PyImport_Import(pName)
  Py_DECREF(pName)
  # Check if module was loaded
  if pModule != nil:
    pFunc = PyObject_GetAttrString(pModule, arguments[1]) # pFunc is a new reference
    if pFunc != nil and PyCallable_Check(pFunc) != 0:
      var countStart = argumentCount - 2
      pArgs = PyTuple_New(countStart)
      for i in 0..(countStart-1):
        pValue = PyLong_FromLong(parseInt(arguments[i + 2]).clong)
        if pValue == nil:
          Py_DECREF(pArgs)
          Py_DECREF(pModule)
          quit "Cannot convert argument number: $1" % $i
        # pValue reference stolen here:
        if PyTuple_SetItem(pArgs, i, pValue) != 0:
          quit "Cannot insert tuple item: $1" % $i
      pValue = PyObject_CallObject(pFunc, pArgs)
      Py_DECREF(pArgs)
      if pValue != nil:
        echo "Result of call: $1" % $PyLong_AsLong(pValue)
        Py_DECREF(pValue)
      else:
        Py_DECREF(pFunc)
        Py_DECREF(pModule)
        PyErr_Print()
        quit "Call failed!"
    else:
      if PyErr_Occurred() != nil:
        PyErr_Print()
      quit "Cannot find function '$1'\n" % arguments[1]
  else:
    PyErr_Print();
    quit "Failed to load '$1'" % arguments[0]
  # Close and delete the Python interpreter
  Py_Finalize()
  

## Run one of the examples
#Example1()
#Example2()
#Example3()
Example4()
#Example5()