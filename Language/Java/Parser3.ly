> {
> module Language.Java.Parser3 where
>
> import Language.Java.Lexer
> import Language.Java.Syntax
 import Language.Java.ParseUtils
>
> import Data.Maybe (catMaybes)
> }

> %tokentype { Token }
> %token
>   'abstract'      { KW_Abstract     }
>   'assert'        { KW_Assert       }
>   'boolean'       { KW_Boolean      }
>   'break'         { KW_Break        }
>   'byte'          { KW_Byte         }
>   'case'          { KW_Case         }
>   'catch'         { KW_Catch        }
>   'char'          { KW_Char         }
>   'class'         { KW_Class        }
>   'const'         { KW_Const        }
>   'continue'      { KW_Continue     }
>   'default'       { KW_Default      }
>   'do'            { KW_Do           }
>   'double'        { KW_Double       }
>   'else'          { KW_Else         }
>   'enum'          { KW_Enum         }
>   'extends'       { KW_Extends      }
>   'final'         { KW_Final        }
>   'finally'       { KW_Finally      }
>   'float'         { KW_Float        }
>   'for'           { KW_For          }
>   'goto'          { KW_Goto         }
>   'if'            { KW_If           }
>   'implements'    { KW_Implements   }
>   'import'        { KW_Import       }
>   'instanceof'    { KW_Instanceof   }
>   'int'           { KW_Int          }
>   'interface'     { KW_Interface    }
>   'long'          { KW_Long         }
>   'native'        { KW_Native       }
>   'new'           { KW_New          }
>   'package'       { KW_Package      }
>   'private'       { KW_Private      }
>   'protected'     { KW_Protected    }
>   'public'        { KW_Public       }
>   'return'        { KW_Return       }
>   'short'         { KW_Short        }
>   'static'        { KW_Static       }
>   'strictfp'      { KW_Strictfp     }
>   'super'         { KW_Super        }
>   'switch'        { KW_Switch       }
>   'synchronized'  { KW_Synchronized }
>   'this'          { KW_This         }
>   'throw'         { KW_Throw        }
>   'throws'        { KW_Throws       }
>   'transient'     { KW_Transient    }
>   'try'           { KW_Try          }
>   'void'          { KW_Void         }
>   'volatile'      { KW_Volatile     }
>   'while'         { KW_While        }

>   '('             { OpenParen     }
>   ')'             { CloseParen    }
>   '['             { OpenSquare    }
>   ']'             { CloseSquare   }
>   '{'             { OpenCurly     }
>   '}'             { CloseCurly    }
>   ';'             { SemiColon     }
>   ','             { Comma         }
>   '.'             { Period        }

>   INT             { IntTok $$ }
>   LONG            { LongTok $$ }
>   DOUBLE          { DoubleTok $$ }
>   FLOAT           { FloatTok $$ }
>   CHAR            { CharTok $$ }
>   STRING          { StringTok $$ }
>   BOOLEAN         { BoolTok $$ }
>   NULL            { NullTok }

>   IDENT           { IdentTok $$ }

>   '='             { Op_Equal     }
>   '>'             { Op_GThan     }
>   '<'             { Op_LThan     }
>   '!'             { Op_Bang      }
>   '~'             { Op_Tilde     }
>   '?'             { Op_Query     }
>   ':'             { Op_Colon     }
>   '=='            { Op_Equals    }
>   '<='            { Op_LThanE    }
>   '>='            { Op_GThanE    }
>   '!='            { Op_BangE     }
>   '&&'            { Op_AAnd      }
>   '||'            { Op_OOr       }
>   '++'            { Op_PPlus     }
>   '--'            { Op_MMinus    }
>   '+'             { Op_Plus      }
>   '-'             { Op_Minus     }
>   '*'             { Op_Star      }
>   '/'             { Op_Slash     }
>   '&'             { Op_And       }
>   '|'             { Op_Or        }
>   '^'             { Op_Caret     }
>   '%'             { Op_Percent   }
>   '<<'            { Op_LShift    }
>   '>>'            { Op_RShift    }
>   '>>>'           { Op_RRShift   }
>   '+='            { Op_PlusE     }
>   '-='            { Op_MinusE    }
>   '*='            { Op_StarE     }
>   '/='            { Op_SlashE    }
>   '&='            { Op_AndE      }
>   '|='            { Op_OrE       }
>   '^='            { Op_CaretE    }
>   '%='            { Op_PercentE  }
>   '<<='           { Op_LShiftE   }
>   '>>='           { Op_RShiftE   }
>   '>>>='          { Op_RRShiftE  }


