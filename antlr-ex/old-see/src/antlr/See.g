grammar See;

options {
	output = AST;
	ASTLabelType = SeeAST;
}

tokens {
	PROGRAM_ROOT;

	FIELD_DECL;
	ARRAY_TYPE;
	ARRAY_DIMENSIONS;
	VAR_DECL;
	STRUCT='struct';

	FUNC_DECL;
	ARG_DECL;
	BLOCK='{'; RETURN='return'; IF='if'; ELSE='else'; WHILE='while';
	SEMI=';';

	PRINT='print'; LEN='len';

	EXPR;
	ASSIGN='='; LOGICAL_OR='||'; LOGICAL_AND='&&'; EQ='=='; NEQ='!=';
	LT='<'; LEQ='<='; GT='>'; GEQ='>=';
	PLUS='+'; MINUS='-'; MUL='*'; DIV='/'; MOD='%';
	LOGICAL_NOT='!'; UNARY_PLUS; UNARY_MINUS;
	DOT='.'; INDEX; CALL;

	NEW_STRUCT; NEW_ARRAY;

	NULL_LIT='null';
}

@lexer::header {
package see;
}

@parser::header {
package see;
}

@lexer::members {
/*
 * Code for implementing the #include directive.
 * Taken from http://www.antlr.org/wiki/pages/viewpage.action?pageId=557057
 */
	class SaveStruct {
		SaveStruct(CharStream input) {
			this.input = input;
			this.marker = input.mark();
		}
		public CharStream input;
		public int marker;
	}

	Stack<SaveStruct> includes = new Stack<SaveStruct>();

	// We should override this method for handling EOF of included file
	public Token nextToken() {
		Token token = super.nextToken();

		if (token.getType() == Token.EOF && !includes.empty()) {
			// We've got EOF and have non empty stack
			SaveStruct ss = includes.pop();
			setCharStream(ss.input);
			input.rewind(ss.marker);
			// this should be used instead of super [like below] to handle exits from nested includes
			// it matters, when the 'include' token is the last in previous stream (using super, lexer 'crashes' returning EOF token)
			token = this.nextToken();
		}

		// Skip first token after switching on another input
		// You need to use this rather than super as there may be nested include files
		if (((CommonToken)token).getStartIndex() < 0)
			token = this.nextToken();

		return token;
	}
}


/* Lexer rule for the #include directive */
fragment
FILENAME:	('a'..'z' | 'A'..'Z' | '0'..'9' | '.' | '_' | '-' | ' ' | '/' | ':' | '\\')+
	;
INCLUDE	:	'#' (' '|'\t')* 'include' (' '|'\t')* '<' f=FILENAME '>'
		{
			String fileName = $f.text;
			try {
				// save current lexer's state
				SaveStruct ss = new SaveStruct(input);
				includes.push(ss);
				
				// switch on new input stream
				setCharStream(new ANTLRFileStream(fileName));
				reset();
			} catch (Exception fnf) { throw new Error("Cannot open file " + fileName); }
		}
	;


/*
 * PARSER
 */

program	:	topLevelElement* -> ^(PROGRAM_ROOT topLevelElement*)
	;

topLevelElement
	:	structDeclaration
	|	globalVarDeclaration
	|	functionDeclaration
	;


structDeclaration
	:	'struct' ID '{' structMember+ '}' -> ^('struct' ID structMember+)
	;

structMember
	:	type ID (',' ID)* ';' -> ^(FIELD_DECL type ID)+
	|	structDeclaration
	;


type
@init {int level = 0;}
	:	(typeNotArray -> typeNotArray)
		(	('[' ']' {level++;})+
			-> ^(ARRAY_TYPE $type ARRAY_DIMENSIONS[Integer.toString(level)])
		)?
	;
typeNotArray
	:	primitiveType
	|	structType
	;
primitiveType
	:	'int'
	|	'double'
	|	'void'
	|	'char'
	|	'boolean'
	;
structType
	:	ID (
			('.' ID) => op='.'^ ID
			{$op.tree.setUnknownTokenBoundaries();}
		)*
	;


globalVarDeclaration
	:	type ID (',' ID)* ';' -> ^(VAR_DECL type ID)+
	;

localVarDeclaration
	:	type localVarDeclarator (',' localVarDeclarator)* ';'
		-> ^(VAR_DECL type localVarDeclarator)+
	;

localVarDeclarator
	:	ID ('=' expression)? -> ID expression?
	;

formalArgList
	:	type ID (',' type ID)* -> ^(ARG_DECL type ID)+
	;


functionDeclaration
	:	type ID '(' formalArgList? ')' block
		-> ^(FUNC_DECL type ID formalArgList? block)
	;


block	:	'{' statement* '}' -> ^('{' statement*)
	;

statement
	:	structDeclaration
	|	localVarDeclaration
	|	expression ';'!
	|	'return' expression? ';' -> ^('return' expression?)
	|	ifStat
	|	whileStat
	|	printStat
	|	';'
	|	block
	;

ifStat	:	IF '(' expression ')' s1=statement
		( (ELSE statement) => ELSE s2=statement
		| // no ELSE clause
		)
		-> ^(IF expression $s1 $s2?)
	;

