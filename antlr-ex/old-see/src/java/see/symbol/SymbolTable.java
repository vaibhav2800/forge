package see.symbol;

import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.antlr.runtime.TokenStream;

import see.Listener;
import see.SeeAST;
import see.SeeLexer;

/** Singleton class responsible for symbol management. */
public class SymbolTable {

	public final Scope globalScope;
	public final Listener listener;
	public final String lineSep;
	private final TokenStream tokens;

	// type indexes
	/** user stands for struct, array and the nullType */
	public static final int index_USER = 0;
	public static final int index_BOOLEAN = 1;
	public static final int index_CHAR = 2;
	public static final int index_INT = 3;
	public static final int index_DOUBLE = 4;
	public static final int index_VOID = 5;
	public static final int index_FUNCTION = 6;

	// built-in types
	public final BuiltInType tBoolean;
	public final BuiltInType tChar;
	public final BuiltInType tInt;
	public final BuiltInType tDouble;
	public final BuiltInType tVoid;
	public final BuiltInType tFunc;
	public final BuiltInType tNull;

	// type tables; stored in TypeTables.java for text formatting reasons.
	// Promotion tables are indexed with the types of the two operands
	// (not with an operand and the result of the operation).

	/* Arithmetic +, -, *, / operators */
	final Type[][] arithmResultType;
	final Type[][] promoteArithm;
	/* Modulus operator, % */
	final Type[][] modResultType;
	final Type[][] promoteMod;
	/* Relational operators, <, <=, >, >= */
	final Type[][] relResultType;
	final Type[][] promoteRel;
	/* Equality operators ==, != */
	final Type[][] eqResultType;
	final Type[][] promoteEq;
	/* Logical operators &&, || */
	final Type[][] logResultType;
	final Type[][] promoteLog;
	/* Assignment operator = */
	final Type[][] promoteAssign;

	private static final String[] sortedBuiltInNames;

	static {
		sortedBuiltInNames = new String[] { "boolean", "char", "int", "double",
				"void", "#function", "#null" };
		Arrays.sort(sortedBuiltInNames);
	}

	static final String arraySuffix = "[]";

	static SymbolTable instance;

	private SymbolTable(TokenStream tokens) {
		globalScope = new Scope("global", null);

		tBoolean = new BuiltInType("boolean", globalScope, index_BOOLEAN);
		tChar = new BuiltInType("char", globalScope, index_CHAR);
		tInt = new BuiltInType("int", globalScope, index_INT);
		tDouble = new BuiltInType("double", globalScope, index_DOUBLE);
		tVoid = new BuiltInType("void", globalScope, index_VOID);
		tFunc = new BuiltInType("#function", globalScope, index_FUNCTION);
		tNull = new BuiltInType("#null", globalScope, index_USER);

		globalScope.define(tBoolean);
		globalScope.define(tChar);
		globalScope.define(tInt);
		globalScope.define(tDouble);
		globalScope.define(tVoid);

		listener = new Listener();
		lineSep = System.getProperty("line.separator", "\n");
		this.tokens = tokens;

		// create type tables
		TypeTables ttab = new TypeTables(tBoolean, tChar, tInt, tDouble, tVoid);
		arithmResultType = ttab.arithmResultType;
		promoteArithm = ttab.promoteArithm;
		modResultType = ttab.modResultType;
		promoteMod = ttab.promoteMod;
		relResultType = ttab.relResultType;
		promoteRel = ttab.promoteRel;
		eqResultType = ttab.eqResultType;
		promoteEq = ttab.promoteEq;
		logResultType = ttab.logResultType;
		promoteLog = ttab.promoteLog;
		promoteAssign = ttab.promoteAssign;
	}

	public static void makeSingleton(TokenStream tokens) {
		if (instance != null)
			throw new IllegalStateException("Internal Error: "
					+ "attempting to reinitialize SymbolTable");
		instance = new SymbolTable(tokens);
	}

	public static SymbolTable getInstance() {
		if (instance == null)
			throw new IllegalStateException("Internal Error: "
					+ "SymbolTable not initialized");
		return instance;
	}

	static boolean isBuiltInSymbolName(String name) {
		return Arrays.binarySearch(sortedBuiltInNames, name) >= 0;
	}

