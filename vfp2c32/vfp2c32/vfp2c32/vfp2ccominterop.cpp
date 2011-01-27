#include "rpc.h"
#include "pro_ext.h"
#include "vfp2c32.h"
#include "vfp2ccominterop.h"
#include "vfp2cutil.h"
#include "vfpmacros.h"
#include "vfp2ccppapi.h"

IDynamicComWrapper::~IDynamicComWrapper()
{

}

STDMETHODIMP IDynamicComWrapper::QueryInterface(REFIID riid, void **ppvObject)
{
	*ppvObject = NULL;
	HRESULT hr;

	// IUnknown
	if (::IsEqualIID(riid, __uuidof(IUnknown)))
	{
		*ppvObject = this;
		hr = S_OK;
	}
	// IDispatch
	else if (::IsEqualIID(riid, __uuidof(IDispatch)))
	{
		*ppvObject = static_cast<IDispatch*>(this);
		hr = S_OK;
	}
	else if(m_pUnk)
	{
		hr = m_pUnk->QueryInterface(riid,ppvObject);
		if (SUCCEEDED(hr))
		{
			IUnknown *pTmp;
			pTmp = reinterpret_cast<IUnknown*>(ppvObject);
			pTmp->Release();
		}
	}
	else
		hr = E_NOINTERFACE;

	return hr;
}

STDMETHODIMP_(ULONG) IDynamicComWrapper::AddRef()
{
	return ++m_RefCount;
}

STDMETHODIMP_(ULONG) IDynamicComWrapper::Release()
{
	m_RefCount--;
	if (m_RefCount == 0)
	{
		if (m_pUnk)
		{
			m_pUnk->Release();
			m_pUnk = 0;
		}
		delete this;
	}
	return m_RefCount;
}

STDMETHODIMP IDynamicComWrapper::GetTypeInfoCount(UINT* pctinfo)
{
	*pctinfo = 0; 
	return S_OK;
}

STDMETHODIMP IDynamicComWrapper::GetTypeInfo(UINT /*itinfo*/, LCID /*lcid*/, ITypeInfo** /*pptinfo*/)
{
	return E_NOTIMPL;
}

STDMETHODIMP IDynamicComWrapper::GetIDsOfNames(REFIID riid, LPOLESTR* rgszNames, UINT cNames, LCID lcid, DISPID* rgdispid)
{
	*rgdispid = 1;
/*      HRESULT Hr = S_OK;
      for( UINT i=0; i<cNames; i++ ) {
         const _ATL_DISPATCH_ENTRY<T>* pMap = T::_GetDispMap();
         while( pMap->pfn!=NULL ) {
            if( ::lstrcmpiW(pMap->szName, rgszNames[i])==0 ) {
               rgdispid[i] = pMap->dispid==DISPID_UNKNOWN ? dispid : pMap->dispid;
               break;
            }
            dispid++;
            pMap++;
         }
         if( pMap->pfn==NULL ) {
            rgdispid[i] = DISPID_UNKNOWN;
            Hr = DISP_E_UNKNOWNNAME; 
         }
      }
  */
  return S_OK;
}

