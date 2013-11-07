tree grammar Def;

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
Scope crtScope = symtab.globalScope;
/** Needed for return statements. RETURN.symbol = crtFunction. */
FunctionSymbol crtFunction;
}

topdown	:	declVarParamField
	|	enterStruct
	|	enterFunc
	|	enterBlock
	|	returnStat
	|	idRef
	|	primitiveRef
	;

bottomup:	exitStruct
	|	exitFunc
	|	exitBlock
	;


declVarParamField
	:	^((VAR_DECL|ARG_DECL|FIELD_DECL) typeTree=. id=ID .?)
		{
		symtab.defineVariable($id, crtScope);
		$typeTree.scope = crtScope;
		}
	;


enterStruct
	:	^('struct' ID .*)
		{
		StructType ss = symtab.defineStruct($ID, crtScope);
		crtScope = ss;
		}
	;
exitStruct
	:	'struct'
		{crtScope = crtScope.parent;}
	;


enterFunc
	:	^(FUNC_DECL typeTree=. ID .+)
		{
		FunctionSymbol fs = symtab.defineFunction($ID, crtScope);
		crtFunction = fs;
		$typeTree.scope = crtScope;
		crtScope = fs;
		}
	;
exitFunc:	FUNC_DECL
		{crtScope = crtScope.parent;}
	;


enterBlock
	:	BLOCK
		{crtScope = symtab.defineLocalScope(crtScope);}
	;
exitBlock
	:	BLOCK
		{crtScope = crtScope.parent;}
	;


returnStat
	:	RETURN
		{$RETURN.symbol = crtFunction;}
	;


idRef	:	{$start.hasAncestor(EXPR)}? ID
		{$ID.scope = crtScope;}
	;

/* Not really needed, but keeping consistent with
 * resolving types (including primitives) in Ref.g and in general, using scopes.
 * This is required for `new int[5][]' (where primitiveRef is in an expression).
 */
primitiveRef
	:	{$start.hasAncestor(EXPR)}?
	(	'int'
	|	'double'
	|	'void'
	|	'char'
	|	'boolean'
	)
	{$start.scope = crtScope;}
	;
