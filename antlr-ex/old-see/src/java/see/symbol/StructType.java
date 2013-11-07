package see.symbol;

import see.SeeAST;

public class StructType extends Scope implements Type {

	/** Encapsulated Symbol Object to which most Symbol methods are delegated */
	private final Symbol sym;

	StructType(String name, Scope scope, SeeAST def) {
		super(name, scope);
		sym = new NamedSymbol(name, scope, def);
	}

	@Override
	public int getTypeIndex() {
		return SymbolTable.index_USER;
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
	public SeeAST getDefNode() {
		return sym.getDefNode();
	}

	@Override
	public String getDefLocation() {
		return sym.getDefLocation();
	}

	@Override
	public Type getType() {
		throw new UnsupportedOperationException("Internal Error: "
				+ "Cannot call getType() on StructType. This object IS a Type.");
	}

	@Override
	public void setType(Type type) {
		throw new UnsupportedOperationException("Internal Error: "
				+ "Cannot call setType() on StructType. This object IS a Type.");
	}

	@Override
	public String toString() {
		String memb = members.keySet().toString();
		memb = memb.substring(1, memb.length() - 1);
		return "struct " + getName() + ":{" + memb + "}";
	}

}
