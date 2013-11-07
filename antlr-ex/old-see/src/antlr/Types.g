tree grammar Types;

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

bottomup
	:	exprRoot
	|	varDecl
	|	returnStat
	|	ifStat
	|	whileStat
	|	printStat
	;

/* 
 * exprRoot for variable initializer was previously matched by bottomup rule.
 * Don't mention it here (leave it `init = .?') so we don't make a second pass over it.
 */
varDecl	:	^(VAR_DECL type=. ID init=.?)
		{
		$ID.evalType = $ID.symbol.getType();
		if ($init != null)
			symtab.checkVarInit($ID, $init);
		}
	;

returnStat
	:	^(RETURN retVal=.?)
		{symtab.checkReturnStat($RETURN, $retVal);}
	;

ifStat	:	^(IF bexp=. s1=. s2=.?)
		{symtab.checkCondition($bexp);}
	;

whileStat
	:	^(WHILE bexp=. stat=.)
		{symtab.checkCondition($bexp);}
	;

printStat
	:	^(PRINT e=.)
		{symtab.checkPrintStat($e);}
	;

exprRoot:	^(EXPR expr)
		{
		$EXPR.evalType = $expr.type;
		$EXPR.symbol = $expr.start.symbol;
		}
	;

expr returns [Type type]
@after {$start.evalType = $type;}
	:	BOOLEAN_LIT	{$type = symtab.tBoolean;}
	|	CHAR_LIT	{$type = symtab.tChar;}
	|	INT_LIT		{$type = symtab.tInt;}
	|	DOUBLE_LIT	{$type = symtab.tDouble;}
	|	NULL_LIT	{$type = symtab.tNull;}
	|	primitiveType	{$type = (Type)$start.symbol;}
	|	ID		{$type = symtab.IDExprType($ID);}
	|	^(UNARY_MINUS a=expr)	{$type = symtab.uPlusMinus($a.start);}
	|	^(UNARY_PLUS a=expr)	{$type = symtab.uPlusMinus($a.start);}
	|	^(LOGICAL_NOT a=expr)	{$type = symtab.not($a.start);}
	|	^(arithmOp a=expr b=expr)	{$type = symtab.arithm($a.start, $b.start);}
	|	^('%' a=expr b=expr)	{$type = symtab.mod($a.start, $b.start);}
	|	^(relOp a=expr b=expr)	{$type = symtab.relOp($a.start, $b.start);}
	|	^(eqOp a=expr b=expr)	{$type = symtab.eqOp($a.start, $b.start);}
	|	^(logOp a=expr b=expr)	{$type = symtab.logOp($a.start, $b.start);}
	|	^(DOT a=expr ID)
		// DOT.symbol and DOT.evalType are both needed by 'new'
		// Must allow `new Outer' and `new Outer.Inner' but not `new Outer.field'
		{
		$DOT.symbol = symtab.field($a.start, $ID);

		if ($DOT.symbol == null)
			$type = symtab.tVoid;
		else if ($DOT.symbol instanceof Type)
			$type = (Type)$DOT.symbol;
		else
			$type = $DOT.symbol.getType();
		}
	|	^(INDEX a=expr b=expr)	{$type = symtab.index($a.start, $b.start);}
	|	call			{$type = $call.type;}
	|	^('=' a=expr b=expr)	{$type = symtab.assign($a.start, $b.start);}
	|	^(NEW_STRUCT a=expr)	{$type = symtab.newOpStruct($a.start);}
	|	^(NEW_ARRAY t=expr ARRAY_DIMENSIONS (i=expr {symtab.checkArrayIndexExpr($i.start);})+)
		{$type = symtab.newOpArray($t.start, $ARRAY_DIMENSIONS.int);}
	|	^(LEN a=expr)		{$type = symtab.lenOp($a.start);}
	;

arithmOp:	'+' | '-' | '*' | '/'
	;

relOp	:	'<' | '<=' | '>' | '>='
	;

eqOp	:	'==' | '!='
	;

logOp	:	'&&' | '||'
	;

call returns [Type type]
@init { List<SeeAST> args = new ArrayList<SeeAST>(); }
	:	^(CALL f=expr (a=expr {args.add($a.start);})*)
		{$type = symtab.call($f.start, args);}
	;

primitiveType
	:	('int'
	|	'double'
	|	'void'
	|	'char'
	|	'boolean')
	;
