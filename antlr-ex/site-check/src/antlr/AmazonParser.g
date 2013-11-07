parser grammar AmazonParser;

options {
tokenVocab=AmazonLexer;
superClass=SiteParser;
}

@header {
package sitecheck;
}

page returns [String val]
	:	.* START_TAG DOLLAR NR END_TAG
		{$val = $NR.text;}
	;
	catch [RecognitionException e] {throw e;}
