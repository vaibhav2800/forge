lexer grammar EmagLexer;

options {
filter = true;
}

@header {
package sitecheck;
}

fragment
DIGIT	:	'0'..'9';

NR	:	DIGIT	// first digit
		((DIGIT | '.')* DIGIT)? // digits and dots, ending in digit
	;

MARK	:	',<sup class="money-decimal">' DIGIT DIGIT '</sup> Lei';

// some items will have a 'strikethrough-ed' price inside this tag
IGNORE	:	'<span class="pret-pachet-taiat">' .* '</span>' {skip();};

// Don't skip 'all else' in the lexer, otherwise:
// NR [random text] MARK will end up as NR MARK in the parser
REST	:	.
	;
