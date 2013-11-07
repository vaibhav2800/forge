lexer grammar PCgarageLexer;

options {
filter = true;
}

@header {
package sitecheck;
}

PRET	:	'Pret:';

ID	:	('a'..'z' | 'A'..'Z')+ {$channel = HIDDEN;};

NR	:	DIGIT
		((DIGIT | '.')* DIGIT)?
		',' DIGIT DIGIT
	;

fragment
DIGIT	:	'0'..'9';
