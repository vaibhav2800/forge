lexer grammar QuestionsLexer;

options {
filter = true;
}

@header {
package rezitests;
}

@members {
boolean inTable;

static enum Data {
	Q_NR,
	Q_TITLE,
	Q_TITLE_BR,
	OPT_NAME,
	OPT_TEXT,
}

Data expected = Data.Q_NR;
}

TABLE_START
	:	'<table' (~'>')* '>'
		{inTable = true;}
	;

TABLE_END
	:	'</table>'
		{inTable = false;}
	;

//
// Rules are active only inside the table
//

// Match strikethrough tags anywhere in the table
// The parser will receive these intermixed with the other tokens below
S_ST	:	{inTable}?
		'<s>'
	;
S_END	:	{inTable}?
		'</s>'
	;



// fragment rules for <b> and <br> tags
fragment
B_ST	:	'<b>'
	;
fragment
B_END	:	'</b>'
	;
fragment
BR	:	'<br>'
	;


// if we encounter whitespace when starting a new token, discard it
WS	:	{inTable}?
		(' ' | '\t' | '\n' | '\r')+
		{$channel = HIDDEN;}
	;


/*
 * separate rules below and use `expected' to allow optional <s> and </s> tags:
 *
 * 1. Title <br>
 * &nbsp;&nbsp;&nbsp;<b>A</b>: text <br>
 * ...
 * &nbsp;&nbsp;&nbsp;<b>E</b>: text <br>
 * <b> <span onmousemove="...">Vezi raspuns</span></b> <br><br>
 *
 * 2. <s> Title </s> <br>
 * <s>&nbsp;&nbsp;&nbsp;<b>A</b>: text <br> </s>
 * <s><b> <span onmousemove="...">Vezi raspuns</span></b> <br><br></s>
 *
 * The <s> tags surround only the title text (not the nr and <br>) in the title line,
 * but the whole of the other lines (including the <br> tags).
 * So these cases must be treated differently in the grammar.
 */

fragment
NR	:	'0'..'9'+
	;
Q_NR	:	{inTable && (expected == Data.Q_NR)}?
		NR '.'
		{setText($NR.text);}
		{expected = Data.Q_TITLE;}
	;

fragment
TEXT	:	(~'<')+
	;
Q_TITLE	:	{inTable && (expected == Data.Q_TITLE)}?
		TEXT
		{expected = Data.Q_TITLE_BR;}
	;

// This rule allows Q_TITLE to be optionally surrounded by <s> tags;
// Use it to enforce grammar on input stream, but throw away this token
Q_TITLE_BR
	:	{inTable && (expected == Data.Q_TITLE_BR)}?
		BR
		{$channel = HIDDEN;}
		{expected = Data.OPT_NAME;}
	;


fragment
LETTER	:	'A'..'Z'
	;
OPT_NAME:	{inTable && (expected == Data.OPT_NAME)}?
		('&nbsp;'*) B_ST LETTER B_END ':'
		{setText($LETTER.text);}
		{expected = Data.OPT_TEXT;}
	;

OPT_TEXT:	{inTable && (expected == Data.OPT_TEXT)}?
		TEXT BR
		{setText($TEXT.text);}
		{expected = Data.OPT_NAME;}
	;

fragment
ESC_TEXT:	(~'\"')+
	;
ANSWER	:	{inTable && (expected == Data.OPT_NAME)}?
		B_ST WS?
		'<span onmousemove=\"'
		ESC_TEXT
		'\">Vezi raspuns</span>'
		B_END WS? BR BR

		{
		String s = $ESC_TEXT.text;

		// escape '\%' so ANTLR doesn't interpret as StringTemplate
		// even in the above comment :) it must be escaped
		String s1 = "Raspuns\%3A", s2 = "\%3C";
		int i1 = s.indexOf(s1) + s1.length();
		int i2 = s.indexOf(s2, i1);
		s = s.substring(i1, i2);
		s = s.replaceAll("\%20", "");
		setText(s);
		}
		{expected = Data.Q_NR;}
	;
