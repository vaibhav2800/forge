package see.symbol;

class BuiltInType extends NamedSymbol implements Type {

	private final int typeIndex;

	BuiltInType(String name, Scope globalScope, int typeIndex) {
		super(name, globalScope, null);
		this.typeIndex = typeIndex;
	}

	@Override
	public int getTypeIndex() {
		return typeIndex;
	}

	@Override
	public Type getType() {
		throw new UnsupportedOperationException(
				"Cannot call getType() on BuiltInType Symbol. This object IS a Type.");
	}

	@Override
	public void setType(Type type) {
		throw new UnsupportedOperationException(
				"Cannot perform setType(..) on BuiltInType Symbol. This object IS a Type.");
	}

	@Override
	public String getDefLocation() {
		return "<built-in-type " + getName() + ">";
	}

	@Override
	public String toString() {
		return getName();
	}

}
