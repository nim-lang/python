
## Various Python 2 examples

import python2
import os, strutils


## Very high level python binding examples
proc example1() =
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
  returnValue = pyMain(cArgumentList.len, addr(cArgumentList[0]))
  if returnValue == 1:
    echo("Exception occured!")
  elif returnValue == 2:
    echo("Invalid parameter list passed to the Python interpreter!")

proc example2() =
  ## Executing a python script from a file
  var
    fileName: string = "script_example1.py"
  # Set program name in python (recommended)
  pySetProgramName("Example 2 ŽĆČŠĐ ŁĄŻĘĆŃŚŹ ЯБГДЖЙ ÄäÜüß")
  # Initialize the Python interpreter
  pyInitialize()
  # Execute the script
  if pyRunAnyFile(fileName) == -1:
    echo("Exception occured in Python script!")
  # Display program name
  echo pyGetProgramName()
  # Close and delete the Python interpreter
  pyFinalize()

proc example3() =
  ## Executing a python script from a string
  # Setup the string variable with some python code
  var pythonString = "import time\nprint('Today is ', time.ctime(time.time()))"
  # Initialize the Python interpreter
  pyInitialize()
  # Execute the string script
  if pyRunSimpleString(pythonString) == -1:
    echo("Exception occured in Python script!")
  # Close and delete the Python interpreter
  pyFinalize()

proc example4() =
  ## Simple example of an Exception in a python script
  # Initialize the Python interpreter
  pyInitialize()
  # Variable Initialization
  var
    pythonString: cstring = "import time\nd=\nprint('Today is ', time.ctime(time.time()))"
    pyGlobals: PyObjectPtr = pyModuleGetDict(pyImportAddModule("__main__"))
    pyLocals: PyObjectPtr = pyGlobals
  # Check globals, locals dictionaries and run the python string
  if pyGlobals == nil or pyLocals == nil:
    echo("Error creating globals and locals dictionaries")
  elif pyRunString(pythonString, pyFileInput, pyGlobals, pyLocals) == nil:
    echo("Exception occured in Python script!")
  # Close and delete the Python interpreter
  pyFinalize()

## Pure Embedding (C example translation)
## https://docs.python.org/2/extending/embedding.html#pure-embedding
proc example5() =
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
    pName, pModule, pFunc, pArgs, pValue: PyObjectPtr
  # Check command line arguments
  if len(arguments) < 2:
    quit "Usage: call pythonfile funcname [args]"
  # Initialize the Python interpreter
  pyInitialize()
  # Get the app name into a python object
  pName = pyStringFromString(arguments[0]) # Error checking of pName left out
  #echo PyBytes_AsString(PyUnicode_AsASCIIString(pName))
  pModule = pyImportImport(pName)
  pyDecref(pName)
  # Check if module was loaded
  if pModule != nil:
    pFunc = pyObjectGetAttrString(pModule, arguments[1]) # pFunc is a new reference
    if pFunc != nil and pyCallableCheck(pFunc) != 0:
      var countStart = argumentCount - 2
      pArgs = pyTupleNew(countStart)
      for i in 0..(countStart-1):
        pValue = pyLongFromLong(parseInt(arguments[i + 2]).clong)
        if pValue == nil:
          pyDecref(pArgs)
          pyDecref(pModule)
          quit "Cannot convert argument number: $1" % $i
        # pValue reference stolen here:
        if pyTupleSetItem(pArgs, i, pValue) != 0:
          quit "Cannot insert tuple item: $1" % $i
      pValue = pyObjectCallObject(pFunc, pArgs)
      pyDecref(pArgs)
      if pValue != nil:
        echo "Result of call: $1" % $pyLongAsLong(pValue)
        pyDecref(pValue)
      else:
        pyDecref(pFunc)
        pyDecref(pModule)
        pyErrPrint()
        quit "Call failed!"
    else:
      if pyErrOccurred() != nil:
        pyErrPrint()
      quit "Cannot find function '$1'\n" % arguments[1]
  else:
    pyErrPrint();
    quit "Failed to load '$1'" % arguments[0]
  # Close and delete the Python interpreter
  pyFinalize()
  

## Run one of the examples
#example1()
#example2()
#example3()
example4()
#example5()
