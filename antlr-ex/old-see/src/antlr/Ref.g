tree grammar Ref;

options {
tokenVocab = See;
ASTLabelType = SeeAST;
filter = true;
}

@header {
package see;

import see.symbol.*;
}

@members {
SymbolTable symtab = SymbolTable.getInstance();
}

topdown	:	declVarParamField
	|	functionDeclaration
	|	exprRoot
	;

/*
 * The root of the type tree knows its scope; It was set by Def.g.
 * Pass this scope down to invoked rules
 */
type returns [Type t]
@after {$start.symbol = $t;}
	:	nonArr=nonArrayType[$start.scope]
		{$t = $nonArr.t;}
	|	^(ARRAY_TYPE nonArr=nonArrayType[$start.scope] ARRAY_DIMENSIONS)
		{
		if ($nonArr.t != null)
			$t = ArrayType.getInstance($nonArr.t, $ARRAY_DIMENSIONS.int);
		else
			$t = $nonArr.t;
		}
	;

nonArrayType [Scope scope] returns [Type t]
	:	pt=primitiveType[$scope] {$t = $pt.t;}
	|	st=structType[$scope] {$t = $st.t;}
	;

primitiveType [Scope scope] returns [Type t]
@after {$t = symtab.resolveSimpleType($start, $scope);}
	:	'int'
	|	'double'
	|	'void'
	|	'char'
	|	'boolean'
	;

/* Casting to (StructType) is safe.
 * The return value is either null or a Type matched as an ID (which is certainly a StructType).
 */
structType [Scope scope] returns [StructType t]
	:	ID {$t = (StructType)symtab.resolveSimpleType($ID, $scope);}
	|	^('.' st=structType[scope] ID)
		{
		if ($st.t != null)
			$t = symtab.resolveMemberType($ID, $st.t);
		else
			$t = null;
		}
	;


declVarParamField
	:	^((VAR_DECL|ARG_DECL|FIELD_DECL) type ID .?)
		{$ID.symbol.setType($type.t);}
	;

functionDeclaration
	:	^(FUNC_DECL type ID .+)
		{((FunctionSymbol)$ID.symbol).setReturnType($type.t);}
	;


/* Add source file information to imaginary EXPR node */
exprRoot:	^(EXPR expr) {$EXPR.token.setInputStream($expr.start.token.getInputStream());}
	;

expr	:	BOOLEAN_LIT
	|	CHAR_LIT
	|	INT_LIT
	|	DOUBLE_LIT
	|	NULL_LIT
	|	primitiveType[$start.scope] {$start.symbol = $primitiveType.t;}
	|	ID	{$ID.symbol = symtab.resolveSymbolRef($ID);}
	|	^(UNARY_MINUS a=expr)
	|	^(UNARY_PLUS a=expr)
	|	^(LOGICAL_NOT a=expr)
	|	^(arithmOp a=expr b=expr)
	|	^('%' a=expr b=expr)
	|	^(relOp a=expr b=expr)
	|	^(eqOp a=expr b=expr)
	|	^(logOp a=expr b=expr)
	|	^(DOT a=expr ID)
	|	^(INDEX a=expr b=expr)
	|	^(CALL expr+)
	|	^('=' a=expr b=expr)
	|	^(NEW_STRUCT expr)
	|	^(NEW_ARRAY expr ARRAY_DIMENSIONS expr+)
	|	^(LEN expr)
	;

arithmOp:	'+' | '-' | '*' | '/'
	;

relOp	:	'<' | '<=' | '>' | '>='
	;

eqOp	:	'==' | '!='
	;

logOp	:	'&&' | '||'
	;