	/*
	 * Symbol definition. These methods are called from Def.g.
	 */

	public void defineVariable(SeeAST ID, Scope crtScope) {
		checkNewSymbolArgs(ID, crtScope, "defineVariable()");
		reportIfIllegalRedef(ID, crtScope);

		VariableSymbol vs = new VariableSymbol(ID.getText(), crtScope, ID);
		crtScope.define(vs);
		ID.symbol = vs;
	}

	public StructType defineStruct(SeeAST ID, Scope crtScope) {
		checkNewSymbolArgs(ID, crtScope, "defineStruct()");
		reportIfIllegalRedef(ID, crtScope);

		StructType ss = new StructType(ID.getText(), crtScope, ID);
		crtScope.define(ss);
		ID.symbol = ss;
		return ss;
	}

	public FunctionSymbol defineFunction(SeeAST ID, Scope crtScope) {
		checkNewSymbolArgs(ID, crtScope, "defineFunction()");
		reportIfIllegalRedef(ID, crtScope);

		FunctionSymbol fs = new FunctionSymbol(ID.getText(), crtScope, ID);
		crtScope.define(fs);
		ID.symbol = fs;
		return fs;
	}

	public Scope defineLocalScope(Scope crtScope) {
		return new Scope("local", crtScope);
	}

	private void checkNewSymbolArgs(SeeAST ID, Scope crtScope, String funcName) {
		if (ID == null || ID.token == null || ID.token.getType() != SeeLexer.ID)
			throw new IllegalArgumentException("Internal Error: " + funcName
					+ " requires ID payload in AST node");
		if (crtScope == null)
			throw new IllegalArgumentException("Internal Error: " + funcName
					+ " requires non-null Scope");
	}

	private void reportIfIllegalRedef(SeeAST ID, Scope scope) {
		Symbol old = scope.resolve(ID.getText());
		if (old == null)
			return;

		Scope oldScope = old.getScope();
		boolean success;

		if (scope instanceof StructType) {
			// in a struct, we can define members with any names except
			// the struct's name and other members' names

			if (scope.name.equals(ID.getText()) || oldScope == scope)
				success = false;
			else
				success = true;
		} else {
			// outside a struct,
			// may only redefine global symbols and only in local scopes

			success = (oldScope == globalScope && scope != globalScope);
		}

		if (!success) {
			String msg = "redefinition of `" + ID.getText() + "'";
			listener.error(ID.getLocation(), msg);

			msg = "previous definition of `" + ID.getText() + "' was here";
			listener.note(old.getDefLocation(), msg);

			listener.write(null, null, null);
		}
	}

	/*
	 * Resolve references to Symbols and Types (but NOT to fields). These
	 * methods are called from Ref.g.
	 */

	/**
	 * Resolves a type starting in the current scope and lookin up the scope
	 * tree. This is how we resolve simple types such as "A" or "int", and the
	 * Outer type in Outer.Inner1.Inner2.
	 * 
	 * If invoked with an ID nameNode and the return value is not null, the
	 * caller can safely cast to StructType. The grammar doesn't match
	 * primitives or array types as IDs.
	 */
	public Type resolveSimpleType(SeeAST nameNode, Scope refScope) {
		if (nameNode == null || nameNode.token == null)
			throw new IllegalArgumentException("Internal Error: "
					+ "resolveSimpleType requires AST node with token");
		if (refScope == null)
			throw new IllegalArgumentException("Internal Error: "
					+ "resolveSimpleType requires non-null scope");

		String name = nameNode.getText();
		Symbol symb = refScope.resolve(name);

		if (!(symb instanceof Type)) {
			// simpleSymb is null or not a type
			String msg = (symb == null ? "unknown identifier" : "not a type");
			listener.error(nameNode.getLocation(), msg + " `" + text(nameNode)
					+ "'");
			return null;
		}

		return (Type) symb;
	}

