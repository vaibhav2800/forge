package see.symbol;

import see.SeeAST;

class NamedSymbol implements Symbol {

	private final String name;
	private final Scope scope;
	private final SeeAST def;
	private Type type;

	NamedSymbol(String name, Scope scope, SeeAST def) {
		if (name == null)
			throw new IllegalArgumentException(
					"Internal Error: Symbol name cannot be null");
		if (scope == null)
			throw new IllegalArgumentException(
					"Internal Error: Symbol scope cannot be null");

		if (def == null) {
			// strip the ending "[][]" from Array names to find element name
			String elem = name;
			if (elem.endsWith(SymbolTable.arraySuffix)) {
				int pos = elem.indexOf(SymbolTable.arraySuffix);
				elem = elem.substring(0, pos);
			}

			// AST node may be null only for buit-in symbols in the global scope
			if (!SymbolTable.isBuiltInSymbolName(elem) || scope.parent != null)
				throw new IllegalArgumentException(
						"Internal Error: Symbol def AST node cannot be null");
		}

		this.name = name;
		this.scope = scope;
		this.def = def;
	}

	@Override
	public SeeAST getDefNode() {
		return def;
	}

	@Override
	public String getName() {
		return name;
	}

	@Override
	public Scope getScope() {
		return scope;
	}

	@Override
	public Type getType() {
		return type;
	}

	@Override
	public void setType(Type type) {
		this.type = type;
	}

	@Override
	public String getDefLocation() {
		if (def == null)
			return "<FIXME:unknown-location>";
		return def.getLocation();
	}

}
