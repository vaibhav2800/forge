package see.symbol;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;

public class Scope {

	public final String name;
	public final Scope parent;
	protected final Map<String, Symbol> members;

	protected Scope(String name, Scope parent) {
		this.name = name;
		this.parent = parent;
		this.members = new LinkedHashMap<String, Symbol>();
	}

	/** Define a Symbol in current scope */
	void define(Symbol sym) {
		members.put(sym.getName(), sym);
	}

	/** Get the ordered list of members */
	public Set<Map.Entry<String, Symbol>> getOrderedMembers() {
		return members.entrySet();
	}

	/** Look up name in this scope or in enclosing scope if not here */
	public Symbol resolve(String name) {
		Symbol s = members.get(name);
		if (s != null)
			return s;

		if (parent != null)
			return parent.resolve(name);
		return null;
	}

	/**
	 * For a.b, only look in a to resolve b, not up scope tree. Also needed by
	 * ArrayType: if Type A in an inner scope overrides A in the global scope,
	 * upon A[][] x we want to see if A[][] is defined in the inner scope and
	 * use it, perhaps after defining A[] and A[][]; we must not resolve to the
	 * outer A[][].
	 */
	public Symbol resolveMember(String name) {
		return members.get(name);
	}

}
