grammar Config;

@lexer::header {
package sitecheck;
}

@header {
package sitecheck;

import java.util.Map;
import java.util.HashMap;
}

@members {
public static class Entry {
	public final String key, value;

	public Entry(String key, String value) {
		this.key = key;
		this.value = value;
	}
}
}

EQ	:	'=';

LEADING_COMMENT
	:	// only at start of line
		{getCharPositionInLine()==0}? =>
		(' ' | '\t')* '#'	// allow leading whitespace
		(~('\n' | '\r'))*	// match everything until end of line
		(NEWLINE | EOF)
		{skip();}
	;

DATA	:	~('\r' | '\n' | '=')+
	;

NEWLINE	:	'\r'? '\n';


line_kv returns [String key, String value]
@init {
	$value="";
}
	:	k=DATA {$key = $k.text;}
		EQ
		// value may contain the '=' character
		( v=(DATA | EQ) {$value += $v.text;} )*
		(NEWLINE | EOF)
	;
	catch [RecognitionException e] {throw e;}

file returns [Map<String, String> map, List<Entry> list]
@init {
	$map = new HashMap<String, String>();
	$list = new ArrayList<Entry>();
}
	:
	(	kv=line_kv
		{
		$map.put($kv.key, $kv.value);
		$list.add(new Entry($kv.key, $kv.value));
		}
	|	NEWLINE //empty line
	)*
	EOF
	;
	catch [RecognitionException e] {throw e;}
