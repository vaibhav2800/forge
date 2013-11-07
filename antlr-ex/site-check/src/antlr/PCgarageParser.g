parser grammar PCgarageParser;

options {
tokenVocab=PCgarageLexer;
superClass=SiteParser;
}

@header {
package sitecheck;
}

page returns [String val]
	:	.* PRET NR {$val = $NR.text;} .*
	;
	catch [RecognitionException e] {throw e;}
