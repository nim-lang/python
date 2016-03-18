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
  tMethodBufferIncrease* = 10
  tMemberBufferIncrease* = 10
  tGetsetBufferIncrease* = 10
  # Flag passed to newmethodobject
  methOldargs* = 0x0000
  methVarargs* = 0x0001
  methKeywords* = 0x0002
  methNoargs* = 0x0004
  methO* = 0x0008
  methClass* = 0x0010
  methStatic* = 0x0020
  methCoexist* = 0x0040
  # Masks for the co_flags field of PyCodeObject
  coOptimized* = 0x0001
  coNewlocals* = 0x0002
  coVarargs* = 0x0004
  coVarkeywords* = 0x0008
  coNested* = 0x0010
  coGenerator* = 0x0020
  coFutureDivision* = 0x2000
  coFutureAbsoluteImport* = 0x4000
  coFutureWithStatement* = 0x8000
  coFuturePrintFunction* = 0x10000
  coFutureUnicodeLiterals* = 0x20000
{.deprecated: [PYT_METHOD_BUFFER_INCREASE: tMethodBufferIncrease].}
{.deprecated: [PYT_MEMBER_BUFFER_INCREASE: tMemberBufferIncrease].}
{.deprecated: [PYT_GETSET_BUFFER_INCREASE: tGetsetBufferIncrease].}
{.deprecated: [METH_OLDARGS: methOldargs].}
{.deprecated: [METH_VARARGS: methVarargs].}
{.deprecated: [METH_KEYWORDS: methKeywords].}
{.deprecated: [METH_NOARGS: methNoargs].}
{.deprecated: [METH_O: methO].}
{.deprecated: [METH_CLASS: methClass].}
{.deprecated: [METH_STATIC: methStatic].}
{.deprecated: [METH_COEXIST: methCoexist].}
{.deprecated: [CO_OPTIMIZED: coOptimized].}
{.deprecated: [CO_NEWLOCALS: coNewlocals].}
{.deprecated: [CO_VARARGS: coVarargs].}
{.deprecated: [CO_VARKEYWORDS: coVarkeywords].}
{.deprecated: [CO_NESTED: coNested].}
{.deprecated: [CO_GENERATOR: coGenerator].}
{.deprecated: [CO_FUTURE_DIVISION: coFutureDivision].}
{.deprecated: [CO_FUTURE_ABSOLUTE_IMPORT: coFutureAbsoluteImport].}
{.deprecated: [CO_FUTURE_WITH_STATEMENT: coFutureWithStatement].}
{.deprecated: [CO_FUTURE_PRINT_FUNCTION: coFuturePrintFunction].}
{.deprecated: [CO_FUTURE_UNICODE_LITERALS: coFutureUnicodeLiterals].}

type                          
  # Rich comparison opcodes introduced in version 2.1
  RichComparisonOpcode* = enum 
    rcoLT, rcoLE, rcoEQ, rcoNE, rcoGT, rcoGE

const
  # PySequenceMethods contains sq_contains
  tpflagsHaveGetCharBuffer* = (1 shl 0)
  # Objects which participate in garbage collection (see objimp.h)
  tpflagsHaveSequenceIn* = (1 shl 1)
  # PySequenceMethods and PyNumberMethods contain in-place operators
  tpflagsGc* = (1 shl 2)
  # PyNumberMethods do their own Coercion
  tpflagsHaveInplaceops* = (1 shl 3)
  tpflagsCheckTypes* = (1 shl 4)
  # Objects which are weakly referencable if their tp_weaklistoffset is > 0
  # XXX Should this have the same value as Py_TPFLAGS_HAVE_RICHCOMPARE?
  # These both indicate a feature that appeared in the same alpha release.
  tpflagsHaveRichCompare* = (1 shl 5)
  # tp_iter is defined
  tpflagsHaveWeakRefs* = (1 shl 6)
  # New members introduced by Python 2.2 exist
  tpflagsHaveIter* = (1 shl 7)
  # Set if the type object is dynamically allocated
  tpflagsHaveClass* = (1 shl 8)
  # Set if the type allows subclassing
  tpflagsHeapType* = (1 shl 9)
  # Set if the type is 'ready' -- fully initialized
  tpflagsBaseType* = (1 shl 10)
  # Set while the type is being 'readied', to prevent recursive ready calls
  tpflagsReady* = (1 shl 12)
  # Objects support garbage collection (see objimp.h)
  tpflagsReadying* = (1 shl 13)
  tpflagsHaveGc* = (1 shl 14)
  tpflagsDefault* = tpflagsHaveGetCharBuffer or
                    tpflagsHaveSequenceIn or
                    tpflagsHaveInplaceops or
                    tpflagsHaveRichCompare or 
                    tpflagsHaveWeakRefs or
                    tpflagsHaveIter or 
                    tpflagsHaveClass
{.deprecated: [Py_TPFLAGS_HAVE_GETCHARBUFFER: tpflagsHaveGetCharBuffer].}
{.deprecated: [Py_TPFLAGS_HAVE_SEQUENCE_IN: tpflagsHaveSequenceIn].}
{.deprecated: [Py_TPFLAGS_GC: tpflagsGc].}
{.deprecated: [Py_TPFLAGS_HAVE_INPLACEOPS: tpflagsHaveInplaceops].}
{.deprecated: [Py_TPFLAGS_CHECKTYPES: tpflagsCheckTypes].}
{.deprecated: [Py_TPFLAGS_HAVE_RICHCOMPARE: tpflagsHaveRichCompare].}
{.deprecated: [Py_TPFLAGS_HAVE_WEAKREFS: tpflagsHaveWeakRefs].}
{.deprecated: [Py_TPFLAGS_HAVE_ITER: tpflagsHaveIter].}
{.deprecated: [Py_TPFLAGS_HAVE_CLASS: tpflagsHaveClass].}
{.deprecated: [Py_TPFLAGS_HEAPTYPE: tpflagsHeapType].}
{.deprecated: [Py_TPFLAGS_BASETYPE: tpflagsBaseType].}
{.deprecated: [Py_TPFLAGS_READY: tpflagsReady].}
{.deprecated: [Py_TPFLAGS_READYING: tpflagsReadying].}
{.deprecated: [Py_TPFLAGS_HAVE_GC: tpflagsHaveGc].}
{.deprecated: [Py_TPFLAGS_DEFAULT: tpflagsDefault].}

type 
  PFlag* = enum 
    tpfHaveGetCharBuffer, tpfHaveSequenceIn, tpfGC, tpfHaveInplaceOps, 
    tpfCheckTypes, tpfHaveRichCompare, tpfHaveWeakRefs, tpfHaveIter, 
    tpfHaveClass, tpfHeapType, tpfBaseType, tpfReady, tpfReadying, tpfHaveGC
  PFlags* = set[PFlag]

const 
  tpflagsDefaultSet* = {tpfHaveGetCharBuffer, tpfHaveSequenceIn, 
    tpfHaveInplaceOps, tpfHaveRichCompare, tpfHaveWeakRefs, tpfHaveIter, 
    tpfHaveClass}
{.deprecated: [TPFLAGS_DEFAULT: tpflagsDefault].}

const # Python opcodes
  singleInput* = 256 
  fileInput* = 257
  evalInput* = 258
  funcdef* = 259
  parameters* = 260
  varargslist* = 261
  fpdef* = 262
  fplist* = 263
  statement* = 264
  simpleStmt* = 265
  smallStmt* = 266
  exprStmt* = 267
  augassign* = 268
  printStmt* = 269
  delStmt* = 270
  passStmt* = 271
  flowStmt* = 272
  breakStmt* = 273
  continueStmt* = 274
  returnStmt* = 275
  raiseStmt* = 276
  importStmt* = 277
  importAsName* = 278
  dottedAsName* = 279
  dottedName* = 280
  globalStmt* = 281
  execStmt* = 282
  assertStmt* = 283
  compoundStmt* = 284
  ifStmt* = 285
  whileStmt* = 286
  forStmt* = 287
  tryStmt* = 288
  exceptClause* = 289
  suite* = 290
  test* = 291
  andTest* = 291
  notTest* = 293
  comparison* = 294
  compOp* = 295
  expression* = 296
  xorExpr* = 297
  andExpr* = 298
  shiftExpr* = 299
  arithExpr* = 300
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
  listIter* = 317
  listFor* = 318
  listIf* = 319

const 
  tShort* = 0
  tInt* = 1
  tLong* = 2
  tFloat* = 3
  tDouble* = 4
  tString* = 5
  tObject* = 6
  tChar* = 7                 # 1-character string
  tByte* = 8                 # 8-bit signed int
  tUbyte* = 9
  tUshort* = 10
  tUint* = 11
  tUlong* = 12
  tStringInplace* = 13
  tObjectEx* = 16 
  readonly* = 1
  ro* = readonly              # Shorthand 
  readRestricted* = 2
  writeRestricted* = 4
  restricted* = (readRestricted or writeRestricted)
{.deprecated: [T_SHORT: tShort].}
{.deprecated: [T_INT: tInt].}
{.deprecated: [T_LONG: tLong].}
{.deprecated: [T_FLOAT: tFloat].}
{.deprecated: [T_DOUBLE: tDouble].}
{.deprecated: [T_STRING: tString].}
{.deprecated: [T_OBJECT: tObject].}
{.deprecated: [T_CHAR: tChar].}
{.deprecated: [T_BYTE: tByte].}
{.deprecated: [T_UBYTE: tUbyte].}
{.deprecated: [T_USHORT: tUshort].}
{.deprecated: [T_UINT: tUint].}
{.deprecated: [T_ULONG: tUlong].}
{.deprecated: [T_STRING_INPLACE: tStringInplace].}
{.deprecated: [T_OBJECT_EX: tObjectEx].}
{.deprecated: [READ_RESTRICTED: readRestricted].}
{.deprecated: [WRITE_RESTRICTED: writeRestricted].}

type 
  PyMemberType* = enum 
    mtShort, mtInt, mtLong, mtFloat, mtDouble, mtString, mtObject, mtChar, 
    mtByte, mtUByte, mtUShort, mtUInt, mtULong, mtStringInplace, mtObjectEx
  
  PyMemberFlag* = enum 
    mfDefault, mfReadOnly, mfReadRestricted, mfWriteRestricted, mfRestricted
  
  IntPtr* = ptr int
  
