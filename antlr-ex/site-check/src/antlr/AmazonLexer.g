lexer grammar AmazonLexer;

options {
filter=true;
}

@header {
package sitecheck;
}

START_TAG
	:	'<b class="priceLarge">'
	;

DOLLAR	:	'$'
	;

END_TAG	:	'</b>'
	;

fragment
DIGIT	:	'0'..'9'
	;

NR	:	DIGIT (DIGIT | ',')* '.' DIGIT DIGIT
	;