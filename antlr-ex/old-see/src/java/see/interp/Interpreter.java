package see.interp;

import static see.symbol.SymbolTable.index_BOOLEAN;
import static see.symbol.SymbolTable.index_CHAR;
import static see.symbol.SymbolTable.index_DOUBLE;
import static see.symbol.SymbolTable.index_INT;
import static see.symbol.SymbolTable.index_USER;
import static see.symbol.SymbolTable.index_VOID;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Stack;
import java.util.Map.Entry;

import see.Listener;
import see.SeeAST;
import see.SeeLexer;
import see.symbol.FunctionSymbol;
import see.symbol.Scope;
import see.symbol.StructType;
import see.symbol.Symbol;
import see.symbol.SymbolTable;
import see.symbol.Type;

public class Interpreter {

	public final Listener listener;
	private final SymbolTable symtab;
	private final Scope globalScope;
	private final FunctionReturnException sharedReturn = new FunctionReturnException();

	private SeeAST treeRoot;
	private MemorySpace globals = new MemorySpace("#global");
	private Stack<MemorySpace> functionStack = new Stack<MemorySpace>();
	/** Top of functionStack, so we don't call a stack.top() to get it */
	private MemorySpace crtFuncSpace;
	/**
	 * null in the interpreted language; don't mix interpreter bugs with user
	 * programs dereferencing null
	 */
	private static Object nullObj = new Object() {
		public String toString() {
			return "nullRef";
		}
	};

	public Interpreter(SeeAST treeRoot) {
		this.treeRoot = treeRoot;
		listener = new Listener();
		symtab = SymbolTable.getInstance();
		globalScope = symtab.globalScope;
	}

	public void run() {
		// declare global variables and locate main() function
		SeeAST main = null;
		for (Object o : treeRoot.getChildren()) {
			SeeAST node = (SeeAST) o;

			switch (node.getType()) {
			case SeeLexer.FUNC_DECL:
				if (node.getChild(1).getText().equals("main"))
					main = node;
				break;

			case SeeLexer.VAR_DECL:
				declareVariable(node, globals);
				break;
			}
		}

		if (main == null) {
			listener.error(null, "No `main' function");
			return;
		}

		FunctionSymbol mainSymb = (FunctionSymbol) ((SeeAST) main.getChild(1)).symbol;
		if (mainSymb.getOrderedMembers().size() != 0) {
			listener.error(main.getLocation(),
					"`main' method must have no parameters");
			return;
		}

		crtFuncSpace = new MemorySpace("main");
		functionStack.push(crtFuncSpace);
		block((SeeAST) main.getChild(2));
	}

	private void declareVariable(SeeAST varDeclNode, MemorySpace space) {
		Type type = (Type) ((SeeAST) varDeclNode.getChild(0)).symbol;
		SeeAST ID = (SeeAST) varDeclNode.getChild(1);

		// ^(VAR_DECL type ID expr?)
		if (varDeclNode.getChildCount() == 3)
			assign(ID, (SeeAST) varDeclNode.getChild(2));
		else
			space.put(ID.getText(), getDefaultValue(type));
	}

	private static Object getDefaultValue(Type t) {
		switch (t.getTypeIndex()) {
		case index_BOOLEAN:
			return Boolean.FALSE;
		case index_CHAR:
			return Character.MIN_VALUE;
		case index_INT:
			return Integer.valueOf(0);
		case index_DOUBLE:
			return Double.valueOf(0);
		case index_USER:
			return nullObj;
		default:
			throw new IllegalArgumentException("Internal Error: "
					+ "unexpected typeindex " + t.getTypeIndex()
					+ " requested to getDefaultValue().");
		}
	}