whileStat
	:	WHILE '(' expression ')' statement
		-> ^(WHILE expression statement)
	;

printStat
	:	'print' expression ';' -> ^('print' expression)
	;


expression
	:	expr -> ^(EXPR[$expr.start] expr)
	;

/*
 * START expr Grammar
 * Do not call any of the rules below directly.
 * Only call `expression' as it adds a single EXPR root at the top.
 */

expr	:	assignExpr
	;

/* '=' is right to left associative */
assignExpr
	:	orExpr ('='^ assignExpr)?
	;

orExpr	:	andExpr ('||'^ andExpr)*
	;

andExpr	:	equalityExpr ('&&'^ equalityExpr)*
	;

equalityExpr
	:	relationalExpr (('=='^ | '!='^) relationalExpr)*
	;

relationalExpr
	:	additiveExpr (('<'^ | '<='^ | '>'^ | '>='^) additiveExpr)*
	;

additiveExpr
	:	multiplicativeExpr (('+'^ | '-'^) multiplicativeExpr)*
	;

multiplicativeExpr
	:	unaryExpr (('*'^ | '/'^ | '%'^) unaryExpr)*
	;

/* '!', unary '+' and unary '-' are right associative */
unaryExpr
	:	'!'^ unaryExpr
	|	op='+'^ unaryExpr {$op.setType(UNARY_PLUS);}
	|	op='-'^ unaryExpr {$op.setType(UNARY_MINUS);}
	|	lenExpr
	;

lenExpr	:	'len'^ postfixExpr
	|	postfixExpr
	;

postfixExpr
	:	newExpr
		(	op='.'^ ID
			{
				$op.tree.setUnknownTokenBoundaries();
			}
		|	op='['^ expr rbr=']'!
			{
				$op.setType(INDEX);
				$op.tree.setUnknownTokenBoundaries();
				$op.tree.setTokenStopIndex($rbr.getTokenIndex());
			}
		|	op='('^ (expr (','! expr)*)? rpar=')'!
			{
				$op.setType(CALL);
				$op.tree.setUnknownTokenBoundaries();
				$op.tree.setTokenStopIndex($rpar.getTokenIndex());
			}
		)*
	;

newExpr	:	(arrayCreator) => arrayCreator
	|	structCreator
	|	primary
	;

structCreator
	:	op='new' structType {$op.setType(NEW_STRUCT);}
		// optional parantheses, match if available
		( ('(' ')') => '(' ')' )?
		-> ^($op structType)
	;

arrayCreator
@init {int dims = 0;}
	:	op='new' baseType=typeNotArray {$op.setType(NEW_ARRAY);}
		(('[' expr ']')	=> '[' expr ']' {dims++;})+
		(('[' ']')	=> '[' ']' {dims++;})*
		-> ^($op $baseType ARRAY_DIMENSIONS[Integer.toString(dims)] expr+)
	;

primary	:	INT_LIT		{$INT_LIT.tree.primitiveLiteralVal = Integer.valueOf($INT_LIT.text);}
	|	DOUBLE_LIT	{$DOUBLE_LIT.tree.primitiveLiteralVal = Double.valueOf($DOUBLE_LIT.text);}
	|	CHAR_LIT
		{
			String s = $CHAR_LIT.text;
			s = s.substring(1, s.length() - 1);
			char c;
			if (s.length() == 1) {
				c = s.charAt(0);
			} else {
				// grammar guarantees length = 2 and first char '\\'
				switch(s.charAt(1)) {
					case 't':	c = '\t'; break;
					case 'r':	c = '\r'; break;
					case 'n':	c = '\n'; break;
					// default means '\\', '\"' or '\''
					default:	c = s.charAt(1);
				}
			}
			$CHAR_LIT.tree.primitiveLiteralVal = Character.valueOf(c);
		}
	|	BOOLEAN_LIT	{$BOOLEAN_LIT.tree.primitiveLiteralVal = Boolean.valueOf($BOOLEAN_LIT.text);}
	|	NULL_LIT
	|	ID
	|	'('! expr ')'!
	;

/*
 * END expr grammar
 */


/*
 * LEXER
 */

INT_LIT	:	'0'
	|	'1'..'9' ('0'..'9')*
	;

DOUBLE_LIT
	:	INT_LIT '.' ('0'..'9')*
	|	'.' ('0'..'9')+
	;

CHAR_LIT:	'\''
		( ~('\\'|'\r'|'\n')
		| '\\' ('t' | 'r' | 'n' | '\\' | '\"' | '\'')
		)
		'\''
	;

BOOLEAN_LIT
	:	'true' | 'false'
	;

ID	:	('a'..'z'|'A'..'Z'|'_') ('a'..'z'|'A'..'Z'|'0'..'9'|'_')*;

SL_COMMENT
	:	'//' (~('\r' | '\n'))* '\r'? '\n' {$channel = HIDDEN;}
	;

ML_COMMENT
	:	'/*' .* '*/' {$channel = HIDDEN;}
	;

WS	:	(' ' | '\t' | '\r' | '\n') {$channel = HIDDEN;}
	;
