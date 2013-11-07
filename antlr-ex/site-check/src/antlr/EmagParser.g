parser grammar EmagParser;

options {
tokenVocab = EmagLexer;
superClass = SiteParser;
}

@header {
package sitecheck;
}

page returns [String val]
	:	((NR MARK) => NR MARK {$val = $NR.text; return $val;}
		| .
		)*
	;
	catch [RecognitionException e] {throw e;}