	private Object exec(SeeAST t) {
		switch (t.getType()) {
		case SeeLexer.BLOCK:
			block(t);
			break;

		// empty statement ';'
		case SeeLexer.SEMI:
			break;

		case SeeLexer.STRUCT:
			break;

		case SeeLexer.VAR_DECL:
			declareVariable(t, crtFuncSpace);
			break;

		case SeeLexer.PRINT:
			System.out.print(exec((SeeAST) t.getChild(0)));
			break;

		case SeeLexer.ID:
			return loadID(t);

			/*
			 * expressions
			 */
		case SeeLexer.EXPR:
			return exec((SeeAST) t.getChild(0));

			// primitives
		case SeeLexer.BOOLEAN_LIT:
		case SeeLexer.CHAR_LIT:
		case SeeLexer.INT_LIT:
		case SeeLexer.DOUBLE_LIT:
			return t.primitiveLiteralVal;
		case SeeLexer.NULL_LIT:
			return nullObj;

		case SeeLexer.ASSIGN:
			return assign(t);

		case SeeLexer.LOGICAL_OR:
			return logOR(t);
		case SeeLexer.LOGICAL_AND:
			return logAND(t);
		case SeeLexer.EQ:
			return eq(t);
		case SeeLexer.NEQ:
			return !eq(t);
		case SeeLexer.LOGICAL_NOT:
			return logNot(t);

		case SeeLexer.LT:
			return lt(t);
		case SeeLexer.LEQ:
			return leq(t);
		case SeeLexer.GT:
			return !leq(t);
		case SeeLexer.GEQ:
			return !lt(t);

		case SeeLexer.PLUS:
			return plus(t);
		case SeeLexer.MINUS:
			return minus(t);
		case SeeLexer.MUL:
			return mul(t);
		case SeeLexer.DIV:
			return div(t);
		case SeeLexer.MOD:
			return mod(t);
		case SeeLexer.UNARY_PLUS:
			return exec((SeeAST) t.getChild(0));
		case SeeLexer.UNARY_MINUS:
			return unaryMinus(t);

		case SeeLexer.DOT:
			return loadField(t);
		case SeeLexer.INDEX:
			return index(t);
		case SeeLexer.LEN:
			return lenOp(t);

		case SeeLexer.NEW_STRUCT:
			return newStruct(t);
		case SeeLexer.NEW_ARRAY:
			return newArray(t);

		case SeeLexer.CALL:
			return call(t);
		case SeeLexer.RETURN:
			returnStat(t);
			break;
		case SeeLexer.IF:
			ifStat(t);
			break;
		case SeeLexer.WHILE:
			whileStat(t);
			break;

		default:
			throw new IllegalArgumentException("Internal Error: "
					+ "Unexpected token type " + t.getType() + " in exec()");
		}

		return null;
	}

	@SuppressWarnings("unchecked")
	private void block(SeeAST node) {
		List<Object> l = node.getChildren();

		if (l != null) {
			for (Object o : l)
				exec((SeeAST) o);
		}
	}

	private Object promote(Object value, int valueTypeInd, int promoteToTypeInd) {
		if (valueTypeInd != index_CHAR && valueTypeInd != index_INT)
			throw new IllegalArgumentException("Unexpected valueType index "
					+ valueTypeInd + " in promote()");
		if (promoteToTypeInd != index_INT && promoteToTypeInd != index_DOUBLE)
			throw new IllegalArgumentException("Unexpected promoteToType "
					+ "index " + promoteToTypeInd + " in promote()");

		int val;
		if (valueTypeInd == index_CHAR)
			val = ((Character) value);
		else
			val = ((Integer) value).intValue();

		if (promoteToTypeInd == index_INT)
			return Integer.valueOf(val);
		else
			return Double.valueOf(val);
	}

	/** Assign called from expr rules */
	private Object assign(SeeAST t) {
		SeeAST lhs = (SeeAST) t.getChild(0);
		SeeAST rhs = (SeeAST) t.getChild(1);
		return assign(lhs, rhs);
	}

	/** Assign called by assign(SeeAST) above and by var initializers */
	private Object assign(SeeAST lhs, SeeAST rhs) {
		Object value = exec(rhs);

		if (rhs.promoteToType != null) {
			value = promote(value, rhs.evalType.getTypeIndex(),
					rhs.promoteToType.getTypeIndex());
		}

		if (lhs.getType() == SeeLexer.DOT)
			return fieldAssign(lhs, value);

		if (lhs.getType() == SeeLexer.INDEX)
			return arrayElemAssign(lhs, value);

		// left should be an ID
		ensureNodeType(lhs, SeeLexer.ID, "assign(lhs, rhs)");

		String name = lhs.symbol.getName();
		if (lhs.symbol.getScope() == globalScope)
			globals.put(name, value);
		else
			crtFuncSpace.put(name, value);

		return value;
	}

	private Object loadID(SeeAST ID) {
		ensureNodeType(ID, SeeLexer.ID, "loadID");
		Object val;

		if (ID.symbol.getScope() == globalScope)
			val = globals.get(ID.getText());
		else
			val = crtFuncSpace.get(ID.getText());

		if (val == null)
			throw new IllegalStateException(
					"Attempted to retrieve undefined ID " + ID.getText());

		return val;
	}

	/** Logical OR `||' operator */
	private Boolean logOR(SeeAST t) {
		Boolean vl = (Boolean) exec((SeeAST) t.getChild(0));
		if (vl.booleanValue())
			return vl;
		Boolean vr = (Boolean) exec((SeeAST) t.getChild(1));
		return vr;
	}

