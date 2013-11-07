package see;

import org.antlr.runtime.CharStream;
import org.antlr.runtime.Token;
import org.antlr.runtime.tree.CommonTree;

import see.symbol.Scope;
import see.symbol.Symbol;
import see.symbol.Type;

public class SeeAST extends CommonTree {

	/**
	 * Enclosing scope for this reference ID node. Definition ID nodes (which
	 * define variables, structs or functions) have scope=null for now; set by
	 * Def.g
	 */
	public Scope scope;

	/**
	 * Symbol defined or referenced; set by Ref.g for non-field "ID" references;
	 * set by Types.g for field "expr.ID" references.
	 * 
	 * Most interior operator nodes in expressions have symbol = null, because
	 * they can only return a value (primitive or reference; also void for void
	 * function calls and errors during static type check) but cannot return a
	 * type.
	 * 
	 * The operator that can return a type as well as a value (DOT), ID nodes
	 * and also primitive type nodes in expressions have the symbol field set as
	 * well as the evalType.
	 */
	public Symbol symbol;

	/**
	 * The type of the (sub) expression; null for field IDs in "expr.ID" (for
	 * now); set by Types.g
	 */
	public Type evalType;

	/** Type promotion, if needed; set by Types.g */
	public Type promoteToType;

	/**
	 * Value of primitive literals from the source code (BOOLEAN_LIT, CHAR_LIT,
	 * INT_LIT, DOUBLE_LIT) set by See.g using the appropriate wrapper type.
	 * Null for other nodes.
	 */
	public Object primitiveLiteralVal;

	public SeeAST() {
	}

	public SeeAST(Token t) {
		super(t);
	}

	public String getLocation() {
		Token tok = getToken();
		if (tok == null) {
			return "<unknown location>";
		}

		String fileName = getFileName(tok);
		int line = tok.getLine();
		int col = tok.getCharPositionInLine();

		if (!fileName.isEmpty())
			fileName += ":";
		return fileName + line + ":" + col;
	}

	private static String getFileName(Token tok) {
		CharStream cs = tok.getInputStream();
		if (cs == null)
			return "";

		String fileName = cs.getSourceName();
		if (fileName == null)
			return "";
		else
			return fileName;
	}

}