	/**
	 * Resolve a type ONLY in this scope, NOT looking up the scope tree. This is
	 * how we resolve Inner types like Outer.Inner1.Inner2.
	 * 
	 * These (Outer and Inner) tokens are IDs in the grammar, which guarantees
	 * that if they are types, they are structs (primitives and arrays aren't
	 * matched as IDs).
	 */
	public StructType resolveMemberType(SeeAST nameNode, Scope refScope) {
		if (nameNode == null || nameNode.token == null)
			throw new IllegalArgumentException("Internal Error: "
					+ "resolveMemberType requires AST node with token");
		if (refScope == null)
			throw new IllegalArgumentException("Internal Error: "
					+ "resolveMemberType requires non-null refScope");

		String name = nameNode.getText();
		Symbol symb = refScope.resolveMember(name);

		if (!(symb instanceof StructType)) {
			// simpleSymb is null or not a type
			String msg = (symb == null ? "unknown identifier" : "not a struct");
			listener.error(nameNode.getLocation(), msg + " `" + text(nameNode)
					+ "'");
			return null;
		}

		return (StructType) symb;
	}

	public Symbol resolveSymbolRef(SeeAST ID) {
		if (ID == null || ID.token == null || ID.token.getType() != SeeLexer.ID) {
			throw new IllegalArgumentException("Internal Error: "
					+ "resolveSymbolRef requires AST node with ID payload.");
		}

		Symbol sym = ID.scope.resolve(ID.getText());

		if (sym == null) {
			listener.error(ID.getLocation(), "unknown identifier `"
					+ ID.getText() + "'");
			return null;
		}

		if (sym instanceof VariableSymbol && sym.getScope() != globalScope) {
			// check for illegal forward references
			int defIndex = sym.getDefNode().token.getTokenIndex();
			int refIndex = ID.token.getTokenIndex();
			if (defIndex > refIndex)
				listener.error(ID.getLocation(), "illegal forward reference "
						+ "to " + text(ID) + " in `"
						+ text((SeeAST) ID.getParent()) + "'");

			// check for "int x = x+2";
			if (ID.hasAncestor(SeeLexer.VAR_DECL)) {
				SeeAST var_decl = (SeeAST) ID.getAncestor(SeeLexer.VAR_DECL);
				SeeAST lhs = (SeeAST) var_decl.getChild(1);

				if (lhs == sym.getDefNode()) {
					SeeAST expr = (SeeAST) var_decl.getChild(2);
					listener.error(lhs.getLocation(), "recursive"
							+ " initialization of " + text(lhs) + " with `"
							+ text(expr) + "'");
				}
			}
		}

		return sym;
	}

	/*
	 * Expression type computation. These methods are called from Types.g.
	 */

	public Type IDExprType(SeeAST ID) {
		if (ID.symbol instanceof Type)
			return (Type) ID.symbol;
		return ID.symbol.getType();
	}

	public Type uPlusMinus(SeeAST a) {
		if (!(a.evalType == tInt || a.evalType == tDouble)) {
			listener.error(a.getLocation(), text(a)
					+ " must have int or double type in "
					+ text((SeeAST) a.getParent()));
			return tVoid;
		}
		return a.evalType;
	}

	public Type not(SeeAST a) {
		if (a.evalType != tBoolean) {
			listener.error(a.getLocation(), text(a)
					+ " must have boolean type in "
					+ text((SeeAST) a.getParent()));
			// even though wrong, assume boolean result
			return tBoolean;
		}
		return a.evalType;
	}

	Type getResultType(Type[][] resultTable, Type[][] promoteTable, SeeAST a,
			SeeAST b) {
		int ta = a.evalType.getTypeIndex();
		int tb = b.evalType.getTypeIndex();
		Type result = resultTable[ta][tb];

		if (result == tVoid) {
			listener.error(a.getLocation(), text(a) + ", " + text(b)
					+ " have incompatible types in `"
					+ text((SeeAST) a.getParent()) + "'");
		} else {
			a.promoteToType = promoteTable[ta][tb];
			b.promoteToType = promoteTable[tb][ta];
		}

		return result;
	}

	/** Binary arithmetic operators +, -, * or / but not % */
	public Type arithm(SeeAST a, SeeAST b) {
		return getResultType(arithmResultType, promoteArithm, a, b);
	}

	/** Arithmetic % operator */
	public Type mod(SeeAST a, SeeAST b) {
		return getResultType(modResultType, promoteMod, a, b);
	}

