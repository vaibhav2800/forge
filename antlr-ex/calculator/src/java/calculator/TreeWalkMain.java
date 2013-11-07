package calculator;

import org.antlr.runtime.ANTLRInputStream;
import org.antlr.runtime.CommonTokenStream;
import org.antlr.runtime.tree.CommonTree;
import org.antlr.runtime.tree.CommonTreeNodeStream;

public class TreeWalkMain {

	public static void main(String[] args) throws Exception {
		// Create an input character stream from standard in
		ANTLRInputStream input = new ANTLRInputStream(System.in);
		// Create an ExprLexer that feeds from that stream
		TreeBuildExprLexer lexer = new TreeBuildExprLexer(input);
		// Create a stream of tokens fed by the lexer
		CommonTokenStream tokens = new CommonTokenStream(lexer);
		// Create a parser that feeds off the token stream
		TreeBuildExprParser parser = new TreeBuildExprParser(tokens);
		// Begin parsing at rule prog, get return value structure
		TreeBuildExprParser.prog_return r = parser.prog();
		// WALK RESULTING TREE
		CommonTree t = (CommonTree) r.getTree(); // get tree from parser
		// Create a tree node stream from resulting tree
		CommonTreeNodeStream nodes = new CommonTreeNodeStream(t);
		TreeWalkExpr walker = new TreeWalkExpr(nodes); // create a tree parser
		walker.prog(); // launch at start rule prog
	}

}
