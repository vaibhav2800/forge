package see.symbol;

public class ArrayType extends NamedSymbol implements Type {

	public final int dimensions;
	public final Type elementType;

	private ArrayType(String name, Type elementType) {
		super(name, elementType.getScope(), elementType.getDefNode());

		if (elementType instanceof ArrayType)
			dimensions = ((ArrayType) elementType).dimensions + 1;
		else
			dimensions = 1;

		this.elementType = elementType;
	}

	public static ArrayType getInstance(Type simpleType, int dimensions) {
		if (simpleType == null || dimensions <= 0)
			throw new IllegalArgumentException("Internal Error: "
					+ "ArrayType needs non-null type and dimensions >= 0");
		if (simpleType instanceof ArrayType)
			throw new IllegalArgumentException("Internal Error: "
					+ "provided parameter simpleType is of ArrayType");

		// ArrayTypes (e.g. int[][]) are the only symbols with "[]" in the name.
		// They can only be defined by this method.
		// No instanceof checks are needed; just null checks to see if defined

		String simpleName = simpleType.getName();
		Scope defScope = simpleType.getScope();

		/*
		 * check if Type has already been defined and return it
		 */
		StringBuilder sb = new StringBuilder(simpleName);
		for (int i = 0; i < dimensions; i++)
			sb.append(SymbolTable.arraySuffix);
		Symbol arrSymb = defScope.resolveMember(sb.toString());
		if (arrSymb != null)
			return (ArrayType) arrSymb;

		/*
		 * define ArrayTypes for all dimensions <= requested dimensions
		 */
		sb = new StringBuilder(simpleName);
		int crtDim = 0;
		Type prevType = null, crtType = simpleType;

		// check up to where it's already defined;
		// we know it's not defined for `dimensions'
		do {
			sb.append(SymbolTable.arraySuffix);
			crtDim++;
			prevType = crtType;
			crtType = (Type) defScope.resolveMember(sb.toString());
		} while (crtType != null);

		crtType = new ArrayType(sb.toString(), prevType);
		defScope.define(crtType);
		while (crtDim < dimensions) {
			sb.append(SymbolTable.arraySuffix);
			crtDim++;
			prevType = crtType;
			crtType = new ArrayType(sb.toString(), prevType);
			defScope.define(crtType);
		}

		return (ArrayType) crtType;
	}

	@Override
	public int getTypeIndex() {
		return SymbolTable.index_USER;
	}

	@Override
	public Type getType() {
		throw new UnsupportedOperationException(
				"Cannot call getType() on ArrayType Symbol. This object IS a Type.");
	}

	@Override
	public void setType(Type type) {
		throw new UnsupportedOperationException(
				"Cannot perform setType(..) on ArrayType Symbol. This object IS a Type.");
	}

	@Override
	public String toString() {
		return getName();
	}

}