type
  CstringPtr* = ptr cstring
  FrozenPtrPtr* = ptr Frozen
  FrozenPtr* = ptr Frozen
  PyObjectPtr* = ptr PyObject
  PyObjectPtrPtr* = ptr PyObjectPtr
  PyObjectPtrPtrPtr* = ptr PyObjectPtrPtr
  PyIntObjectPtr* = ptr PyIntObject
  PyTypeObjectPtr* = ptr PyTypeObject
  PySliceObjectPtr* = ptr PySliceObject
  PyCFunction* = proc (self, args: PyObjectPtr): PyObjectPtr{.cdecl.}
  UnaryFunc* = proc (ob1: PyObjectPtr): PyObjectPtr{.cdecl.}
  BinaryFunc* = proc (ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl.}
  TernaryFunc* = proc (ob1, ob2, ob3: PyObjectPtr): PyObjectPtr{.cdecl.}
  Inquiry* = proc (ob1: PyObjectPtr): int{.cdecl.}
  Coercion* = proc (ob1, ob2: PyObjectPtrPtr): int{.cdecl.}
  IntArgFunc* = proc (ob1: PyObjectPtr, i: int): PyObjectPtr{.cdecl.}
  IntIntArgFunc* = proc (ob1: PyObjectPtr, i1, i2: int): PyObjectPtr{.cdecl.}
  IntObjArgProc* = proc (ob1: PyObjectPtr, i: int, 
                         ob2: PyObjectPtr): int{.cdecl.}
  IntIntObjArgProc* = proc (ob1: PyObjectPtr, i1, i2: int, 
                            ob2: PyObjectPtr): int{.cdecl.}
  ObjObjargProc* = proc (ob1, ob2, ob3: PyObjectPtr): int{.cdecl.}
  PyDestructor* = proc (ob: PyObjectPtr){.cdecl.}
  PrintFunc* = proc (ob: PyObjectPtr, f: File, i: int): int{.cdecl.}
  GetAttrFunc* = proc (ob1: PyObjectPtr, name: cstring): PyObjectPtr{.cdecl.}
  SetAttrFunc* = proc (ob1: PyObjectPtr, name: cstring, 
                       ob2: PyObjectPtr): int{.cdecl.}
  CmpFunc* = proc (ob1, ob2: PyObjectPtr): int{.cdecl.}
  ReprFunc* = proc (ob: PyObjectPtr): PyObjectPtr{.cdecl.}
  HashFunc* = proc (ob: PyObjectPtr): int32{.cdecl.}
  GetAttroFunc* = proc (ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl.}
  SetAttroFunc* = proc (ob1, ob2, ob3: PyObjectPtr): int{.cdecl.} 
  GetReadBufferProc* = proc (ob1: PyObjectPtr, i: int, p: pointer): int{.cdecl.}
  GetWriteBufferProc* = proc (ob1: PyObjectPtr, i: int, 
                              p: pointer): int{.cdecl.}
  GetSegCountProc* = proc (ob1: PyObjectPtr, i: int): int{.cdecl.}
  GetCharBufferProc* = proc (ob1: PyObjectPtr, 
                             i: int, pstr: cstring): int{.cdecl.}
  ObjObjProc* = proc (ob1, ob2: PyObjectPtr): int{.cdecl.}
  VisitProc* = proc (ob1: PyObjectPtr, p: pointer): int{.cdecl.}
  TraverseProc* = proc (ob1: PyObjectPtr, prc: VisitProc, 
                        p: pointer): int{.cdecl.}
  RichCmpFunc* = proc (ob1, ob2: PyObjectPtr, i: int): PyObjectPtr{.cdecl.}
  GetIterFunc* = proc (ob1: PyObjectPtr): PyObjectPtr{.cdecl.}
  IterNextFunc* = proc (ob1: PyObjectPtr): PyObjectPtr{.cdecl.}
  DescrGetFunc* = proc (ob1, ob2, ob3: PyObjectPtr): PyObjectPtr{.cdecl.}
  DescrSetFunc* = proc (ob1, ob2, ob3: PyObjectPtr): int{.cdecl.}
  InitProc* = proc (self, args, kwds: PyObjectPtr): int{.cdecl.}
  NewFunc* = proc (subtype: PyTypeObjectPtr, 
                   args, kwds: PyObjectPtr): PyObjectPtr{.cdecl.}
  AllocFunc* = proc (self: PyTypeObjectPtr, nitems: int): PyObjectPtr{.cdecl.}
  PyNumberMethods*{.final.} = object 
    nbAdd*: BinaryFunc
    nbSubstract*: BinaryFunc
    nbMultiply*: BinaryFunc
    nbDivide*: BinaryFunc
    nbRemainder*: BinaryFunc
    nbDivmod*: BinaryFunc
    nbPower*: TernaryFunc
    nbNegative*: UnaryFunc
    nbPositive*: UnaryFunc
    nbAbsolute*: UnaryFunc
    nbNonzero*: Inquiry
    nbInvert*: UnaryFunc
    nbLshift*: BinaryFunc
    nbRshift*: BinaryFunc
    nbAnd*: BinaryFunc
    nbXor*: BinaryFunc
    nbOr*: BinaryFunc
    nbCoerce*: Coercion
    nbInt*: UnaryFunc
    nbLong*: UnaryFunc
    nbFloat*: UnaryFunc
    nbOct*: UnaryFunc
    nbHex*: UnaryFunc       
    # jah 29-sep-2000: updated for python 2.0 added from .h
    nbInplaceAdd*: BinaryFunc
    nbInplaceSubtract*: BinaryFunc
    nbInplaceMultiply*: BinaryFunc
    nbInplaceDivide*: BinaryFunc
    nbInplaceRemainder*: BinaryFunc
    nbInplacePower*: TernaryFunc
    nbInplaceLshift*: BinaryFunc
    nbInplaceRshift*: BinaryFunc
    nbInplaceAnd*: BinaryFunc
    nbInplaceXor*: BinaryFunc
    nbInplaceOr*: BinaryFunc 
    # Added in release 2.2
    # The following require the tpflagsHaveClass flag
    nbFloorDivide*: BinaryFunc
    nbTrueDivide*: BinaryFunc
    nbInplaceFloorDivide*: BinaryFunc
    nbInplaceTrueDivide*: BinaryFunc

  PyNumberMethodsPtr* = ptr PyNumberMethods
  PySequenceMethods*{.final.} = object 
    sqLength*: Inquiry
    sqConcat*: BinaryFunc
    sqRepeat*: IntArgFunc
    sqItem*: IntArgFunc
    sqSlice*: IntIntArgFunc
    sqAssItem*: IntObjArgProc
    sqAssSlice*: IntIntObjArgProc 
    sqContains*: ObjObjProc
    sqInplaceConcat*: BinaryFunc
    sqInplaceRepeat*: IntArgFunc

  PySequenceMethodsPtr* = ptr PySequenceMethods
  PyMappingMethods*{.final.} = object 
    mpLength*: Inquiry
    mpSubscript*: BinaryFunc
    mpAssSubscript*: ObjObjargProc

  PyMappingMethodsPtr* = ptr PyMappingMethods 
  PyBufferProcs*{.final.} = object 
    bfGetreadbuffer*: GetReadBufferProc
    bfGetwritebuffer*: GetWriteBufferProc
    bfGetsegcount*: GetSegCountProc
    bfGetcharbuffer*: GetCharBufferProc

  PyBufferProcsPtr* = ptr PyBufferProcs
  PyComplex*{.final.} = object 
    float*: float64
    imag*: float64

  PyObject*{.pure, inheritable.} = object 
    obRefcnt*: int
    obType*: PyTypeObjectPtr

  PyIntObject* = object of RootObj
    obIval*: int32

  BytePtr* = ptr int8
  Frozen*{.final.} = object 
    name*: cstring
    code*: BytePtr
    size*: int

  PySliceObject* = object of PyObject
    start*, stop*, step*: PyObjectPtr

  PyMethodDefPtr* = ptr PyMethodDef
  PyMethodDef*{.final.} = object  # structmember.h
    mlName*: cstring
    mlMeth*: PyCFunction
    mlFlags*: int
    mlDoc*: cstring

  PyMemberDefPtr* = ptr PyMemberDef
  PyMemberDef*{.final.} = object  # descrobject.h Descriptors
    name*: cstring
    theType*: int
    offset*: int
    flags*: int
    doc*: cstring

  Getter* = proc (obj: PyObjectPtr, context: pointer): PyObjectPtr{.cdecl.}
  Setter* = proc (obj, value: PyObjectPtr, context: pointer): int{.cdecl.}
  PyGetSetDefPtr* = ptr PyGetSetDef
  PyGetSetDef*{.final.} = object 
    name*: cstring
    get*: Getter
    Setter*: Setter
    doc*: cstring
    closure*: pointer

  wrapperfunc* = proc (self, args: PyObjectPtr, 
                       wrapped: pointer): PyObjectPtr{.cdecl.}
  wrapperbasePtr* = ptr wrapperbase

  # Various kinds of descriptor objects
  # #define PyDescr_COMMON \
  #          PyObject_HEAD \
  #          PyTypeObject *d_type; \
  #          PyObject *d_name
  wrapperbase*{.final.} = object
    name*: cstring
    wrapper*: wrapperfunc
    doc*: cstring

  PyDescrObjectPtr* = ptr PyDescrObject
  PyDescrObject* = object of PyObject
    dType*: PyTypeObjectPtr
    dName*: PyObjectPtr

  PyMethodDescrObjectPtr* = ptr PyMethodDescrObject
  PyMethodDescrObject* = object of PyDescrObject
    dMethod*: PyMethodDefPtr

  PyMemberDescrObjectPtr* = ptr PyMemberDescrObject
  PyMemberDescrObject* = object of PyDescrObject
    dMember*: PyMemberDefPtr

  PyGetSetDescrObjectPtr* = ptr PyGetSetDescrObject
  PyGetSetDescrObject* = object of PyDescrObject
    dGetset*: PyGetSetDefPtr

  PyWrapperDescrObjectPtr* = ptr PyWrapperDescrObject
  PyWrapperDescrObject* = object of PyDescrObject # object.h
    dBase*: wrapperbasePtr
    dWrapped*: pointer       # This can be any function pointer
  
  PyTypeObject* = object of PyObject
    obSize*: int             # Number of items in variable part
    tpName*: cstring         # For printing
    tpBasicsize*, tpItemsize*: int # For allocation
    # Methods to implement standard operations
    tpDealloc*: PyDestructor
    tpPrint*: PrintFunc
    tpGetattr*: GetAttrFunc
    tpSetattr*: SetAttrFunc
    tpCompare*: CmpFunc
    tpRepr*: ReprFunc
    # Method suites for standard classes
    tpAsNumber*: PyNumberMethodsPtr
    tpAsSequence*: PySequenceMethodsPtr
    # More standard operations (here for binary compatibility)
    tpAsMapping*: PyMappingMethodsPtr
    tpHash*: HashFunc
    tpCall*: TernaryFunc
    tpStr*: ReprFunc
    tpGetattro*: GetAttroFunc
    tpSetattro*: SetAttroFunc
    # Functions to access object as input/output buffer
    tpAsBuffer*: PyBufferProcsPtr
    # Flags to define presence of optional/expanded features
    tpFlags*: int32
    # Documentation string
    tpDoc*: cstring
    # call function for all accessible objects
    tpTraverse*: TraverseProc
    # delete references to contained objects
    tpClear*: Inquiry
    # rich comparisons
    tpRichcompare*: RichCmpFunc
    # weak reference enabler
    tpWeaklistoffset*: int32
    # Iterators
    tpIter*: GetIterFunc
    tpIternext*: IterNextFunc
    # Attribute descriptor and subclassing stuff
    tpMethods*: PyMethodDefPtr
    tpMembers*: PyMemberDefPtr
    tpGetset*: PyGetSetDefPtr
    tpBase*: PyTypeObjectPtr
    tpDict*: PyObjectPtr
    tpDescrGet*: DescrGetFunc
    tpDescrSet*: DescrSetFunc
    tpDictoffset*: int32
    tpInit*: InitProc
    tpAlloc*: AllocFunc
    tpNew*: NewFunc
    tpFree*: PyDestructor   # Low-level free-memory routine
    tpIsGc*: Inquiry       # For PyObject_IS_GC
    tpBases*: PyObjectPtr
    tpMro*: PyObjectPtr        # method resolution order
    tpCache*: PyObjectPtr
    tpSubclasses*: PyObjectPtr
    tpWeaklist*: PyObjectPtr
    #More spares
    tpXxx7*: pointer
    tpXxx8*: pointer

  PyMethodChainPtr* = ptr PyMethodChain
  PyMethodChain*{.final.} = object 
    methods*: PyMethodDefPtr
    link*: PyMethodChainPtr

  PyClassObjectPtr* = ptr PyClassObject
  PyClassObject* = object of PyObject
    clBases*: PyObjectPtr      # A tuple of class objects
    clDict*: PyObjectPtr       # A dictionary
    clName*: PyObjectPtr       # A string
    # The following three are functions or NULL
    clGetattr*: PyObjectPtr
    clSetattr*: PyObjectPtr
    clDelattr*: PyObjectPtr

  PyInstanceObjectPtr* = ptr PyInstanceObject
  PyInstanceObject* = object of PyObject 
    inClass*: PyClassObjectPtr # The class object
    inDict*: PyObjectPtr       # A dictionary
  
  PyMethodObjectPtr* = ptr PyMethodObject
  PyMethodObject* = object of PyObject # Bytecode object, compile.h
    imFunc*: PyObjectPtr       # The function implementing the method
    imSelf*: PyObjectPtr       # The instance it is bound to, or NULL
    imClass*: PyObjectPtr      # The class that defined the method
  
  PyCodeObjectPtr* = ptr PyCodeObject
  PyCodeObject* = object of PyObject # from pystate.h
    coArgcount*: int         # #arguments, except *args
    coNlocals*: int          # #local variables
    coStacksize*: int        # #entries needed for evaluation stack
    coFlags*: int            # CO_..., see below
    coCode*: PyObjectPtr       # instruction opcodes (it hides a PyStringObject)
    coConsts*: PyObjectPtr     # list (constants used)
    coNames*: PyObjectPtr      # list of strings (names used)
    coVarnames*: PyObjectPtr   # tuple of strings (local variable names)
    coFreevars*: PyObjectPtr   # tuple of strings (free variable names)
    coCellvars*: PyObjectPtr   # tuple of strings (cell variable names)
    # The rest doesn't count for hash/cmp
    coFilename*: PyObjectPtr   # string (where it was loaded from)
    coName*: PyObjectPtr       # string (name, for reference)
    coFirstlineno*: int      # first source line number
    coLnotab*: PyObjectPtr     # string (encoding addr<->lineno mapping)
  
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
    recursionDepth*: int
    ticker*: int
    tracing*: int
    sysProfilefunc*: PyObjectPtr
    sysTracefunc*: PyObjectPtr
    curexcType*: PyObjectPtr
    curexcValue*: PyObjectPtr
    curexcTraceback*: PyObjectPtr
    excType*: PyObjectPtr
    excValue*: PyObjectPtr
    excTraceback*: PyObjectPtr
    dict*: PyObjectPtr

  PyTryBlockPtr* = ptr PyTryBlock
  PyTryBlock*{.final.} = object 
    bType*: int              # what kind of block this is
    bHandler*: int           # where to jump to find handler
    bLevel*: int             # value stack level to pop to
  
  coMaxblocks* = range[0..19]
  PyFrameObject* = object of PyObject # start of the VAR_HEAD of an object
    # From traceback.c
    obSize*: int             # Number of items in variable part
    # End of the Head of an object
    fBack*: PyFrameObjectPtr   # previous frame, or NULL
    fCode*: PyCodeObjectPtr    # code segment
    fBuiltins*: PyObjectPtr    # builtin symbol table (PyDictObject)
    fGlobals*: PyObjectPtr     # global symbol table (PyDictObject)
    fLocals*: PyObjectPtr      # local symbol table (PyDictObject)
    fValuestack*: PyObjectPtrPtr # points after the last local
                                 # Next free slot in fValuestack.
                                 # Frame creation sets to fValuestack.
                                 # Frame evaluation usually NULLs it, 
                                 # but a frame that yields sets it
                                 # to the current stack top. 
    fStacktop*: PyObjectPtrPtr
    fTrace*: PyObjectPtr       # Trace function
    fExcType*, fExcValue*, fExcTraceback*: PyObjectPtr
    fTstate*: PyThreadStatePtr
    fLasti*: int             # Last instruction if called
    fLineno*: int            # Current line number
    fRestricted*: int        # Flag set if restricted operations
                              # in this scope
    fIblock*: int            # index in f_blockstack
    fBlockstack*: array[coMaxblocks, PyTryBlock] # for try and loop blocks
    fNlocals*: int           # number of locals
    fNcells*: int
    fNfreevars*: int
    fStacksize*: int         # size of value stack
    fLocalsplus*: array[0..0, PyObjectPtr] # locals+stack, dynamically sized
  
  PyTraceBackObjectPtr* = ptr PyTraceBackObject
  PyTraceBackObject* = object of PyObject # Parse tree node interface
    tbNext*: PyTraceBackObjectPtr
    tbFrame*: PyFrameObjectPtr
    tbLasti*: int
    tbLineno*: int

  NodePtr* = ptr Node
  Node*{.final.} = object    # From weakrefobject.h
    nType*: int16
    nStr*: cstring
    nLineno*: int16
    nNchildren*: int16
    nChild*: NodePtr

  PyWeakReferencePtr* = ptr PyWeakReference
  PyWeakReference* = object of PyObject 
    wr_object*: PyObjectPtr
    wr_callback*: PyObjectPtr
    hash*: int32
    wr_prev*: PyWeakReferencePtr
    wr_next*: PyWeakReferencePtr
{.deprecated: [CO_MAXBLOCKS: coMaxblocks].}

const                         
  pydatetimeDateDatasize* = 4 # of bytes for year, month, and day
  pydatetimeTimeDatasize* = 6 # of bytes for hour, minute, second, and usecond
  pydatetimeDatetimeDatasize* = 10 # of bytes for year, month, 
                                   # day, hour, minute, second, and usecond.
{.deprecated: [PyDateTime_DATE_DATASIZE: pydatetimeDateDatasize].}
{.deprecated: [PyDateTime_TIME_DATASIZE: pydatetimeTimeDatasize].}
{.deprecated: [PyDateTime_DATETIME_DATASIZE: pydatetimeDatetimeDatasize].}