> %name mparse compilationUnit
> %%

----------------------------------------------------------------------------
-- Packages and compilation units

> compilationUnit   :: { CompilationUnit }
>       : opt(packageDecl) list(importDecl) list(typeDecl)      
>               { CompilationUnit $1 $2 (catMaybes $3) }

> packageDecl       :: { PackageDecl }
>       : 'package' name ';'            { PackageDecl $2 }

> importDecl        :: { ImportDecl }
>       : 'import' bopt('static') name bopt(dotStar) ';'        
>               { ImportDecl $2 $3 $4 }

> dotStar :: { () }
>       : '.' '*'                       { () }

> typeDecl          :: { Maybe TypeDecl }
>       : classOrInterfaceDecl          { Just $1 }
>       | ';'                           { Nothing }

----------------------------------------------------------------------------
-- Declarations

-- Class declarations

> classOrInterfaceDecl  :: { TypeDecl }
>       : list(modifier) classDecl                     { ClassTypeDecl ($2 $1) }
-- TODO: modifier = public private protected abstract static strictfp final
>       | list(modifier) interfaceDecl                 { InterfaceTypeDecl ($2 $1) }
-- TODO: modifier = public private protected abstract static strictfp

> classDecl         :: { Mod ClassDecl }
>       : normalClassDecl               { $1 }
>       | enumClassDecl                 { $1 }

> normalClassDecl   :: { Mod ClassDecl }
>       : 'class' ident lopt(typeParams) opt(extends) lopt(implements) classBody
>               { \ms -> ClassDecl ms $2 $3 ((fmap head) $4) $5 $6 }
-- TODO: check that the extends clause only contains one type.

> enumClassDecl     :: { Mod ClassDecl }
>       : 'enum' ident lopt(implements) enumBody
>               { \ms -> EnumDecl ms $2 $3 $4 }

> extends           :: { [RefType] }
>       : 'extends' refTypeList                 { $2 }

> implements        :: { [RefType] }
>       : 'implements' refTypeList              { $2 }

> classBody         :: { ClassBody }
>       : '{' classBodyDecls '}'                { ClassBody $2 }

> enumBody          :: { EnumBody }
>       : '{' seplist(enumConst,',') opt(',') lopt(enumBodyDecls) '}'
>               { EnumBody $2 $4 }

> enumBodyDecls     :: { [Decl] }
>       : ';' classBodyDecls                    { $2 }

> enumConst         :: { EnumConstant }
>       : ident lopt(args) opt(classBody)
>               { EnumConstant $1 $2 $3 }

> classBodyDecls    :: { [Decl] }
>       : list(classBodyDecl)                   { $1 }

-- Interface declarations

> interfaceDecl     :: { Mod InterfaceDecl }
>       : 'interface' ident lopt(typeParams) lopt(extends) interfaceBody
>               { \ms -> InterfaceDecl ms $2 $3 $4 $5 }

> interfaceBody     :: { InterfaceBody }
>       : '{' list(interfaceBodyDecl) '}'          { InterfaceBody (catMaybes $2) }

-- Declarations

> classBodyDecl         :: { Decl }
>       : list(modifier) memberDecl     { MemberDecl ($2 $1) }
-- TODO: Check that the modifiers on the memberDecl are valid
>       | bopt('static') block          { InitDecl $1 $2 }

> memberDecl            :: { Mod MemberDecl }
>       : fieldDecl         { $1 }
>       | methodDecl        { $1 }
>       | constrDecl        { $1 }
>       | classDecl         { MemberClassDecl . $1 }
>       | interfaceDecl     { MemberInterfaceDecl . $1 }

> fieldDecl             :: { Mod MemberDecl }
>       : type varDecls     { \ms -> FieldDecl ms $1 $2 }

> methodDecl            :: { Mod MemberDecl }
>       : lopt(typeParams) resultType ident formalParams lopt(throws) methodBody
>               { \ms -> MethodDecl ms $1 $2 $3 $4 $5 $6 }

> methodBody            :: { MethodBody }
>       : ';'                               { MethodBody Nothing }
>       | block                             { MethodBody (Just $1) }

> constrDecl            :: { Mod MemberDecl }
>       : lopt(typeParams) ident formalParams  lopt(throws) constrBody
>               { \ms -> ConstructorDecl ms $1 $2 $3 $4 $5 }