	/** Relational operators <, <=, >, >= */
	public Type relOp(SeeAST a, SeeAST b) {
		return getResultType(relResultType, promoteRel, a, b);
	}

	/** Equality operators ==, != */
	public Type eqOp(SeeAST a, SeeAST b) {
		Type result = getResultType(eqResultType, promoteEq, a, b);
		Type typeA = a.evalType;
		Type typeB = b.evalType;

		if (result != tVoid && typeA.getTypeIndex() == index_USER) {
			// both types are USER (struct, array or the null literal)
			// if both not null, require typeA == typeB
			if (typeA != typeB && typeA != tNull && typeB != tNull)
				listener.error(a.getLocation(), text(a) + ", " + text(b)
						+ " have incompatible types in `"
						+ text((SeeAST) a.getParent()) + "'");
		}

		return result;
	}

	/** Logical operators &&, || */
	public Type logOp(SeeAST a, SeeAST b) {
		return getResultType(logResultType, promoteLog, a, b);
	}

	/** Field access operator . */
	public Symbol field(SeeAST a, SeeAST ID) {
		Type ta = a.evalType;

		if (!(ta instanceof StructType)) {
			listener.error(a.getLocation(), "`" + text(a)
					+ "' is not a struct type in `"
					+ text((SeeAST) a.getParent()) + ";");
			return null;
		}

		Symbol field = ((StructType) ta).resolveMember(ID.getText());

		if (field == null) {
			listener.error(ID.getLocation(), "`" + ID.getText()
					+ "' is not a field of " + text(a) + " in `"
					+ text((SeeAST) a.getParent()) + "'");
			return null;
		}

		// allow Outer.Inner but not x.Inner
		if ((field instanceof Type) && !(a.symbol instanceof Type)) {
			listener.error(ID.getLocation(), "cannot access inner type `"
					+ text(ID) + "' using outer instance `" + text(a)
					+ "' in `" + text((SeeAST) a.getParent()) + "'");
			return null;
		}

		// allow x.y but not Outer.y
		if (!(field instanceof Type) && (a.symbol instanceof Type)) {
			listener.error(ID.getLocation(), "cannot acces field `" + text(ID)
					+ "' using type name `" + text(a) + "' in `"
					+ text((SeeAST) a.getParent()) + "'");
			return null;
		}

		ID.symbol = field;
		return field;
	}

	/** Check if integer (and report error); set promoteToType appropriately. */
	public boolean checkArrayIndexExpr(SeeAST indexExpr) {
		Type t = indexExpr.evalType;
		indexExpr.promoteToType = promoteAssign[t.getTypeIndex()][index_INT];

		if (!canAssignTo(t, tInt, indexExpr.promoteToType)) {
			listener.error(indexExpr.getLocation(), "`" + text(indexExpr)
					+ "' must have int type in `"
					+ text((SeeAST) indexExpr.getParent()) + "'");
			return false;
		}

		return true;
	}

	/** Array indexing */
	public Type index(SeeAST a, SeeAST b) {
		Type ta = a.evalType;
		if (!(ta instanceof ArrayType)) {
			listener.error(a.getLocation(), "`" + text(a)
					+ "' is not array in `" + text((SeeAST) a.getParent())
					+ "'");
			return tVoid;
		}

		// report error if non-int index, but return correct elementType
		checkArrayIndexExpr(b);

		return ((ArrayType) ta).elementType;
	}

	private boolean canAssignTo(Type valueType, Type destType, Type promotion) {
		if (valueType == tNull)
			return destType.getTypeIndex() == index_USER;

		return valueType == destType || promotion == destType;
	}

