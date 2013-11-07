grammar upp;

@parser::header {
package upp;
}

@lexer::header {
package upp;

import java.util.LinkedList;
import java.util.TreeMap;
}

@lexer::members {
public final Map<String, List<String>>
		mapInstall = new TreeMap<String, List<String>>(String.CASE_INSENSITIVE_ORDER),
		mapOptional = new TreeMap<String, List<String>>(String.CASE_INSENSITIVE_ORDER),
		mapRemove = new TreeMap<String, List<String>>(String.CASE_INSENSITIVE_ORDER);

public final List<Category> cats = new LinkedList<Category>();

{
	// instance initializer block
	cats.add(new Category("(no category)"));
}

private void addPackages(Map<String, List<String>> map, String key, String packageStr) {
	List<String> list = map.get(key);
	if (list == null) {
		list = new LinkedList<String>();
		map.put(key, list);
	}

	String[] packages = packageStr.trim().split("[ \\t]+");
	for (String s : packages)
		list.add(s);
}
}

fragment WS		:	(' ' | '\t');

fragment BODY_END	: ']';
fragment PCK_INST	: '@';
fragment PCK_OPT	: '?';
fragment PCK_DEL	: '^';
fragment FREETEXT_START	: (~(BODY_END | PCK_INST | PCK_OPT | PCK_DEL | WS | '\n'));

fragment LINE	:	(~'\n')*;
fragment LINE_NO_PCKINST	:	(~('\n' | PCK_INST))*;
fragment LINE_NO_PCKOPT		:	(~('\n' | PCK_OPT))*;
fragment LINE_NO_PCKDEL		:	(~('\n' | PCK_DEL))*;


TOP_LEVEL_ELEMENT
@init {
String itemName="", label="", tmp="";
boolean hasFreeText = false;
}
:	(~'\n')* '\n' {tmp = $text.trim();}
	(
		// empty line; ignore
		{tmp.isEmpty()}?=> {$channel = HIDDEN;}
	|
		// item
		{tmp.endsWith("[")}?=>
		{itemName = tmp.substring(0, tmp.length()-1).trim();}
		(WS*
			(a=PCK_INST
				((LINE_NO_PCKINST PCK_INST) => b=LINE_NO_PCKINST c=PCK_INST
					{label = $a.text + $b.text.trim() + $c.text;}
				 | {label = $a.text;}
				)
			 pck=LINE {addPackages(mapInstall, label, $pck.text);}
			 | a=PCK_OPT
				((LINE_NO_PCKOPT PCK_OPT) => b=LINE_NO_PCKOPT c=PCK_OPT
					{label = $a.text + $b.text.trim() + $c.text;}
				 | {label = $a.text;}
				)
			 pck=LINE {addPackages(mapOptional, label, $pck.text);}
			 | a=PCK_DEL
				((LINE_NO_PCKDEL PCK_DEL) => b=LINE_NO_PCKDEL c=PCK_DEL
					{label = $a.text + $b.text.trim() + $c.text;}
				 | {label = $a.text;}
				)
			 pck=LINE {addPackages(mapRemove, label, $pck.text);}
			 | FREETEXT_START LINE {hasFreeText = true;}
			 | // empty line
			)
		 '\n'
		)*
		WS* BODY_END WS* '\n'
		{cats.get(cats.size()-1).items.add(new Item(itemName, $text, hasFreeText));}
	|
		// category
		{cats.add(new Category(tmp));}
	)
	;


file	:	TOP_LEVEL_ELEMENT*
	;