> constrBody            :: { ConstructorBody }
>       : '{' opt(explConstrInv) list(blockStmt) '}'
>               { ConstructorBody $2 $3 }

> explConstrInv         :: { ExplConstrInv }
>      :             lopt(refTypeArgs) 'this'  args ';'      { ThisInvoke  $1 $3 }
>      |             lopt(refTypeArgs) 'super' args ';'      { SuperInvoke $1 $3 }
>      | primary '.' lopt(refTypeArgs) 'super' args ';'      { PrimarySuperInvoke $1 $3 $5 }

-- TODO: This should be parsed like class bodies, and post-checked.
--       That would give far better error messages.
> interfaceBodyDecl     :: { Maybe MemberDecl }
>       : list(modifier) interfaceMemberDecl            { Just ($2 $1) }
>       | ';'                                           { Nothing }

> interfaceMemberDecl   :: { Mod MemberDecl }
>       : fieldDecl         { $1 }
>       | absMethodDecl     { $1 }
>       | classDecl         { MemberClassDecl . $1 }
>       | interfaceDecl     { MemberInterfaceDecl . $1 }

> absMethodDecl         :: { Mod MemberDecl }
>       : lopt(typeParams) resultType ident formalParams lopt(throws) ';'
>               { \ms -> MethodDecl ms $1 $2 $3 $4 $5 (MethodBody Nothing) }

> throws                :: { [ExceptionType] }
>       : 'throws' seplist1(refType,',')      { $2 }


-- Formal parameters

> formalParams             :: { [FormalParam] }
>       : '(' formalParamsAux ')'                           { $2 }

> formalParamsAux          :: { [FormalParam] }
>       : {- empty -}                                       { [] }
>       | lastFormalParam                                   { [$1] }
>       | seplist1(formalParam,',') ',' lastFormalParam     { $1 ++ [$3] }

> lastFormalParam       :: { FormalParam }
>       : list(modifier) type optEllipsis varDeclId
>           { FormalParam $1 $2 $3 $4 }         -- TODO: modifier = final

> formalParam           :: { FormalParam }
>       : list(modifier) type varDeclId
>           { FormalParam $1 $2 False $3 }      -- TODO: modifier = final

> optEllipsis           :: { Bool }
>       : '.' '.' '.'       { True }
>       | {- empty -}       { False }


-- Modifiers

> modifier      :: { Modifier }
>       : 'public'                  { Public    }
>       | 'protected'               { Protected }
>       | 'private'                 { Private   }
>       | 'abstract'                { Abstract  }
>       | 'static'                  { Static    }
>       | 'strictfp'                { StrictFP  }
>       | 'final'                   { Final }
>       | 'native'                  { Native }
>       | 'transient'               { Transient }
>       | 'volatile'                { Volatile }

----------------------------------------------------------------------------
-- Variable declarations

> varDecl           :: { VarDecl }
>       : varDeclId opt(varInit)            { VarDecl $1 $2 }

> varDeclId         :: { VarDeclId }
>       : ident list(arrBrackets)
>               { foldr (\_ f -> VarDeclArray . f) VarId $2 $1 }

> varDecls          :: { [VarDecl] }
>       : seplist1(varDecl,',')             { $1 }

> arrBrackets       :: { () }
>       : '[' ']'                           { () }

> localVarDecl      :: { ([Modifier], Type, [VarDecl]) }
>       : list(modifier) type varDecls      { ($1,$2,$3) }
        -- TODO: modifier = public protected private static final transient volatile

> varInit               :: { VarInit }
>       : '=' exp                   { InitExp $2 }
>       | '=' arrayInit             { InitArray $2 }

> arrayInit             :: { ArrayInit }
>       : '{' seplist(varInit,',') opt(',') '}' { ArrayInit $2 }

----------------------------------------------------------------------------
-- Statements

> block                 :: { Block }
>       : '{' list(blockStmt) '}'                   { Block $2 }

> blockStmt             :: { BlockStmt }
>       : list(modifier) classDecl                  { LocalClass ($2 $1) }
>       | localVarDecl ';'    { let (m,t,vds) = $1 in LocalVars m t vds }
>       | stmt                                      { BlockStmt $1 }

