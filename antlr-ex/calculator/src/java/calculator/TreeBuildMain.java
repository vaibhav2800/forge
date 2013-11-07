package calculator;

import org.antlr.runtime.ANTLRInputStream;
import org.antlr.runtime.CommonTokenStream;

public class TreeBuildMain {

	public static void main(String[] args) throws Exception {
		// Create an input character stream from standard in
		ANTLRInputStream input = new ANTLRInputStream(System.in);
		// Create an ExprLexer that feeds from that stream
		TreeBuildExprLexer lexer = new TreeBuildExprLexer(input);
		// Create a stream of tokens fed by the lexer
		CommonTokenStream tokens = new CommonTokenStream(lexer);
		// Create a parser that feeds off the token stream
		TreeBuildExprParser parser = new TreeBuildExprParser(tokens);
		// Begin parsing at rule prog
		parser.prog();
	}

}
