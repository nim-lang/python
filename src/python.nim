#
#    Light-weight binding for the Python interpreter
#       (c) 2010 Andreas Rumpf 
#    Based on 'PythonEngine' module by Dr. Dietmar Budelsky
#
#
#************************************************************************
#                                                                        
# Module:  Unit 'PythonEngine'     Copyright (c) 1997                    
#                                                                        
# Version: 3.0                     Dr. Dietmar Budelsky                  
# Sub-Version: 0.25                dbudelsky@web.de                      
#                                  Germany                               
#                                                                        
#                                  Morgan Martinet                       
#                                  4721 rue Brebeuf                      
#                                  H2J 3L2 MONTREAL (QC)                 
#                                  CANADA                                
#                                  e-mail: mmm@free.fr                   
#                                                                        
#  look our page at: http://www.multimania.com/marat                     
#************************************************************************
#  Functionality:  Delphi Components that provide an interface to the    
#                  Python language (see python.txt for more infos on     
#                  Python itself).                                       
#                                                                        
#************************************************************************
#  Contributors:                                                         
#      Grzegorz Makarewicz (mak@mikroplan.com.pl)                        
#      Andrew Robinson (andy@hps1.demon.co.uk)                           
#      Mark Watts(mark_watts@hotmail.com)                                
#      Olivier Deckmyn (olivier.deckmyn@mail.dotcom.fr)                  
#      Sigve Tjora (public@tjora.no)                                     
#      Mark Derricutt (mark@talios.com)                                  
#      Igor E. Poteryaev (jah@mail.ru)                                   
#      Yuri Filimonov (fil65@mail.ru)                                    
#      Stefan Hoffmeister (Stefan.Hoffmeister@Econos.de)                 
#************************************************************************
# This source code is distributed with no WARRANTY, for no reason or use.
# Everyone is allowed to use and change this code free for his own tasks 
# and projects, as long as this header and its copyright text is intact. 
# For changed versions of this code, which are public distributed the    
# following additional conditions have to be fullfilled:                 
# 1) The header has to contain a comment on the change and the author of 
#    it.                                                                 
# 2) A copy of the changed source has to be sent to the above E-Mail     
#    address or my then valid address, if this is possible to the        
#    author.                                                             
# The second condition has the target to maintain an up to date central  
# version of the component. If this condition is not acceptable for      
# confidential or legal reasons, everyone is free to derive a component  
# or to generate a diff file to my or other original sources.            
# Dr. Dietmar Budelsky, 1997-11-17                                       
#************************************************************************

{.deadCodeElim: on.}

import 
  dynlib,
  strutils


when defined(windows): 
  const dllname = "python(27|26|25|24|23|22|21|20|16|15).dll"
elif defined(macosx):
  const dllname = "libpython(2.7|2.6|2.5|2.4|2.3|2.2|2.1|2.0|1.6|1.5).dylib"
else: 
  const dllver = ".1"
  const dllname = "libpython(2.7|2.6|2.5|2.4|2.3|2.2|2.1|2.0|1.6|1.5).so" & 
                  dllver

  
const 
  PYT_METHOD_BUFFER_INCREASE* = 10
  PYT_MEMBER_BUFFER_INCREASE* = 10
  PYT_GETSET_BUFFER_INCREASE* = 10
  METH_VARARGS* = 0x0001
  METH_KEYWORDS* = 0x0002 # Masks for the co_flags field of PyCodeObject
  CO_OPTIMIZED* = 0x0001
  CO_NEWLOCALS* = 0x0002
  CO_VARARGS* = 0x0004
  CO_VARKEYWORDS* = 0x0008

type                          # Rich comparison opcodes introduced in version 2.1
  RichComparisonOpcode* = enum 
    pyLT, pyLE, pyEQ, pyNE, pyGT, pyGE

const
  Py_TPFLAGS_HAVE_GETCHARBUFFER* = (1 shl 0) # PySequenceMethods contains sq_contains
  Py_TPFLAGS_HAVE_SEQUENCE_IN* = (1 shl 1) # Objects which participate in garbage collection (see objimp.h)
  Py_TPFLAGS_GC* = (1 shl 2)  # PySequenceMethods and PyNumberMethods contain in-place operators
  Py_TPFLAGS_HAVE_INPLACEOPS* = (1 shl 3) # PyNumberMethods do their own coercion */
  Py_TPFLAGS_CHECKTYPES* = (1 shl 4)
  Py_TPFLAGS_HAVE_RICHCOMPARE* = (1 shl 5) # Objects which are weakly referencable if their tp_weaklistoffset is >0
                                           # XXX Should this have the same value as Py_TPFLAGS_HAVE_RICHCOMPARE?
                                           # These both indicate a feature that appeared in the same alpha release.
  Py_TPFLAGS_HAVE_WEAKREFS* = (1 shl 6) # tp_iter is defined
  Py_TPFLAGS_HAVE_ITER* = (1 shl 7) # New members introduced by Python 2.2 exist
  Py_TPFLAGS_HAVE_CLASS* = (1 shl 8) # Set if the type object is dynamically allocated
  Py_TPFLAGS_HEAPTYPE* = (1 shl 9) # Set if the type allows subclassing
  Py_TPFLAGS_BASETYPE* = (1 shl 10) # Set if the type is 'ready' -- fully initialized
  Py_TPFLAGS_READY* = (1 shl 12) # Set while the type is being 'readied', to prevent recursive ready calls
  Py_TPFLAGS_READYING* = (1 shl 13) # Objects support garbage collection (see objimp.h)
  Py_TPFLAGS_HAVE_GC* = (1 shl 14)
  Py_TPFLAGS_DEFAULT* = Py_TPFLAGS_HAVE_GETCHARBUFFER or
      Py_TPFLAGS_HAVE_SEQUENCE_IN or Py_TPFLAGS_HAVE_INPLACEOPS or
      Py_TPFLAGS_HAVE_RICHCOMPARE or Py_TPFLAGS_HAVE_WEAKREFS or
      Py_TPFLAGS_HAVE_ITER or Py_TPFLAGS_HAVE_CLASS 

type 
  PFlag* = enum 
    tpfHaveGetCharBuffer, tpfHaveSequenceIn, tpfGC, tpfHaveInplaceOps, 
    tpfCheckTypes, tpfHaveRichCompare, tpfHaveWeakRefs, tpfHaveIter, 
    tpfHaveClass, tpfHeapType, tpfBaseType, tpfReady, tpfReadying, tpfHaveGC
  PFlags* = set[PFlag]

const 
  TPFLAGS_DEFAULT* = {tpfHaveGetCharBuffer, tpfHaveSequenceIn, 
    tpfHaveInplaceOps, tpfHaveRichCompare, tpfHaveWeakRefs, tpfHaveIter, 
    tpfHaveClass}

const # Python opcodes
  single_input* = 256 
  file_input* = 257
  eval_input* = 258
  funcdef* = 259
  parameters* = 260
  varargslist* = 261
  fpdef* = 262
  fplist* = 263
  stmt* = 264
  simple_stmt* = 265
  small_stmt* = 266
  expr_stmt* = 267
  augassign* = 268
  print_stmt* = 269
  del_stmt* = 270
  pass_stmt* = 271
  flow_stmt* = 272
  break_stmt* = 273
  continue_stmt* = 274
  return_stmt* = 275
  raise_stmt* = 276
  import_stmt* = 277
  import_as_name* = 278
  dotted_as_name* = 279
  dotted_name* = 280
  global_stmt* = 281
  exec_stmt* = 282
  assert_stmt* = 283
  compound_stmt* = 284
  if_stmt* = 285
  while_stmt* = 286
  for_stmt* = 287
  try_stmt* = 288
  except_clause* = 289
  suite* = 290
  test* = 291
  and_test* = 291
  not_test* = 293
  comparison* = 294
  comp_op* = 295
  expr* = 296
  xor_expr* = 297
  and_expr* = 298
  shift_expr* = 299
  arith_expr* = 300
  term* = 301
  factor* = 302
  power* = 303
  atom* = 304
  listmaker* = 305
  lambdef* = 306
  trailer* = 307
  subscriptlist* = 308
  subscript* = 309
  sliceop* = 310
  exprlist* = 311
  testlist* = 312
  dictmaker* = 313
  classdef* = 314
  arglist* = 315
  argument* = 316
  list_iter* = 317
  list_for* = 318
  list_if* = 319

const 
  T_SHORT* = 0
  T_INT* = 1
  T_LONG* = 2
  T_FLOAT* = 3
  T_DOUBLE* = 4
  T_STRING* = 5
  T_OBJECT* = 6
  T_CHAR* = 7                 # 1-character string
  T_BYTE* = 8                 # 8-bit signed int
  T_UBYTE* = 9
  T_USHORT* = 10
  T_UINT* = 11
  T_ULONG* = 12
  T_STRING_INPLACE* = 13
  T_OBJECT_EX* = 16 
  READONLY* = 1
  RO* = READONLY              # Shorthand 
  READ_RESTRICTED* = 2
  WRITE_RESTRICTED* = 4
  RESTRICTED* = (READ_RESTRICTED or WRITE_RESTRICTED)
  pySingleInput* = 256
  pyFileInput*   = 257
  pyEvalInput*   = 258

type 
  PyMemberType* = enum 
    mtShort, mtInt, mtLong, mtFloat, mtDouble, mtString, mtObject, mtChar, 
    mtByte, mtUByte, mtUShort, mtUInt, mtULong, mtStringInplace, mtObjectEx
  PyMemberFlag* = enum 
    mfDefault, mfReadOnly, mfReadRestricted, mfWriteRestricted, mfRestricted

type 
  IntPtr* = ptr int

#  PLong* = ptr int32
#  PFloat* = ptr float32
#  PShort* = ptr int8
  