	/** Logical AND `&&' operator */
	private Boolean logAND(SeeAST t) {
		Boolean vl = (Boolean) exec((SeeAST) t.getChild(0));
		if (!vl.booleanValue())
			return vl;
		Boolean vr = (Boolean) exec((SeeAST) t.getChild(1));
		return vr;
	}

	/** Equality operator `==' */
	private Boolean eq(SeeAST t) {
		ChildValues cv = execChildrenAndPromote(t);
		Object leftVal = cv.left, rightVal = cv.right;

		// are they structs, arrays or the null literal?
		if (((SeeAST) t.getChild(0)).evalType.getTypeIndex() == index_USER)
			return leftVal == rightVal;

		// primitives
		return leftVal.equals(rightVal);
	}

	/** Logical not `!' */
	private Boolean logNot(SeeAST t) {
		Boolean val = (Boolean) exec((SeeAST) t.getChild(0));
		return !val;
	}

	/** Lower than operator < */
	private Boolean lt(SeeAST t) {
		ChildValues cv = execChildrenAndPromote(t);
		Object leftVal = cv.left, rightVal = cv.right;

		if (leftVal instanceof Integer)
			return ((Integer) leftVal).compareTo((Integer) rightVal) < 0;

		if (leftVal instanceof Double)
			return ((Double) leftVal).compareTo((Double) rightVal) < 0;

		return ((Character) leftVal).compareTo((Character) rightVal) < 0;
	}

	/** Lower equal operator `<=' */
	private Boolean leq(SeeAST t) {
		ChildValues cv = execChildrenAndPromote(t);
		Object leftVal = cv.left, rightVal = cv.right;

		if (leftVal instanceof Integer)
			return ((Integer) leftVal).compareTo((Integer) rightVal) <= 0;

		if (leftVal instanceof Double)
			return ((Double) leftVal).compareTo((Double) rightVal) <= 0;

		return ((Character) leftVal).compareTo((Character) rightVal) <= 0;
	}

	/** Plus `+' */
	private Object plus(SeeAST t) {
		ChildValues cv = execChildrenAndPromote(t);
		Object leftVal = cv.left, rightVal = cv.right;

		if (leftVal instanceof Integer)
			return ((Integer) leftVal) + ((Integer) rightVal);

		return ((Double) leftVal) + ((Double) rightVal);
	}

	/** Minus `-' */
	private Object minus(SeeAST t) {
		ChildValues cv = execChildrenAndPromote(t);
		Object leftVal = cv.left, rightVal = cv.right;

		if (leftVal instanceof Integer)
			return ((Integer) leftVal) - ((Integer) rightVal);

		return ((Double) leftVal) - ((Double) rightVal);
	}

	/** Multiply `*' */
	private Object mul(SeeAST t) {
		ChildValues cv = execChildrenAndPromote(t);
		Object leftVal = cv.left, rightVal = cv.right;

		if (leftVal instanceof Integer)
			return ((Integer) leftVal) * ((Integer) rightVal);

		return ((Double) leftVal) * ((Double) rightVal);
	}

	/** Divide `/' */
	private Object div(SeeAST t) {
		ChildValues cv = execChildrenAndPromote(t);
		Object leftVal = cv.left, rightVal = cv.right;

		if (leftVal instanceof Integer)
			return ((Integer) leftVal) / ((Integer) rightVal);

		return ((Double) leftVal) / ((Double) rightVal);
	}

	/** Mod `%' */
	private Object mod(SeeAST t) {
		ChildValues cv = execChildrenAndPromote(t);
		Object leftVal = cv.left, rightVal = cv.right;

		return ((Integer) leftVal) % ((Integer) rightVal);
	}

	/** Unary Minus `-' */
	private Object unaryMinus(SeeAST t) {
		SeeAST node = (SeeAST) t.getChild(0);
		Object val = exec(node);

		if (val instanceof Integer)
			return -((Integer) val);

		return -((Double) val);
	}

	/** DOT operator `.' */
	private Object loadField(SeeAST dot) {
		ensureNodeType(dot, SeeLexer.DOT, "loadField");

		SeeAST leftNode = (SeeAST) dot.getChild(0);
		SeeAST rightNode = (SeeAST) dot.getChild(1);

		Object memSpace = exec(leftNode);
		if (memSpace == nullObj) {
			throw new UserNullPointerException(
					"Attempt to dereference null at " + dot.getLocation());
		}

		Object val = ((MemorySpace) memSpace).get(rightNode.getText());

		if (val == null)
			throw new IllegalStateException(
					"Attempted to retrieve undefined ID " + rightNode.getText());

		return val;
	}