	/** Function call */
	public Type call(SeeAST funcExpr, List<SeeAST> args) {
		// defensive: check both evalType and symbol fields
		if (funcExpr.evalType != tFunc
				|| !(funcExpr.symbol instanceof FunctionSymbol)) {
			listener.error(funcExpr.getLocation(), "`" + text(funcExpr)
					+ "' must be function in `"
					+ text((SeeAST) funcExpr.getParent()) + "'");
			return tVoid;
		}

		FunctionSymbol funcSymb = (FunctionSymbol) funcExpr.symbol;
		Set<Map.Entry<String, Symbol>> formalArgs = funcSymb
				.getOrderedMembers();

		// check argument count
		int argCount = formalArgs.size();
		if (args.size() != argCount) {
			String reason = args.size() < argCount ? "too few" : "too many";
			listener.error(funcExpr.getLocation(), reason
					+ " arguments in call `"
					+ text((SeeAST) funcExpr.getParent()) + "'");

			// after reporting error, assume correct return type
			return funcSymb.getReturnType();
		}

		int i = 0;
		for (Map.Entry<String, Symbol> formalArg : formalArgs) {
			SeeAST actualArg = args.get(i++);

			if (actualArg.symbol instanceof Type) {
				listener.error(actualArg.getLocation(), "type name `"
						+ text(actualArg)
						+ "' passed as function argument in `"
						+ text((SeeAST) funcExpr.getParent()) + "'");
				continue;
			}

			Type formalType = formalArg.getValue().getType();
			Type actualType = actualArg.evalType;
			int tFormal = formalType.getTypeIndex();
			int tActual = actualType.getTypeIndex();
			actualArg.promoteToType = promoteAssign[tActual][tFormal];

			if (!canAssignTo(actualType, formalType, actualArg.promoteToType))
				listener.error(actualArg.getLocation(), text(actualArg)
						+ ", argument " + formalArg.getKey() + ":<"
						+ formalType + "> have incompatible types in "
						+ text((SeeAST) funcExpr.getParent()));
		}

		// assume correct return type
		return funcSymb.getReturnType();
	}

	/** Return statement */
	public void checkReturnStat(SeeAST RET, SeeAST optExpr) {
		if (RET == null || RET.token.getType() != SeeLexer.RETURN)
			throw new IllegalArgumentException("Internal Error: "
					+ "checkReturnStat needs AST node with RETURN token.");
		if (!(RET.symbol instanceof FunctionSymbol))
			throw new IllegalArgumentException("Internal Error: "
					+ "RETURN node's Symbol is not a FunctionSymbol.");

		FunctionSymbol funcSymb = (FunctionSymbol) RET.symbol;
		Type funcRetType = funcSymb.getReturnType();

		// void function mustn't return a value
		if (funcRetType == tVoid) {
			if (optExpr != null)
				listener.error(RET.getLocation(), "`return' with a value, "
						+ "in function returning void: `" + text(RET) + "'");
			return;
		}

		// function is not void, check presence of return value
		if (optExpr == null) {
			listener.error(RET.getLocation(), "`return' without value, "
					+ "in non-void function: `" + text(RET) + "'");
			return;
		}

		Type exprType = optExpr.evalType;
		int tFuncRet = funcRetType.getTypeIndex();
		int tExpr = exprType.getTypeIndex();
		optExpr.promoteToType = promoteAssign[tExpr][tFuncRet];

		if (!canAssignTo(exprType, funcRetType, optExpr.promoteToType))
			listener.error(optExpr.getLocation(), "bad return type: "
					+ funcSymb.getName() + "():<" + funcRetType.getName()
					+ ">, `" + text(optExpr) + "' have incompatible types in `"
					+ text((SeeAST) optExpr.getParent()) + "'");
	}

	/** Assignment operator = */
	public Type assign(SeeAST a, SeeAST b) {
		Type ta = a.evalType;
		if (!(a.symbol instanceof VariableSymbol)
				&& (a.token.getType() != SeeLexer.INDEX)) {
			listener.error(a.getLocation(), "`" + text(a)
					+ "' is not a variable or field in `"
					+ text((SeeAST) a.getParent()) + "'");
			return tVoid;
		}

		Type aType = a.evalType, bType = b.evalType;
		int tA = aType.getTypeIndex(), tB = bType.getTypeIndex();

		b.promoteToType = promoteAssign[tB][tA];
		if (!canAssignTo(bType, aType, b.promoteToType))
			listener.error(a.getLocation(), "`" + text(a) + "', `" + text(b)
					+ "' have incompatible types in `"
					+ text((SeeAST) a.getParent()) + "'");

		// evaluate to a's type, even with errors
		return ta;
	}