type
  cstringPtr* = ptr cstring
  frozenPtrPtr* = ptr frozen
  frozenPtr* = ptr frozen
  PyObjectPtr* = ptr PyObject
  PyObjectPtrPtr* = ptr PyObjectPtr
  PyObjectPtrPtrPtr* = ptr PyObjectPtrPtr
  PyIntObjectPtr* = ptr PyIntObject
  PyTypeObjectPtr* = ptr PyTypeObject
  PySliceObjectPtr* = ptr PySliceObject
  PyCFunction* = proc (self, args: PyObjectPtr): PyObjectPtr{.cdecl.}
  unaryfunc* = proc (ob1: PyObjectPtr): PyObjectPtr{.cdecl.}
  binaryfunc* = proc (ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl.}
  ternaryfunc* = proc (ob1, ob2, ob3: PyObjectPtr): PyObjectPtr{.cdecl.}
  inquiry* = proc (ob1: PyObjectPtr): int{.cdecl.}
  coercion* = proc (ob1, ob2: PyObjectPtrPtr): int{.cdecl.}
  intargfunc* = proc (ob1: PyObjectPtr, i: int): PyObjectPtr{.cdecl.}
  intintargfunc* = proc (ob1: PyObjectPtr, i1, i2: int): PyObjectPtr{.cdecl.}
  intobjargproc* = proc (ob1: PyObjectPtr, i: int, ob2: PyObjectPtr): int{.cdecl.}
  intintobjargproc* = proc (ob1: PyObjectPtr, i1, i2: int, ob2: PyObjectPtr): int{.
      cdecl.}
  objobjargproc* = proc (ob1, ob2, ob3: PyObjectPtr): int{.cdecl.}
  pydestructor* = proc (ob: PyObjectPtr){.cdecl.}
  printfunc* = proc (ob: PyObjectPtr, f: File, i: int): int{.cdecl.}
  getattrfunc* = proc (ob1: PyObjectPtr, name: cstring): PyObjectPtr{.cdecl.}
  setattrfunc* = proc (ob1: PyObjectPtr, name: cstring, ob2: PyObjectPtr): int{.
      cdecl.}
  cmpfunc* = proc (ob1, ob2: PyObjectPtr): int{.cdecl.}
  reprfunc* = proc (ob: PyObjectPtr): PyObjectPtr{.cdecl.}
  hashfunc* = proc (ob: PyObjectPtr): int32{.cdecl.}
  getattrofunc* = proc (ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl.}
  setattrofunc* = proc (ob1, ob2, ob3: PyObjectPtr): int{.cdecl.} 
  getreadbufferproc* = proc (ob1: PyObjectPtr, i: int, p: pointer): int{.cdecl.}
  getwritebufferproc* = proc (ob1: PyObjectPtr, i: int, p: pointer): int{.cdecl.}
  getsegcountproc* = proc (ob1: PyObjectPtr, i: int): int{.cdecl.}
  getcharbufferproc* = proc (ob1: PyObjectPtr, i: int, pstr: cstring): int{.cdecl.}
  objobjproc* = proc (ob1, ob2: PyObjectPtr): int{.cdecl.}
  visitproc* = proc (ob1: PyObjectPtr, p: pointer): int{.cdecl.}
  traverseproc* = proc (ob1: PyObjectPtr, prc: visitproc, p: pointer): int{.
      cdecl.}
  richcmpfunc* = proc (ob1, ob2: PyObjectPtr, i: int): PyObjectPtr{.cdecl.}
  getiterfunc* = proc (ob1: PyObjectPtr): PyObjectPtr{.cdecl.}
  iternextfunc* = proc (ob1: PyObjectPtr): PyObjectPtr{.cdecl.}
  descrgetfunc* = proc (ob1, ob2, ob3: PyObjectPtr): PyObjectPtr{.cdecl.}
  descrsetfunc* = proc (ob1, ob2, ob3: PyObjectPtr): int{.cdecl.}
  initproc* = proc (self, args, kwds: PyObjectPtr): int{.cdecl.}
  newfunc* = proc (subtype: PyTypeObjectPtr, args, kwds: PyObjectPtr): PyObjectPtr{.
      cdecl.}
  allocfunc* = proc (self: PyTypeObjectPtr, nitems: int): PyObjectPtr{.cdecl.}
  PyNumberMethods*{.final.} = object 
    nb_add*: binaryfunc
    nb_substract*: binaryfunc
    nb_multiply*: binaryfunc
    nb_divide*: binaryfunc
    nb_remainder*: binaryfunc
    nb_divmod*: binaryfunc
    nb_power*: ternaryfunc
    nb_negative*: unaryfunc
    nb_positive*: unaryfunc
    nb_absolute*: unaryfunc
    nb_nonzero*: inquiry
    nb_invert*: unaryfunc
    nb_lshift*: binaryfunc
    nb_rshift*: binaryfunc
    nb_and*: binaryfunc
    nb_xor*: binaryfunc
    nb_or*: binaryfunc
    nb_coerce*: coercion
    nb_int*: unaryfunc
    nb_long*: unaryfunc
    nb_float*: unaryfunc
    nb_oct*: unaryfunc
    nb_hex*: unaryfunc       #/ jah 29-sep-2000: updated for python 2.0
                              #/                   added from .h
    nb_inplace_add*: binaryfunc
    nb_inplace_subtract*: binaryfunc
    nb_inplace_multiply*: binaryfunc
    nb_inplace_divide*: binaryfunc
    nb_inplace_remainder*: binaryfunc
    nb_inplace_power*: ternaryfunc
    nb_inplace_lshift*: binaryfunc
    nb_inplace_rshift*: binaryfunc
    nb_inplace_and*: binaryfunc
    nb_inplace_xor*: binaryfunc
    nb_inplace_or*: binaryfunc # Added in release 2.2
                                # The following require the Py_TPFLAGS_HAVE_CLASS flag
    nb_floor_divide*: binaryfunc
    nb_true_divide*: binaryfunc
    nb_inplace_floor_divide*: binaryfunc
    nb_inplace_true_divide*: binaryfunc

  PyNumberMethodsPtr* = ptr PyNumberMethods
  PySequenceMethods*{.final.} = object 
    sq_length*: inquiry
    sq_concat*: binaryfunc
    sq_repeat*: intargfunc
    sq_item*: intargfunc
    sq_slice*: intintargfunc
    sq_ass_item*: intobjargproc
    sq_ass_slice*: intintobjargproc 
    sq_contains*: objobjproc
    sq_inplace_concat*: binaryfunc
    sq_inplace_repeat*: intargfunc

  PySequenceMethodsPtr* = ptr PySequenceMethods
  PyMappingMethods*{.final.} = object 
    mp_length*: inquiry
    mp_subscript*: binaryfunc
    mp_ass_subscript*: objobjargproc

  PyMappingMethodsPtr* = ptr PyMappingMethods 
  PyBufferProcs*{.final.} = object 
    bf_getreadbuffer*: getreadbufferproc
    bf_getwritebuffer*: getwritebufferproc
    bf_getsegcount*: getsegcountproc
    bf_getcharbuffer*: getcharbufferproc

  PyBufferProcsPtr* = ptr PyBufferProcs
  Py_complex*{.final.} = object 
    float*: float64
    imag*: float64

  PyObject*{.pure, inheritable.} = object 
    ob_refcnt*: int
    ob_type*: PyTypeObjectPtr

  PyIntObject* = object of RootObj
    ob_ival*: int32

  BytePtr* = ptr int8
  frozen*{.final.} = object 
    name*: cstring
    code*: BytePtr
    size*: int

  PySliceObject* = object of PyObject
    start*, stop*, step*: PyObjectPtr

  PyMethodDefPtr* = ptr PyMethodDef
  PyMethodDef*{.final.} = object  # structmember.h
    ml_name*: cstring
    ml_meth*: PyCFunction
    ml_flags*: int
    ml_doc*: cstring

  PyMemberDefPtr* = ptr PyMemberDef
  PyMemberDef*{.final.} = object  # descrobject.h
                                   # Descriptors
    name*: cstring
    theType*: int
    offset*: int
    flags*: int
    doc*: cstring

  getter* = proc (obj: PyObjectPtr, context: pointer): PyObjectPtr{.cdecl.}
  setter* = proc (obj, value: PyObjectPtr, context: pointer): int{.cdecl.}
  PyGetSetDefPtr* = ptr PyGetSetDef
  PyGetSetDef*{.final.} = object 
    name*: cstring
    get*: getter
    setter*: setter
    doc*: cstring
    closure*: pointer

  wrapperfunc* = proc (self, args: PyObjectPtr, wrapped: pointer): PyObjectPtr{.
      cdecl.}
  wrapperbasePtr* = ptr wrapperbase

  # Various kinds of descriptor objects
  ##define PyDescr_COMMON \
  #          PyObject_HEAD \
  #          PyTypeObject *d_type; \
  #          PyObject *d_name
  wrapperbase*{.final.} = object
    name*: cstring
    wrapper*: wrapperfunc
    doc*: cstring

  PyDescrObjectPtr* = ptr PyDescrObject
  PyDescrObject* = object of PyObject
    d_type*: PyTypeObjectPtr
    d_name*: PyObjectPtr

  PyMethodDescrObjectPtr* = ptr PyMethodDescrObject
  PyMethodDescrObject* = object of PyDescrObject
    d_method*: PyMethodDefPtr

  PyMemberDescrObjectPtr* = ptr PyMemberDescrObject
  PyMemberDescrObject* = object of PyDescrObject
    d_member*: PyMemberDefPtr

  PyGetSetDescrObjectPtr* = ptr PyGetSetDescrObject
  PyGetSetDescrObject* = object of PyDescrObject
    d_getset*: PyGetSetDefPtr

  PyWrapperDescrObjectPtr* = ptr PyWrapperDescrObject
  PyWrapperDescrObject* = object of PyDescrObject # object.h
    d_base*: wrapperbasePtr
    d_wrapped*: pointer       # This can be any function pointer
  
  PyTypeObject* = object of PyObject
    ob_size*: int             # Number of items in variable part
    tp_name*: cstring         # For printing
    tp_basicsize*, tp_itemsize*: int # For allocation
                                     # Methods to implement standard operations
    tp_dealloc*: pydestructor
    tp_print*: printfunc
    tp_getattr*: getattrfunc
    tp_setattr*: setattrfunc
    tp_compare*: cmpfunc
    tp_repr*: reprfunc       # Method suites for standard classes
    tp_as_number*: PyNumberMethodsPtr
    tp_as_sequence*: PySequenceMethodsPtr
    tp_as_mapping*: PyMappingMethodsPtr # More standard operations (here for binary compatibility)
    tp_hash*: hashfunc
    tp_call*: ternaryfunc
    tp_str*: reprfunc
    tp_getattro*: getattrofunc
    tp_setattro*: setattrofunc #/ jah 29-sep-2000: updated for python 2.0
                                # Functions to access object as input/output buffer
    tp_as_buffer*: PyBufferProcsPtr # Flags to define presence of optional/expanded features
    tp_flags*: int32
    tp_doc*: cstring          # Documentation string
                              # call function for all accessible objects
    tp_traverse*: traverseproc # delete references to contained objects
    tp_clear*: inquiry       # rich comparisons
    tp_richcompare*: richcmpfunc # weak reference enabler
    tp_weaklistoffset*: int32 # Iterators
    tp_iter*: getiterfunc
    tp_iternext*: iternextfunc # Attribute descriptor and subclassing stuff
    tp_methods*: PyMethodDefPtr
    tp_members*: PyMemberDefPtr
    tp_getset*: PyGetSetDefPtr
    tp_base*: PyTypeObjectPtr
    tp_dict*: PyObjectPtr
    tp_descr_get*: descrgetfunc
    tp_descr_set*: descrsetfunc
    tp_dictoffset*: int32
    tp_init*: initproc
    tp_alloc*: allocfunc
    tp_new*: newfunc
    tp_free*: pydestructor   # Low-level free-memory routine
    tp_is_gc*: inquiry       # For PyObject_IS_GC
    tp_bases*: PyObjectPtr
    tp_mro*: PyObjectPtr        # method resolution order
    tp_cache*: PyObjectPtr
    tp_subclasses*: PyObjectPtr
    tp_weaklist*: PyObjectPtr   #More spares
    tp_xxx7*: pointer
    tp_xxx8*: pointer

  PyMethodChainPtr* = ptr PyMethodChain
  PyMethodChain*{.final.} = object 
    methods*: PyMethodDefPtr
    link*: PyMethodChainPtr

  PyClassObjectPtr* = ptr PyClassObject
  PyClassObject* = object of PyObject
    cl_bases*: PyObjectPtr      # A tuple of class objects
    cl_dict*: PyObjectPtr       # A dictionary
    cl_name*: PyObjectPtr       # A string
                              # The following three are functions or NULL
    cl_getattr*: PyObjectPtr
    cl_setattr*: PyObjectPtr
    cl_delattr*: PyObjectPtr

  PyInstanceObjectPtr* = ptr PyInstanceObject
  PyInstanceObject* = object of PyObject 
    in_class*: PyClassObjectPtr # The class object
    in_dict*: PyObjectPtr       # A dictionary
  
  PyMethodObjectPtr* = ptr PyMethodObject
  PyMethodObject* = object of PyObject # Bytecode object, compile.h
    im_func*: PyObjectPtr       # The function implementing the method
    im_self*: PyObjectPtr       # The instance it is bound to, or NULL
    im_class*: PyObjectPtr      # The class that defined the method
  
  PyCodeObjectPtr* = ptr PyCodeObject
  PyCodeObject* = object of PyObject # from pystate.h
    co_argcount*: int         # #arguments, except *args
    co_nlocals*: int          # #local variables
    co_stacksize*: int        # #entries needed for evaluation stack
    co_flags*: int            # CO_..., see below
    co_code*: PyObjectPtr       # instruction opcodes (it hides a PyStringObject)
    co_consts*: PyObjectPtr     # list (constants used)
    co_names*: PyObjectPtr      # list of strings (names used)
    co_varnames*: PyObjectPtr   # tuple of strings (local variable names)
    co_freevars*: PyObjectPtr   # tuple of strings (free variable names)
    co_cellvars*: PyObjectPtr   # tuple of strings (cell variable names)
                              # The rest doesn't count for hash/cmp
    co_filename*: PyObjectPtr   # string (where it was loaded from)
    co_name*: PyObjectPtr       # string (name, for reference)
    co_firstlineno*: int      # first source line number
    co_lnotab*: PyObjectPtr     # string (encoding addr<->lineno mapping)
  
  PyInterpreterStatePtr* = ptr PyInterpreterState
  PyThreadStatePtr* = ptr PyThreadState
  PyFrameObjectPtr* = ptr PyFrameObject # Interpreter environments
  PyInterpreterState*{.final.} = object  # Thread specific information
    next*: PyInterpreterStatePtr
    tstate_head*: PyThreadStatePtr
    modules*: PyObjectPtr
    sysdict*: PyObjectPtr
    builtins*: PyObjectPtr
    checkinterval*: int

  PyThreadState*{.final.} = object  # from frameobject.h
    next*: PyThreadStatePtr
    interp*: PyInterpreterStatePtr
    frame*: PyFrameObjectPtr
    recursion_depth*: int
    ticker*: int
    tracing*: int
    sys_profilefunc*: PyObjectPtr
    sys_tracefunc*: PyObjectPtr
    curexc_type*: PyObjectPtr
    curexc_value*: PyObjectPtr
    curexc_traceback*: PyObjectPtr
    exc_type*: PyObjectPtr
    exc_value*: PyObjectPtr
    exc_traceback*: PyObjectPtr
    dict*: PyObjectPtr

  PyTryBlockPtr* = ptr PyTryBlock
  PyTryBlock*{.final.} = object 
    b_type*: int              # what kind of block this is
    b_handler*: int           # where to jump to find handler
    b_level*: int             # value stack level to pop to
  
  CO_MAXBLOCKS* = range[0..19]
  PyFrameObject* = object of PyObject # start of the VAR_HEAD of an object
                                        # From traceback.c
    ob_size*: int             # Number of items in variable part
                              # End of the Head of an object
    f_back*: PyFrameObjectPtr   # previous frame, or NULL
    f_code*: PyCodeObjectPtr    # code segment
    f_builtins*: PyObjectPtr    # builtin symbol table (PyDictObject)
    f_globals*: PyObjectPtr     # global symbol table (PyDictObject)
    f_locals*: PyObjectPtr      # local symbol table (PyDictObject)
    f_valuestack*: PyObjectPtrPtr # points after the last local
                              # Next free slot in f_valuestack. Frame creation sets to f_valuestack.
                              # Frame evaluation usually NULLs it, but a frame that yields sets it
                              # to the current stack top. 
    f_stacktop*: PyObjectPtrPtr
    f_trace*: PyObjectPtr       # Trace function
    f_exc_type*, f_exc_value*, f_exc_traceback*: PyObjectPtr
    f_tstate*: PyThreadStatePtr
    f_lasti*: int             # Last instruction if called
    f_lineno*: int            # Current line number
    f_restricted*: int        # Flag set if restricted operations
                              # in this scope
    f_iblock*: int            # index in f_blockstack
    f_blockstack*: array[CO_MAXBLOCKS, PyTryBlock] # for try and loop blocks
    f_nlocals*: int           # number of locals
    f_ncells*: int
    f_nfreevars*: int
    f_stacksize*: int         # size of value stack
    f_localsplus*: array[0..0, PyObjectPtr] # locals+stack, dynamically sized
  
  PyTraceBackObjectPtr* = ptr PyTraceBackObject
  PyTraceBackObject* = object of PyObject # Parse tree node interface
    tb_next*: PyTraceBackObjectPtr
    tb_frame*: PyFrameObjectPtr
    tb_lasti*: int
    tb_lineno*: int

  NodePtr* = ptr node
  node*{.final.} = object    # From weakrefobject.h
    n_type*: int16
    n_str*: cstring
    n_lineno*: int16
    n_nchildren*: int16
    n_child*: NodePtr

  PyWeakReferencePtr* = ptr PyWeakReference
  PyWeakReference* = object of PyObject 
    wr_object*: PyObjectPtr
    wr_callback*: PyObjectPtr
    hash*: int32
    wr_prev*: PyWeakReferencePtr
    wr_next*: PyWeakReferencePtr


