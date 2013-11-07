package see.symbol;

import see.SeeAST;

public interface Symbol {

	/** All Symbols have a name */
	public String getName();

	public void setType(Type type) throws UnsupportedOperationException;

	public Type getType() throws UnsupportedOperationException;

	/**
	 * All symbols know their containing scope. Array types use the scope of
	 * their element type.
	 */
	public Scope getScope();

	/**
	 * Definition ID node from AST. null for built-ins. Array types use the
	 * DefNode of their element type.
	 */
	public SeeAST getDefNode();

	/** Def location if known, otherwise <unknown-location> or <built-in-..> */
	public String getDefLocation();

}