STDMETHODIMP IDynamicComWrapper::Invoke(DISPID dispidMember, REFIID riid, LCID lcid, WORD wFlags, 
										DISPPARAMS* pdispparams, VARIANT* pvarResult, EXCEPINFO* pexcepinfo, UINT* puArgErr)
{
	if (pvarResult)
	{
		VariantInit(pvarResult);
		if (wFlags == DISPATCH_METHOD)
		{
			pvarResult->vt = VT_BSTR;
			pvarResult->bstrVal = SysAllocString(L"Hello Fox");
			return S_OK;
		}
	}
	return DISP_E_MEMBERNOTFOUND;
/*
      if( (DISPATCH_PROPERTYPUT!=wFlags) && (pdispparams->cNamedArgs>0) ) return DISP_E_NONAMEDARGS;
      const _ATL_DISPATCH_ENTRY<T>* pMap = T::_GetDispMap();
      DISPID i = 1;
      while( pMap->pfn!=NULL ) {
         DISPID dispid = pMap->dispid==DISPID_UNKNOWN ? i : pMap->dispid;
         if( dispidMember==dispid ) {
            if( (DISPATCH_PROPERTYPUT==wFlags) && (DISPID_PROPERTYPUT==(pMap+1)->dispid) ) 
               pMap++;
            VARTYPE* pArgs = (VARTYPE*) pMap->vtArgs;
            if( pArgs == NULL ) pArgs = (VARTYPE*) &pMap->vtSingle;
            UINT nArgs = pMap->nArgs;
            if( pdispparams->cArgs != nArgs ) return DISP_E_BADPARAMCOUNT;
            VARIANTARG** ppVarArgs = nArgs ? (VARIANTARG**)_alloca(sizeof(VARIANTARG*)*nArgs) : NULL;
            VARIANTARG* pVarArgs = nArgs ? (VARIANTARG*)_alloca(sizeof(VARIANTARG)*nArgs) : NULL;
            UINT i;
            for( i=0; i<nArgs; i++ ) {
               ppVarArgs[i] = &pVarArgs[i];
               ::VariantInit(&pVarArgs[i]);
               if( FAILED(::VariantCopyInd(&pVarArgs[i], &pdispparams->rgvarg[nArgs-i-1])) ) return DISP_E_TYPEMISMATCH;
               if( FAILED(::VariantChangeType(&pVarArgs[i], &pVarArgs[i], 0, pArgs[i])) ) return DISP_E_TYPEMISMATCH;
            }
            T *pT = static_cast<T*>(this);
            CComStdCallThunk<T> thunk;
            thunk.Init(pMap->pfn, pT);
            CComVariant tmpResult;
            if( pvarResult==NULL ) pvarResult = &tmpResult;
            HRESULT Hr = ::DispCallFunc(
               &thunk,
               0,
               CC_STDCALL,
               pMap->vtReturn,
               nArgs,
               pArgs,
               nArgs ? ppVarArgs : NULL,
               pvarResult);
            for( i=0; i<nArgs; i++ ) ::VariantClear(&pVarArgs[i]);
            return Hr;
         }
         i++;
         pMap++;
      }
      return DISP_E_MEMBERNOTFOUND;
	*/
}

void IDynamicComWrapper::CreateComObject(wchar_t *pComClass, REFCLSID rInterface)
{
	HRESULT hr;
	CLSID pClsId;
	hr = CLSIDFromProgID(pComClass,&pClsId);
	if (FAILED(hr))
	{
		SaveWin32Error("CLSIDFromProgID", hr);
		throw E_APIERROR;
	}
	
	hr = CoCreateInstance(pClsId, NULL, CLSCTX_INPROC_SERVER, rInterface,(void**)&m_pUnk);
	if (FAILED(hr))
	{
		SaveWin32Error("CoCreateInstance", hr);
		throw E_APIERROR;
	}
}

void _fastcall CoCreateComProxy(ParamBlk *parm)
{
	IDynamicComWrapper* pProxy = 0;
try
{
	FoxWString pComClass(p1);
	FoxString pInterface(p2,0);
	FoxString pTypeInfo(p3,0);

	CLSID *pClsId;
	CLSID clsid;
	HRESULT hr;

	pProxy = new IDynamicComWrapper();
	if (!pProxy)
		throw E_INSUFMEMORY;

	if (pInterface.Len() == sizeof(CLSID))
		pClsId = (CLSID*)(void*)pInterface;
	else
	{
		FoxWString pWInterface(p2);
		hr = CLSIDFromString(pWInterface,&clsid);
		if (FAILED(hr))
		{
			SaveWin32Error("CLSIDFromString", hr);
			throw E_APIERROR;
		}
		pClsId = &clsid;
	}

	pProxy->CreateComObject(pComClass,*pClsId);

	Value vObject = {'0'};
	char aCommand[VFP2C_MAX_CALLBACKBUFFER];

	sprintfex(aCommand,"SYS(3096,%I)",pProxy);
	Evaluate(vObject,aCommand);
	Return(vObject);
}
catch(int nErrorNo)
{
	if (pProxy)
		delete pProxy;
	RaiseError(nErrorNo);
}
}