const                         
  PyDateTime_DATE_DATASIZE* = 4 # # of bytes for year, month, and day
  PyDateTime_TIME_DATASIZE* = 6 # # of bytes for hour, minute, second, and usecond
  PyDateTime_DATETIME_DATASIZE* = 10 # # of bytes for year, month, 
                                     # day, hour, minute, second, and usecond. 

type 
  PyDateTime_Delta* = object of PyObject
    hashcode*: int            # -1 when unknown
    days*: int                # -MAX_DELTA_DAYS <= days <= MAX_DELTA_DAYS
    seconds*: int             # 0 <= seconds < 24*3600 is invariant
    microseconds*: int        # 0 <= microseconds < 1000000 is invariant
  
  PyDateTime_DeltaPtr* = ptr PyDateTime_Delta
  PyDateTime_TZInfo* = object of PyObject # a pure abstract base clase
  PyDateTime_TZInfoPtr* = ptr PyDateTime_TZInfo 
  PyDateTime_BaseTZInfo* = object of PyObject
    hashcode*: int
    hastzinfo*: bool          # boolean flag
  
  PyDateTime_BaseTZInfoPtr* = ptr PyDateTime_BaseTZInfo 
  PyDateTime_BaseTime* = object of PyDateTime_BaseTZInfo
    data*: array[0..pred(PyDateTime_TIME_DATASIZE), int8]

  PyDateTime_BaseTimePtr* = ptr PyDateTime_BaseTime
  PyDateTime_Time* = object of PyDateTime_BaseTime # hastzinfo true
    tzinfo*: PyObjectPtr

  PyDateTime_TimePtr* = ptr PyDateTime_Time 
  PyDateTime_Date* = object of PyDateTime_BaseTZInfo
    data*: array[0..pred(PyDateTime_DATE_DATASIZE), int8]

  PyDateTime_DatePtr* = ptr PyDateTime_Date 
  PyDateTime_BaseDateTime* = object of PyDateTime_BaseTZInfo
    data*: array[0..pred(PyDateTime_DATETIME_DATASIZE), int8]

  PyDateTime_BaseDateTimePtr* = ptr PyDateTime_BaseDateTime
  PyDateTime_DateTime* = object of PyDateTime_BaseTZInfo
    data*: array[0..pred(PyDateTime_DATETIME_DATASIZE), int8]
    tzinfo*: PyObjectPtr

  PyDateTime_DateTimePtr* = ptr PyDateTime_DateTime 

#----------------------------------------------------#
#                                                    #
#         New exception classes                      #
#                                                    #
#----------------------------------------------------#

#
#  // Python's exceptions
#  EPythonError   = object(Exception)
#      EName: String;
#      EValue: String;
#  end;
#  EPyExecError   = object(EPythonError)
#  end;
#
#  // Standard exception classes of Python
#
#/// jah 29-sep-2000: updated for python 2.0
#///                   base classes updated according python documentation
#
#{ Hierarchy of Python exceptions, Python 2.3, copied from <INSTALL>\Python\exceptions.c
#
#Exception\n\
# |\n\
# +-- SystemExit\n\
# +-- StopIteration\n\
# +-- StandardError\n\
# |    |\n\
# |    +-- KeyboardInterrupt\n\
# |    +-- ImportError\n\
# |    +-- EnvironmentError\n\
# |    |    |\n\
# |    |    +-- IOError\n\
# |    |    +-- OSError\n\
# |    |         |\n\
# |    |         +-- WindowsError\n\
# |    |         +-- VMSError\n\
# |    |\n\
# |    +-- EOFError\n\
# |    +-- RuntimeError\n\
# |    |    |\n\
# |    |    +-- NotImplementedError\n\
# |    |\n\
# |    +-- NameError\n\
# |    |    |\n\
# |    |    +-- UnboundLocalError\n\
# |    |\n\
# |    +-- AttributeError\n\
# |    +-- SyntaxError\n\
# |    |    |\n\
# |    |    +-- IndentationError\n\
# |    |         |\n\
# |    |         +-- TabError\n\
# |    |\n\
# |    +-- TypeError\n\
# |    +-- AssertionError\n\
# |    +-- LookupError\n\
# |    |    |\n\
# |    |    +-- IndexError\n\
# |    |    +-- KeyError\n\
# |    |\n\
# |    +-- ArithmeticError\n\
# |    |    |\n\
# |    |    +-- OverflowError\n\
# |    |    +-- ZeroDivisionError\n\
# |    |    +-- FloatingPointError\n\
# |    |\n\
# |    +-- ValueError\n\
# |    |    |\n\
# |    |    +-- UnicodeError\n\
# |    |        |\n\
# |    |        +-- UnicodeEncodeError\n\
# |    |        +-- UnicodeDecodeError\n\
# |    |        +-- UnicodeTranslateError\n\
# |    |\n\
# |    +-- ReferenceError\n\
# |    +-- SystemError\n\
# |    +-- MemoryError\n\
# |\n\
# +---Warning\n\
#      |\n\
#      +-- UserWarning\n\
#      +-- DeprecationWarning\n\
#      +-- PendingDeprecationWarning\n\
#      +-- SyntaxWarning\n\
#      +-- OverflowWarning\n\
#      +-- RuntimeWarning\n\
#      +-- FutureWarning"
#}
#   EPyException = class (EPythonError);
#   EPyStandardError = class (EPyException);
#   EPyArithmeticError = class (EPyStandardError);
#   EPyLookupError = class (EPyStandardError);
#   EPyAssertionError = class (EPyStandardError);
#   EPyAttributeError = class (EPyStandardError);
#   EPyEOFError = class (EPyStandardError);
#   EPyFloatingPointError = class (EPyArithmeticError);
#   EPyEnvironmentError = class (EPyStandardError);
#   EPyIOError = class (EPyEnvironmentError);
#   EPyOSError = class (EPyEnvironmentError);
#   EPyImportError = class (EPyStandardError);
#   EPyIndexError = class (EPyLookupError);
#   EPyKeyError = class (EPyLookupError);
#   EPyKeyboardInterrupt = class (EPyStandardError);
#   EPyMemoryError = class (EPyStandardError);
#   EPyNameError = class (EPyStandardError);
#   EPyOverflowError = class (EPyArithmeticError);
#   EPyRuntimeError = class (EPyStandardError);
#   EPyNotImplementedError = class (EPyRuntimeError);
#   EPySyntaxError = class (EPyStandardError)
#   public
#      EFileName: string;
#      ELineStr: string;
#      ELineNumber: Integer;
#      EOffset: Integer;
#   end;
#   EPyIndentationError = class (EPySyntaxError);
#   EPyTabError = class (EPyIndentationError);
#   EPySystemError = class (EPyStandardError);
#   EPySystemExit = class (EPyException);
#   EPyTypeError = class (EPyStandardError);
#   EPyUnboundLocalError = class (EPyNameError);
#   EPyValueError = class (EPyStandardError);
#   EPyUnicodeError = class (EPyValueError);
#   UnicodeEncodeError = class (EPyUnicodeError);
#   UnicodeDecodeError = class (EPyUnicodeError);
#   UnicodeTranslateError = class (EPyUnicodeError);
#   EPyZeroDivisionError = class (EPyArithmeticError);
#   EPyStopIteration = class(EPyException);
#   EPyWarning = class (EPyException);
#   EPyUserWarning = class (EPyWarning);
#   EPyDeprecationWarning = class (EPyWarning);
#   PendingDeprecationWarning = class (EPyWarning);
#   FutureWarning = class (EPyWarning);
#   EPySyntaxWarning = class (EPyWarning);
#   EPyOverflowWarning = class (EPyWarning);
#   EPyRuntimeWarning = class (EPyWarning);
#   EPyReferenceError = class (EPyStandardError);
#

