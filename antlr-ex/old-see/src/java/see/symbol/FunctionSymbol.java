package see.symbol;

import see.SeeAST;

public class FunctionSymbol extends Scope implements Symbol {

	/** Encapsulated Symbol Object to which all Symbol methods are delegated */
	private final Symbol sym;
	/** This function's return Type */
	private Type returnType;

	FunctionSymbol(String name, Scope scope, SeeAST def) {
		super(name, scope);
		sym = new NamedSymbol(name, scope, def);
		sym.setType(SymbolTable.getInstance().tFunc);
	}

	public void setReturnType(Type returnType) {
		this.returnType = returnType;
	}

	public Type getReturnType() {
		return returnType;
	}

	@Override
	public String getName() {
		return sym.getName();
	}

	@Override
	public Scope getScope() {
		return sym.getScope();
	}

	@Override
	public Type getType() {
		return sym.getType();
	}

	@Override
	public void setType(Type type) {
		throw new UnsupportedOperationException(
				"Cannot perform setType(..) on FunctionSymbol, "
						+ "this object's Type is "
						+ SymbolTable.getInstance().tFunc + ". "
						+ "Are you trying to call setReturnType()?");
	}

	@Override
	public SeeAST getDefNode() {
		return sym.getDefNode();
	}

	@Override
	public String getDefLocation() {
		return sym.getDefLocation();
	}

}