> stmt                  :: { Stmt }
>       : ident ':' stmt                            { Labeled $1 $3 }
>       | 'if' '(' exp ')' stmt                     { IfThen $3 $5 }
>       | 'if' '(' exp ')' stmtNSI 'else' stmt      { IfThenElse $3 $5 $7 }
>       | 'while' '(' exp ')' stmt                  { While $3 $5 }
>       | 'for' '(' opt(forInit) ';' opt(exp) ';' opt(forUp) ')' stmt
>               { BasicFor $3 $5 $7 $9 }
>       | 'for' '(' list(modifier) type ident ':' exp ')' stmt
>               { EnhancedFor $3 $4 $5 $7 $9 }
>       | stmtNoTrail                               { $1 }

> stmtNoTrail           :: { Stmt }
>       : block                                     { StmtBlock $1 }
>       | ';'                                       { Empty }
>       | stmtExp ';'                               { ExpStmt $1 }
>       | 'assert' exp opt(assertExp2) ';'          { Assert $2 $3  }
>       | 'switch' '(' exp ')' switchBlock          { Switch $3 $5 }
>       | 'do' stmt 'while' '(' exp ')' ';'         { Do $2 $5 }
>       | 'break' opt(ident) ';'                    { Break $2 }
>       | 'continue' opt(ident) ';'                 { Continue $2 }
>       | 'return' opt(exp) ';'                     { Return $2 }
>       | 'synchronized' '(' exp ')' block          { Synchronized $3 $5 }
>       | 'throw' exp ';'                           { Throw $2 }
>       | 'try' block catches                       { Try $2 $3 Nothing }
>       | 'try' block lopt(catches) 'finally' block { Try $2 $3 (Just $5) }

> stmtNSI               :: { Stmt }
>       : stmtNoTrail                               { $1 }
>       | ident ':' stmtNSI                         { Labeled $1 $3 }
>       | 'if' '(' exp ')' stmtNSI 'else' stmtNSI   { IfThenElse $3 $5 $7 }
>       | 'while' '(' exp ')' stmtNSI               { While $3 $5 }
>       | 'for' '(' opt(forInit) ';' opt(exp) ';' opt(forUp) ')' stmtNSI
>               { BasicFor $3 $5 $7 $9 }
>       | 'for' '(' list(modifier) type ident ':' exp ')' stmtNSI
>               { EnhancedFor $3 $4 $5 $7 $9 }

> assertExp2            :: { Exp }
>       : ':' exp                                   { $2 }

-- Switches

> switchBlock           :: { [SwitchBlock] }
>       : '{' list(switchStmt) '}'                  { $2 }

> switchStmt            :: { SwitchBlock }
>       : switchLabel list(blockStmt)               { SwitchBlock $1 $2 }

> switchLabel           :: { SwitchLabel }
>       : 'case' exp ':'                            { SwitchCase $2 }
>       | 'default' ':'                             { Default }

-- For loops

> forInit               :: { ForInit }
>       : localVarDecl            { let (m,t,vds) = $1 in ForLocalVars m t vds }
>       | seplist1(stmtExp,',')                         { ForInitExps $1 }

> forUp                 :: { [Exp] }
>       : seplist1(stmtExp,',')                         { $1 }

-- Try-catch clauses

> catches               :: { [Catch] }
>       : list1(catch)                              { $1 }

> catch                 :: { Catch }
>       : 'catch' '(' formalParam ')' block         { Catch $3 $5 }

----------------------------------------------------------------------------
-- Expressions

> stmtExp :: { Exp }
>       : postIncDec                { $1 }
>       | preIncDec                 { $1 }
>       | assignment                { $1 }
>       | methodInvocation          { MethodInv $1 }
>       | instanceCreation          { $1 }

> postIncDec            :: { Exp }
>       : postfixExp postfixOp      { $2 $1 }

> preIncDec             :: { Exp }
>       : preIncDecOp unaryExp      { $1 $2 }

> assignment            :: { Exp }
>       : lhs assignOp assignExp        { Assign $1 $2 $3 }

> lhs                   :: { Lhs }
>       : name                          { NameLhs $1 }
>       | fieldAccess                   { FieldLhs $1 }
>       | arrayAccess                   { ArrayLhs (fst $1) (snd $1) }

> exp                   :: { Exp }
>       : assignExp                     { $1 }

> assignExp             :: { Exp }
>       : assignment                    { $1 }
>       | condExp                       { $1 }

> condExp               :: { Exp }
>       : condExp '?' exp ':' condExp   { Cond $1 $3 $5 }
>       | infixExp                      { $1 }