	/** Assign to field; called by assign() */
	private Object fieldAssign(SeeAST dot, Object value) {
		ensureNodeType(dot, SeeLexer.DOT, "fieldAssign");

		// grammar guarantees ^(DOT expr ID) – so child(1) is ID
		String fieldName = dot.getChild(1).getText();

		Object instance = exec((SeeAST) dot.getChild(0));

		if (instance == nullObj)
			throw new UserNullPointerException(
					"Attempt to dereference null at " + dot.getLocation());

		((MemorySpace) instance).put(fieldName, value);
		return value;
	}

	/** Array index operator `[]' */
	private Object index(SeeAST t) {
		SeeAST leftNode = (SeeAST) t.getChild(0);
		SeeAST rightNode = (SeeAST) t.getChild(1);

		Object[] leftVal = (Object[]) exec(leftNode);
		if (leftVal == nullObj)
			throw new UserNullPointerException(
					"Attempt to dereference null at " + t.getLocation());

		Object rightObj = exec(rightNode);
		int rightVal;
		if (rightObj instanceof Character)
			rightVal = (Character) rightObj;
		else
			rightVal = (Integer) rightObj;

		if (rightVal < 0 || rightVal >= leftVal.length)
			throw new UserArrayIndexOutOfBoundsException("Array index "
					+ rightVal + " out of bounds at " + t.getLocation());

		return leftVal[rightVal];
	}

	/** Length of array operator `len' */
	private Integer lenOp(SeeAST t) {
		Object[] array = (Object[]) exec((SeeAST) t.getChild(0));
		if (array == nullObj)
			throw new UserNullPointerException(
					"Asked for length of null array at " + t.getLocation());

		return array.length;
	}

	/** New struct `new' operator */
	private Object newStruct(SeeAST t) {
		SeeAST child = (SeeAST) t.getChild(0);
		StructType st = (StructType) child.symbol;
		MemorySpace newMemSpace = new MemorySpace(st.getName());

		// initialize all fields with the default value
		for (Map.Entry<String, Symbol> member : st.getOrderedMembers()) {
			Symbol symb = member.getValue();
			if (symb instanceof Type)
				continue;
			newMemSpace.put(member.getKey(), getDefaultValue(symb.getType()));
		}

		return newMemSpace;
	}

	/** New array `new[][]' operator */
	private Object newArray(SeeAST t) {
		SeeAST typeNode = (SeeAST) t.getChild(0);
		Type elementType = (Type) typeNode.symbol;

		int totalDims = Integer.valueOf(t.getChild(1).getText());

		List<Integer> knownDims = new ArrayList<Integer>();
		int dimsToCreate = t.getChildCount() - 2;
		for (int i = 0; i < dimsToCreate; i++) {
			SeeAST sizeExpr = (SeeAST) t.getChild(2 + i);

			Object sizeExprVal = exec(sizeExpr);
			Integer size;
			if (sizeExprVal instanceof Character)
				size = Integer.valueOf((Character) sizeExprVal);
			else
				size = (Integer) sizeExprVal;

			knownDims.add(size);
		}

		int[] dimsArr = new int[knownDims.size()];
		int i = 0;
		for (Integer dim : knownDims)
			dimsArr[i++] = dim;

		// grammar guarantees at least one entry in dimsList
		return createArray(dimsArr, dimsArr.length, totalDims, elementType);
	}

	/** Array Element assign - called by assign() */
	private Object arrayElemAssign(SeeAST index, Object value) {
		Object[] array = (Object[]) exec((SeeAST) index.getChild(0));

		if (array == nullObj)
			throw new UserNullPointerException(
					"Attempt to dereference null at " + index.getLocation());

		Object posObj = exec((SeeAST) index.getChild(1));

		int pos;
		if (posObj instanceof Character)
			pos = (Character) posObj;
		else
			pos = (Integer) posObj;

		if (pos < 0 || pos >= array.length)
			throw new UserArrayIndexOutOfBoundsException("Array index " + pos
					+ " out of bounds at " + index.getLocation());

		// value has already been promoted by the caller assign(..)
		return array[pos] = value;
	}

