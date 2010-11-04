class IDynamicComWrapper : public IDispatch
{
public:
	IDynamicComWrapper() : m_RefCount(1) {};
	~IDynamicComWrapper();
	
	// IUnknown methods
	STDMETHOD(QueryInterface)(REFIID riid, void **ppvObject);
	STDMETHOD_(ULONG, AddRef)();
	STDMETHOD_(ULONG, Release)();

	// IDispatch methods
	STDMETHOD(GetTypeInfoCount)(UINT* pctinfo);
	STDMETHOD(GetTypeInfo)(UINT itinfo, LCID lcid, ITypeInfo** pptinfo);
	STDMETHOD(GetIDsOfNames)(REFIID riid, LPOLESTR* rgszNames, UINT cNames, LCID lcid, DISPID* rgdispid);
	STDMETHOD(Invoke)(DISPID dispidMember, REFIID riid, LCID lcid, WORD wFlags, 
		DISPPARAMS* pdispparams, VARIANT* pvarResult, EXCEPINFO* pexcepinfo, UINT* puArgErr);

	void CreateComObject(wchar_t *pComClass, REFCLSID rInterface);

private:
	long m_RefCount;
	IUnknown *m_pUnk;
};

#ifdef __cplusplus
extern "C" {
#endif

void _fastcall CoCreateComProxy(ParamBlk *parm);

#ifdef __cplusplus
}
#endif // end of extern "C"