-- TODO: Fix precedence
> infixExp              :: { Exp }
>       : infixExp infixOp unaryExp     { BinOp $1 $2 $3 }
>       | infixExp 'instanceof' refType { InstanceOf $1 $3 }

> unaryExp              :: { Exp }
>       : preIncDec                     { $1 }
>       | prefixOp unaryExp             { $1 $2 }
>       | '(' type ')' unaryExp         { Cast $2 $4 }
>       | postfixExp                    { $1 }


> postfixExp            :: { Exp }
>       : primary               { $1 }
>       | name                  { ExpName $1 }
>       | postIncDec            { $1 }


> primary               :: { Exp }
>       : primaryNoNewArray         { $1 }
>       | arrayCreation             { $1 }

> primaryNoNewArray     :: { Exp }
>       : literal                   { Lit $1 }
>       | resultType '.' 'class'    { ClassLit $1 }
>       | 'this'                    { This }
>       | name '.' 'this'           { ThisClass $1 }
>       | '(' exp ')'               { Paren $2 }
>       | instanceCreation          { $1 }
>       | fieldAccess               { FieldAccess $1 }
>       | methodInvocation          { MethodInv $1 }
>       | arrayAccess               { ArrayAccess (fst $1) (snd $1) }

> instanceCreation      :: { Exp }
>       :             'new' lopt(typeArgs) classType args opt(classBody)
>              { InstanceCreation $2 $3 $4 $5 }
>       | primary '.' 'new' lopt(typeArgs) ident args opt(classBody)
>              { QualInstanceCreation $1 $4 $5 $6 $7 }

> fieldAccess          :: { FieldAccess }
>       : primary '.' ident             { PrimaryFieldAccess $1 $3 }
>       | 'super' '.' ident             { SuperFieldAccess      $3 }
>       | name '.' 'super' '.' ident    { ClassFieldAccess   $1 $5 }

> methodInvocation     :: { MethodInvocation }
>       : name args                 { MethodCall $1 $2 }
>       | primary '.' lopt(refTypeArgs) ident args      
>               { PrimaryMethodCall $1 $3 $4 $5 }
>       | 'super' '.' lopt(refTypeArgs) ident args
>               { SuperMethodCall      $3 $4 $5 }
>       | name '.' 'super' '.' lopt(refTypeArgs) ident args
>               { ClassMethodCall   $1 $5 $6 $7 }
>       | name '.' lopt(refTypeArgs) ident args
>               { TypeMethodCall    $1 $3 $4 $5 }

> args                  :: { [Argument] }
>       : '(' seplist(exp,',') ')'               { $2 }

-- Arrays

> arrayAccess            :: { (Exp, Exp) }
>       : arrayRef '[' exp ']'          { ($1, $3) }

> arrayRef              :: { Exp }
>       : name                          { ExpName $1 }
>       | primaryNoNewArray             { $1 }

> arrayCreation         :: { Exp }
>       : 'new' type list1(dimExpr) dims        { ArrayCreate $2 $3 $4 }
>       | 'new' type dims1 arrayInit            { ArrayCreateInit $2 $3 $4 }

> dimExpr               :: { Exp }
>       : '[' exp ']'                   { $2 }

> dims                  :: { Int }
>       : opt(dims1)                    { maybe 0 id $1 }

> dims1                 :: { Int }
>       : list1(dim)                    { length $1 }

> dim                   :: { () }
>       : '[' ']'                       { () }

-- Literals

> literal               :: { Literal }
>       : INT                           { Int $1 }
>       | LONG                          { Word $1 }
>       | FLOAT                         { Float $1 }
>       | DOUBLE                        { Double $1 }
>       | BOOLEAN                       { Boolean $1 }
>       | CHAR                          { Char $1 }
>       | STRING                        { String $1 }
>       | NULL                          { Null }


-- Operators

> infixOp               :: { Op }
>       : '*'                       { Mult    }
>       | '/'                       { Div     }
>       | '%'                       { Rem     }
>       | '+'                       { Add     }
>       | '-'                       { Sub     }
>       | '<<'                      { LShift  }
>       | '>>'                      { RShift  }
>       | '>>>'                     { RRShift }
>       | '<'                       { LThan   }
>       | '>'                       { GThan   }
>       | '<='                      { LThanE  }
>       | '>='                      { GThanE  }
>       | '=='                      { Equal   }
>       | '!='                      { NotEq   }
>       | '&'                       { And     }
>       | '^'                       { Xor     }
>       | '|'                       { Or      }
>       | '&&'                      { CAnd    }
>       | '||'                      { COr     }