	/** New operator for structs `new' */
	public Type newOpStruct(SeeAST a) {
		SeeAST parent = (SeeAST) a.getParent();

		if (!(a.symbol instanceof Type)) {
			listener.error(parent.getLocation(), "not a type `" + text(a)
					+ "' in `" + text(parent) + "'");
			return tVoid;
		}

		// defensive: make sure a.evalType has been set to a.symbol from Types.g
		if (a.symbol != a.evalType) {
			throw new IllegalStateException("Internal Error: "
					+ "a.symbol != a.evalType for ^('new' a=expr) in AST");
		}

		boolean struct = a.evalType instanceof StructType;
		boolean array = a.evalType instanceof ArrayType;
		boolean canCreate = struct || array;

		if (!canCreate) {
			listener.error(parent.getLocation(), "`" + text(a)
					+ "' must be struct or array type in `" + text(parent)
					+ "'");
			return tVoid;
		}

		return a.evalType;
	}

	/** New operator for Arrays `new []' */
	public Type newOpArray(SeeAST a, int totalDims) {
		SeeAST parent = (SeeAST) a.getParent();

		if (!(a.symbol instanceof Type)) {
			listener.error(parent.getLocation(), "not a type `" + text(a)
					+ "' in `" + text(parent) + "'");
			return tVoid;
		}

		// defensive: make sure a.evalType has been set to a.symbol from Types.g
		if (a.symbol != a.evalType) {
			throw new IllegalStateException("Internal Error: "
					+ "a.symbol != a.evalType for ^('new' a=expr dims) in AST");
		}

		return ArrayType.getInstance(a.evalType, totalDims);
	}

	/** Length operator `len' */
	public Type lenOp(SeeAST a) {
		SeeAST parent = (SeeAST) a.getParent();

		// report any errors, but assume correct return type

		if (!(a.evalType instanceof ArrayType)) {
			listener.error(parent.getLocation(), "`" + text(a)
					+ "' not of array type in `" + text(parent) + "'");
			return tInt;
		}

		// a.symbol may be null, a Symbol (e.g. VariableSymbol) or a Type
		// make sure it's not a Type
		if (a.symbol instanceof Type) {
			listener.error(parent.getLocation(), "not array instance `"
					+ text(a) + "' in `" + text(parent) + "'");
			return tInt;
		}

		return tInt;
	}

	/** Variable declaration with initialization expression */
	public void checkVarInit(SeeAST ID, SeeAST expr) {
		Type idType = ID.symbol.getType();
		Type exprType = expr.evalType;
		int tID = idType.getTypeIndex(), tExpr = exprType.getTypeIndex();
		expr.promoteToType = promoteAssign[tExpr][tID];

		if (!canAssignTo(exprType, idType, expr.promoteToType))
			listener.error(expr.getLocation(), text(ID) + ", `" + text(expr)
					+ "' have incompatible types in variable initialization.");
	}

	/** Report non-boolean type of expression in if, while conditions */
	public void checkCondition(SeeAST expr) {
		if (expr.evalType != tBoolean)
			listener.error(expr.getLocation(), "condition `" + text(expr)
					+ "' must have boolean type in `"
					+ text((SeeAST) expr.getParent()));
	}

	/** Check argument of `print' statement */
	public void checkPrintStat(SeeAST exprNode) {
		SeeAST parent = (SeeAST) exprNode.getParent();

		if (exprNode.evalType == tVoid) {
			listener.error(exprNode.getLocation(), "bad argument `"
					+ text(exprNode) + "' in `" + text(parent) + "'");
			listener.note(exprNode.getLocation(),
					"print statement requires non-void argument.");
		}

		// make sure expr is not a Type
		if (exprNode.symbol instanceof Type) {
			listener.error(exprNode.getLocation(), "bad argument `"
					+ text(exprNode) + "' in `" + text(parent) + "'");
			listener.note(exprNode.getLocation(),
					"print statement requires value not type.");
		}
	}

	/*
	 * Utility method
	 */
	String text(SeeAST node) {
		int start = node.getTokenStartIndex();
		int stop = node.getTokenStopIndex();
		String s = tokens.toString(start, stop);

		if (node.evalType != null)
			s += ":<" + node.evalType + ">";

		return s;
	}

}