	/**
	 * Create (part of) a new array with recursive calls.
	 * 
	 * The user asks for: double[][][] d = new double[7][9][];
	 * 
	 * nonEmptyDims=[7, 9], lastN=2 for the first call (then 1), totalDims=3 and
	 * elementType is `double'.
	 */
	private Object createArray(int[] nonEmptyDims, int lastN, int totalDims,
			Type elementType) {
		int size = nonEmptyDims[nonEmptyDims.length - lastN];
		Object[] result = new Object[size];

		if (lastN == 1) {
			// if all dimensions specified to new[][] operator, then cells
			// contain elementType not arrays:
			// use default value for elementType; else use nullObj
			Object cellValue;
			if (nonEmptyDims.length == totalDims)
				cellValue = getDefaultValue(elementType);
			else
				cellValue = nullObj;

			for (int i = 0; i < size; i++)
				result[i] = cellValue;

		} else {
			for (int i = 0; i < size; i++)
				result[i] = createArray(nonEmptyDims, lastN - 1, totalDims,
						elementType);
		}

		return result;
	}

	/** Call operator (function call) */
	private Object call(SeeAST t) {
		FunctionSymbol fsymb = (FunctionSymbol) ((SeeAST) t.getChild(0)).symbol;
		MemorySpace fspace = new MemorySpace(fsymb.getName());

		Iterator<Entry<String, Symbol>> it = fsymb.getOrderedMembers()
				.iterator();
		int childCount = t.getChildCount();
		for (int i = 1; i < childCount; i++) {
			SeeAST argNode = (SeeAST) t.getChild(i);
			Object val = exec(argNode);

			if (argNode.promoteToType != null) {
				val = promote(val, argNode.evalType.getTypeIndex(),
						argNode.promoteToType.getTypeIndex());
			}

			String name = it.next().getKey();
			fspace.put(name, val);
		}

		Object retVal = null;
		functionStack.push(fspace);
		crtFuncSpace = fspace;
		try {
			SeeAST func_def = (SeeAST) fsymb.getDefNode().getParent();
			int n = func_def.getChildCount();
			exec((SeeAST) func_def.getChild(n - 1));
		} catch (FunctionReturnException fre) {
			retVal = fre.retVal;
		}
		functionStack.pop();
		crtFuncSpace = functionStack.peek();

		if (retVal == null
				&& fsymb.getReturnType().getTypeIndex() != index_VOID)
			throw new IllegalStateException("Non-void function "
					+ fsymb.getName() + " ended without returning a value;"
					+ " called from " + t.getLocation());

		return retVal;
	}

	/** Return statement */
	private void returnStat(SeeAST t) {
		if (t.getChildCount() == 0)
			sharedReturn.retVal = null;
		else
			sharedReturn.retVal = exec((SeeAST) t.getChild(0));

		throw sharedReturn;
	}

	/** If statement */
	private void ifStat(SeeAST t) {
		SeeAST cond = (SeeAST) t.getChild(0);
		SeeAST nodeThen = (SeeAST) t.getChild(1);
		SeeAST nodeElse = null;
		if (t.getChildCount() == 3)
			nodeElse = (SeeAST) t.getChild(2);

		if ((Boolean) exec(cond)) {
			exec(nodeThen);
		} else {
			if (nodeElse != null)
				exec(nodeElse);
		}
	}

	/** While statement */
	private void whileStat(SeeAST t) {
		SeeAST cond = (SeeAST) t.getChild(0);
		SeeAST stat = (SeeAST) t.getChild(1);

		while ((Boolean) exec(cond)) {
			exec(stat);
		}
	}

	/*
	 * Utility
	 */

	private static void ensureNodeType(SeeAST node, int expectedType,
			String caller) {
		if (node.getType() != expectedType)
			throw new IllegalArgumentException("Unexpected type "
					+ node.getType() + " in " + caller + "; expected "
					+ expectedType);
	}

	private static class ChildValues {
		final Object left, right;

		ChildValues(Object left, Object right) {
			this.left = left;
			this.right = right;
		}
	}

	private ChildValues execChildrenAndPromote(SeeAST t) {
		SeeAST leftNode = (SeeAST) t.getChild(0);
		SeeAST rightNode = (SeeAST) t.getChild(1);
		Object leftVal = exec(leftNode);
		Object rightVal = exec(rightNode);

		if (leftNode.promoteToType != null) {
			leftVal = promote(leftVal, leftNode.evalType.getTypeIndex(),
					leftNode.promoteToType.getTypeIndex());
		}
		if (rightNode.promoteToType != null) {
			rightVal = promote(rightVal, rightNode.evalType.getTypeIndex(),
					rightNode.promoteToType.getTypeIndex());
		}

		return new ChildValues(leftVal, rightVal);
	}

}