type 
  PyDateTimeDelta* = object of PyObject
    hashcode*: int            # -1 when unknown
    days*: int                # -MAX_DELTA_DAYS <= days <= MAX_DELTA_DAYS
    seconds*: int             # 0 <= seconds < 24*3600 is invariant
    microseconds*: int        # 0 <= microseconds < 1000000 is invariant
  
  PyDateTimeDeltaPtr* = ptr PyDateTimeDelta
  PyDateTimeTZInfo* = object of PyObject # a pure abstract base clase
  PyDateTimeTZInfoPtr* = ptr PyDateTimeTZInfo 
  PyDateTimeBaseTZInfo* = object of PyObject
    hashcode*: int
    # boolean flag
    hastzinfo*: bool
  
  PyDateTimeBaseTZInfoPtr* = ptr PyDateTimeBaseTZInfo 
  PyDateTimeBaseTime* = object of PyDateTimeBaseTZInfo
    data*: array[0..pred(pydatetimeTimeDatasize), int8]

  PyDateTimeBaseTimePtr* = ptr PyDateTimeBaseTime
  PyDateTimeTime* = object of PyDateTimeBaseTime # hastzinfo true
    tzinfo*: PyObjectPtr

  PyDateTimeTimePtr* = ptr PyDateTimeTime 
  PyDateTimeDate* = object of PyDateTimeBaseTZInfo
    data*: array[0..pred(pydatetimeDateDatasize), int8]

  PyDateTimeDatePtr* = ptr PyDateTimeDate 
  PyDateTimeBaseDateTime* = object of PyDateTimeBaseTZInfo
    data*: array[0..pred(pydatetimeDatetimeDatasize), int8]

  PyDateTimeBaseDateTimePtr* = ptr PyDateTimeBaseDateTime
  PyDateTimeDateTime* = object of PyDateTimeBaseTZInfo
    data*: array[0..pred(pydatetimeDatetimeDatasize), int8]
    tzinfo*: PyObjectPtr

  PyDateTimeDateTimePtr* = ptr PyDateTimeDateTime

## Deprecated type definitions
{.deprecated: [TAllocFunc: AllocFunc].}
{.deprecated: [TBinaryFunc: BinaryFunc].}
{.deprecated: [PByte: BytePtr].}
{.deprecated: [TCmpFunc: CmpFunc].}
{.deprecated: [TCO_MAXBLOCKS: coMaxblocks].}
{.deprecated: [TCoercion: Coercion].}
{.deprecated: [TDescrGetFunc: DescrGetFunc].}
{.deprecated: [TDescrSetFunc: DescrSetFunc].}
{.deprecated: [Tfrozen: Frozen].}
{.deprecated: [P_frozen: FrozenPtr].}
{.deprecated: [PP_frozen: FrozenPtrPtr].}
{.deprecated: [TGetAttrFunc: GetAttrFunc].}
{.deprecated: [TGetAttroFunc: GetAttroFunc].}
{.deprecated: [TGetCharBufferProc: GetCharBufferProc].}
{.deprecated: [TGetIterFunc: GetIterFunc].}
{.deprecated: [TGetReadBufferProc: GetReadBufferProc].}
{.deprecated: [TGetSegCountProc: GetSegCountProc].}
{.deprecated: [TGetter: Getter].}
{.deprecated: [TGetWriteBufferProc: GetWriteBufferProc].}
{.deprecated: [THashFunc: HashFunc].}
{.deprecated: [TInitProc: InitProc].}
{.deprecated: [TInquiry: Inquiry].}
{.deprecated: [TIntArgFunc: IntArgFunc].}
{.deprecated: [TIntIntArgFunc: IntIntArgFunc].}
{.deprecated: [TIntIntObjArgProc: IntIntObjArgProc].}
{.deprecated: [TIntObjArgProc: IntObjArgProc].}
{.deprecated: [PInt: IntPtr].}
{.deprecated: [TIterNextFunc: IterNextFunc].}
{.deprecated: [TNewFunc: NewFunc].}
{.deprecated: [Tnode: Node].}
{.deprecated: [PNode: NodePtr].}
{.deprecated: [TObjObjargProc: ObjObjargProc].}
{.deprecated: [TObjObjProc: ObjObjProc].}
{.deprecated: [TPFlag: PFlag].}
{.deprecated: [TPFlags: PFlags].}
{.deprecated: [TPrintFunc: PrintFunc].}
{.deprecated: [pwrapperbase: wrapperbasePtr].}
{.deprecated: [TPyComplex: PyComplex].}
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
{.deprecated: [TPyDestructor: PyDestructor].}
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
{.deprecated: [TReprFunc: ReprFunc].}
{.deprecated: [TRichCmpFunc: RichCmpFunc].}
{.deprecated: [TRichComparisonOpcode: RichComparisonOpcode].}
{.deprecated: [TSetAttrFunc: SetAttrFunc].}
{.deprecated: [TSetAttroFunc: SetAttroFunc].}
{.deprecated: [TSetter: Setter].}
{.deprecated: [TTernaryFunc: TernaryFunc].}
{.deprecated: [TTraverseProc: TraverseProc].}
{.deprecated: [TUnaryFunc: UnaryFunc].}
{.deprecated: [TVisitProc: VisitProc].}
{.deprecated: [Twrapperbase: wrapperbase].}
{.deprecated: [Twrapperfunc: wrapperfunc].}


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
#Hierarchy of Python exceptions, Python 2.3, 
#copied from <INSTALL>\Python\exceptions.c
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


var 
  PyArg_Parse*: proc (args: PyObjectPtr, format: cstring): int{.cdecl, varargs.} 
  PyArg_ParseTuple*: proc (args: PyObjectPtr, format: cstring, 
                           x1: pointer = nil, x2: pointer = nil, 
                           x3: pointer = nil): int{.cdecl, varargs.} 
  Py_BuildValue*: proc (format: cstring): PyObjectPtr{.cdecl, varargs.} 
  PyCode_Addr2Line*: proc (co: PyCodeObjectPtr, addrq: int): int{.cdecl.}
  DLL_Py_GetBuildInfo*: proc (): cstring{.cdecl.}

var
  debugFlag*: IntPtr
  verboseFlag*: IntPtr
  interactiveFlag*: IntPtr
  optimizeFlag*: IntPtr
  noSiteFlag*: IntPtr
  useClassExceptionsFlag*: IntPtr
  frozenFlag*: IntPtr
  tabcheckFlag*: IntPtr
  unicodeFlag*: IntPtr
  ignoreEnvironmentFlag*: IntPtr
  divisionWarningFlag*: IntPtr 
  #_PySys_TraceFunc: PyObjectPtrPtr;
  #_PySys_ProfileFunc: PyObjectPtrPtrPtr;
  importFrozenModules*: FrozenPtrPtr
  noneVar*: PyObjectPtr
  ellipsis*: PyObjectPtr
  falseVar*: PyIntObjectPtr
  trueVar*: PyIntObjectPtr
  notImplemented*: PyObjectPtr
  excAttributeError*: PyObjectPtrPtr
  excEOFError*: PyObjectPtrPtr
  excIOError*: PyObjectPtrPtr
  excImportError*: PyObjectPtrPtr
  excIndexError*: PyObjectPtrPtr
  excKeyError*: PyObjectPtrPtr
  excKeyboardInterrupt*: PyObjectPtrPtr
  excMemoryError*: PyObjectPtrPtr
  excNameError*: PyObjectPtrPtr
  excOverflowError*: PyObjectPtrPtr
  excRuntimeError*: PyObjectPtrPtr
  excSyntaxError*: PyObjectPtrPtr
  excSystemError*: PyObjectPtrPtr
  excSystemExit*: PyObjectPtrPtr
  excTypeError*: PyObjectPtrPtr
  excValueError*: PyObjectPtrPtr
  excZeroDivisionError*: PyObjectPtrPtr
  excArithmeticError*: PyObjectPtrPtr
  excException*: PyObjectPtrPtr
  excFloatingPointError*: PyObjectPtrPtr
  excLookupError*: PyObjectPtrPtr
  excStandardError*: PyObjectPtrPtr
  excAssertionError*: PyObjectPtrPtr
  excEnvironmentError*: PyObjectPtrPtr
  excIndentationError*: PyObjectPtrPtr
  excMemoryErrorInst*: PyObjectPtrPtr
  excNotImplementedError*: PyObjectPtrPtr
  excOSError*: PyObjectPtrPtr
  excTabError*: PyObjectPtrPtr
  excUnboundLocalError*: PyObjectPtrPtr
  excUnicodeError*: PyObjectPtrPtr
  excWarning*: PyObjectPtrPtr
  excDeprecationWarning*: PyObjectPtrPtr
  excRuntimeWarning*: PyObjectPtrPtr
  excSyntaxWarning*: PyObjectPtrPtr
  excUserWarning*: PyObjectPtrPtr
  excOverflowWarning*: PyObjectPtrPtr
  excReferenceError*: PyObjectPtrPtr
  excStopIteration*: PyObjectPtrPtr
  excFutureWarning*: PyObjectPtrPtr
  excPendingDeprecationWarning*: PyObjectPtrPtr
  excUnicodeDecodeError*: PyObjectPtrPtr
  excUnicodeEncodeError*: PyObjectPtrPtr
  excUnicodeTranslateError*: PyObjectPtrPtr
  typeType*: PyTypeObjectPtr
  cfunctionType*: PyTypeObjectPtr
  cobjectType*: PyTypeObjectPtr
  classType*: PyTypeObjectPtr
  codeType*: PyTypeObjectPtr
  complexType*: PyTypeObjectPtr
  dictType*: PyTypeObjectPtr
  fileType*: PyTypeObjectPtr
  floatType*: PyTypeObjectPtr
  frameType*: PyTypeObjectPtr
  functionType*: PyTypeObjectPtr
  instanceType*: PyTypeObjectPtr
  intType*: PyTypeObjectPtr
  listType*: PyTypeObjectPtr
  longType*: PyTypeObjectPtr
  methodType*: PyTypeObjectPtr
  moduleType*: PyTypeObjectPtr
  objectType*: PyTypeObjectPtr
  rangeType*: PyTypeObjectPtr
  sliceType*: PyTypeObjectPtr
  stringType*: PyTypeObjectPtr
  tupleType*: PyTypeObjectPtr
  baseobjectType*: PyTypeObjectPtr
  bufferType*: PyTypeObjectPtr
  calliterType*: PyTypeObjectPtr
  cellType*: PyTypeObjectPtr
  classmethodType*: PyTypeObjectPtr
  propertyType*: PyTypeObjectPtr
  seqiterType*: PyTypeObjectPtr
  staticmethodType*: PyTypeObjectPtr
  superType*: PyTypeObjectPtr
  symtableentryType*: PyTypeObjectPtr
  tracebackType*: PyTypeObjectPtr
  unicodeType*: PyTypeObjectPtr
  wrapperdescrType*: PyTypeObjectPtr
  basestringType*: PyTypeObjectPtr
  boolType*: PyTypeObjectPtr
  enumType*: PyTypeObjectPtr
{.deprecated: [Py_DebugFlag: debugFlag].}
{.deprecated: [Py_VerboseFlag: verboseFlag].}
{.deprecated: [Py_InteractiveFlag: interactiveFlag].}
{.deprecated: [Py_OptimizeFlag: optimizeFlag].}
{.deprecated: [Py_NoSiteFlag: noSiteFlag].}
{.deprecated: [Py_UseClassExceptionsFlag: useClassExceptionsFlag].}
{.deprecated: [Py_FrozenFlag: frozenFlag].}
{.deprecated: [Py_TabcheckFlag: tabcheckFlag].}
{.deprecated: [Py_UnicodeFlag: unicodeFlag].}
{.deprecated: [Py_IgnoreEnvironmentFlag: ignoreEnvironmentFlag].}
{.deprecated: [Py_DivisionWarningFlag: divisionWarningFlag].}
{.deprecated: [PyImport_FrozenModules: importFrozenModules].}
{.deprecated: [Py_None: noneVar].}
{.deprecated: [Py_Ellipsis: ellipsis].}
{.deprecated: [Py_False: falseVar].}
{.deprecated: [Py_True: trueVar].}
{.deprecated: [Py_NotImplemented: notImplemented].}
{.deprecated: [PyExc_AttributeError: excAttributeError].}
{.deprecated: [PyExc_EOFError: excEOFError].}
{.deprecated: [PyExc_IOError: excIOError].}
{.deprecated: [PyExc_ImportError: excImportError].}
{.deprecated: [PyExc_IndexError: excIndexError].}
{.deprecated: [PyExc_KeyError: excKeyError].}
{.deprecated: [PyExc_KeyboardInterrupt: excKeyboardInterrupt].}
{.deprecated: [PyExc_MemoryError: excMemoryError].}
{.deprecated: [PyExc_NameError: excNameError].}
{.deprecated: [PyExc_OverflowError: excOverflowError].}
{.deprecated: [PyExc_RuntimeError: excRuntimeError].}
{.deprecated: [PyExc_SyntaxError: excSyntaxError].}
{.deprecated: [PyExc_SystemError: excSystemError].}
{.deprecated: [PyExc_SystemExit: excSystemExit].}
{.deprecated: [PyExc_TypeError: excTypeError].}
{.deprecated: [PyExc_ValueError: excValueError].}
{.deprecated: [PyExc_ZeroDivisionError: excZeroDivisionError].}
{.deprecated: [PyExc_ArithmeticError: excArithmeticError].}
{.deprecated: [PyExc_Exception: excException].}
{.deprecated: [PyExc_FloatingPointError: excFloatingPointError].}
{.deprecated: [PyExc_LookupError: excLookupError].}
{.deprecated: [PyExc_StandardError: excStandardError].}
{.deprecated: [PyExc_AssertionError: excAssertionError].}
{.deprecated: [PyExc_EnvironmentError: excEnvironmentError].}
{.deprecated: [PyExc_IndentationError: excIndentationError].}
{.deprecated: [PyExc_MemoryErrorInst: excMemoryErrorInst].}
{.deprecated: [PyExc_NotImplementedError: excNotImplementedError].}
{.deprecated: [PyExc_OSError: excOSError].}
{.deprecated: [PyExc_TabError: excTabError].}
{.deprecated: [PyExc_UnboundLocalError: excUnboundLocalError].}
{.deprecated: [PyExc_UnicodeError: excUnicodeError].}
{.deprecated: [PyExc_Warning: excWarning].}
{.deprecated: [PyExc_DeprecationWarning: excDeprecationWarning].}
{.deprecated: [PyExc_RuntimeWarning: excRuntimeWarning].}
{.deprecated: [PyExc_SyntaxWarning: excSyntaxWarning].}
{.deprecated: [PyExc_UserWarning: excUserWarning].}
{.deprecated: [PyExc_OverflowWarning: excOverflowWarning].}
{.deprecated: [PyExc_ReferenceError: excReferenceError].}
{.deprecated: [PyExc_StopIteration: excStopIteration].}
{.deprecated: [PyExc_FutureWarning: excFutureWarning].}
{.deprecated: [PyExc_PendingDeprecationWarning: excPendingDeprecationWarning].}
{.deprecated: [PyExc_UnicodeDecodeError: excUnicodeDecodeError].}
{.deprecated: [PyExc_UnicodeEncodeError: excUnicodeEncodeError].}
{.deprecated: [PyExc_UnicodeTranslateError: excUnicodeTranslateError].}
{.deprecated: [PyType_Type: typeType].}
{.deprecated: [PyCFunction_Type: cfunctionType].}
{.deprecated: [PyCObject_Type: cobjectType].}
{.deprecated: [PyClass_Type: classType].}
{.deprecated: [PyCode_Type: codeType].}
{.deprecated: [PyComplex_Type: complexType].}
{.deprecated: [PyDict_Type: dictType].}
{.deprecated: [PyFile_Type: fileType].}
{.deprecated: [PyFloat_Type: floatType].}
{.deprecated: [PyFrame_Type: frameType].}
{.deprecated: [PyFunction_Type: functionType].}
{.deprecated: [PyInstance_Type: instanceType].}
{.deprecated: [PyInt_Type: intType].}
{.deprecated: [PyList_Type: listType].}
{.deprecated: [PyLong_Type: longType].}
{.deprecated: [PyMethod_Type: methodType].}
{.deprecated: [PyModule_Type: moduleType].}
{.deprecated: [PyObject_Type: objectType].}
{.deprecated: [PyRange_Type: rangeType].}
{.deprecated: [PySlice_Type: sliceType].}
{.deprecated: [PyString_Type: stringType].}
{.deprecated: [PyTuple_Type: tupleType].}
{.deprecated: [PyBaseObject_Type: baseobjectType].}
{.deprecated: [PyBuffer_Type: bufferType].}
{.deprecated: [PyCallIter_Type: calliterType].}
{.deprecated: [PyCell_Type: cellType].}
{.deprecated: [PyClassMethod_Type: classmethodType].}
{.deprecated: [PyProperty_Type: propertyType].}
{.deprecated: [PySeqIter_Type: seqiterType].}
{.deprecated: [PyStaticMethod_Type: staticmethodType].}
{.deprecated: [PySuper_Type: superType].}
{.deprecated: [PySymtableEntry_Type: symtableentryType].}
{.deprecated: [PyTraceBack_Type: tracebackType].}
{.deprecated: [PyUnicode_Type: unicodeType].}
{.deprecated: [PyWrapperDescr_Type: wrapperdescrType].}
{.deprecated: [PyBaseString_Type: basestringType].}
{.deprecated: [PyBool_Type: boolType].}
{.deprecated: [PyEnum_Type: enumType].}

