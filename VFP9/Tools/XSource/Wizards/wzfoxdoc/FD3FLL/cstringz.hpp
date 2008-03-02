
#pragma warning (disable: 4270)

/*
nonstandard extension used: 'initializing': a non-const 'type1' must be initialized with 
an l-value, not a function returning 'type2'

A nonconst reference must be initialized with an l-value, which makes the reference a name 
for that l-value. A function call is only an l-value if the return type of the function is a 
reference. A Microsoft extension to the C++ language allows any function call to be treated as 
an l-value for the purpose of initializing references. If Microsoft extensions are disabled (/Za), 
then this an error.
This warning can be avoided by ensuring the reference is a const reference. However, if the 
reference is const and the function return type is not compatible with the type of the 
reference, the compiler will silently generate and initialize a temporary. Although this is not 
incorrect, it is inefficient and probably undesirable.

*/

class CStringz {
	protected:
	char *str;
	MHANDLE mh;
	BOOL IsLocked;
	void Create(Value *val);

	public:
	CStringz();						//default const
	CStringz(char *);				//constructor
	CStringz (ParamBlk *parm,int pnum);//Constructor
	CStringz(Value *);				//cons
	CStringz (CStringz &);	//copy constr
	~CStringz();					//destructor
	void Refresh();
	void Show();
	MHANDLE GetHandle() {return mh;}
	int len();
	int val();
	BOOL GetIsLocked() {return IsLocked;}
	char *pstring();	//return a pointer to the string
	char Char(int i);
	CStringz & Upper(void) ;
	CStringz & Lower(void) ;
	int operator ==(CStringz & s); //equality
	CStringz & operator = (CStringz &) ;	//overloaded assignment
	CStringz & operator = (Value *) ;	//overloaded assignment
	CStringz & operator = (char *) ;	//overloaded assignment
//	void *operator new (unsigned int);
//	void operator delete(void *);
	friend CStringz operator +(CStringz&,CStringz &);
//	friend ostream &operator <<(ostream &, const CStringz &);

	void Lock();
	void UnLock();
		
};