> assignOp              :: { AssignOp }
>       : '='                           { EqualA }
>       | '*='                          { MultA }
>       | '/='                          { DivA }
>       | '%='                          { RemA }
>       | '+='                          { AddA }
>       | '-='                          { SubA }
>       | '<<='                         { LShiftA }
>       | '>>='                         { RShiftA }
>       | '>>>='                        { RRShiftA }
>       | '&='                          { AndA }
>       | '^='                          { XorA }
>       | '|='                          { OrA }

> preIncDecOp           :: { Exp -> Exp }
>       : '++'                          { PreIncrement }
>       | '--'                          { PreDecrement }

> prefixOp              :: { Exp -> Exp }
>       : '!'                           { PreNot }
>       | '~'                           { PreBitCompl }
>       | '+'                           { PrePlus }
>       | '-'                           { PreMinus }

> postfixOp             :: { Exp -> Exp }
>       : '++'                          { PostIncrement }
>       | '--'                          { PostDecrement }

----------------------------------------------------------------------------
-- Types

> type          :: { Type }
>       : refType               { RefType $1 }
>       | primType              { PrimType $1 }

> primType      :: { PrimType }
>       : 'boolean'             { BooleanT  }
>       | 'byte'                { ByteT     }
>       | 'short'               { ShortT    }
>       | 'int'                 { IntT      }
>       | 'long'                { LongT     }
>       | 'char'                { CharT     }
>       | 'float'               { FloatT    }
>       | 'double'              { DoubleT   }

> refType       :: { RefType }
>       : type '[' ']'                          { ArrayType $1 }
>       | classType                             { ClassRefType $1 }
-- No longer relevant:
       | ident                                 { TypeVariable $1 }

> classType     :: { ClassType }
>       : seplist1(classTypeSpec,'.')           { ClassType $1 }

> classTypeSpec :: { (Ident, [TypeArgument]) }
>       : ident lopt(typeArgs)                  { ($1, $2) }

> resultType  :: { Maybe Type }
>       : 'void'                { Nothing }
>       | type                  { Just $1 }

> refTypeList    :: { [RefType] }
>       : seplist1(refType,',')     { $1 }

----------------------------------------------------------------------------
-- Type parameters and arguments

> typeParams    :: { [TypeParam] }
>       : '<' seplist1(typeParam,',') '>'    { $2 }

> typeParam     :: { TypeParam }
>       : ident lopt(bounds)                { TypeParam $1 $2 }

> bounds        :: { [RefType] }
>       : 'extends' seplist1(refType,'&')   { $2 }


> typeArgs      :: { [TypeArgument] }
>       : '<' seplist1(typeArg,',') '>'      { $2 }

> typeArg       :: { TypeArgument }
>       : refType                           { ActualType $1 }
>       | '?' opt(wildcardBound)            { Wildcard $2 }

> wildcardBound :: { WildcardBound }
>       : 'extends' refType                 { ExtendsBound $2 }
>       | 'super' refType                   { SuperBound $2 }

> refTypeArgs   :: { [RefType] }
>       : '<' seplist1(refType,',') '>'      { $2 }

----------------------------------------------------------------------------
-- Names

> ident :: { Ident }
>       : IDENT                 { Ident $1 }

> name  :: { Name }
>       : seplist1(ident,'.')   { Name $1 }

----------------------------------------------------------------------------
-- Higher-order productions

> opt(p)    : p                     { Just $1 }
>           |                       { Nothing }
    
> lopt(p)   : opt(p)                { maybe [] id $1 }

> bopt(p)   : opt(p)                { maybe False (const True) $1 }
    
 fopt(p)   : opt(p)                { maybe id id $1 }

> list(p)   : list1(p)              { $1 }
>           |                       { [] }
    
> list1(p)  : p                     { [$1] }
>           | p list1(p)            { $1 : $2 }

> seplist(p,s)  : seplist1(p,s)     { $1 }
>               |                   { [] }

> seplist1(p,s) : p                     { [$1] }
>               | p s seplist1(p,s)     { $1 : $3 }

 flist(p)  : list(p)               { foldr (.) id $1 }


----------------------------------------------------------------------------
-- Helper functions

> {

> happyError = undefined

> type Mod a = [Modifier] -> a

> }