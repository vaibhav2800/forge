parser grammar PageLinksParser;

options {
tokenVocab = PageLinksLexer;
}

@header {
package rezitests;

import java.util.Set;
import java.util.LinkedHashSet;
}

page_links returns [List<String> links]
@init {
	Set<String> linkSet = new LinkedHashSet<>();
}
@after {
	$links = new ArrayList<>(linkSet);
}
	:	(l=PAGE_LINK {linkSet.add($l.text);})+
	;
