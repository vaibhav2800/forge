grammar upp;

@header {
package upp;
}

@lexer::header {
package upp;
}

@lexer::members {
	private List<Item> items = new ArrayList<Item>();

	List<Item> getItems() {
		return new ArrayList<Item>(items);
	}
}

fragment WS			:	(' ' | '\t');
fragment NEWLINE	:	('\n' | '\r');

fragment ITEM_START	: '*';
fragment BODY_START	: '{';
fragment BODY_END	: '}';
fragment PCK_MUST	: '@';
fragment PCK_OPT	: '?';
fragment PCK_DEL	: '^';
fragment FREETEXT_START	: (~(BODY_END | PCK_MUST | PCK_OPT | PCK_DEL | WS | NEWLINE));

fragment LINE	:	(~NEWLINE)*;
fragment LINE_NO_PCKMUST	:	(~(NEWLINE | PCK_MUST))*;
fragment LINE_NO_PCKOPT		:	(~(NEWLINE | PCK_OPT))*;
fragment LINE_NO_PCKDEL		:	(~(NEWLINE | PCK_DEL))*;
fragment LINE_NO_BODYST		:	(~(NEWLINE | BODY_START))*;
fragment LINE_NO_BODYST_ITEMST	:	(~(NEWLINE | BODY_START | ITEM_START))*;

ITEM
@init {
Item item = null;
}
@after {
// $text can also be used anywhere in the rule
// and returns the text matched up to that point
item.setLiteralText($text);
items.add(item);
}
:	WS* ITEM_START
	((LINE_NO_BODYST_ITEMST ITEM_START) => item_label=LINE_NO_BODYST_ITEMST ITEM_START
	 |
	) item_name=LINE_NO_BODYST
	{item = new Item($item_name.text, $item_label.text);}
	BODY_START WS* NEWLINE
	(WS*
		(PCK_MUST
			((LINE_NO_PCKMUST PCK_MUST) => label=LINE_NO_PCKMUST PCK_MUST
			 | {label = null;}
			)
		 pck=LINE {item.addPackages($pck.text, $label.text, PackageType.MANDATORY);}
		 | PCK_OPT
			((LINE_NO_PCKOPT PCK_OPT) => label=LINE_NO_PCKOPT PCK_OPT
			 | {label = null;}
			)
		 pck=LINE {item.addPackages($pck.text, $label.text, PackageType.OPTIONAL);}
		 | PCK_DEL
			((LINE_NO_PCKDEL PCK_DEL) => label=LINE_NO_PCKDEL PCK_DEL
			 | {label = null;}
			)
		 pck=LINE {item.addPackages($pck.text, $label.text, PackageType.UNWANTED);}
		 | c=FREETEXT_START l=LINE {item.addFreeText($c.text + $l.text);}
		 | {item.addFreeText("");} // empty line
		)
	 NEWLINE
	)*
	WS* BODY_END WS* NEWLINE
	;

OUTER_DATA
@init {
	boolean non_empty = false;
}
@after {
	if (non_empty) {
		String name = $text;
		name = name.replaceAll("^[ \\t\\n]+\\n", "");
		name = name.replaceAll("[ \\t\\n]+$", "");
		Item item = new Item(name, null);
		// this is a hack for displaying blank lines around categories
		item.setLiteralText("\n" + name + "\n");
		item.addFreeText(name);
		items.add(item);
	}
}
:	(
		WS*
		(~(ITEM_START | WS | NEWLINE) {non_empty = true;} (~NEWLINE)*)?
		NEWLINE
	)+
	;

upp_config_file
	:
	(ITEM | OUTER_DATA)*
	;
