package see.symbol;

import see.SeeAST;

class VariableSymbol extends NamedSymbol {

	VariableSymbol(String name, Scope scope, SeeAST def) {
		super(name, scope, def);
	}

}