var 
  PyArg_Parse*: proc (args: PyObjectPtr, format: cstring): int{.cdecl, varargs.} 
  PyArg_ParseTuple*: proc (args: PyObjectPtr, format: cstring, x1: pointer = nil, 
                           x2: pointer = nil, x3: pointer = nil): int{.cdecl, varargs.} 
  Py_BuildValue*: proc (format: cstring): PyObjectPtr{.cdecl, varargs.} 
  PyCode_Addr2Line*: proc (co: PyCodeObjectPtr, addrq: int): int{.cdecl.}
  DLL_Py_GetBuildInfo*: proc (): cstring{.cdecl.}

var
  Py_DebugFlag*: IntPtr
  Py_VerboseFlag*: IntPtr
  Py_InteractiveFlag*: IntPtr
  Py_OptimizeFlag*: IntPtr
  Py_NoSiteFlag*: IntPtr
  Py_UseClassExceptionsFlag*: IntPtr
  Py_FrozenFlag*: IntPtr
  Py_TabcheckFlag*: IntPtr
  Py_UnicodeFlag*: IntPtr
  Py_IgnoreEnvironmentFlag*: IntPtr
  Py_DivisionWarningFlag*: IntPtr 
  #_PySys_TraceFunc:    PyObjectPtrPtr;
  #_PySys_ProfileFunc: PyObjectPtrPtrPtr;
  PyImport_FrozenModules*: frozenPtrPtr
  Py_None*: PyObjectPtr
  Py_Ellipsis*: PyObjectPtr
  Py_False*: PyIntObjectPtr
  Py_True*: PyIntObjectPtr
  Py_NotImplemented*: PyObjectPtr
  PyExc_AttributeError*: PyObjectPtrPtr
  PyExc_EOFError*: PyObjectPtrPtr
  PyExc_IOError*: PyObjectPtrPtr
  PyExc_ImportError*: PyObjectPtrPtr
  PyExc_IndexError*: PyObjectPtrPtr
  PyExc_KeyError*: PyObjectPtrPtr
  PyExc_KeyboardInterrupt*: PyObjectPtrPtr
  PyExc_MemoryError*: PyObjectPtrPtr
  PyExc_NameError*: PyObjectPtrPtr
  PyExc_OverflowError*: PyObjectPtrPtr
  PyExc_RuntimeError*: PyObjectPtrPtr
  PyExc_SyntaxError*: PyObjectPtrPtr
  PyExc_SystemError*: PyObjectPtrPtr
  PyExc_SystemExit*: PyObjectPtrPtr
  PyExc_TypeError*: PyObjectPtrPtr
  PyExc_ValueError*: PyObjectPtrPtr
  PyExc_ZeroDivisionError*: PyObjectPtrPtr
  PyExc_ArithmeticError*: PyObjectPtrPtr
  PyExc_Exception*: PyObjectPtrPtr
  PyExc_FloatingPointError*: PyObjectPtrPtr
  PyExc_LookupError*: PyObjectPtrPtr
  PyExc_StandardError*: PyObjectPtrPtr
  PyExc_AssertionError*: PyObjectPtrPtr
  PyExc_EnvironmentError*: PyObjectPtrPtr
  PyExc_IndentationError*: PyObjectPtrPtr
  PyExc_MemoryErrorInst*: PyObjectPtrPtr
  PyExc_NotImplementedError*: PyObjectPtrPtr
  PyExc_OSError*: PyObjectPtrPtr
  PyExc_TabError*: PyObjectPtrPtr
  PyExc_UnboundLocalError*: PyObjectPtrPtr
  PyExc_UnicodeError*: PyObjectPtrPtr
  PyExc_Warning*: PyObjectPtrPtr
  PyExc_DeprecationWarning*: PyObjectPtrPtr
  PyExc_RuntimeWarning*: PyObjectPtrPtr
  PyExc_SyntaxWarning*: PyObjectPtrPtr
  PyExc_UserWarning*: PyObjectPtrPtr
  PyExc_OverflowWarning*: PyObjectPtrPtr
  PyExc_ReferenceError*: PyObjectPtrPtr
  PyExc_StopIteration*: PyObjectPtrPtr
  PyExc_FutureWarning*: PyObjectPtrPtr
  PyExc_PendingDeprecationWarning*: PyObjectPtrPtr
  PyExc_UnicodeDecodeError*: PyObjectPtrPtr
  PyExc_UnicodeEncodeError*: PyObjectPtrPtr
  PyExc_UnicodeTranslateError*: PyObjectPtrPtr
  PyType_Type*: PyTypeObjectPtr
  PyCFunction_Type*: PyTypeObjectPtr
  PyCObject_Type*: PyTypeObjectPtr
  PyClass_Type*: PyTypeObjectPtr
  PyCode_Type*: PyTypeObjectPtr
  PyComplex_Type*: PyTypeObjectPtr
  PyDict_Type*: PyTypeObjectPtr
  PyFile_Type*: PyTypeObjectPtr
  PyFloat_Type*: PyTypeObjectPtr
  PyFrame_Type*: PyTypeObjectPtr
  PyFunction_Type*: PyTypeObjectPtr
  PyInstance_Type*: PyTypeObjectPtr
  PyInt_Type*: PyTypeObjectPtr
  PyList_Type*: PyTypeObjectPtr
  PyLong_Type*: PyTypeObjectPtr
  PyMethod_Type*: PyTypeObjectPtr
  PyModule_Type*: PyTypeObjectPtr
  PyObject_Type*: PyTypeObjectPtr
  PyRange_Type*: PyTypeObjectPtr
  PySlice_Type*: PyTypeObjectPtr
  PyString_Type*: PyTypeObjectPtr
  PyTuple_Type*: PyTypeObjectPtr
  PyBaseObject_Type*: PyTypeObjectPtr
  PyBuffer_Type*: PyTypeObjectPtr
  PyCallIter_Type*: PyTypeObjectPtr
  PyCell_Type*: PyTypeObjectPtr
  PyClassMethod_Type*: PyTypeObjectPtr
  PyProperty_Type*: PyTypeObjectPtr
  PySeqIter_Type*: PyTypeObjectPtr
  PyStaticMethod_Type*: PyTypeObjectPtr
  PySuper_Type*: PyTypeObjectPtr
  PySymtableEntry_Type*: PyTypeObjectPtr
  PyTraceBack_Type*: PyTypeObjectPtr
  PyUnicode_Type*: PyTypeObjectPtr
  PyWrapperDescr_Type*: PyTypeObjectPtr
  PyBaseString_Type*: PyTypeObjectPtr
  PyBool_Type*: PyTypeObjectPtr
  PyEnum_Type*: PyTypeObjectPtr

  #PyArg_GetObject: proc(args: PyObjectPtr; nargs, i: integer; p_a: PyObjectPtrPtr): integer; cdecl;
  #PyArg_GetLong: proc(args: PyObjectPtr; nargs, i: integer; p_a: PLong): integer; cdecl;
  #PyArg_GetShort: proc(args: PyObjectPtr; nargs, i: integer; p_a: PShort): integer; cdecl;
  #PyArg_GetFloat: proc(args: PyObjectPtr; nargs, i: integer; p_a: PFloat): integer; cdecl;
  #PyArg_GetString: proc(args: PyObjectPtr; nargs, i: integer; p_a: PString): integer; cdecl;
  #PyArgs_VaParse:  proc (args: PyObjectPtr; format: PChar; 
  #                          va_list: array of const): integer; cdecl;
  # Does not work!
  # Py_VaBuildValue: proc (format: PChar; va_list: array of const): PyObjectPtr; cdecl;
  #PyBuiltin_Init: proc; cdecl;