//typedef struct tagPARAMDATA {
//    OLECHAR * szName;   /* parameter name */
//    VARTYPE vt;         /* parameter type */
//} PARAMDATA, * LPPARAMDATA;

//typedef struct tagMETHODDATA {
//   OLECHAR * szName;   /* method name */
//    PARAMDATA * ppdata; /* pointer to an array of PARAMDATAs */
//    DISPID dispid;      /* method ID */
//    UINT iMeth;         /* method index */
//    CALLCONV cc;        /* calling convention */
//    UINT cArgs;         /* count of arguments */
//    WORD wFlags;        /* same wFlags as on IDispatch::Invoke() */
//    VARTYPE vtReturn;
//} METHODDATA, * LPMETHODDATA;

//typedef struct tagINTERFACEDATA {
//    METHODDATA * pmethdata;  /* pointer to an array of METHODDATAs */
//    UINT cMembers;      /* count of members */
//} INTERFACEDATA, * LPINTERFACEDATA;

/* VARIANT STRUCTURE
 *
 *  VARTYPE vt;
 *  WORD wReserved1;
 *  WORD wReserved2;
 *  WORD wReserved3;
 *  union {
 *    LONGLONG       VT_I8
 *    LONG           VT_I4
 *    BYTE           VT_UI1
 *    SHORT          VT_I2
 *    FLOAT          VT_R4
 *    DOUBLE         VT_R8
 *    VARIANT_BOOL   VT_BOOL
 *    SCODE          VT_ERROR
 *    CY             VT_CY
 *    DATE           VT_DATE
 *    BSTR           VT_BSTR
 *    IUnknown *     VT_UNKNOWN
 *    IDispatch *    VT_DISPATCH
 *    SAFEARRAY *    VT_ARRAY
 *    BYTE *         VT_BYREF|VT_UI1
 *    SHORT *        VT_BYREF|VT_I2
 *    LONG *         VT_BYREF|VT_I4
 *    LONGLONG *     VT_BYREF|VT_I8
 *    FLOAT *        VT_BYREF|VT_R4
 *    DOUBLE *       VT_BYREF|VT_R8
 *    VARIANT_BOOL * VT_BYREF|VT_BOOL
 *    SCODE *        VT_BYREF|VT_ERROR
 *    CY *           VT_BYREF|VT_CY
 *    DATE *         VT_BYREF|VT_DATE
 *    BSTR *         VT_BYREF|VT_BSTR
 *    IUnknown **    VT_BYREF|VT_UNKNOWN
 *    IDispatch **   VT_BYREF|VT_DISPATCH
 *    SAFEARRAY **   VT_BYREF|VT_ARRAY
 *    VARIANT *      VT_BYREF|VT_VARIANT
 *    PVOID          VT_BYREF (Generic ByRef)
 *    CHAR           VT_I1
 *    USHORT         VT_UI2
 *    ULONG          VT_UI4
 *    ULONGLONG      VT_UI8
 *    INT            VT_INT
 *    UINT           VT_UINT
 *    DECIMAL *      VT_BYREF|VT_DECIMAL
 *    CHAR *         VT_BYREF|VT_I1
 *    USHORT *       VT_BYREF|VT_UI2
 *    ULONG *        VT_BYREF|VT_UI4
 *    ULONGLONG *    VT_BYREF|VT_UI8
 *    INT *          VT_BYREF|VT_INT
 *    UINT *         VT_BYREF|VT_UINT
 *  }
 */