proc vaBuildValue*(format: cstring; va_list: varargs): PyObjectPtr{.cdecl, 
  importc: "Py_VaBuildValue", dynlib: dllname.}
proc builtinInit*(){.cdecl, importc: "_PyBuiltin_Init", dynlib: dllname.}
proc complexFromCComplex*(c: PyComplex): PyObjectPtr{.cdecl, 
  importc: "PyComplex_FromCComplex", dynlib: dllname.}
proc complexFromDoubles*(realv, imag: float64): PyObjectPtr{.cdecl, 
  importc: "PyComplex_FromDoubles", dynlib: dllname.}
proc complexRealAsDouble*(op: PyObjectPtr): float64{.cdecl, 
  importc: "PyComplex_RealAsDouble", dynlib: dllname.}
proc complexImagAsDouble*(op: PyObjectPtr): float64{.cdecl, 
  importc: "PyComplex_ImagAsDouble", dynlib: dllname.}
proc complexAsCComplex*(op: PyObjectPtr): PyComplex{.cdecl, 
  importc: "PyComplex_AsCComplex", dynlib: dllname.}
proc cfunctionGetFunction*(ob: PyObjectPtr): pointer{.cdecl, 
  importc: "PyCFunction_GetFunction", dynlib: dllname.}
proc cfunctionGetSelf*(ob: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyCFunction_GetSelf", dynlib: dllname.}
proc callableCheck*(ob: PyObjectPtr): int{.cdecl, importc: "PyCallable_Check", 
  dynlib: dllname.}
proc cobjectFromVoidPtr*(cobj, destruct: pointer): PyObjectPtr{.cdecl, 
  importc: "PyCObject_FromVoidPtr", dynlib: dllname.}
proc cobjectAsVoidPtr*(ob: PyObjectPtr): pointer{.cdecl, 
  importc: "PyCObject_AsVoidPtr", dynlib: dllname.}
proc classNew*(ob1, ob2, ob3: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyClass_New", dynlib: dllname.}
proc classIsSubclass*(ob1, ob2: PyObjectPtr): int{.cdecl, 
  importc: "PyClass_IsSubclass", dynlib: dllname.}
proc initModule4*(name: cstring, methods: PyMethodDefPtr, doc: cstring, 
                    passthrough: PyObjectPtr, Api_Version: int): PyObjectPtr{.
                    cdecl, importc: "Py_InitModule4", dynlib: dllname.}
proc errBadArgument*(): int{.cdecl, importc: "PyErr_BadArgument", 
  dynlib: dllname.}
proc errBadInternalCall*(){.cdecl, importc: "PyErr_BadInternalCall", 
  dynlib: dllname.}
proc errCheckSignals*(): int{.cdecl, importc: "PyErr_CheckSignals", 
  dynlib: dllname.}
proc errClear*(){.cdecl, importc: "PyErr_Clear", dynlib: dllname.}
proc errFetch*(errtype, errvalue, errtraceback: PyObjectPtrPtr){.cdecl, 
  importc: "PyErr_Fetch", dynlib: dllname.}
proc errNoMemory*(): PyObjectPtr{.cdecl, importc: "PyErr_NoMemory", 
  dynlib: dllname.}
proc errOccurred*(): PyObjectPtr{.cdecl, importc: "PyErr_Occurred", 
  dynlib: dllname.}
proc errPrint*(){.cdecl, importc: "PyErr_Print", dynlib: dllname.}
proc errRestore*(errtype, errvalue, errtraceback: PyObjectPtr){.cdecl, 
  importc: "PyErr_Restore", dynlib: dllname.}
proc errSetFromErrno*(ob: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyErr_SetFromErrno", dynlib: dllname.}
proc errSetNone*(value: PyObjectPtr){.cdecl, importc: "PyErr_SetNone", 
  dynlib: dllname.}
proc errSetObject*(ob1, ob2: PyObjectPtr){.cdecl, importc: "PyErr_SetObject", 
  dynlib: dllname.}
proc errSetString*(ErrorObject: PyObjectPtr, text: cstring){.cdecl, 
  importc: "PyErr_SetString", dynlib: dllname.}
proc importGetModuleDict*(): PyObjectPtr{.cdecl, 
  importc: "PyImport_GetModuleDict", dynlib: dllname.}
proc intFromLong*(x: int32): PyObjectPtr{.cdecl, importc: "PyInt_FromLong", 
  dynlib: dllname.}
proc initialize*(){.cdecl, importc: "Py_Initialize", 
  dynlib: dllname.}
proc exit*(RetVal: int){.cdecl, importc: "Py_Exit", 
  dynlib: dllname.}
proc evalGetBuiltins*(): PyObjectPtr{.cdecl, importc: "PyEval_GetBuiltins", 
  dynlib: dllname.}
proc dictGetItem*(mp, key: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyDict_GetItem", dynlib: dllname.}
proc dictSetItem*(mp, key, item: PyObjectPtr): int{.cdecl, 
  importc: "PyDict_SetItem", dynlib: dllname.}
proc dictDelItem*(mp, key: PyObjectPtr): int{.cdecl, 
  importc: "PyDict_DelItem", dynlib: dllname.}
proc dictClear*(mp: PyObjectPtr){.cdecl, importc: "PyDict_Clear", 
  dynlib: dllname.}
proc dictNext*(mp: PyObjectPtr, pos: IntPtr, key, 
                 value: PyObjectPtrPtr): int{.cdecl, importc: "PyDict_Next", 
                 dynlib: dllname.}
proc dictKeys*(mp: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyDict_Keys", 
  dynlib: dllname.}
proc dictValues*(mp: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyDict_Values", dynlib: dllname.}
proc dictItems*(mp: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyDict_Items", dynlib: dllname.}
proc dictSize*(mp: PyObjectPtr): int{.cdecl, importc: "PyDict_Size", 
  dynlib: dllname.}
proc dictDelItemString*(dp: PyObjectPtr, key: cstring): int{.cdecl, 
  importc: "PyDict_DelItemString", dynlib: dllname.}
proc dictNew*(): PyObjectPtr{.cdecl, importc: "PyDict_New", 
  dynlib: dllname.}
proc dictGetItemString*(dp: PyObjectPtr, key: cstring): PyObjectPtr{.cdecl, 
  importc: "PyDict_GetItemString", dynlib: dllname.}
proc dictSetItemString*(dp: PyObjectPtr, key: cstring, 
                          item: PyObjectPtr): int{.cdecl, 
                          importc: "PyDict_SetItemString", dynlib: dllname.}
proc dictproxyNew*(obj: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyDictProxy_New", dynlib: dllname.}
proc moduleGetDict*(module: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyModule_GetDict", dynlib: dllname.}
proc objectStr*(v: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyObject_Str", 
  dynlib: dllname.}
proc runString*(str: cstring, start: int, globals: PyObjectPtr, 
                  locals: PyObjectPtr): PyObjectPtr{.cdecl, 
                  importc: "PyRun_String", dynlib: dllname.}
proc runSimpleString*(str: cstring): int{.cdecl, 
  importc: "PyRun_SimpleString", dynlib: dllname.}
proc stringAsString*(ob: PyObjectPtr): cstring{.cdecl, 
  importc: "PyString_AsString", dynlib: dllname.}
proc stringFromString*(str: cstring): PyObjectPtr{.cdecl, 
  importc: "PyString_FromString", dynlib: dllname.}
proc sysSetArgv*(argc: int, argv: cstringArray){.cdecl, 
  importc: "PySys_SetArgv", dynlib: dllname.} 
#+ means, Grzegorz or me has tested his non object version of this function
#+
proc cfunctionNew*(md: PyMethodDefPtr, ob: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyCFunction_New", dynlib: dllname.} #+
proc evalCallObject*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyEval_CallObject", dynlib: dllname.} #-
proc evalCallObjectWithKeywords*(ob1, ob2, ob3: PyObjectPtr): PyObjectPtr{.cdecl,
   importc: "PyEval_CallObjectWithKeywords", dynlib: dllname.} #-
proc evalGetFrame*(): PyObjectPtr{.cdecl, importc: "PyEval_GetFrame", 
  dynlib: dllname.} #-
proc evalGetGlobals*(): PyObjectPtr{.cdecl, importc: "PyEval_GetGlobals", 
  dynlib: dllname.} #-
proc evalGetLocals*(): PyObjectPtr{.cdecl, importc: "PyEval_GetLocals", 
  dynlib: dllname.} #-
proc evalGetOwner*(): PyObjectPtr {.cdecl, importc: "PyEval_GetOwner", 
  dynlib: dllname.}
proc evalGetRestricted*(): int{.cdecl, importc: "PyEval_GetRestricted", 
  dynlib: dllname.} #-
proc evalInitThreads*(){.cdecl, importc: "PyEval_InitThreads", 
  dynlib: dllname.} #-
proc evalRestoreThread*(tstate: PyThreadStatePtr){.cdecl, 
  importc: "PyEval_RestoreThread", dynlib: dllname.} #-
proc evalSaveThread*(): PyThreadStatePtr{.cdecl, 
  importc: "PyEval_SaveThread", dynlib: dllname.} #-
proc fileFromString*(pc1, pc2: cstring): PyObjectPtr{.cdecl, 
  importc: "PyFile_FromString", dynlib: dllname.} #-
proc fileGetLine*(ob: PyObjectPtr, i: int): PyObjectPtr{.cdecl, 
  importc: "PyFile_GetLine", dynlib: dllname.} #-
proc fileName*(ob: PyObjectPtr): PyObjectPtr{.cdecl, importc: "PyFile_Name", 
  dynlib: dllname.} #-
proc fileSetBufSize*(ob: PyObjectPtr, i: int){.cdecl, 
  importc: "PyFile_SetBufSize", dynlib: dllname.} #-
proc fileSoftSpace*(ob: PyObjectPtr, i: int): int{.cdecl, 
  importc: "PyFile_SoftSpace", dynlib: dllname.} #-
proc fileWriteObject*(ob1, ob2: PyObjectPtr, i: int): int{.cdecl, 
  importc: "PyFile_WriteObject", dynlib: dllname.} #-
proc fileWriteString*(s: cstring, ob: PyObjectPtr){.cdecl, 
  importc: "PyFile_WriteString", dynlib: dllname.} #+
proc floatAsDouble*(ob: PyObjectPtr): float64{.cdecl, 
  importc: "PyFloat_AsDouble", dynlib: dllname.} #+
proc floatFromDouble*(db: float64): PyObjectPtr{.cdecl, 
  importc: "PyFloat_FromDouble", dynlib: dllname.} #-
proc functionGetCode*(ob: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyFunction_GetCode", dynlib: dllname.} #-
proc functionGetGlobals*(ob: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyFunction_GetGlobals", dynlib: dllname.} #-
proc functionNew*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyFunction_New", dynlib: dllname.} #-
proc importAddModule*(name: cstring): PyObjectPtr{.cdecl, 
  importc: "PyImport_AddModule", dynlib: dllname.} #-
proc importCleanup*(){.cdecl, importc: "PyImport_Cleanup", 
  dynlib: dllname.} #-
proc importGetMagicNumber*(): int32{.cdecl, 
  importc: "PyImport_GetMagicNumber", dynlib: dllname.} #+
proc importImportFrozenModule*(key: cstring): int{.cdecl, 
  importc: "PyImport_ImportFrozenModule", dynlib: dllname.} #+
proc importImportModule*(name: cstring): PyObjectPtr{.cdecl, 
  importc: "PyImport_ImportModule", dynlib: dllname.} #+
proc importImport*(name: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyImport_Import", dynlib: dllname.} #-
proc importInit*() {.cdecl, importc: "PyImport_Init", 
  dynlib: dllname.}
proc importReloadModule*(ob: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyImport_ReloadModule", dynlib: dllname.} #-
proc instanceNew*(obClass, obArg, obKW: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyInstance_New", dynlib: dllname.} #+
proc intAsLong*(ob: PyObjectPtr): int32{.cdecl, importc: "PyInt_AsLong", 
  dynlib: dllname.} #-
proc listAppend*(ob1, ob2: PyObjectPtr): int{.cdecl, 
  importc: "PyList_Append", dynlib: dllname.} #-
proc listAsTuple*(ob: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyList_AsTuple", dynlib: dllname.} #+
proc listGetItem*(ob: PyObjectPtr, i: int): PyObjectPtr{.cdecl, 
  importc: "PyList_GetItem", dynlib: dllname.} #-
proc listGetSlice*(ob: PyObjectPtr, i1, i2: int): PyObjectPtr{.cdecl, 
  importc: "PyList_GetSlice", dynlib: dllname.} #-
proc listInsert*(dp: PyObjectPtr, idx: int, item: PyObjectPtr): int{.cdecl, 
  importc: "PyList_Insert", dynlib: dllname.} #-
proc listNew*(size: int): PyObjectPtr{.cdecl, importc: "PyList_New", 
  dynlib: dllname.} #-
proc listReverse*(ob: PyObjectPtr): int{.cdecl, importc: "PyList_Reverse", 
  dynlib: dllname.} #-
proc listSetItem*(dp: PyObjectPtr, idx: int, item: PyObjectPtr): int{.cdecl, 
  importc: "PyList_SetItem", dynlib: dllname.} #-
proc listSetSlice*(ob: PyObjectPtr, i1, i2: int, ob2: PyObjectPtr): int{.cdecl,
   importc: "PyList_SetSlice", dynlib: dllname.} #+
proc listSize*(ob: PyObjectPtr): int{.cdecl, importc: "PyList_Size", 
  dynlib: dllname.} #-
proc listSort*(ob: PyObjectPtr): int{.cdecl, importc: "PyList_Sort", 
  dynlib: dllname.} #-
proc longAsDouble*(ob: PyObjectPtr): float64{.cdecl, 
  importc: "PyLong_AsDouble", dynlib: dllname.} #+
proc longAsLong*(ob: PyObjectPtr): int32{.cdecl, importc: "PyLong_AsLong", 
  dynlib: dllname.} #+
proc longFromDouble*(db: float64): PyObjectPtr{.cdecl, 
  importc: "PyLong_FromDouble", dynlib: dllname.} #+
proc longFromLong*(L: int32): PyObjectPtr{.cdecl, importc: "PyLong_FromLong", 
  dynlib: dllname.} #-
proc longFromString*(pc: cstring, ppc: var cstring, i: int): PyObjectPtr{.cdecl,
   importc: "PyLong_FromString", dynlib: dllname.} #-
proc longFromUnsignedLong*(val: int): PyObjectPtr{.cdecl, 
  importc: "PyLong_FromUnsignedLong", dynlib: dllname.} #-
proc longAsUnsignedLong*(ob: PyObjectPtr): int{.cdecl, 
  importc: "PyLong_AsUnsignedLong", dynlib: dllname.} #-
proc longFromUnicode*(ob: PyObjectPtr, a, b: int): PyObjectPtr{.cdecl, 
  importc: "PyLong_FromUnicode", dynlib: dllname.} #-
proc longFromLongLong*(val: int64): PyObjectPtr{.cdecl, 
  importc: "PyLong_FromLongLong", dynlib: dllname.} #-
proc longAsLongLong*(ob: PyObjectPtr): int64{.cdecl, 
  importc: "PyLong_AsLongLong", dynlib: dllname.} #-
proc mappingCheck*(ob: PyObjectPtr): int{.cdecl, importc: "PyMapping_Check", 
  dynlib: dllname.} #-
proc mappingGetItemString*(ob: PyObjectPtr, key: cstring): PyObjectPtr{.cdecl,
   importc: "PyMapping_GetItemString", dynlib: dllname.} #-
proc mappingHasKey*(ob, key: PyObjectPtr): int{.cdecl, 
  importc: "PyMapping_HasKey", dynlib: dllname.} #-
proc mappingHasKeyString*(ob: PyObjectPtr, key: cstring): int{.cdecl, 
  importc: "PyMapping_HasKeyString", dynlib: dllname.} #-
proc mappingLength*(ob: PyObjectPtr): int{.cdecl, 
  importc: "PyMapping_Length", dynlib: dllname.} #-
proc mappingSetItemString*(ob: PyObjectPtr, key: cstring, 
                             value: PyObjectPtr): int{.cdecl, 
                             importc: "PyMapping_SetItemString", 
                             dynlib: dllname.} #-
proc methodClass*(ob: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyMethod_Class", dynlib: dllname.} #-
proc methodFunction*(ob: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyMethod_Function", dynlib: dllname.} #-
proc methodNew*(ob1, ob2, ob3: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyMethod_New", dynlib: dllname.} #-
proc methodSelf*(ob: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyMethod_Self", dynlib: dllname.} #-
proc moduleGetName*(ob: PyObjectPtr): cstring{.cdecl, 
  importc: "PyModule_GetName", dynlib: dllname.} #-
proc moduleNew*(key: cstring): PyObjectPtr{.cdecl, importc: "PyModule_New", 
  dynlib: dllname.} #-
proc numberAbsolute*(ob: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyNumber_Absolute", dynlib: dllname.} #-
proc numberAdd*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyNumber_Add", dynlib: dllname.} #-
proc numberAnd*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyNumber_And", dynlib: dllname.} #-
proc numberCheck*(ob: PyObjectPtr): int{.cdecl, importc: "PyNumber_Check", 
  dynlib: dllname.} #-
proc numberCoerce*(ob1, ob2: var PyObjectPtr): int{.cdecl, 
  importc: "PyNumber_Coerce", dynlib: dllname.} #-
proc numberDivide*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyNumber_Divide", dynlib: dllname.} #-
proc numberFloorDivide*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyNumber_FloorDivide", dynlib: dllname.} #-
proc numberTrueDivide*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyNumber_TrueDivide", dynlib: dllname.} #-
proc numberDivmod*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyNumber_Divmod", dynlib: dllname.} #-
proc numberFloat*(ob: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyNumber_Float", dynlib: dllname.} #-
proc numberInt*(ob: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyNumber_Int", dynlib: dllname.} #-
proc numberInvert*(ob: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyNumber_Invert", dynlib: dllname.} #-
proc numberLong*(ob: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyNumber_Long", dynlib: dllname.} #-
proc numberLshift*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyNumber_Lshift", dynlib: dllname.} #-
proc numberMultiply*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyNumber_Multiply", dynlib: dllname.} #-
proc numberNegative*(ob: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyNumber_Negative", dynlib: dllname.} #-
proc numberOr*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyNumber_Or", dynlib: dllname.} #-
proc numberPositive*(ob: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyNumber_Positive", dynlib: dllname.} #-
proc numberPower*(ob1, ob2, ob3: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyNumber_Power", dynlib: dllname.} #-
proc numberRemainder*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyNumber_Remainder", dynlib: dllname.} #-
proc numberRshift*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyNumber_Rshift", dynlib: dllname.} #-
proc numberSubtract*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyNumber_Subtract", dynlib: dllname.} #-
proc numberXor*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyNumber_Xor", dynlib: dllname.} #-
proc osInitInterrupts*(){.cdecl, importc: "PyOS_InitInterrupts", 
  dynlib: dllname.} #-
proc osInterruptOccurred*(): int{.cdecl, importc: "PyOS_InterruptOccurred", 
  dynlib: dllname.} #-
proc objectCallObject*(ob, args: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyObject_CallObject", dynlib: dllname.} #-
proc objectCompare*(ob1, ob2: PyObjectPtr): int{.cdecl, 
  importc: "PyObject_Compare", dynlib: dllname.} #-
proc objectGetAttr*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyObject_GetAttr", dynlib: dllname.} #+
proc objectGetAttrString*(ob: PyObjectPtr, c: cstring): PyObjectPtr{.cdecl, 
  importc: "PyObject_GetAttrString", dynlib: dllname.} #-
proc objectGetItem*(ob, key: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyObject_GetItem", dynlib: dllname.} #-
proc objectDelItem*(ob, key: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyObject_DelItem", dynlib: dllname.} #-
proc objectHasAttrString*(ob: PyObjectPtr, key: cstring): int{.cdecl, 
  importc: "PyObject_HasAttrString", dynlib: dllname.} #-
proc objectHash*(ob: PyObjectPtr): int32{.cdecl, importc: "PyObject_Hash", 
  dynlib: dllname.} #-
proc objectIsTrue*(ob: PyObjectPtr): int{.cdecl, importc: "PyObject_IsTrue", 
  dynlib: dllname.} #-
proc objectLength*(ob: PyObjectPtr): int{.cdecl, importc: "PyObject_Length", 
  dynlib: dllname.} #-
proc objectRepr*(ob: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyObject_Repr", dynlib: dllname.} #-
proc objectSetAttr*(ob1, ob2, ob3: PyObjectPtr): int{.cdecl, 
  importc: "PyObject_SetAttr", dynlib: dllname.} #-
proc objectSetAttrString*(ob: PyObjectPtr, key: cstring, 
                            value: PyObjectPtr): int{.cdecl, 
                            importc: "PyObject_SetAttrString", dynlib: dllname.} #-
proc objectSetItem*(ob1, ob2, ob3: PyObjectPtr): int{.cdecl, 
  importc: "PyObject_SetItem", dynlib: dllname.} #-
proc objectInit*(ob: PyObjectPtr, t: PyTypeObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyObject_Init", dynlib: dllname.} #-
proc objectInitVar*(ob: PyObjectPtr, t: PyTypeObjectPtr, 
                      size: int): PyObjectPtr{.cdecl, importc: "PyObject_InitVar", 
                      dynlib: dllname.} #-
proc objectNew*(t: PyTypeObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyObject_New", dynlib: dllname.} #-
proc objectNewVar*(t: PyTypeObjectPtr, size: int): PyObjectPtr{.cdecl, 
  importc: "PyObject_NewVar", dynlib: dllname.}
proc objectFree*(ob: PyObjectPtr){.cdecl, importc: "PyObject_Free", 
  dynlib: dllname.} #-
proc objectIsInstance*(inst, cls: PyObjectPtr): int{.cdecl, 
  importc: "PyObject_IsInstance", dynlib: dllname.} #-
proc objectIsSubclass*(derived, cls: PyObjectPtr): int{.cdecl, 
  importc: "PyObject_IsSubclass", dynlib: dllname.}
proc objectGenericGetAttr*(obj, name: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyObject_GenericGetAttr", dynlib: dllname.}
proc objectGenericSetAttr*(obj, name, value: PyObjectPtr): int{.cdecl, 
  importc: "PyObject_GenericSetAttr", dynlib: dllname.} #-
proc objectGCMalloc*(size: int): PyObjectPtr{.cdecl, 
  importc: "PyObject_GC_Malloc", dynlib: dllname.} #-
proc objectGCNew*(t: PyTypeObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyObject_GC_New", dynlib: dllname.} #-
proc objectGCNewVar*(t: PyTypeObjectPtr, size: int): PyObjectPtr{.cdecl, 
  importc: "PyObject_GC_NewVar", dynlib: dllname.} #-
proc objectGCResize*(t: PyObjectPtr, newsize: int): PyObjectPtr{.cdecl, 
  importc: "PyObject_GC_Resize", dynlib: dllname.} #-
proc objectGCDel*(ob: PyObjectPtr){.cdecl, importc: "PyObject_GC_Del", 
  dynlib: dllname.} #-
proc objectGCTrack*(ob: PyObjectPtr){.cdecl, importc: "PyObject_GC_Track", 
  dynlib: dllname.} #-
proc objectGCUnTrack*(ob: PyObjectPtr){.cdecl, 
  importc: "PyObject_GC_UnTrack", dynlib: dllname.} #-
proc rangeNew*(l1, l2, l3: int32, i: int): PyObjectPtr{.cdecl, 
  importc: "PyRange_New", dynlib: dllname.} #-
proc sequenceCheck*(ob: PyObjectPtr): int{.cdecl, 
  importc: "PySequence_Check", dynlib: dllname.} #-
proc sequenceConcat*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PySequence_Concat", dynlib: dllname.} #-
proc sequenceCount*(ob1, ob2: PyObjectPtr): int{.cdecl, 
  importc: "PySequence_Count", dynlib: dllname.} #-
proc sequenceGetItem*(ob: PyObjectPtr, i: int): PyObjectPtr{.cdecl, 
  importc: "PySequence_GetItem", dynlib: dllname.} #-
proc sequenceGetSlice*(ob: PyObjectPtr, i1, i2: int): PyObjectPtr{.cdecl, 
  importc: "PySequence_GetSlice", dynlib: dllname.} #-
proc sequenceIn*(ob1, ob2: PyObjectPtr): int{.cdecl, 
  importc: "PySequence_In", dynlib: dllname.} #-
proc sequenceIndex*(ob1, ob2: PyObjectPtr): int{.cdecl, 
  importc: "PySequence_Index", dynlib: dllname.} #-
proc sequenceLength*(ob: PyObjectPtr): int{.cdecl, 
  importc: "PySequence_Length", dynlib: dllname.} #-
proc sequenceRepeat*(ob: PyObjectPtr, count: int): PyObjectPtr{.cdecl, 
  importc: "PySequence_Repeat", dynlib: dllname.} #-
proc sequenceSetItem*(ob: PyObjectPtr, i: int, value: PyObjectPtr): int{.cdecl,
   importc: "PySequence_SetItem", dynlib: dllname.} #-
proc sequenceSetSlice*(ob: PyObjectPtr, i1, i2: int, 
                         value: PyObjectPtr): int{.cdecl, 
                         importc: "PySequence_SetSlice", dynlib: dllname.} #-
proc sequenceDelSlice*(ob: PyObjectPtr, i1, i2: int): int{.cdecl, 
  importc: "PySequence_DelSlice", dynlib: dllname.} #-
proc sequenceTuple*(ob: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PySequence_Tuple", dynlib: dllname.} #-
proc sequenceContains*(ob, value: PyObjectPtr): int{.cdecl, 
  importc: "PySequence_Contains", dynlib: dllname.} #-
proc sliceGetIndices*(ob: PySliceObjectPtr, len: int, 
                        start, stop, step: var int): int{.cdecl, 
                        importc: "PySlice_GetIndices", dynlib: dllname.} #-
proc sliceGetIndicesEx*(ob: PySliceObjectPtr, len: int, 
                          start, stop, step, slicelength: var int): int{.cdecl, 
                          importc: "PySlice_GetIndicesEx", dynlib: dllname.} #-
proc sliceNew*(start, stop, step: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PySlice_New", dynlib: dllname.} #-
proc stringConcat*(ob1: var PyObjectPtr, ob2: PyObjectPtr){.cdecl, 
  importc: "PyString_Concat", dynlib: dllname.} #-
proc stringConcatAndDel*(ob1: var PyObjectPtr, ob2: PyObjectPtr){.cdecl, 
  importc: "PyString_ConcatAndDel", dynlib: dllname.} #-
proc stringFormat*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyString_Format", dynlib: dllname.} #-
proc stringFromStringAndSize*(s: cstring, i: int): PyObjectPtr{.cdecl, 
  importc: "PyString_FromStringAndSize", dynlib: dllname.} #-
proc stringSize*(ob: PyObjectPtr): int{.cdecl, importc: "PyString_Size", 
  dynlib: dllname.} #-
proc stringDecodeEscape*(s: cstring, length: int, errors: cstring, unicode: int, 
                           recode_encoding: cstring): PyObjectPtr{.cdecl, 
                           importc: "PyString_DecodeEscape", dynlib: dllname.} #-
proc stringRepr*(ob: PyObjectPtr, smartquotes: int): PyObjectPtr{.cdecl, 
  importc: "PyString_Repr", dynlib: dllname.} #+
proc sysGetObject*(s: cstring): PyObjectPtr{.cdecl, 
  importc: "PySys_GetObject", dynlib: dllname.} #-
#-
#PySys_Init:procedure; cdecl, importc, dynlib: dllname;
#-
proc sysSetObject*(s: cstring, ob: PyObjectPtr): int{.cdecl, 
  importc: "PySys_SetObject", dynlib: dllname.} #-
proc sysSetPath*(path: cstring){.cdecl, importc: "PySys_SetPath", 
  dynlib: dllname.} #-
#PyTraceBack_Fetch:function:PyObjectPtr; cdecl, importc, dynlib: dllname;
#-
proc tracebackHere*(p: pointer): int{.cdecl, importc: "PyTraceBack_Here", 
  dynlib: dllname.} #-
proc tracebackPrint*(ob1, ob2: PyObjectPtr): int{.cdecl, 
  importc: "PyTraceBack_Print", dynlib: dllname.} #-
#PyTraceBack_Store:function (ob:PyObjectPtr):integer; cdecl, importc, dynlib: dllname;
#+
proc tupleGetItem*(ob: PyObjectPtr, i: int): PyObjectPtr{.cdecl, 
  importc: "PyTuple_GetItem", dynlib: dllname.} #-
proc tupleGetSlice*(ob: PyObjectPtr, i1, i2: int): PyObjectPtr{.cdecl, 
  importc: "PyTuple_GetSlice", dynlib: dllname.} #+
proc tupleNew*(size: int): PyObjectPtr{.cdecl, importc: "PyTuple_New", 
  dynlib: dllname.} #+
proc tupleSetItem*(ob: PyObjectPtr, key: int, value: PyObjectPtr): int{.cdecl,
   importc: "PyTuple_SetItem", dynlib: dllname.} #+
proc tupleSize*(ob: PyObjectPtr): int{.cdecl, importc: "PyTuple_Size", 
  dynlib: dllname.} #+
proc typeIsSubtype*(a, b: PyTypeObjectPtr): int{.cdecl, 
  importc: "PyType_IsSubtype", dynlib: dllname.}
proc typeGenericAlloc*(atype: PyTypeObjectPtr, nitems: int): PyObjectPtr{.cdecl,
   importc: "PyType_GenericAlloc", dynlib: dllname.}
proc typeGenericNew*(atype: PyTypeObjectPtr, 
                       args, kwds: PyObjectPtr): PyObjectPtr{.cdecl, 
                       importc: "PyType_GenericNew", dynlib: dllname.}
proc typeReady*(atype: PyTypeObjectPtr): int{.cdecl, importc: "PyType_Ready", 
  dynlib: dllname.} #+
proc unicodeFromWideChar*(w: pointer, size: int): PyObjectPtr{.cdecl, 
  importc: "PyUnicode_FromWideChar", dynlib: dllname.} #+
proc unicodeAsWideChar*(unicode: PyObjectPtr, w: pointer, size: int): int{.cdecl,
   importc: "PyUnicode_AsWideChar", dynlib: dllname.} #-
proc unicodeFromOrdinal*(ordinal: int): PyObjectPtr{.cdecl, 
  importc: "PyUnicode_FromOrdinal", dynlib: dllname.}
proc weakrefGetObject*(theRef: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyWeakref_GetObject", dynlib: dllname.}
proc weakrefNewProxy*(ob, callback: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyWeakref_NewProxy", dynlib: dllname.}
proc weakrefNewRef*(ob, callback: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyWeakref_NewRef", dynlib: dllname.}
proc wrapperNew*(ob1, ob2: PyObjectPtr): PyObjectPtr{.cdecl, 
  importc: "PyWrapper_New", dynlib: dllname.}
proc boolFromLong*(ok: int): PyObjectPtr{.cdecl, importc: "PyBool_FromLong", 
  dynlib: dllname.} #-
proc atExit*(prc: proc () {.cdecl.}): int{.cdecl, importc: "Py_AtExit", 
  dynlib: dllname.} #-
#Py_Cleanup:procedure; cdecl, importc, dynlib: dllname;
#-
proc compileString*(s1, s2: cstring, i: int): PyObjectPtr{.cdecl, 
  importc: "Py_CompileString", dynlib: dllname.} #-
proc fatalError*(s: cstring){.cdecl, importc: "Py_FatalError", 
  dynlib: dllname.} #-
proc findMethod*(md: PyMethodDefPtr, ob: PyObjectPtr, 
                   key: cstring): PyObjectPtr{.cdecl, importc: "Py_FindMethod", 
                   dynlib: dllname.} #-
proc findMethodInChain*(mc: PyMethodChainPtr, ob: PyObjectPtr, 
                          key: cstring): PyObjectPtr{.cdecl, 
                          importc: "Py_FindMethodInChain", dynlib: dllname.}                 #-
proc flushLine*(){.cdecl, importc: "Py_FlushLine", 
  dynlib: dllname.} #+
proc finalize*(){.cdecl, importc: "Py_Finalize", 
  dynlib: dllname.} #-
proc errExceptionMatches*(exc: PyObjectPtr): int{.cdecl, 
  importc: "PyErr_ExceptionMatches", dynlib: dllname.} #-
proc errGivenExceptionMatches*(raised_exc, exc: PyObjectPtr): int{.cdecl, 
  importc: "PyErr_GivenExceptionMatches", dynlib: dllname.} #-
proc evalEvalCode*(co: PyCodeObjectPtr, 
                     globals, locals: PyObjectPtr): PyObjectPtr{.cdecl, 
                     importc: "PyEval_EvalCode", dynlib: dllname.} #+
proc getVersion*(): cstring{.cdecl, importc: "Py_GetVersion", 
  dynlib: dllname.} #+
proc getCopyright*(): cstring{.cdecl, importc: "Py_GetCopyright", 
  dynlib: dllname.} #+
proc getExecPrefix*(): cstring{.cdecl, importc: "Py_GetExecPrefix", 
  dynlib: dllname.} #+
proc getPath*(): cstring{.cdecl, importc: "Py_GetPath", 
  dynlib: dllname.} #+
proc getPrefix*(): cstring{.cdecl, importc: "Py_GetPrefix", 
  dynlib: dllname.} #+
proc getProgramName*(): cstring{.cdecl, importc: "Py_GetProgramName", 
  dynlib: dllname.} #-
proc parserSimpleParseString*(str: cstring, start: int): NodePtr{.cdecl, 
  importc: "PyParser_SimpleParseString", dynlib: dllname.} #-
proc nodeFree*(n: NodePtr){.cdecl, importc: "PyNode_Free", 
  dynlib: dllname.} #-
proc errNewException*(name: cstring, base, dict: PyObjectPtr): PyObjectPtr{.cdecl,
   importc: "PyErr_NewException", dynlib: dllname.} #-
proc malloc*(size: int): pointer {.cdecl, importc: "Py_Malloc", 
  dynlib: dllname.}
proc memMalloc*(size: int): pointer {.cdecl, importc: "PyMem_Malloc", 
  dynlib: dllname.}
proc objectCallMethod*(obj: PyObjectPtr, theMethod, 
                         format: cstring): PyObjectPtr{.cdecl, 
                         importc: "PyObject_CallMethod", dynlib: dllname.}
proc setProgramName*(name: cstring){.cdecl, importc: "Py_SetProgramName", 
  dynlib: dllname.}
proc isInitialized*(): int{.cdecl, importc: "Py_IsInitialized", 
  dynlib: dllname.}
proc getProgramFullPath*(): cstring{.cdecl, importc: "Py_GetProgramFullPath", 
  dynlib: dllname.}
proc newInterpreter*(): PyThreadStatePtr{.cdecl, 
  importc: "Py_NewInterpreter", dynlib: dllname.}
proc endInterpreter*(tstate: PyThreadStatePtr){.cdecl, 
  importc: "Py_EndInterpreter", dynlib: dllname.}
proc evalAcquireLock*(){.cdecl, importc: "PyEval_AcquireLock", 
  dynlib: dllname.}
proc evalReleaseLock*(){.cdecl, importc: "PyEval_ReleaseLock", 
  dynlib: dllname.}
proc evalAcquireThread*(tstate: PyThreadStatePtr){.cdecl, 
  importc: "PyEval_AcquireThread", dynlib: dllname.}
proc evalReleaseThread*(tstate: PyThreadStatePtr){.cdecl, 
  importc: "PyEval_ReleaseThread", dynlib: dllname.}
proc interpreterstateNew*(): PyInterpreterStatePtr{.cdecl, 
  importc: "PyInterpreterState_New", dynlib: dllname.}
proc interpreterstateClear*(interp: PyInterpreterStatePtr){.cdecl, 
  importc: "PyInterpreterState_Clear", dynlib: dllname.}
proc interpreterstateDelete*(interp: PyInterpreterStatePtr){.cdecl, 
  importc: "PyInterpreterState_Delete", dynlib: dllname.}
proc threadStateNew*(interp: PyInterpreterStatePtr): PyThreadStatePtr{.cdecl, 
  importc: "PyThreadState_New", dynlib: dllname.}
proc threadStateClear*(tstate: PyThreadStatePtr){.cdecl, 
  importc: "PyThreadState_Clear", dynlib: dllname.}
proc threadStateDelete*(tstate: PyThreadStatePtr){.cdecl, 
  importc: "PyThreadState_Delete", dynlib: dllname.}
proc threadStateGet*(): PyThreadStatePtr{.cdecl, 
  importc: "PyThreadState_Get", dynlib: dllname.}
proc threadStateSwap*(tstate: PyThreadStatePtr): PyThreadStatePtr{.cdecl, 
  importc: "PyThreadState_Swap", dynlib: dllname.} 
{.deprecated: [PyComplex_FromCComplex: complexFromCComplex].}
{.deprecated: [PyComplex_FromDoubles: complexFromDoubles].}
{.deprecated: [PyComplex_RealAsDouble: complexRealAsDouble].}
{.deprecated: [PyComplex_ImagAsDouble: complexImagAsDouble].}
{.deprecated: [PyComplex_AsCComplex: complexAsCComplex].}
{.deprecated: [PyCFunction_GetFunction: cfunctionGetFunction].}
{.deprecated: [PyCFunction_GetSelf: cfunctionGetSelf].}
{.deprecated: [PyCallable_Check: callableCheck].}
{.deprecated: [PyCObject_FromVoidPtr: cobjectFromVoidPtr].}
{.deprecated: [PyCObject_AsVoidPtr: cobjectAsVoidPtr].}
{.deprecated: [PyClass_New: classNew].}
{.deprecated: [PyClass_IsSubclass: classIsSubclass].}
{.deprecated: [Py_InitModule4: initModule4].}
{.deprecated: [PyErr_BadArgument: errBadArgument].}
{.deprecated: [PyErr_BadInternalCall: errBadInternalCall].}
{.deprecated: [PyErr_CheckSignals: errCheckSignals].}
{.deprecated: [PyErr_Clear: errClear].}
{.deprecated: [PyErr_Fetch: errFetch].}
{.deprecated: [PyErr_NoMemory: errNoMemory].}
{.deprecated: [PyErr_Occurred: errOccurred].}
{.deprecated: [PyErr_Print: errPrint].}
{.deprecated: [PyErr_Restore: errRestore].}
{.deprecated: [PyErr_SetFromErrno: errSetFromErrno].}
{.deprecated: [PyErr_SetNone: errSetNone].}
{.deprecated: [PyErr_SetObject: errSetObject].}
{.deprecated: [PyErr_SetString: errSetString].}
{.deprecated: [PyImport_GetModuleDict: importGetModuleDict].}
{.deprecated: [PyInt_FromLong: intFromLong].}
{.deprecated: [Py_Initialize: initialize].}
{.deprecated: [Py_Exit: exit].}
{.deprecated: [PyEval_GetBuiltins: evalGetBuiltins].}
{.deprecated: [PyDict_GetItem: dictGetItem].}
{.deprecated: [PyDict_SetItem: dictSetItem].}
{.deprecated: [PyDict_DelItem: dictDelItem].}
{.deprecated: [PyDict_Clear: dictClear].}
{.deprecated: [PyDict_Next: dictNext].}
{.deprecated: [PyDict_Keys: dictKeys].}
{.deprecated: [PyDict_Values: dictValues].}
{.deprecated: [PyDict_Items: dictItems].}
{.deprecated: [PyDict_Size: dictSize].}
{.deprecated: [PyDict_DelItemString: dictDelItemString].}
{.deprecated: [PyDict_New: dictNew].}
{.deprecated: [PyDict_GetItemString: dictGetItemString].}
{.deprecated: [PyDict_SetItemString: dictSetItemString].}
{.deprecated: [PyDictProxy_New: dictproxyNew].}
{.deprecated: [PyModule_GetDict: moduleGetDict].}
{.deprecated: [PyObject_Str: objectStr].}
{.deprecated: [PyRun_String: runString].}
{.deprecated: [PyRun_SimpleString: runSimpleString].}
{.deprecated: [PyString_AsString: stringAsString].}
{.deprecated: [PyString_FromString: stringFromString].}
{.deprecated: [PySys_SetArgv: sysSetArgv].}
{.deprecated: [PyCFunction_New: cfunctionNew].}
{.deprecated: [PyEval_CallObject: evalCallObject].}
{.deprecated: [PyEval_CallObjectWithKeywords: evalCallObjectWithKeywords].}
{.deprecated: [PyEval_GetFrame: evalGetFrame].}
{.deprecated: [PyEval_GetGlobals: evalGetGlobals].}
{.deprecated: [PyEval_GetLocals: evalGetLocals].}
{.deprecated: [PyEval_GetOwner: evalGetOwner].}
{.deprecated: [PyEval_GetRestricted: evalGetRestricted].}
{.deprecated: [PyEval_InitThreads: evalInitThreads].}
{.deprecated: [PyEval_RestoreThread: evalRestoreThread].}
{.deprecated: [PyEval_SaveThread: evalSaveThread].}
{.deprecated: [PyFile_FromString: fileFromString].}
{.deprecated: [PyFile_GetLine: fileGetLine].}
{.deprecated: [PyFile_Name: fileName].}
{.deprecated: [PyFile_SetBufSize: fileSetBufSize].}
{.deprecated: [PyFile_SoftSpace: fileSoftSpace].}
{.deprecated: [PyFile_WriteObject: fileWriteObject].}
{.deprecated: [PyFile_WriteString: fileWriteString].}
{.deprecated: [PyFloat_AsDouble: floatAsDouble].}
{.deprecated: [PyFloat_FromDouble: floatFromDouble].}
{.deprecated: [PyFunction_GetCode: functionGetCode].}
{.deprecated: [PyFunction_GetGlobals: functionGetGlobals].}
{.deprecated: [PyFunction_New: functionNew].}
{.deprecated: [PyImport_AddModule: importAddModule].}
{.deprecated: [PyImport_Cleanup: importCleanup].}
{.deprecated: [PyImport_GetMagicNumber: importGetMagicNumber].}
{.deprecated: [PyImport_ImportFrozenModule: importImportFrozenModule].}
{.deprecated: [PyImport_ImportModule: importImportModule].}
{.deprecated: [PyImport_Import: importImport].}
{.deprecated: [PyImport_Init: importInit].}
{.deprecated: [PyImport_ReloadModule: importReloadModule].}
{.deprecated: [PyInstance_New: instanceNew].}
{.deprecated: [PyInt_AsLong: intAsLong].}
{.deprecated: [PyList_Append: listAppend].}
{.deprecated: [PyList_AsTuple: listAsTuple].}
{.deprecated: [PyList_GetItem: listGetItem].}
{.deprecated: [PyList_GetSlice: listGetSlice].}
{.deprecated: [PyList_Insert: listInsert].}
{.deprecated: [PyList_New: listNew].}
{.deprecated: [PyList_Reverse: listReverse].}
{.deprecated: [PyList_SetItem: listSetItem].}
{.deprecated: [PyList_SetSlice: listSetSlice].}
{.deprecated: [PyList_Size: listSize].}
{.deprecated: [PyList_Sort: listSort].}
{.deprecated: [PyLong_AsDouble: longAsDouble].}
{.deprecated: [PyLong_AsLong: longAsLong].}
{.deprecated: [PyLong_FromDouble: longFromDouble].}
{.deprecated: [PyLong_FromLong: longFromLong].}
{.deprecated: [PyLong_FromString: longFromString].}
{.deprecated: [PyLong_FromUnsignedLong: longFromUnsignedLong].}
{.deprecated: [PyLong_AsUnsignedLong: longAsUnsignedLong].}
{.deprecated: [PyLong_FromUnicode: longFromUnicode].}
{.deprecated: [PyLong_FromLongLong: longFromLongLong].}
{.deprecated: [PyLong_AsLongLong: longAsLongLong].}
{.deprecated: [PyMapping_Check: mappingCheck].}
{.deprecated: [PyMapping_GetItemString: mappingGetItemString].}
{.deprecated: [PyMapping_HasKey: mappingHasKey].}
{.deprecated: [PyMapping_HasKeyString: mappingHasKeyString].}
{.deprecated: [PyMapping_Length: mappingLength].}
{.deprecated: [PyMapping_SetItemString: mappingSetItemString].}
{.deprecated: [PyMethod_Class: methodClass].}
{.deprecated: [PyMethod_Function: methodFunction].}
{.deprecated: [PyMethod_New: methodNew].}
{.deprecated: [PyMethod_Self: methodSelf].}
{.deprecated: [PyModule_GetName: moduleGetName].}
{.deprecated: [PyModule_New: moduleNew].}
{.deprecated: [PyNumber_Absolute: numberAbsolute].}
{.deprecated: [PyNumber_Add: numberAdd].}
{.deprecated: [PyNumber_And: numberAnd].}
{.deprecated: [PyNumber_Check: numberCheck].}
{.deprecated: [PyNumber_Coerce: numberCoerce].}
{.deprecated: [PyNumber_Divide: numberDivide].}
{.deprecated: [PyNumber_FloorDivide: numberFloorDivide].}
{.deprecated: [PyNumber_TrueDivide: numberTrueDivide].}
{.deprecated: [PyNumber_Divmod: numberDivmod].}
{.deprecated: [PyNumber_Float: numberFloat].}
{.deprecated: [PyNumber_Int: numberInt].}
{.deprecated: [PyNumber_Invert: numberInvert].}
{.deprecated: [PyNumber_Long: numberLong].}
{.deprecated: [PyNumber_Lshift: numberLshift].}
{.deprecated: [PyNumber_Multiply: numberMultiply].}
{.deprecated: [PyNumber_Negative: numberNegative].}
{.deprecated: [PyNumber_Or: numberOr].}
{.deprecated: [PyNumber_Positive: numberPositive].}
{.deprecated: [PyNumber_Power: numberPower].}
{.deprecated: [PyNumber_Remainder: numberRemainder].}
{.deprecated: [PyNumber_Rshift: numberRshift].}
{.deprecated: [PyNumber_Subtract: numberSubtract].}
{.deprecated: [PyNumber_Xor: numberXor].}
{.deprecated: [PyOS_InitInterrupts: osInitInterrupts].}
{.deprecated: [PyOS_InterruptOccurred: osInterruptOccurred].}
{.deprecated: [PyObject_CallObject: objectCallObject].}
{.deprecated: [PyObject_Compare: objectCompare].}
{.deprecated: [PyObject_GetAttr: objectGetAttr].}
{.deprecated: [PyObject_GetAttrString: objectGetAttrString].}
{.deprecated: [PyObject_GetItem: objectGetItem].}
{.deprecated: [PyObject_DelItem: objectDelItem].}
{.deprecated: [PyObject_HasAttrString: objectHasAttrString].}
{.deprecated: [PyObject_Hash: objectHash].}
{.deprecated: [PyObject_IsTrue: objectIsTrue].}
{.deprecated: [PyObject_Length: objectLength].}
{.deprecated: [PyObject_Repr: objectRepr].}
{.deprecated: [PyObject_SetAttr: objectSetAttr].}
{.deprecated: [PyObject_SetAttrString: objectSetAttrString].}
{.deprecated: [PyObject_SetItem: objectSetItem].}
{.deprecated: [PyObject_Init: objectInit].}
{.deprecated: [PyObject_InitVar: objectInitVar].}
{.deprecated: [PyObject_New: objectNew].}
{.deprecated: [PyObject_NewVar: objectNewVar].}
{.deprecated: [PyObject_Free: objectFree].}
{.deprecated: [PyObject_IsInstance: objectIsInstance].}
{.deprecated: [PyObject_IsSubclass: objectIsSubclass].}
{.deprecated: [PyObject_GenericGetAttr: objectGenericGetAttr].}
{.deprecated: [PyObject_GenericSetAttr: objectGenericSetAttr].}
{.deprecated: [PyObject_GC_Malloc: objectGCMalloc].}
{.deprecated: [PyObject_GC_New: objectGCNew].}
{.deprecated: [PyObject_GC_NewVar: objectGCNewVar].}
{.deprecated: [PyObject_GC_Resize: objectGCResize].}
{.deprecated: [PyObject_GC_Del: objectGCDel].}
{.deprecated: [PyObject_GC_Track: objectGCTrack].}
{.deprecated: [PyObject_GC_UnTrack: objectGCUnTrack].}
{.deprecated: [PyRange_New: rangeNew].}
{.deprecated: [PySequence_Check: sequenceCheck].}
{.deprecated: [PySequence_Concat: sequenceConcat].}
{.deprecated: [PySequence_Count: sequenceCount].}
{.deprecated: [PySequence_GetItem: sequenceGetItem].}
{.deprecated: [PySequence_GetSlice: sequenceGetSlice].}
{.deprecated: [PySequence_In: sequenceIn].}
{.deprecated: [PySequence_Index: sequenceIndex].}
{.deprecated: [PySequence_Length: sequenceLength].}
{.deprecated: [PySequence_Repeat: sequenceRepeat].}
{.deprecated: [PySequence_SetItem: sequenceSetItem].}
{.deprecated: [PySequence_SetSlice: sequenceSetSlice].}
{.deprecated: [PySequence_DelSlice: sequenceDelSlice].}
{.deprecated: [PySequence_Tuple: sequenceTuple].}
{.deprecated: [PySequence_Contains: sequenceContains].}
{.deprecated: [PySlice_GetIndices: sliceGetIndices].}
{.deprecated: [PySlice_GetIndicesEx: sliceGetIndicesEx].}
{.deprecated: [PySlice_New: sliceNew].}
{.deprecated: [PyString_Concat: stringConcat].}
{.deprecated: [PyString_ConcatAndDel: stringConcatAndDel].}
{.deprecated: [PyString_Format: stringFormat].}
{.deprecated: [PyString_FromStringAndSize: stringFromStringAndSize].}
{.deprecated: [PyString_Size: stringSize].}
{.deprecated: [PyString_DecodeEscape: stringDecodeEscape].}
{.deprecated: [PyString_Repr: stringRepr].}
{.deprecated: [PySys_GetObject: sysGetObject].}
{.deprecated: [PySys_SetObject: sysSetObject].}
{.deprecated: [PySys_SetPath: sysSetPath].}
{.deprecated: [PyTraceBack_Here: tracebackHere].}
{.deprecated: [PyTraceBack_Print: tracebackPrint].}
{.deprecated: [PyTuple_GetItem: tupleGetItem].}
{.deprecated: [PyTuple_GetSlice: tupleGetSlice].}
{.deprecated: [PyTuple_New: tupleNew].}
{.deprecated: [PyTuple_SetItem: tupleSetItem].}
{.deprecated: [PyTuple_Size: tupleSize].}
{.deprecated: [PyType_IsSubtype: typeIsSubtype].}
{.deprecated: [PyType_GenericAlloc: typeGenericAlloc].}
{.deprecated: [PyType_GenericNew: typeGenericNew].}
{.deprecated: [PyType_Ready: typeReady].}
{.deprecated: [PyUnicode_FromWideChar: unicodeFromWideChar].}
{.deprecated: [PyUnicode_AsWideChar: unicodeAsWideChar].}
{.deprecated: [PyUnicode_FromOrdinal: unicodeFromOrdinal].}
{.deprecated: [PyWeakref_GetObject: weakrefGetObject].}
{.deprecated: [PyWeakref_NewProxy: weakrefNewProxy].}
{.deprecated: [PyWeakref_NewRef: weakrefNewRef].}
{.deprecated: [PyWrapper_New: wrapperNew].}
{.deprecated: [PyBool_FromLong: boolFromLong].}
{.deprecated: [Py_AtExit: atExit].}
{.deprecated: [Py_CompileString: compileString].}
{.deprecated: [Py_FatalError: fatalError].}
{.deprecated: [Py_FindMethod: findMethod].}
{.deprecated: [Py_FindMethodInChain: findMethodInChain].}
{.deprecated: [Py_FlushLine: flushLine].}
{.deprecated: [Py_Finalize: finalize].}
{.deprecated: [PyErr_ExceptionMatches: errExceptionMatches].}
{.deprecated: [PyErr_GivenExceptionMatches: errGivenExceptionMatches].}
{.deprecated: [PyEval_EvalCode: evalEvalCode].}
{.deprecated: [Py_GetVersion: getVersion].}
{.deprecated: [Py_GetCopyright: getCopyright].}
{.deprecated: [Py_GetExecPrefix: getExecPrefix].}
{.deprecated: [Py_GetPath: getPath].}
{.deprecated: [Py_GetPrefix: getPrefix].}
{.deprecated: [Py_GetProgramName: getProgramName].}
{.deprecated: [PyParser_SimpleParseString: parserSimpleParseString].}
{.deprecated: [PyNode_Free: nodeFree].}
{.deprecated: [PyErr_NewException: errNewException].}
{.deprecated: [Py_Malloc: malloc].}
{.deprecated: [PyMem_Malloc: memMalloc].}
{.deprecated: [PyObject_CallMethod: objectCallMethod].}
{.deprecated: [Py_SetProgramName: setProgramName].}
{.deprecated: [Py_IsInitialized: isInitialized].}
{.deprecated: [Py_GetProgramFullPath: getProgramFullPath].}
{.deprecated: [Py_NewInterpreter: newInterpreter].}
{.deprecated: [Py_EndInterpreter: endInterpreter].}
{.deprecated: [PyEval_AcquireLock: evalAcquireLock].}
{.deprecated: [PyEval_ReleaseLock: evalReleaseLock].}
{.deprecated: [PyEval_AcquireThread: evalAcquireThread].}
{.deprecated: [PyEval_ReleaseThread: evalReleaseThread].}
{.deprecated: [PyInterpreterState_New: interpreterstateNew].}
{.deprecated: [PyInterpreterState_Clear: interpreterstateClear].}
{.deprecated: [PyInterpreterState_Delete: interpreterstateDelete].}
{.deprecated: [PyThreadState_New: threadStateNew].}
{.deprecated: [PyThreadState_Clear: threadStateClear].}
{.deprecated: [PyThreadState_Delete: threadStateDelete].}
{.deprecated: [PyThreadState_Get: threadStateGet].}
{.deprecated: [PyThreadState_Swap: threadStateSwap].}

# Run the interpreter independantly of the Nim application
proc main*(argc: int, argv: CstringPtr): int{.cdecl, importc: 
  "Py_Main", dynlib: dllname.}
{.deprecated: [Py_Main: main].}
# Execute a script from a file
proc runAnyFile*(filename: string): int =
  result = runSimpleString(readFile(filename))

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
proc importExecCodeModule*(name: string, codeobject: PyObjectPtr): PyObjectPtr
{.deprecated: [PyImport_ExecCodeModule: importExecCodeModule].}
proc stringCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyString_Check: stringCheck].}
proc stringCheckExact*(obj: PyObjectPtr): bool
{.deprecated: [PyString_CheckExact: stringCheckExact].}
proc floatCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyFloat_Check: floatCheck].}
proc floatCheckExact*(obj: PyObjectPtr): bool
{.deprecated: [PyFloat_CheckExact: floatCheckExact].}
proc intCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyInt_Check: intCheck].}
proc intCheckExact*(obj: PyObjectPtr): bool
{.deprecated: [PyInt_CheckExact: intCheckExact].}
proc longCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyLong_Check: longCheck].}
proc longCheckExact*(obj: PyObjectPtr): bool
{.deprecated: [PyLong_CheckExact: longCheckExact].}
proc tupleCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyTuple_Check: tupleCheck].}
proc tupleCheckExact*(obj: PyObjectPtr): bool
{.deprecated: [PyTuple_CheckExact: tupleCheckExact].}
proc instanceCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyInstance_Check: instanceCheck].}
proc classCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyClass_Check: classCheck].}
proc methodCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyMethod_Check: methodCheck].}
proc listCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyList_Check: listCheck].}
proc listCheckExact*(obj: PyObjectPtr): bool
{.deprecated: [PyList_CheckExact: listCheckExact].}
proc dictCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyDict_Check: dictCheck].}
proc dictCheckExact*(obj: PyObjectPtr): bool
{.deprecated: [PyDict_CheckExact: dictCheckExact].}
proc moduleCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyModule_Check: moduleCheck].}
proc moduleCheckExact*(obj: PyObjectPtr): bool
{.deprecated: [PyModule_CheckExact: moduleCheckExact].}
proc sliceCheck*(obj: PyObjectPtr): bool
{.deprecated: [PySlice_Check: sliceCheck].}
proc functionCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyFunction_Check: functionCheck].}
proc unicodeCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyUnicode_Check: unicodeCheck].}
proc unicodeCheckExact*(obj: PyObjectPtr): bool
{.deprecated: [PyUnicode_CheckExact: unicodeCheckExact].}
proc typeISGC*(t: PyTypeObjectPtr): bool
{.deprecated: [PyType_IS_GC: typeISGC].}
proc objectISGC*(obj: PyObjectPtr): bool
{.deprecated: [PyObject_IS_GC: objectISGC].}
proc boolCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyBool_Check: boolCheck].}
proc basestringCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyBaseString_Check: basestringCheck].}
proc enumCheck*(obj: PyObjectPtr): bool
{.deprecated: [PyEnum_Check: enumCheck].}
proc objectTypeCheck*(obj: PyObjectPtr, t: PyTypeObjectPtr): bool
{.deprecated: [PyObject_TypeCheck: objectTypeCheck].}
proc initModule*(name: cstring, md: PyMethodDefPtr): PyObjectPtr
{.deprecated: [Py_InitModule: initModule].}
proc typeHasFeature*(AType: PyTypeObjectPtr, AFlag: int): bool
{.deprecated: [PyType_HasFeature: typeHasFeature].}

# implementation
proc incref*(op: PyObjectPtr) {.inline.} = 
  inc(op.obRefcnt)
{.deprecated: [Py_INCREF: incref].}

proc decref*(op: PyObjectPtr) {.inline.} = 
  dec(op.obRefcnt)
  if op.obRefcnt == 0: 
    op.obType.tpDealloc(op)
{.deprecated: [Py_DECREF: decref].}

proc xIncref*(op: PyObjectPtr) {.inline.} = 
  if op != nil: incref(op)
{.deprecated: [Py_XINCREF: xIncref].}
  
proc xDecref*(op: PyObjectPtr) {.inline.} = 
  if op != nil: decref(op)
{.deprecated: [Py_XDECREF: xDecref].}
  
proc importExecCodeModule(name: string, codeobject: PyObjectPtr): PyObjectPtr = 
  var m, d, v, modules: PyObjectPtr
  m = importAddModule(cstring(name))
  if m == nil: 
    return nil
  d = moduleGetDict(m)
  if dictGetItemString(d, "__builtins__") == nil: 
    if dictSetItemString(d, "__builtins__", evalGetBuiltins()) != 0: 
      return nil
  if dictSetItemString(d, "__file__", 
                          PyCodeObjectPtr(codeobject).coFilename) != 0: 
    errClear() # Not important enough to report
  v = evalEvalCode(PyCodeObjectPtr(codeobject), d, d) # XXX owner ?
  if v == nil: 
    return nil
  xDecref(v)
  modules = importGetModuleDict()
  if dictGetItemString(modules, cstring(name)) == nil: 
    errSetString(excImportError[] , cstring(
        "Loaded module " & name & "not found in sys.modules"))
    return nil
  xIncref(m)
  result = m

proc stringCheck(obj: PyObjectPtr): bool = 
  result = objectTypeCheck(obj, stringType)

proc stringCheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj.obType == stringType)

proc floatCheck(obj: PyObjectPtr): bool = 
  result = objectTypeCheck(obj, floatType)

proc floatCheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj.obType == floatType)

proc intCheck(obj: PyObjectPtr): bool = 
  result = objectTypeCheck(obj, intType)

proc intCheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj.obType == intType)

proc longCheck(obj: PyObjectPtr): bool = 
  result = objectTypeCheck(obj, longType)

proc longCheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj.obType == longType)

proc tupleCheck(obj: PyObjectPtr): bool = 
  result = objectTypeCheck(obj, tupleType)

proc tupleCheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj[].obType == tupleType)

proc instanceCheck(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj[].obType == instanceType)

proc classCheck(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj[].obType == classType)

proc methodCheck(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj[].obType == methodType)

proc listCheck(obj: PyObjectPtr): bool = 
  result = objectTypeCheck(obj, listType)

proc listCheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj[].obType == listType)

proc dictCheck(obj: PyObjectPtr): bool = 
  result = objectTypeCheck(obj, dictType)

proc dictCheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj[].obType == dictType)

proc moduleCheck(obj: PyObjectPtr): bool = 
  result = objectTypeCheck(obj, moduleType)

proc moduleCheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj[].obType == moduleType)

proc sliceCheck(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj[].obType == sliceType)

proc functionCheck(obj: PyObjectPtr): bool = 
  result = (obj != nil) and
      ((obj.obType == cfunctionType) or
      (obj.obType == functionType))

proc unicodeCheck(obj: PyObjectPtr): bool = 
  result = objectTypeCheck(obj, unicodeType)

proc unicodeCheckExact(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj.obType == unicodeType)

proc typeISGC(t: PyTypeObjectPtr): bool = 
  result = typeHasFeature(t, tpflagsHaveGc)

proc objectISGC(obj: PyObjectPtr): bool = 
  result = typeISGC(obj.obType) and
      ((obj.obType.tpIsGc == nil) or (obj.obType.tpIsGc(obj) == 1))

proc boolCheck(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj.obType == boolType)

proc basestringCheck(obj: PyObjectPtr): bool = 
  result = objectTypeCheck(obj, basestringType)

proc enumCheck(obj: PyObjectPtr): bool = 
  result = (obj != nil) and (obj.obType == enumType)

proc objectTypeCheck(obj: PyObjectPtr, t: PyTypeObjectPtr): bool = 
  result = (obj != nil) and (obj.obType == t)
  if not result and (obj != nil) and (t != nil): 
    result = typeIsSubtype(obj.obType, t) == 1
  
proc initModule(name: cstring, md: PyMethodDefPtr): PyObjectPtr = 
  result = initModule4(name, md, nil, nil, 1012)

proc typeHasFeature(AType: PyTypeObjectPtr, AFlag: int): bool = 
  #(((t)->tp_flags & (f)) != 0)
  result = (AType.tpFlags and AFlag) != 0

proc init(lib: LibHandle) = 
  debugFlag = cast[IntPtr](symAddr(lib, "Py_DebugFlag"))
  verboseFlag = cast[IntPtr](symAddr(lib, "Py_VerboseFlag"))
  interactiveFlag = cast[IntPtr](symAddr(lib, "Py_InteractiveFlag"))
  optimizeFlag = cast[IntPtr](symAddr(lib, "Py_OptimizeFlag"))
  noSiteFlag = cast[IntPtr](symAddr(lib, "Py_NoSiteFlag"))
  useClassExceptionsFlag = cast[IntPtr](
    symAddr(lib, "Py_UseClassExceptionsFlag")
  )
  frozenFlag = cast[IntPtr](symAddr(lib, "Py_FrozenFlag"))
  tabcheckFlag = cast[IntPtr](symAddr(lib, "Py_TabcheckFlag"))
  unicodeFlag = cast[IntPtr](symAddr(lib, "Py_UnicodeFlag"))
  ignoreEnvironmentFlag = cast[IntPtr](
    symAddr(lib, "Py_IgnoreEnvironmentFlag")
  )
  divisionWarningFlag = cast[IntPtr](symAddr(lib, "Py_DivisionWarningFlag"))
  noneVar = cast[PyObjectPtr](symAddr(lib, "_Py_NoneStruct"))
  ellipsis = cast[PyObjectPtr](symAddr(lib, "_Py_EllipsisObject"))
  falseVar = cast[PyIntObjectPtr](symAddr(lib, "_Py_ZeroStruct"))
  trueVar = cast[PyIntObjectPtr](symAddr(lib, "_Py_TrueStruct"))
  notImplemented = cast[PyObjectPtr](symAddr(lib, "_Py_NotImplementedStruct"))
  importFrozenModules = cast[FrozenPtrPtr](
    symAddr(lib, "PyImport_FrozenModules")
  )
  excAttributeError = cast[PyObjectPtrPtr](
    symAddr(lib, "PyExc_AttributeError")
  )
  excEOFError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_EOFError"))
  excIOError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_IOError"))
  excImportError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_ImportError"))
  excIndexError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_IndexError"))
  excKeyError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_KeyError"))
  excKeyboardInterrupt = cast[PyObjectPtrPtr](
    symAddr(lib, "PyExc_KeyboardInterrupt")
  )
  excMemoryError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_MemoryError"))
  excNameError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_NameError"))
  excOverflowError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_OverflowError"))
  excRuntimeError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_RuntimeError"))
  excSyntaxError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_SyntaxError"))
  excSystemError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_SystemError"))
  excSystemExit = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_SystemExit"))
  excTypeError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_TypeError"))
  excValueError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_ValueError"))
  excZeroDivisionError = cast[PyObjectPtrPtr](
    symAddr(lib, "PyExc_ZeroDivisionError")
  )
  excArithmeticError = cast[PyObjectPtrPtr](
    symAddr(lib, "PyExc_ArithmeticError")
  )
  excException = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_Exception"))
  excFloatingPointError = cast[PyObjectPtrPtr](
    symAddr(lib, "PyExc_FloatingPointError")
  )
  excLookupError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_LookupError"))
  excStandardError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_StandardError"))
  excAssertionError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_AssertionError"))
  excEnvironmentError = cast[PyObjectPtrPtr](
    symAddr(lib, "PyExc_EnvironmentError")
  )
  excIndentationError = cast[PyObjectPtrPtr](
    symAddr(lib, "PyExc_IndentationError")
  )
  excMemoryErrorInst = cast[PyObjectPtrPtr](
    symAddr(lib, "PyExc_MemoryErrorInst")
  )
  excNotImplementedError = cast[PyObjectPtrPtr](
    symAddr(lib, "PyExc_NotImplementedError")
  )
  excOSError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_OSError"))
  excTabError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_TabError"))
  excUnboundLocalError = cast[PyObjectPtrPtr](
    symAddr(lib, "PyExc_UnboundLocalError")
  )
  excUnicodeError = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_UnicodeError"))
  excWarning = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_Warning"))
  excDeprecationWarning = cast[PyObjectPtrPtr](
    symAddr(lib, "PyExc_DeprecationWarning")
  )
  excRuntimeWarning = cast[PyObjectPtrPtr](
    symAddr(lib, "PyExc_RuntimeWarning")
  )
  excSyntaxWarning = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_SyntaxWarning"))
  excUserWarning = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_UserWarning"))
  excOverflowWarning = cast[PyObjectPtrPtr](
    symAddr(lib, "PyExc_OverflowWarning")
  )
  excReferenceError = cast[PyObjectPtrPtr](
    symAddr(lib, "PyExc_ReferenceError")
  )
  excStopIteration = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_StopIteration"))
  excFutureWarning = cast[PyObjectPtrPtr](symAddr(lib, "PyExc_FutureWarning"))
  excPendingDeprecationWarning = cast[PyObjectPtrPtr](
    symAddr(lib, "PyExc_PendingDeprecationWarning")
  )
  excUnicodeDecodeError = cast[PyObjectPtrPtr](
    symAddr(lib, "PyExc_UnicodeDecodeError")
  )
  excUnicodeEncodeError = cast[PyObjectPtrPtr](
    symAddr(lib, "PyExc_UnicodeEncodeError")
  )
  excUnicodeTranslateError = cast[PyObjectPtrPtr](
    symAddr(lib, "PyExc_UnicodeTranslateError")
  )
  typeType = cast[PyTypeObjectPtr](symAddr(lib, "PyType_Type"))
  cfunctionType = cast[PyTypeObjectPtr](symAddr(lib, "PyCFunction_Type"))
  cobjectType = cast[PyTypeObjectPtr](symAddr(lib, "PyCObject_Type"))
  classType = cast[PyTypeObjectPtr](symAddr(lib, "PyClass_Type"))
  codeType = cast[PyTypeObjectPtr](symAddr(lib, "PyCode_Type"))
  complexType = cast[PyTypeObjectPtr](symAddr(lib, "PyComplex_Type"))
  dictType = cast[PyTypeObjectPtr](symAddr(lib, "PyDict_Type"))
  fileType = cast[PyTypeObjectPtr](symAddr(lib, "PyFile_Type"))
  floatType = cast[PyTypeObjectPtr](symAddr(lib, "PyFloat_Type"))
  frameType = cast[PyTypeObjectPtr](symAddr(lib, "PyFrame_Type"))
  functionType = cast[PyTypeObjectPtr](symAddr(lib, "PyFunction_Type"))
  instanceType = cast[PyTypeObjectPtr](symAddr(lib, "PyInstance_Type"))
  intType = cast[PyTypeObjectPtr](symAddr(lib, "PyInt_Type"))
  listType = cast[PyTypeObjectPtr](symAddr(lib, "PyList_Type"))
  longType = cast[PyTypeObjectPtr](symAddr(lib, "PyLong_Type"))
  methodType = cast[PyTypeObjectPtr](symAddr(lib, "PyMethod_Type"))
  moduleType = cast[PyTypeObjectPtr](symAddr(lib, "PyModule_Type"))
  objectType = cast[PyTypeObjectPtr](symAddr(lib, "PyObject_Type"))
  rangeType = cast[PyTypeObjectPtr](symAddr(lib, "PyRange_Type"))
  sliceType = cast[PyTypeObjectPtr](symAddr(lib, "PySlice_Type"))
  stringType = cast[PyTypeObjectPtr](symAddr(lib, "PyString_Type"))
  tupleType = cast[PyTypeObjectPtr](symAddr(lib, "PyTuple_Type"))
  unicodeType = cast[PyTypeObjectPtr](symAddr(lib, "PyUnicode_Type"))
  baseobjectType = cast[PyTypeObjectPtr](symAddr(lib, "PyBaseObject_Type"))
  bufferType = cast[PyTypeObjectPtr](symAddr(lib, "PyBuffer_Type"))
  calliterType = cast[PyTypeObjectPtr](symAddr(lib, "PyCallIter_Type"))
  cellType = cast[PyTypeObjectPtr](symAddr(lib, "PyCell_Type"))
  classmethodType = cast[PyTypeObjectPtr](symAddr(lib, "PyClassMethod_Type"))
  propertyType = cast[PyTypeObjectPtr](symAddr(lib, "PyProperty_Type"))
  seqiterType = cast[PyTypeObjectPtr](symAddr(lib, "PySeqIter_Type"))
  staticmethodType = cast[PyTypeObjectPtr](
    symAddr(lib, "PyStaticMethod_Type")
  )
  superType = cast[PyTypeObjectPtr](symAddr(lib, "PySuper_Type"))
  symtableentryType = cast[PyTypeObjectPtr](
    symAddr(lib, "PySymtableEntry_Type")
  )
  tracebackType = cast[PyTypeObjectPtr](symAddr(lib, "PyTraceBack_Type"))
  wrapperdescrType = cast[PyTypeObjectPtr](
    symAddr(lib, "PyWrapperDescr_Type")
  )
  basestringType = cast[PyTypeObjectPtr](symAddr(lib, "PyBaseString_Type"))
  boolType = cast[PyTypeObjectPtr](symAddr(lib, "PyBool_Type"))
  enumType = cast[PyTypeObjectPtr](symAddr(lib, "PyEnum_Type"))


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


