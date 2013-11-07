package sitecheck;

import java.net.MalformedURLException;

import org.antlr.runtime.ANTLRInputStream;
import org.antlr.runtime.CommonTokenStream;
import org.antlr.runtime.Lexer;

public class PCgarageRetriever extends SiteRetriever {

	public PCgarageRetriever(String urlString, String userAgent)
			throws MalformedURLException {
		super(urlString, userAgent == null ? "site-check" : userAgent);
	}

	@Override
	protected Lexer getLexer(ANTLRInputStream input) {
		return new PCgarageLexer(input);
	}

	@Override
	protected SiteParser getParser(CommonTokenStream tokens) {
		return new PCgarageParser(tokens);
	}

	@Override
	public boolean mustNotify(String notifyOver, String lastVal, String crtVal) {
		try {
			if (notifyOver == null || lastVal == null)
				return super.mustNotify(notifyOver, lastVal, crtVal);

			// Numbers in file are (DIGIT|'.')* ',' DIGIT DIGIT
			long lastNr = Long.parseLong(lastVal.replaceAll("[.,]", ""));
			long crtNr = Long.parseLong(crtVal.replaceAll("[.,]", ""));

			// notifyOver should be (DIGIT|'.')* (',' DIGIT DIGIT)?
			long notifyNr = Long.parseLong(notifyOver.replaceAll("[.,]", ""));
			if (notifyOver.indexOf(',') == -1)
				notifyNr *= 100;

			return Math.abs(crtNr - lastNr) >= notifyNr;
		} catch (NumberFormatException e) {
			System.err.println(getClass().getName() + ".mustNotify: " + e);
			return true;
		}
	}

}