proc PyComplex_FromCComplex*(c: Py_complex): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyComplex_FromDoubles*(realv, imag: float64): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyComplex_RealAsDouble*(op: PyObjectPtr): float64{.cdecl, importc, dynlib: dllname.}
proc PyComplex_ImagAsDouble*(op: PyObjectPtr): float64{.cdecl, importc, dynlib: dllname.}
proc PyComplex_AsCComplex*(op: PyObjectPtr): Py_complex{.cdecl, importc, dynlib: dllname.}
proc PyCFunction_GetFunction*(ob: PyObjectPtr): pointer{.cdecl, importc, dynlib: dllname.}
proc PyCFunction_GetSelf*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyCallable_Check*(ob: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.}
proc PyCObject_FromVoidPtr*(cobj, destruct: pointer): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyCObject_AsVoidPtr*(ob: PyObjectPtr): pointer{.cdecl, importc, dynlib: dllname.}
proc PyClass_New*(ob1, ob2, ob3: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyClass_IsSubclass*(ob1, ob2: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.}
proc Py_InitModule4*(name: cstring, methods: PyMethodDefPtr, doc: cstring, 
                         passthrough: PyObjectPtr, Api_Version: int): PyObjectPtr{.
      cdecl, importc, dynlib: dllname.}
proc PyErr_BadArgument*(): int{.cdecl, importc, dynlib: dllname.}
proc PyErr_BadInternalCall*(){.cdecl, importc, dynlib: dllname.}
proc PyErr_CheckSignals*(): int{.cdecl, importc, dynlib: dllname.}
proc PyErr_Clear*(){.cdecl, importc, dynlib: dllname.}
proc PyErr_Fetch*(errtype, errvalue, errtraceback: PyObjectPtrPtr){.cdecl, importc, dynlib: dllname.}
proc PyErr_NoMemory*(): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyErr_Occurred*(): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyErr_Print*(){.cdecl, importc, dynlib: dllname.}
proc PyErr_Restore*(errtype, errvalue, errtraceback: PyObjectPtr){.cdecl, importc, dynlib: dllname.}
proc PyErr_SetFromErrno*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyErr_SetNone*(value: PyObjectPtr){.cdecl, importc, dynlib: dllname.}
proc PyErr_SetObject*(ob1, ob2: PyObjectPtr){.cdecl, importc, dynlib: dllname.}
proc PyErr_SetString*(ErrorObject: PyObjectPtr, text: cstring){.cdecl, importc, dynlib: dllname.}
proc PyImport_GetModuleDict*(): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyInt_FromLong*(x: int32): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc Py_Initialize*(){.cdecl, importc, dynlib: dllname.}
proc Py_Exit*(RetVal: int){.cdecl, importc, dynlib: dllname.}
proc PyEval_GetBuiltins*(): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyDict_GetItem*(mp, key: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyDict_SetItem*(mp, key, item: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.}
proc PyDict_DelItem*(mp, key: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.}
proc PyDict_Clear*(mp: PyObjectPtr){.cdecl, importc, dynlib: dllname.}
proc PyDict_Next*(mp: PyObjectPtr, pos: IntPtr, key, value: PyObjectPtrPtr): int{.
      cdecl, importc, dynlib: dllname.}
proc PyDict_Keys*(mp: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyDict_Values*(mp: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyDict_Items*(mp: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyDict_Size*(mp: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.}
proc PyDict_DelItemString*(dp: PyObjectPtr, key: cstring): int{.cdecl, importc, dynlib: dllname.}
proc PyDict_New*(): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyDict_GetItemString*(dp: PyObjectPtr, key: cstring): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyDict_SetItemString*(dp: PyObjectPtr, key: cstring, item: PyObjectPtr): int{.
      cdecl, importc, dynlib: dllname.}
proc PyDictProxy_New*(obj: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyModule_GetDict*(module: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyObject_Str*(v: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyRun_String*(str: cstring, start: int, globals: PyObjectPtr, 
                       locals: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyRun_SimpleString*(str: cstring): int{.cdecl, importc, dynlib: dllname.}
proc PyString_AsString*(ob: PyObjectPtr): cstring{.cdecl, importc, dynlib: dllname.}
proc PyString_FromString*(str: cstring): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PySys_SetArgv*(argc: int, argv: cstringArray){.cdecl, importc, dynlib: dllname.} 
  #+ means, Grzegorz or me has tested his non object version of this function
  #+
proc PyCFunction_New*(md: PyMethodDefPtr, ob: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #+
proc PyEval_CallObject*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyEval_CallObjectWithKeywords*(ob1, ob2, ob3: PyObjectPtr): PyObjectPtr{.
      cdecl, importc, dynlib: dllname.}                 #-
proc PyEval_GetFrame*(): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyEval_GetGlobals*(): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyEval_GetLocals*(): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyEval_GetOwner*(): PyObjectPtr {.cdecl, importc, dynlib: dllname.}
proc PyEval_GetRestricted*(): int{.cdecl, importc, dynlib: dllname.} #-
proc PyEval_InitThreads*(){.cdecl, importc, dynlib: dllname.} #-
proc PyEval_RestoreThread*(tstate: PyThreadStatePtr){.cdecl, importc, dynlib: dllname.} #-
proc PyEval_SaveThread*(): PyThreadStatePtr{.cdecl, importc, dynlib: dllname.} #-
proc PyFile_FromString*(pc1, pc2: cstring): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyFile_GetLine*(ob: PyObjectPtr, i: int): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyFile_Name*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyFile_SetBufSize*(ob: PyObjectPtr, i: int){.cdecl, importc, dynlib: dllname.} #-
proc PyFile_SoftSpace*(ob: PyObjectPtr, i: int): int{.cdecl, importc, dynlib: dllname.} #-
proc PyFile_WriteObject*(ob1, ob2: PyObjectPtr, i: int): int{.cdecl, importc, dynlib: dllname.} #-
proc PyFile_WriteString*(s: cstring, ob: PyObjectPtr){.cdecl, importc, dynlib: dllname.} #+
proc PyFloat_AsDouble*(ob: PyObjectPtr): float64{.cdecl, importc, dynlib: dllname.} #+
proc PyFloat_FromDouble*(db: float64): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyFunction_GetCode*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyFunction_GetGlobals*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyFunction_New*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyImport_AddModule*(name: cstring): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyImport_Cleanup*(){.cdecl, importc, dynlib: dllname.} #-
proc PyImport_GetMagicNumber*(): int32{.cdecl, importc, dynlib: dllname.} #+
proc PyImport_ImportFrozenModule*(key: cstring): int{.cdecl, importc, dynlib: dllname.} #+
proc PyImport_ImportModule*(name: cstring): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #+
proc PyImport_Import*(name: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
                                                               
proc PyImport_Init*() {.cdecl, importc, dynlib: dllname.}
proc PyImport_ReloadModule*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyInstance_New*(obClass, obArg, obKW: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #+
proc PyInt_AsLong*(ob: PyObjectPtr): int32{.cdecl, importc, dynlib: dllname.} #-
proc PyList_Append*(ob1, ob2: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PyList_AsTuple*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #+
proc PyList_GetItem*(ob: PyObjectPtr, i: int): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyList_GetSlice*(ob: PyObjectPtr, i1, i2: int): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyList_Insert*(dp: PyObjectPtr, idx: int, item: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PyList_New*(size: int): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyList_Reverse*(ob: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PyList_SetItem*(dp: PyObjectPtr, idx: int, item: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PyList_SetSlice*(ob: PyObjectPtr, i1, i2: int, ob2: PyObjectPtr): int{.
      cdecl, importc, dynlib: dllname.}                 #+
proc PyList_Size*(ob: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PyList_Sort*(ob: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PyLong_AsDouble*(ob: PyObjectPtr): float64{.cdecl, importc, dynlib: dllname.} #+
proc PyLong_AsLong*(ob: PyObjectPtr): int32{.cdecl, importc, dynlib: dllname.} #+
proc PyLong_FromDouble*(db: float64): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #+
proc PyLong_FromLong*(L: int32): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyLong_FromString*(pc: cstring, ppc: var cstring, i: int): PyObjectPtr{.
      cdecl, importc, dynlib: dllname.}                 #-
proc PyLong_FromUnsignedLong*(val: int): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyLong_AsUnsignedLong*(ob: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PyLong_FromUnicode*(ob: PyObjectPtr, a, b: int): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyLong_FromLongLong*(val: int64): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyLong_AsLongLong*(ob: PyObjectPtr): int64{.cdecl, importc, dynlib: dllname.} #-
proc PyMapping_Check*(ob: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PyMapping_GetItemString*(ob: PyObjectPtr, key: cstring): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyMapping_HasKey*(ob, key: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PyMapping_HasKeyString*(ob: PyObjectPtr, key: cstring): int{.cdecl, importc, dynlib: dllname.} #-
proc PyMapping_Length*(ob: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PyMapping_SetItemString*(ob: PyObjectPtr, key: cstring, value: PyObjectPtr): int{.
      cdecl, importc, dynlib: dllname.}                 #-
proc PyMethod_Class*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyMethod_Function*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyMethod_New*(ob1, ob2, ob3: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyMethod_Self*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyModule_GetName*(ob: PyObjectPtr): cstring{.cdecl, importc, dynlib: dllname.} #-
proc PyModule_New*(key: cstring): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Absolute*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Add*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_And*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Check*(ob: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Coerce*(ob1, ob2: var PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Divide*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_FloorDivide*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_TrueDivide*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Divmod*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Float*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Int*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Invert*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Long*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Lshift*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Multiply*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Negative*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Or*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Positive*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Power*(ob1, ob2, ob3: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Remainder*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Rshift*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Subtract*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyNumber_Xor*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyOS_InitInterrupts*(){.cdecl, importc, dynlib: dllname.} #-
proc PyOS_InterruptOccurred*(): int{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_CallObject*(ob, args: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_Compare*(ob1, ob2: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_GetAttr*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #+
proc PyObject_GetAttrString*(ob: PyObjectPtr, c: cstring): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_GetItem*(ob, key: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_DelItem*(ob, key: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_HasAttrString*(ob: PyObjectPtr, key: cstring): int{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_Hash*(ob: PyObjectPtr): int32{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_IsTrue*(ob: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_Length*(ob: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_Repr*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_SetAttr*(ob1, ob2, ob3: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_SetAttrString*(ob: PyObjectPtr, key: cstring, value: PyObjectPtr): int{.
      cdecl, importc, dynlib: dllname.}                 #-
proc PyObject_SetItem*(ob1, ob2, ob3: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_Init*(ob: PyObjectPtr, t: PyTypeObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_InitVar*(ob: PyObjectPtr, t: PyTypeObjectPtr, size: int): PyObjectPtr{.
      cdecl, importc, dynlib: dllname.}                 #-
proc PyObject_New*(t: PyTypeObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_NewVar*(t: PyTypeObjectPtr, size: int): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyObject_Free*(ob: PyObjectPtr){.cdecl, importc, dynlib: dllname.} #-
proc PyObject_IsInstance*(inst, cls: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_IsSubclass*(derived, cls: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.}
proc PyObject_GenericGetAttr*(obj, name: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyObject_GenericSetAttr*(obj, name, value: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_GC_Malloc*(size: int): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_GC_New*(t: PyTypeObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_GC_NewVar*(t: PyTypeObjectPtr, size: int): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_GC_Resize*(t: PyObjectPtr, newsize: int): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyObject_GC_Del*(ob: PyObjectPtr){.cdecl, importc, dynlib: dllname.} #-
proc PyObject_GC_Track*(ob: PyObjectPtr){.cdecl, importc, dynlib: dllname.} #-
proc PyObject_GC_UnTrack*(ob: PyObjectPtr){.cdecl, importc, dynlib: dllname.} #-
proc PyRange_New*(l1, l2, l3: int32, i: int): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PySequence_Check*(ob: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PySequence_Concat*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PySequence_Count*(ob1, ob2: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PySequence_GetItem*(ob: PyObjectPtr, i: int): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PySequence_GetSlice*(ob: PyObjectPtr, i1, i2: int): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PySequence_In*(ob1, ob2: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PySequence_Index*(ob1, ob2: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PySequence_Length*(ob: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PySequence_Repeat*(ob: PyObjectPtr, count: int): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PySequence_SetItem*(ob: PyObjectPtr, i: int, value: PyObjectPtr): int{.
      cdecl, importc, dynlib: dllname.}                 #-
proc PySequence_SetSlice*(ob: PyObjectPtr, i1, i2: int, value: PyObjectPtr): int{.
      cdecl, importc, dynlib: dllname.}                 #-
proc PySequence_DelSlice*(ob: PyObjectPtr, i1, i2: int): int{.cdecl, importc, dynlib: dllname.} #-
proc PySequence_Tuple*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PySequence_Contains*(ob, value: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PySlice_GetIndices*(ob: PySliceObjectPtr, len: int, 
                             start, stop, step: var int): int{.cdecl, importc, dynlib: dllname.} #-
proc PySlice_GetIndicesEx*(ob: PySliceObjectPtr, len: int, 
                               start, stop, step, slicelength: var int): int{.
      cdecl, importc, dynlib: dllname.}                 #-
proc PySlice_New*(start, stop, step: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyString_Concat*(ob1: var PyObjectPtr, ob2: PyObjectPtr){.cdecl, importc, dynlib: dllname.} #-
proc PyString_ConcatAndDel*(ob1: var PyObjectPtr, ob2: PyObjectPtr){.cdecl, importc, dynlib: dllname.} #-
proc PyString_Format*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyString_FromStringAndSize*(s: cstring, i: int): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyString_Size*(ob: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PyString_DecodeEscape*(s: cstring, length: int, errors: cstring, 
                                unicode: int, recode_encoding: cstring): PyObjectPtr{.
      cdecl, importc, dynlib: dllname.}                 #-
proc PyString_Repr*(ob: PyObjectPtr, smartquotes: int): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #+
proc PySys_GetObject*(s: cstring): PyObjectPtr{.cdecl, importc, dynlib: dllname.} 
#-
#PySys_Init:procedure; cdecl, importc, dynlib: dllname;
#-
proc PySys_SetObject*(s: cstring, ob: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PySys_SetPath*(path: cstring){.cdecl, importc, dynlib: dllname.} #-
#PyTraceBack_Fetch:function:PyObjectPtr; cdecl, importc, dynlib: dllname;
#-
proc PyTraceBack_Here*(p: pointer): int{.cdecl, importc, dynlib: dllname.} #-
proc PyTraceBack_Print*(ob1, ob2: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
#PyTraceBack_Store:function (ob:PyObjectPtr):integer; cdecl, importc, dynlib: dllname;
#+
proc PyTuple_GetItem*(ob: PyObjectPtr, i: int): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc PyTuple_GetSlice*(ob: PyObjectPtr, i1, i2: int): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #+
proc PyTuple_New*(size: int): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #+
proc PyTuple_SetItem*(ob: PyObjectPtr, key: int, value: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #+
proc PyTuple_Size*(ob: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #+
proc PyType_IsSubtype*(a, b: PyTypeObjectPtr): int{.cdecl, importc, dynlib: dllname.}
proc PyType_GenericAlloc*(atype: PyTypeObjectPtr, nitems: int): PyObjectPtr{.
      cdecl, importc, dynlib: dllname.}
proc PyType_GenericNew*(atype: PyTypeObjectPtr, args, kwds: PyObjectPtr): PyObjectPtr{.
      cdecl, importc, dynlib: dllname.}
proc PyType_Ready*(atype: PyTypeObjectPtr): int{.cdecl, importc, dynlib: dllname.} #+
proc PyUnicode_FromWideChar*(w: pointer, size: int): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #+
proc PyUnicode_AsWideChar*(unicode: PyObjectPtr, w: pointer, size: int): int{.
      cdecl, importc, dynlib: dllname.}                 #-
proc PyUnicode_FromOrdinal*(ordinal: int): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyWeakref_GetObject*(theRef: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyWeakref_NewProxy*(ob, callback: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyWeakref_NewRef*(ob, callback: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyWrapper_New*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc PyBool_FromLong*(ok: int): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc Py_AtExit*(prc: proc () {.cdecl.}): int{.cdecl, importc, dynlib: dllname.} #-
#Py_Cleanup:procedure; cdecl, importc, dynlib: dllname;
#-
proc Py_CompileString*(s1, s2: cstring, i: int): PyObjectPtr{.cdecl, importc, dynlib: dllname.} #-
proc Py_FatalError*(s: cstring){.cdecl, importc, dynlib: dllname.} #-
proc Py_FindMethod*(md: PyMethodDefPtr, ob: PyObjectPtr, key: cstring): PyObjectPtr{.
      cdecl, importc, dynlib: dllname.}                 #-
proc Py_FindMethodInChain*(mc: PyMethodChainPtr, ob: PyObjectPtr, key: cstring): PyObjectPtr{.
      cdecl, importc, dynlib: dllname.}                 #-
proc Py_FlushLine*(){.cdecl, importc, dynlib: dllname.} #+
proc Py_Finalize*(){.cdecl, importc, dynlib: dllname.} #-
proc PyErr_ExceptionMatches*(exc: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PyErr_GivenExceptionMatches*(raised_exc, exc: PyObjectPtr): int{.cdecl, importc, dynlib: dllname.} #-
proc PyEval_EvalCode*(co: PyCodeObjectPtr, globals, locals: PyObjectPtr): PyObjectPtr{.
      cdecl, importc, dynlib: dllname.}                 #+
proc Py_GetVersion*(): cstring{.cdecl, importc, dynlib: dllname.} #+
proc Py_GetCopyright*(): cstring{.cdecl, importc, dynlib: dllname.} #+
proc Py_GetExecPrefix*(): cstring{.cdecl, importc, dynlib: dllname.} #+
proc Py_GetPath*(): cstring{.cdecl, importc, dynlib: dllname.} #+
proc Py_GetPrefix*(): cstring{.cdecl, importc, dynlib: dllname.} #+
proc Py_GetProgramName*(): cstring{.cdecl, importc, dynlib: dllname.} #-
proc PyParser_SimpleParseString*(str: cstring, start: int): NodePtr{.cdecl, importc, dynlib: dllname.} #-
proc PyNode_Free*(n: NodePtr){.cdecl, importc, dynlib: dllname.} #-
proc PyErr_NewException*(name: cstring, base, dict: PyObjectPtr): PyObjectPtr{.
      cdecl, importc, dynlib: dllname.}                 #-
proc Py_Malloc*(size: int): pointer {.cdecl, importc, dynlib: dllname.}
proc PyMem_Malloc*(size: int): pointer {.cdecl, importc, dynlib: dllname.}
proc PyObject_CallMethod*(obj: PyObjectPtr, theMethod, 
                              format: cstring): PyObjectPtr{.cdecl, importc, dynlib: dllname.}
proc Py_SetProgramName*(name: cstring){.cdecl, importc, dynlib: dllname.}
proc Py_IsInitialized*(): int{.cdecl, importc, dynlib: dllname.}
proc Py_GetProgramFullPath*(): cstring{.cdecl, importc, dynlib: dllname.}
proc Py_NewInterpreter*(): PyThreadStatePtr{.cdecl, importc, dynlib: dllname.}
proc Py_EndInterpreter*(tstate: PyThreadStatePtr){.cdecl, importc, dynlib: dllname.}
proc PyEval_AcquireLock*(){.cdecl, importc, dynlib: dllname.}
proc PyEval_ReleaseLock*(){.cdecl, importc, dynlib: dllname.}
proc PyEval_AcquireThread*(tstate: PyThreadStatePtr){.cdecl, importc, dynlib: dllname.}
proc PyEval_ReleaseThread*(tstate: PyThreadStatePtr){.cdecl, importc, dynlib: dllname.}
proc PyInterpreterState_New*(): PyInterpreterStatePtr{.cdecl, importc, dynlib: dllname.}
proc PyInterpreterState_Clear*(interp: PyInterpreterStatePtr){.cdecl, importc, dynlib: dllname.}
proc PyInterpreterState_Delete*(interp: PyInterpreterStatePtr){.cdecl, importc, dynlib: dllname.}
proc PyThreadState_New*(interp: PyInterpreterStatePtr): PyThreadStatePtr{.cdecl, importc, dynlib: dllname.}
proc PyThreadState_Clear*(tstate: PyThreadStatePtr){.cdecl, importc, dynlib: dllname.}
proc PyThreadState_Delete*(tstate: PyThreadStatePtr){.cdecl, importc, dynlib: dllname.}
proc PyThreadState_Get*(): PyThreadStatePtr{.cdecl, importc, dynlib: dllname.}
proc PyThreadState_Swap*(tstate: PyThreadStatePtr): PyThreadStatePtr{.cdecl, importc, dynlib: dllname.} 

# Run the interpreter independantly of the Nim application
proc Py_Main*(argc: int, argv: cstringPtr): int{.cdecl, importc, dynlib: dllname.}
# Execute a script from a file
proc PyRun_AnyFile*(filename: string): int =
  result = PyRun_SimpleString(readFile(filename))

#Further exported Objects, may be implemented later
#
#    PyCode_New: Pointer;
#    PyErr_SetInterrupt: Pointer;
#    PyFile_AsFile: Pointer;
#    PyFile_FromFile: Pointer;
#    PyFloat_AsString: Pointer;
#    PyFrame_BlockPop: Pointer;
#    PyFrame_BlockSetup: Pointer;
#    PyFrame_ExtendStack: Pointer;
#    PyFrame_FastToLocals: Pointer;
#    PyFrame_LocalsToFast: Pointer;
#    PyFrame_New: Pointer;
#    PyGrammar_AddAccelerators: Pointer;
#    PyGrammar_FindDFA: Pointer;
#    PyGrammar_LabelRepr: Pointer;
#    PyInstance_DoBinOp: Pointer;
#    PyInt_GetMax: Pointer;
#    PyMarshal_Init: Pointer;
#    PyMarshal_ReadLongFromFile: Pointer;
#    PyMarshal_ReadObjectFromFile: Pointer;
#    PyMarshal_ReadObjectFromString: Pointer;
#    PyMarshal_WriteLongToFile: Pointer;
#    PyMarshal_WriteObjectToFile: Pointer;
#    PyMember_Get: Pointer;
#    PyMember_Set: Pointer;
#    PyNode_AddChild: Pointer;
#    PyNode_Compile: Pointer;
#    PyNode_New: Pointer;
#    PyOS_GetLastModificationTime: Pointer;
#    PyOS_Readline: Pointer;
#    PyOS_strtol: Pointer;
#    PyOS_strtoul: Pointer;
#    PyObject_CallFunction: Pointer;
#    PyObject_CallMethod: Pointer;
#    PyObject_Print: Pointer;
#    PyParser_AddToken: Pointer;
#    PyParser_Delete: Pointer;
#    PyParser_New: Pointer;
#    PyParser_ParseFile: Pointer;
#    PyParser_ParseString: Pointer;
#    PyParser_SimpleParseFile: Pointer;
#    PyRun_AnyFile: Pointer;
#    PyRun_File: Pointer;
#    PyRun_InteractiveLoop: Pointer;
#    PyRun_InteractiveOne: Pointer;
#    PyRun_SimpleFile: Pointer;
#    PySys_GetFile: Pointer;
#    PyToken_OneChar: Pointer;
#    PyToken_TwoChars: Pointer;
#    PyTokenizer_Free: Pointer;
#    PyTokenizer_FromFile: Pointer;
#    PyTokenizer_FromString: Pointer;
#    PyTokenizer_Get: Pointer;
#    Py_Main: Pointer;
#    _PyObject_NewVar: Pointer;
#    _PyParser_Grammar: Pointer;
#    _PyParser_TokenNames: Pointer;
#    _PyThread_Started: Pointer;
#    _Py_c_diff: Pointer;
#    _Py_c_neg: Pointer;
#    _Py_c_pow: Pointer;
#    _Py_c_prod: Pointer;
#    _Py_c_quot: Pointer;
#    _Py_c_sum: Pointer;
#

# This function handles all cardinals, pointer types (with no adjustment of pointers!)
# (Extended) floats, which are handled as Python doubles and currencies, handled
# as (normalized) Python doubles.
proc PyImport_ExecCodeModule*(name: string, codeobject: PyObjectPtr): PyObjectPtr
proc PyString_Check*(obj: PyObjectPtr): bool
proc PyString_CheckExact*(obj: PyObjectPtr): bool
proc PyFloat_Check*(obj: PyObjectPtr): bool
proc PyFloat_CheckExact*(obj: PyObjectPtr): bool
proc PyInt_Check*(obj: PyObjectPtr): bool
proc PyInt_CheckExact*(obj: PyObjectPtr): bool
proc PyLong_Check*(obj: PyObjectPtr): bool
proc PyLong_CheckExact*(obj: PyObjectPtr): bool
proc PyTuple_Check*(obj: PyObjectPtr): bool
proc PyTuple_CheckExact*(obj: PyObjectPtr): bool
proc PyInstance_Check*(obj: PyObjectPtr): bool
proc PyClass_Check*(obj: PyObjectPtr): bool
proc PyMethod_Check*(obj: PyObjectPtr): bool
proc PyList_Check*(obj: PyObjectPtr): bool
proc PyList_CheckExact*(obj: PyObjectPtr): bool
proc PyDict_Check*(obj: PyObjectPtr): bool
proc PyDict_CheckExact*(obj: PyObjectPtr): bool
proc PyModule_Check*(obj: PyObjectPtr): bool
proc PyModule_CheckExact*(obj: PyObjectPtr): bool
proc PySlice_Check*(obj: PyObjectPtr): bool
proc PyFunction_Check*(obj: PyObjectPtr): bool
proc PyUnicode_Check*(obj: PyObjectPtr): bool
proc PyUnicode_CheckExact*(obj: PyObjectPtr): bool
proc PyType_IS_GC*(t: PyTypeObjectPtr): bool
proc PyObject_IS_GC*(obj: PyObjectPtr): bool
proc PyBool_Check*(obj: PyObjectPtr): bool
proc PyBaseString_Check*(obj: PyObjectPtr): bool
proc PyEnum_Check*(obj: PyObjectPtr): bool
proc PyObject_TypeCheck*(obj: PyObjectPtr, t: PyTypeObjectPtr): bool
proc Py_InitModule*(name: cstring, md: PyMethodDefPtr): PyObjectPtr
proc PyType_HasFeature*(AType: PyTypeObjectPtr, AFlag: int): bool
# implementation

proc Py_INCREF*(op: PyObjectPtr) {.inline.} = 
  inc(op.ob_refcnt)

proc Py_DECREF*(op: PyObjectPtr) {.inline.} = 
  dec(op.ob_refcnt)
  if op.ob_refcnt == 0: 
    op.ob_type.tp_dealloc(op)

proc Py_XINCREF*(op: PyObjectPtr) {.inline.} = 
  if op != nil: Py_INCREF(op)
  
proc Py_XDECREF*(op: PyObjectPtr) {.inline.} = 
  if op != nil: Py_DECREF(op)
  
proc PyImport_ExecCodeModule(name: string, codeobject: PyObjectPtr): PyObjectPtr = 
  var m, d, v, modules: PyObjectPtr
  m = PyImport_AddModule(cstring(name))
  if m == nil: 
    return nil
  d = PyModule_GetDict(m)
  if PyDict_GetItemString(d, "__builtins__") == nil: 
    if PyDict_SetItemString(d, "__builtins__", PyEval_GetBuiltins()) != 0: 
      return nil
  if PyDict_SetItemString(d, "__file__", 
                          PyCodeObjectPtr(codeobject).co_filename) != 0: 
    PyErr_Clear() # Not important enough to report
  v = PyEval_EvalCode(PyCodeObjectPtr(codeobject), d, d) # XXX owner ?
  if v == nil: 
    return nil
  Py_XDECREF(v)
  modules = PyImport_GetModuleDict()
  if PyDict_GetItemString(modules, cstring(name)) == nil: 
    PyErr_SetString(PyExc_ImportError[] , cstring(
        "Loaded module " & name & "not found in sys.modules"))
    return nil
  Py_XINCREF(m)
  result = m

proc PyString_Check(obj: PyObjectPtr): bool = 
  result = PyObject_TypeCheck(obj, PyString_Type)

proc PyString_CheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj.ob_type == PyString_Type)

proc PyFloat_Check(obj: PyObjectPtr): bool = 
  result = PyObject_TypeCheck(obj, PyFloat_Type)

proc PyFloat_CheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj.ob_type == PyFloat_Type)

proc PyInt_Check(obj: PyObjectPtr): bool = 
  result = PyObject_TypeCheck(obj, PyInt_Type)

proc PyInt_CheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj.ob_type == PyInt_Type)

proc PyLong_Check(obj: PyObjectPtr): bool = 
  result = PyObject_TypeCheck(obj, PyLong_Type)

proc PyLong_CheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj.ob_type == PyLong_Type)

proc PyTuple_Check(obj: PyObjectPtr): bool = 
  result = PyObject_TypeCheck(obj, PyTuple_Type)

proc PyTuple_CheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj[].ob_type == PyTuple_Type)

proc PyInstance_Check(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj[].ob_type == PyInstance_Type)

proc PyClass_Check(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj[].ob_type == PyClass_Type)

proc PyMethod_Check(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj[].ob_type == PyMethod_Type)

proc PyList_Check(obj: PyObjectPtr): bool = 
  result = PyObject_TypeCheck(obj, PyList_Type)

proc PyList_CheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj[].ob_type == PyList_Type)

proc PyDict_Check(obj: PyObjectPtr): bool = 
  result = PyObject_TypeCheck(obj, PyDict_Type)

proc PyDict_CheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj[].ob_type == PyDict_Type)

proc PyModule_Check(obj: PyObjectPtr): bool = 
  result = PyObject_TypeCheck(obj, PyModule_Type)

proc PyModule_CheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj[].ob_type == PyModule_Type)

proc PySlice_Check(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj[].ob_type == PySlice_Type)

proc PyFunction_Check(obj: PyObjectPtr): bool = 
  result = (obj != nil) and
      ((obj.ob_type == PyCFunction_Type) or
      (obj.ob_type == PyFunction_Type))

proc PyUnicode_Check(obj: PyObjectPtr): bool = 
  result = PyObject_TypeCheck(obj, PyUnicode_Type)

proc PyUnicode_CheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj.ob_type == PyUnicode_Type)

proc PyType_IS_GC(t: PyTypeObjectPtr): bool = 
  result = PyType_HasFeature(t, Py_TPFLAGS_HAVE_GC)

proc PyObject_IS_GC(obj: PyObjectPtr): bool = 
  result = PyType_IS_GC(obj.ob_type) and
      ((obj.ob_type.tp_is_gc == nil) or (obj.ob_type.tp_is_gc(obj) == 1))

proc PyBool_Check(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj.ob_type == PyBool_Type)

proc PyBaseString_Check(obj: PyObjectPtr): bool = 
  result = PyObject_TypeCheck(obj, PyBaseString_Type)

proc PyEnum_Check(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj.ob_type == PyEnum_Type)

proc PyObject_TypeCheck(obj: PyObjectPtr, t: PyTypeObjectPtr): bool = 
  result = (obj != nil) and (obj.ob_type == t)
  if not result and (obj != nil) and (t != nil): 
    result = PyType_IsSubtype(obj.ob_type, t) == 1
  
proc Py_InitModule(name: cstring, md: PyMethodDefPtr): PyObjectPtr = 
  result = Py_InitModule4(name, md, nil, nil, 1012)

proc PyType_HasFeature(AType: PyTypeObjectPtr, AFlag: int): bool = 
  #(((t)->tp_flags & (f)) != 0)
  result = (AType.tp_flags and AFlag) != 0

proc init(lib: LibHandle) = 
  Py_DebugFlag = cast[IntPtr](symAddr(lib, "Py_DebugFlag"))
  Py_VerboseFlag = cast[IntPtr](symAddr(lib, "Py_VerboseFlag"))
  Py_InteractiveFlag = cast[IntPtr](symAddr(lib, "Py_InteractiveFlag"))
  Py_OptimizeFlag = cast[IntPtr](symAddr(lib, "Py_OptimizeFlag"))
  Py_NoSiteFlag = cast[IntPtr](symAddr(lib, "Py_NoSiteFlag"))
  Py_UseClassExceptionsFlag = cast[IntPtr](symAddr(lib, "Py_UseClassExceptionsFlag"))
  Py_FrozenFlag = cast[IntPtr](symAddr(lib, "Py_FrozenFlag"))
  Py_TabcheckFlag = cast[IntPtr](symAddr(lib, "Py_TabcheckFlag"))
  Py_UnicodeFlag = cast[IntPtr](symAddr(lib, "Py_UnicodeFlag"))
  Py_IgnoreEnvironmentFlag = cast[IntPtr](symAddr(lib, "Py_IgnoreEnvironmentFlag"))
  Py_DivisionWarningFlag = cast[IntPtr](symAddr(lib, "Py_DivisionWarningFlag"))
  Py_None = cast[PyObjectPtr](symAddr(lib, "_Py_NoneStruct"))
  Py_Ellipsis = cast[PyObjectPtr](symAddr(lib, "_Py_EllipsisObject"))
  Py_False = cast[PyIntObjectPtr](symAddr(lib, "_Py_ZeroStruct"))
  Py_True = cast[PyIntObjectPtr](symAddr(lib, "_Py_TrueStruct"))
  Py_NotImplemented = cast[PyObjectPtr](symAddr(lib, "_Py_NotImplementedStruct"))
  PyImport_FrozenModules = cast[frozenPtrPtr](symAddr(lib, "PyImport_FrozenModules"))
  PyExc_AttributeError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_AttributeError"))
  PyExc_EOFError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_EOFError"))
  PyExc_IOError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_IOError"))
  PyExc_ImportError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_ImportError"))
  PyExc_IndexError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_IndexError"))
  PyExc_KeyError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_KeyError"))
  PyExc_KeyboardInterrupt = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_KeyboardInterrupt"))
  PyExc_MemoryError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_MemoryError"))
  PyExc_NameError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_NameError"))
  PyExc_OverflowError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_OverflowError"))
  PyExc_RuntimeError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_RuntimeError"))
  PyExc_SyntaxError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_SyntaxError"))
  PyExc_SystemError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_SystemError"))
  PyExc_SystemExit = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_SystemExit"))
  PyExc_TypeError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_TypeError"))
  PyExc_ValueError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_ValueError"))
  PyExc_ZeroDivisionError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_ZeroDivisionError"))
  PyExc_ArithmeticError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_ArithmeticError"))
  PyExc_Exception = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_Exception"))
  PyExc_FloatingPointError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_FloatingPointError"))
  PyExc_LookupError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_LookupError"))
  PyExc_StandardError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_StandardError"))
  PyExc_AssertionError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_AssertionError"))
  PyExc_EnvironmentError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_EnvironmentError"))
  PyExc_IndentationError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_IndentationError"))
  PyExc_MemoryErrorInst = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_MemoryErrorInst"))
  PyExc_NotImplementedError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_NotImplementedError"))
  PyExc_OSError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_OSError"))
  PyExc_TabError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_TabError"))
  PyExc_UnboundLocalError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_UnboundLocalError"))
  PyExc_UnicodeError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_UnicodeError"))
  PyExc_Warning = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_Warning"))
  PyExc_DeprecationWarning = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_DeprecationWarning"))
  PyExc_RuntimeWarning = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_RuntimeWarning"))
  PyExc_SyntaxWarning = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_SyntaxWarning"))
  PyExc_UserWarning = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_UserWarning"))
  PyExc_OverflowWarning = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_OverflowWarning"))
  PyExc_ReferenceError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_ReferenceError"))
  PyExc_StopIteration = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_StopIteration"))
  PyExc_FutureWarning = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_FutureWarning"))
  PyExc_PendingDeprecationWarning = cast[PyObjectPtrPtr](symAddr(lib, 
      "PyExc_PendingDeprecationWarning"))
  PyExc_UnicodeDecodeError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_UnicodeDecodeError"))
  PyExc_UnicodeEncodeError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_UnicodeEncodeError"))
  PyExc_UnicodeTranslateError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_UnicodeTranslateError"))
  PyType_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyType_Type"))
  PyCFunction_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyCFunction_Type"))
  PyCObject_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyCObject_Type"))
  PyClass_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyClass_Type"))
  PyCode_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyCode_Type"))
  PyComplex_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyComplex_Type"))
  PyDict_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyDict_Type"))
  PyFile_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyFile_Type"))
  PyFloat_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyFloat_Type"))
  PyFrame_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyFrame_Type"))
  PyFunction_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyFunction_Type"))
  PyInstance_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyInstance_Type"))
  PyInt_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyInt_Type"))
  PyList_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyList_Type"))
  PyLong_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyLong_Type"))
  PyMethod_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyMethod_Type"))
  PyModule_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyModule_Type"))
  PyObject_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyObject_Type"))
  PyRange_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyRange_Type"))
  PySlice_Type = cast[PyTypeObjectPtr](symAddr(lib, "PySlice_Type"))
  PyString_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyString_Type"))
  PyTuple_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyTuple_Type"))
  PyUnicode_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyUnicode_Type"))
  PyBaseObject_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyBaseObject_Type"))
  PyBuffer_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyBuffer_Type"))
  PyCallIter_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyCallIter_Type"))
  PyCell_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyCell_Type"))
  PyClassMethod_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyClassMethod_Type"))
  PyProperty_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyProperty_Type"))
  PySeqIter_Type = cast[PyTypeObjectPtr](symAddr(lib, "PySeqIter_Type"))
  PyStaticMethod_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyStaticMethod_Type"))
  PySuper_Type = cast[PyTypeObjectPtr](symAddr(lib, "PySuper_Type"))
  PySymtableEntry_Type = cast[PyTypeObjectPtr](symAddr(lib, "PySymtableEntry_Type"))
  PyTraceBack_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyTraceBack_Type"))
  PyWrapperDescr_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyWrapperDescr_Type"))
  PyBaseString_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyBaseString_Type"))
  PyBool_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyBool_Type"))
  PyEnum_Type = cast[PyTypeObjectPtr](symAddr(lib, "PyEnum_Type"))

# Unfortunately we have to duplicate the loading mechanism here, because Nimrod
# used to not support variables from dynamic libraries. Well designed API's
# don't require this anyway. Python is an exception.

var
  lib: LibHandle

when defined(windows):
  const
    LibNames = ["python27.dll", "python26.dll", "python25.dll",
      "python24.dll", "python23.dll", "python22.dll", "python21.dll",
      "python20.dll", "python16.dll", "python15.dll"]
elif defined(macosx):
  const
    LibNames = ["libpython2.7.dylib", "libpython2.6.dylib",
      "libpython2.5.dylib", "libpython2.4.dylib", "libpython2.3.dylib", 
      "libpython2.2.dylib", "libpython2.1.dylib", "libpython2.0.dylib",
      "libpython1.6.dylib", "libpython1.5.dylib"]
else:
  const
    LibNames = [
      "libpython2.7.so" & dllver,
      "libpython2.6.so" & dllver, 
      "libpython2.5.so" & dllver, 
      "libpython2.4.so" & dllver, 
      "libpython2.3.so" & dllver, 
      "libpython2.2.so" & dllver, 
      "libpython2.1.so" & dllver, 
      "libpython2.0.so" & dllver,
      "libpython1.6.so" & dllver, 
      "libpython1.5.so" & dllver]
  
for libName in items(LibNames): 
  lib = loadLib(libName, global_symbols=true)
  if lib != nil:
    echo "Loaded dynamic library: '$1'" % libName
    break

if lib == nil:
  quit("could not load python library")
init(lib)


## Deprecated type definitions
{.deprecated: [Tallocfunc: allocfunc].}
{.deprecated: [Tbinaryfunc: binaryfunc].}
{.deprecated: [PByte: BytePtr].}
{.deprecated: [Tcmpfunc: cmpfunc].}
{.deprecated: [TCO_MAXBLOCKS: CO_MAXBLOCKS].}
{.deprecated: [Tcoercion: coercion].}
{.deprecated: [Tdescrgetfunc: descrgetfunc].}
{.deprecated: [Tdescrsetfunc: descrsetfunc].}
{.deprecated: [Tfrozen: frozen].}
{.deprecated: [P_frozen: frozenPtr].}
{.deprecated: [PP_frozen: frozenPtrPtr].}
{.deprecated: [Tgetattrfunc: getattrfunc].}
{.deprecated: [Tgetattrofunc: getattrofunc].}
{.deprecated: [Tgetcharbufferproc: getcharbufferproc].}
{.deprecated: [Tgetiterfunc: getiterfunc].}
{.deprecated: [Tgetreadbufferproc: getreadbufferproc].}
{.deprecated: [Tgetsegcountproc: getsegcountproc].}
{.deprecated: [Tgetter: getter].}
{.deprecated: [Tgetwritebufferproc: getwritebufferproc].}
{.deprecated: [Thashfunc: hashfunc].}
{.deprecated: [Tinitproc: initproc].}
{.deprecated: [Tinquiry: inquiry].}
{.deprecated: [Tintargfunc: intargfunc].}
{.deprecated: [Tintintargfunc: intintargfunc].}
{.deprecated: [Tintintobjargproc: intintobjargproc].}
{.deprecated: [Tintobjargproc: intobjargproc].}
{.deprecated: [PInt: IntPtr].}
{.deprecated: [Titernextfunc: iternextfunc].}
{.deprecated: [Tnewfunc: newfunc].}
{.deprecated: [Tnode: node].}
{.deprecated: [PNode: NodePtr].}
{.deprecated: [Tobjobjargproc: objobjargproc].}
{.deprecated: [Tobjobjproc: objobjproc].}
{.deprecated: [TPFlag: PFlag].}
{.deprecated: [TPFlags: PFlags].}
{.deprecated: [Tprintfunc: printfunc].}
{.deprecated: [pwrapperbase: wrapperbasePtr].}
{.deprecated: [TPy_complex: Py_complex].}
{.deprecated: [TPyBufferProcs: PyBufferProcs].}
{.deprecated: [PPyBufferProcs: PyBufferProcsPtr].}
{.deprecated: [TPyCFunction: PyCFunction].}
{.deprecated: [TPyClassObject: PyClassObject].}
{.deprecated: [PPyClassObject: PyClassObjectPtr].}
{.deprecated: [TPyCodeObject: PyCodeObject].}
{.deprecated: [PPyCodeObject: PyCodeObjectPtr].}
{.deprecated: [TPyDateTime_BaseDateTime: PyDateTime_BaseDateTime].}
{.deprecated: [PPyDateTime_BaseDateTime: PyDateTime_BaseDateTimePtr].}
{.deprecated: [TPyDateTime_BaseTime: PyDateTime_BaseTime].}
{.deprecated: [PPyDateTime_BaseTime: PyDateTime_BaseTimePtr].}
{.deprecated: [TPyDateTime_BaseTZInfo: PyDateTime_BaseTZInfo].}
{.deprecated: [PPyDateTime_BaseTZInfo: PyDateTime_BaseTZInfoPtr].}
{.deprecated: [TPyDateTime_Date: PyDateTime_Date].}
{.deprecated: [PPyDateTime_Date: PyDateTime_DatePtr].}
{.deprecated: [TPyDateTime_DateTime: PyDateTime_DateTime].}
{.deprecated: [PPyDateTime_DateTime: PyDateTime_DateTimePtr].}
{.deprecated: [TPyDateTime_Delta: PyDateTime_Delta].}
{.deprecated: [PPyDateTime_Delta: PyDateTime_DeltaPtr].}
{.deprecated: [TPyDateTime_Time: PyDateTime_Time].}
{.deprecated: [PPyDateTime_Time: PyDateTime_TimePtr].}
{.deprecated: [TPyDateTime_TZInfo: PyDateTime_TZInfo].}
{.deprecated: [PPyDateTime_TZInfo: PyDateTime_TZInfoPtr].}
{.deprecated: [TPyDescrObject: PyDescrObject].}
{.deprecated: [PPyDescrObject: PyDescrObjectPtr].}
{.deprecated: [Tpydestructor: pydestructor].}
{.deprecated: [TPyFrameObject: PyFrameObject].}
{.deprecated: [PPyFrameObject: PyFrameObjectPtr].}
{.deprecated: [TPyGetSetDef: PyGetSetDef].}
{.deprecated: [PPyGetSetDef: PyGetSetDefPtr].}
{.deprecated: [TPyGetSetDescrObject: PyGetSetDescrObject].}
{.deprecated: [PPyGetSetDescrObject: PyGetSetDescrObjectPtr].}
{.deprecated: [TPyInstanceObject: PyInstanceObject].}
{.deprecated: [PPyInstanceObject: PyInstanceObjectPtr].}
{.deprecated: [TPyInterpreterState: PyInterpreterState].}
{.deprecated: [PPyInterpreterState: PyInterpreterStatePtr].}
{.deprecated: [TPyIntObject: PyIntObject].}
{.deprecated: [PPyIntObject: PyIntObjectPtr].}
{.deprecated: [TPyMappingMethods: PyMappingMethods].}
{.deprecated: [PPyMappingMethods: PyMappingMethodsPtr].}
{.deprecated: [TPyMemberDef: PyMemberDef].}
{.deprecated: [PPyMemberDef: PyMemberDefPtr].}
{.deprecated: [TPyMemberDescrObject: PyMemberDescrObject].}
{.deprecated: [PPyMemberDescrObject: PyMemberDescrObjectPtr].}
{.deprecated: [TPyMemberFlag: PyMemberFlag].}
{.deprecated: [TPyMemberType: PyMemberType].}
{.deprecated: [TPyMethodChain: PyMethodChain].}
{.deprecated: [PPyMethodChain: PyMethodChainPtr].}
{.deprecated: [TPyMethodDef: PyMethodDef].}
{.deprecated: [PPyMethodDef: PyMethodDefPtr].}
{.deprecated: [TPyMethodDescrObject: PyMethodDescrObject].}
{.deprecated: [PPyMethodDescrObject: PyMethodDescrObjectPtr].}
{.deprecated: [TPyMethodObject: PyMethodObject].}
{.deprecated: [PPyMethodObject: PyMethodObjectPtr].}
{.deprecated: [TPyNumberMethods: PyNumberMethods].}
{.deprecated: [PPyNumberMethods: PyNumberMethodsPtr].}
{.deprecated: [TPyObject: PyObject].}
{.deprecated: [PPyObject: PyObjectPtr].}
{.deprecated: [PPPyObject: PyObjectPtrPtr].}
{.deprecated: [PPPPyObject: PyObjectPtrPtrPtr].}
{.deprecated: [TPySequenceMethods: PySequenceMethods].}
{.deprecated: [PPySequenceMethods: PySequenceMethodsPtr].}
{.deprecated: [TPySliceObject: PySliceObject].}
{.deprecated: [PPySliceObject: PySliceObjectPtr].}
{.deprecated: [TPyThreadState: PyThreadState].}
{.deprecated: [PPyThreadState: PyThreadStatePtr].}
{.deprecated: [TPyTraceBackObject: PyTraceBackObject].}
{.deprecated: [PPyTraceBackObject: PyTraceBackObjectPtr].}
{.deprecated: [TPyTryBlock: PyTryBlock].}
{.deprecated: [PPyTryBlock: PyTryBlockPtr].}
{.deprecated: [TPyTypeObject: PyTypeObject].}
{.deprecated: [PPyTypeObject: PyTypeObjectPtr].}
{.deprecated: [TPyWeakReference: PyWeakReference].}
{.deprecated: [PPyWeakReference: PyWeakReferencePtr].}
{.deprecated: [TPyWrapperDescrObject: PyWrapperDescrObject].}
{.deprecated: [PPyWrapperDescrObject: PyWrapperDescrObjectPtr].}
{.deprecated: [Treprfunc: reprfunc].}
{.deprecated: [Trichcmpfunc: richcmpfunc].}
{.deprecated: [TRichComparisonOpcode: RichComparisonOpcode].}
{.deprecated: [Tsetattrfunc: setattrfunc].}
{.deprecated: [Tsetattrofunc: setattrofunc].}
{.deprecated: [Tsetter: setter].}
{.deprecated: [Tternaryfunc: ternaryfunc].}
{.deprecated: [Ttraverseproc: traverseproc].}
{.deprecated: [Tunaryfunc: unaryfunc].}
{.deprecated: [Tvisitproc: visitproc].}
{.deprecated: [Twrapperbase: wrapperbase].}
{.deprecated: [Twrapperfunc: wrapperfunc].}