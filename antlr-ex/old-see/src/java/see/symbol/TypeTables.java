package see.symbol;

/**
 * Separate file containing tables, mainly for text formatting reasons.
 * Promotion tables are indexed with the types of the two operands
 * (not with an operand and the result of the operation).
 * structs, arrays and the null type are treated together (user type).
 */
class TypeTables {

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

	public TypeTables(Type _bool, Type _char, Type _int, Type _double, Type _void) {

		/* Arithmetic +, -, *, / operators */

		arithmResultType = new Type[][] {
		/*            user    boolean  char      int       double    void    func */
		/*user*/     {_void,  _void,   _void,    _void,    _void,    _void,  _void},
		/*boolean*/  {_void,  _void,   _void,    _void,    _void,    _void,  _void},
		/*char*/     {_void,  _void,   _int,     _int,     _double,  _void,  _void},
		/*int*/      {_void,  _void,   _int,     _int,     _double,  _void,  _void},
		/*double*/   {_void,  _void,   _double,  _double,  _double,  _void,  _void},
		/*void*/     {_void,  _void,   _void,    _void,    _void,    _void,  _void},
		/*func*/     {_void,  _void,   _void,    _void,    _void,    _void,  _void}
		};

		promoteArithm = new Type[][] {
		/*            user   boolean  char   int    double    void   func */
		/*user*/     {null,  null,    null,  null,  null,     null,  null},
		/*boolean*/  {null,  null,    null,  null,  null,     null,  null},
		/*char*/     {null,  null,    _int,  _int,  _double,  null,  null},
		/*int*/      {null,  null,    null,  null,  _double,  null,  null},
		/*double*/   {null,  null,    null,  null,  null,     null,  null},
		/*void*/     {null,  null,    null,  null,  null,     null,  null},
		/*func*/     {null,  null,    null,  null,  null,     null,  null}
		};

		/* Modulus operator, % */
		modResultType = new Type[][] {
		/*            user    boolean  char    int     double  void    func*/
		/*user*/     {_void,  _void,   _void,  _void,  _void,  _void,  _void},
		/*boolean*/  {_void,  _void,   _void,  _void,  _void,  _void,  _void},
		/*char*/     {_void,  _void,   _int,   _int,   _void,  _void,  _void},
		/*int*/      {_void,  _void,   _int,   _int,   _void,  _void,  _void},
		/*double*/   {_void,  _void,   _void,  _void,  _void,  _void,  _void},
		/*void*/     {_void,  _void,   _void,  _void,  _void,  _void,  _void},
		/*func*/     {_void,  _void,   _void,  _void,  _void,  _void,  _void}
		};

		promoteMod = new Type[][] {
		/*            user   boolean  char   int    double  void   func */
		/*user*/     {null,  null,    null,  null,  null,   null,  null},
		/*boolean*/  {null,  null,    null,  null,  null,   null,  null},
		/*char*/     {null,  null,    _int,  _int,  null,   null,  null},
		/*int*/      {null,  null,    null,  null,  null,   null,  null},
		/*double*/   {null,  null,    null,  null,  null,   null,  null},
		/*void*/     {null,  null,    null,  null,  null,   null,  null},
		/*func*/     {null,  null,    null,  null,  null,   null,  null}
		};

		/* Relational operators, <, <=, >, >= */
		relResultType = new Type[][] {
		/*            user    boolean  char    int     double  void    func */
		/*user*/     {_void,  _void,   _void,  _void,  _void,  _void,  _void},
		/*boolean*/  {_void,  _void,   _void,  _void,  _void,  _void,  _void},
		/*char*/     {_void,  _void,   _bool,  _bool,  _bool,  _void,  _void},
		/*int*/      {_void,  _void,   _bool,  _bool,  _bool,  _void,  _void},
		/*double*/   {_void,  _void,   _bool,  _bool,  _bool,  _void,  _void},
		/*void*/     {_void,  _void,   _void,  _void,  _void,  _void,  _void},
		/*func*/     {_void,  _void,   _void,  _void,  _void,  _void,  _void}
		};

		promoteRel = new Type[][] {
		/*            user   boolean  char   int    double    void   func */
		/*user*/     {null,  null,    null,  null,  null,     null,  null},
		/*boolean*/  {null,  null,    null,  null,  null,     null,  null},
		/*char*/     {null,  null,    null,  _int,  _double,  null,  null},
		/*int*/      {null,  null,    null,  null,  _double,  null,  null},
		/*double*/   {null,  null,    null,  null,  null,     null,  null},
		/*void*/     {null,  null,    null,  null,  null,     null,  null},
		/*func*/     {null,  null,    null,  null,  null,     null,  null}
		};

		/* Equality operators ==, != */
		eqResultType = new Type[][] {
		/*            user    boolean  char    int     double  void    func */
		/*user*/     {_bool,  _void,   _void,  _void,  _void,  _void,  _void},
		/*boolean*/  {_void,  _bool,   _void,  _void,  _void,  _void,  _void},
		/*char*/     {_void,  _void,   _bool,  _bool,  _bool,  _void,  _void},
		/*int*/      {_void,  _void,   _bool,  _bool,  _bool,  _void,  _void},
		/*double*/   {_void,  _void,   _bool,  _bool,  _bool,  _void,  _void},
		/*void*/     {_void,  _void,   _void,  _void,  _void,  _void,  _void},
		/*func*/     {_void,  _void,   _void,  _void,  _void,  _void,  _void}
		};

		promoteEq = new Type[][] {
		/*            user   boolean  char   int    double    void   func */
		/*user*/     {null,  null,    null,  null,  null,     null,  null},
		/*boolean*/  {null,  null,    null,  null,  null,     null,  null},
		/*char*/     {null,  null,    null,  _int,  _double,  null,  null},
		/*int*/      {null,  null,    null,  null,  _double,  null,  null},
		/*double*/   {null,  null,    null,  null,  null,     null,  null},
		/*void*/     {null,  null,    null,  null,  null,     null,  null},
		/*func*/     {null,  null,    null,  null,  null,     null,  null}
		};

		/* Logical operators &&, || */
		logResultType = new Type[][] {
		/*            user    boolean  char    int     double  void    func */
		/*user*/     {_void,  _void,   _void,  _void,  _void,  _void,  _void},
		/*boolean*/  {_void,  _bool,   _void,  _void,  _void,  _void,  _void},
		/*char*/     {_void,  _void,   _void,  _void,  _void,  _void,  _void},
		/*int*/      {_void,  _void,   _void,  _void,  _void,  _void,  _void},
		/*double*/   {_void,  _void,   _void,  _void,  _void,  _void,  _void},
		/*void*/     {_void,  _void,   _void,  _void,  _void,  _void,  _void},
		/*func*/     {_void,  _void,   _void,  _void,  _void,  _void,  _void}
		};

		promoteLog = new Type[][] {
		/*            user   boolean  char   int    double  void   func */
		/*user*/     {null,  null,    null,  null,  null,   null,  null},
		/*boolean*/  {null,  null,    null,  null,  null,   null,  null},
		/*char*/     {null,  null,    null,  null,  null,   null,  null},
		/*int*/      {null,  null,    null,  null,  null,   null,  null},
		/*double*/   {null,  null,    null,  null,  null,   null,  null},
		/*void*/     {null,  null,    null,  null,  null,   null,  null},
		/*func*/     {null,  null,    null,  null,  null,   null,  null}
		};

		/* Assignment operator = */
		promoteAssign = new Type[][] {
		/*            user   boolean  char   int    double    void   func */
		/*user*/     {null,  null,    null,  null,  null,     null,  null},
		/*boolean*/  {null,  null,    null,  null,  null,     null,  null},
		/*char*/     {null,  null,    null,  _int,  _double,  null,  null},
		/*int*/      {null,  null,    null,  null,  _double,  null,  null},
		/*double*/   {null,  null,    null,  null,  null,     null,  null},
		/*void*/     {null,  null,    null,  null,  null,     null,  null},
		/*func*/     {null,  null,    null,  null,  null,     null,  null}
		};

	}

}
