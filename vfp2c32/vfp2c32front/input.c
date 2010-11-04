typedef struct TdevInfo
{
	wchar_t	serialNumber	[257]	;
	BYTE	uniqueID		[20]		;
	wchar_t	vendorString	[10]	;
	wchar_t	productString	[18]	;
	wchar_t	FWVersion		[7]		;
	DWORD	vendorID			;
	DWORD64	deviceSize			;
}devInfo ;
