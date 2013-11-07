lexer grammar PageLinksLexer;

options {
filter = true;
}

@header {
package rezitests;
}

@members {
private String categ;

// If user calls a different (auto-generated) constructor,
// categ will be null and a NullPointerException will be thrown
// in PAGE_LINK to quickly indicate incorrect usage.
public PageLinksLexer(CharStream input, String categ) {
	this(input);
	this.categ = categ;
}
}

fragment
NR	:	'0'..'9'+
	;

PAGE_LINK
	:	'\"intrebari_tema.php?selectionStartIndex='
		NR
		'&idTema=' n2=NR {categ.equals($n2.text)}? '&type=&onlyValid=\"'
		{
		// strip enclosing quotes '\"'
		String s = $text;
		setText(s.substring(1, s.length() - 1));
		}
	;
