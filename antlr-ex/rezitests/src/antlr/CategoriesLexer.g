lexer grammar CategoriesLexer;

options {
filter = true;
}

@header {
package rezitests;
}

fragment
NR	:	'0'..'9'+
	;

fragment
WS	:	(' ' | '\t' | '\n' | '\r')+
	;

fragment
TITLE	:	(~'<')*
	;

CATEG_LINK
	:	n_user=NR '.' WS?
		'<a' WS 'href=\"intrebari_tema.php?idTema=' n_id=NR '\">'
		// use syntactic predicate to avoid ambiguity with TITLE
		((WS) => WS | )		// optional whitespace
		TITLE WS?
		'</a>' WS?
		{setText($n_id.text + "<" + $n_user.text + "<" + $TITLE.text);}
	;
