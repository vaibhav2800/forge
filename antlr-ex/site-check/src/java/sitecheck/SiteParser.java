package sitecheck;

import org.antlr.runtime.Parser;
import org.antlr.runtime.RecognitionException;
import org.antlr.runtime.RecognizerSharedState;
import org.antlr.runtime.TokenStream;

public abstract class SiteParser extends Parser {

	public SiteParser(TokenStream input) {
		super(input);
	}

	public SiteParser(TokenStream input, RecognizerSharedState state) {
		super(input, state);
	}

	/** Parses a (web) page and returns the item's value */
	public abstract String page() throws RecognitionException;

}
