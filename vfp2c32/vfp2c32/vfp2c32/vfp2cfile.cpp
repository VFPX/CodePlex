// to make File operation (CopyFileEx ..) defines and types available
#define _WIN32_WINNT	0x0500
#define WINVER			0x0500

#include <windows.h>
#include <stdio.h>
#include <winioctl.h>
#include <uxtheme.h>

#include "pro_ext.h"
#include "vfp2c32.h"
#include "vfp2cutil.h"
#include "vfp2cfile.h"
#include "vfpmacros.h"
#include "vfp2ccppapi.h"
#include "vfp2chelpers.h"

// dynamic function pointers for runtime linking
static PGETFILESIZEEX fpGetFileSizeEx = 0;
static PGETLONGPATHNAME fpGetLongPathName = 0;
static PLOCKFILEEX fpLockFileEx = 0;
static PUNLOCKFILEEX fpUnlockFileEx = 0;

static PGETSPECIALFOLDER fpGetSpecialFolder = 0;
static PSHILCREATEFROMPATH fpSHILCreateFromPath = 0;
static PSHILCREATEFROMPATHEX fpSHILCreateFromPathEx = 0;
static PGETFILEATTRIBUTESEX fpGetFileAttributesEx = 0;

static PGETKERNELOBJECTSECURITY fpGetKernelObjectSecurity = 0;
static PGETSECURITYDESCRIPTOROWNER fpGetSecurityDescriptorOwner = 0;
static PLOOKUPACCOUNTSIDA fpLookupAccountSidA = 0;

static PFINDFIRSTVOLUME fpFindFirstVolume = 0;
static PFINDNEXTVOLUME fpFindNextVolume = 0;
static PFINDVOLUMECLOSE fpFindVolumeClose = 0;
static FINDFIRSTVOLUMEMOUNTPOINT fpFindFirstVolumeMountPoint = 0;
static PFINDNEXTVOLUMEMOUNTPOINT fpFindNextVolumeMountPoint = 0;
static PFINDVOLUMEMOUNTPOINTCLOSE fpFindVolumeMountPointClose = 0;
static PGETVOLUMENAMEFORVOLUMEMOUNTPOINT fpGetVolumeNameForVolumeMountPoint = 0;
static PQUERYDOSDEVICE fpQueryDosDevice = 0;
static PDEVICEIOCONTROL fpDeviceIoControl = 0;
static PGETVOLUMEPATHNAME fpGetVolumePathName = 0;

// array of HANDLEs for F..Ex functions (FCreateEx, FOpenEx, FWriteEx ...)
static HANDLE gaFileHandles[VFP2C_MAX_FILE_HANDLES] = {0};

// Filesearch class implementation
bool FileSearch::FindFirst(char *pSearch)
{
	m_Handle = FindFirstFile(pSearch,&File);
	if (m_Handle == INVALID_HANDLE_VALUE)
	{
		DWORD nLastError = GetLastError();
		if (nLastError == ERROR_FILE_NOT_FOUND)
			return false;
		else
		{
			SAVEWIN32ERROR(FindFirstFile,nLastError);
			throw E_APIERROR;
		}
	}
	return true;
}

bool FileSearch::FindNext()
{
	BOOL bNext = FindNextFile(m_Handle,&File);
	if (bNext == FALSE)
	{
		DWORD nLastError = GetLastError();
        if (nLastError == ERROR_NO_MORE_FILES)
		{
			FindClose(m_Handle);
			m_Handle = INVALID_HANDLE_VALUE;
			return false;
		}
		else
		{
			SAVEWIN32ERROR(FindNextFile,nLastError);
			throw E_APIERROR;
		}
	}
	return true;
}

bool FileSearch::IsFakeDir() const
{
	if ((File.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) > 0)
		return strcmp(File.cFileName,".") == 0 || strcmp(File.cFileName,"..") == 0;
	else
		return false;
}

const char* FileSearch::Filename() const
{
	if (File.cFileName[0] != '\0')
		return &File.cFileName[0];
	else
		return &File.cAlternateFileName[0];
}

unsigned __int64 FileSearch::Filesize() const
{
	ULARGE_INTEGER nSize;
	nSize.HighPart = File.nFileSizeHigh;
	nSize.LowPart = File.nFileSizeLow;
	return nSize.QuadPart;
}

// init file functions
bool _stdcall VFP2C_Init_File()
{
	HMODULE hDll;
	bool bRetVal = true;
	
	hDll = GetModuleHandle("kernel32.dll");
	if (hDll)
	{
		fpGetFileSizeEx = (PGETFILESIZEEX)GetProcAddress(hDll,"GetFileSizeEx");
		fpGetFileAttributesEx = (PGETFILEATTRIBUTESEX)GetProcAddress(hDll,"GetFileAttributesExA");
		fpGetLongPathName = (PGETLONGPATHNAME)GetProcAddress(hDll,"GetLongPathNameA");
		fpLockFileEx = (PLOCKFILEEX)GetProcAddress(hDll,"LockFileEx");
		fpUnlockFileEx = (PUNLOCKFILEEX)GetProcAddress(hDll,"UnlockFileEx");

		fpFindFirstVolume = (PFINDFIRSTVOLUME)GetProcAddress(hDll,"FindFirstVolumeA");
		fpFindNextVolume = (PFINDNEXTVOLUME)GetProcAddress(hDll,"FindNextVolumeA");
		fpFindVolumeClose = (PFINDVOLUMECLOSE)GetProcAddress(hDll,"FindVolumeClose");
		fpFindFirstVolumeMountPoint = (FINDFIRSTVOLUMEMOUNTPOINT)GetProcAddress(hDll,"FindFirstVolumeMountPointA");
		fpFindNextVolumeMountPoint = (PFINDNEXTVOLUMEMOUNTPOINT)GetProcAddress(hDll,"FindNextVolumeMountPointA");
		fpFindVolumeMountPointClose = (PFINDVOLUMEMOUNTPOINTCLOSE)GetProcAddress(hDll,"FindFirstVolumeMountPoint");
		fpGetVolumeNameForVolumeMountPoint =
			(PGETVOLUMENAMEFORVOLUMEMOUNTPOINT)GetProcAddress(hDll,"GetVolumeNameForVolumeMountPointA");
		fpQueryDosDevice = (PQUERYDOSDEVICE)GetProcAddress(hDll,"QueryDosDeviceA");
		fpDeviceIoControl = (PDEVICEIOCONTROL)GetProcAddress(hDll,"DeviceIoControl");
		fpGetVolumePathName = (PGETVOLUMEPATHNAME)GetProcAddress(hDll,"GetVolumePathNameA");
	}
	else
	{
		ADDWIN32ERROR(GetModuleHandle,GetLastError());
		bRetVal = false;
	}

	hDll = GetModuleHandle("shell32.dll");
	if (hDll)
	{
		fpGetSpecialFolder = (PGETSPECIALFOLDER)GetProcAddress(hDll,"SHGetSpecialFolderPathA");
		fpSHILCreateFromPath = (PSHILCREATEFROMPATH)GetProcAddress(hDll,"SHILCreateFromPath");
		fpSHILCreateFromPathEx = (PSHILCREATEFROMPATHEX)GetProcAddress(hDll,(LPCSTR)SHILCREATEFROMPATHEXID);
	}
	else
	{
		ADDWIN32ERROR(GetModuleHandle,GetLastError());
		bRetVal = false;
	}

	hDll = GetModuleHandle("advapi32.dll");
	if (hDll)
	{
		fpGetKernelObjectSecurity = (PGETKERNELOBJECTSECURITY)GetProcAddress(hDll,"GetKernelObjectSecurity");
		fpGetSecurityDescriptorOwner = (PGETSECURITYDESCRIPTOROWNER)GetProcAddress(hDll,"GetSecurityDescriptorOwner"); 
		fpLookupAccountSidA = (PLOOKUPACCOUNTSIDA)GetProcAddress(hDll,"LookupAccountSidA");
	}
	else
	{
		ADDWIN32ERROR(GetModuleHandle,GetLastError());
		bRetVal = false;
	}

	return bRetVal;
}

// cleanup
void _stdcall VFP2C_Destroy_File()
{
	// release all file handles
	int xj;
	for (xj = 0; xj < VFP2C_MAX_FILE_HANDLES; xj++)
	{
		if (gaFileHandles[xj])
			CloseHandle(gaFileHandles[xj]);
	}
}

void _fastcall ADirEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	FoxString pDestination(p1);
	FoxString pSearchString(p2);
	DWORD nFileFilter = PCOUNT() >= 3 && p3.ev_long ? p3.ev_long : ~FILE_ATTRIBUTE_FAKEDIRECTORY;
	int nDest = PCOUNT() >= 4 && p4.ev_long ? p4.ev_long : ADIREX_DEST_ARRAY;

	FoxString pFileName(MAX_PATH+1);
	FoxArray pArray;
	FoxCursor pCursor;
	FoxDateTime pFileTime;
	FoxInt64 pFileSize;
	FileSearch pSearch;
	FoxDateTimeLiteral pCreationTime, pAccessTime, pWriteTime;

	CBuffer pCallback;
	CBuffer pCallbackCmd;

	bool bToLocal = (nDest & ADIREX_UTC_TIMES) == 0;
	bool bEnumFakeDirs = (nFileFilter & FILE_ATTRIBUTE_FAKEDIRECTORY) != 0;
	nFileFilter &= ~FILE_ATTRIBUTE_FAKEDIRECTORY;

	DWORD nFileCnt = 0;
	PADIREXFILTER fpFilterFunc;

	if (!(nDest & (ADIREX_DEST_ARRAY | ADIREX_DEST_CURSOR | ADIREX_DEST_CALLBACK)))
		nDest |= ADIREX_DEST_ARRAY;

	if ((nDest & ADIREX_DEST_CALLBACK) && pDestination.Len() > VFP2C_MAX_CALLBACKFUNCTION)
		throw E_INVALIDPARAMS;
	
	if (nDest & ADIREX_FILTER_ALL)
		fpFilterFunc = AdirExFilter_All;
	else if (nDest & ADIREX_FILTER_NONE)
		fpFilterFunc = AdirExFilter_None;
	else if (nDest & ADIREX_FILTER_EXACT)
		fpFilterFunc = AdirExFilter_Exact;
	else
		fpFilterFunc = AdirExFilter_One;

	// destination is array
	if (nDest & ADIREX_DEST_ARRAY)
		pArray.Dimension((char*)pDestination,1,7);
	// else if destination is cursor
	else if (nDest & ADIREX_DEST_CURSOR)
	{
		pCursor.Create(pDestination,"filename C(254), dosfilename C(13), creationtime T, accesstime T, "
						"writetime T, filesize N(20,0), fileattribs I");
	}
	else // destination is callback procedure
	{
		pCallback.Size(VFP2C_MAX_CALLBACKBUFFER);
		pCallbackCmd.Size(VFP2C_MAX_CALLBACKBUFFER);
		sprintfex(pCallback,"%S('%%S','%%S',%%S,%%S,%%S,%%0F,%%U)",(char*)pDestination);
	}
	
	if (!pSearch.FindFirst(pSearchString))
	{
		Return(0);
		return;
	}

	if (nDest & ADIREX_DEST_ARRAY) // if destination is array
	{
		do 
		{
			if (fpFilterFunc(pSearch.File.dwFileAttributes,nFileFilter))
			{
				if (!bEnumFakeDirs && pSearch.IsFakeDir())
					continue;
				
				nFileCnt++;
				pArray.ReDimension(nFileCnt,7);
				pArray(nFileCnt,1) = pFileName = pSearch.File.cFileName;
				pArray(nFileCnt,2) = pFileName = pSearch.File.cAlternateFileName;

				pFileTime = pSearch.File.ftCreationTime;
				if (bToLocal)
					pFileTime.ToLocal();
				pArray(nFileCnt,3) = pFileTime;

				pFileTime = pSearch.File.ftLastAccessTime;
				if (bToLocal)
					pFileTime.ToLocal();
				pArray(nFileCnt,4) = pFileTime;

				pFileTime = pSearch.File.ftLastWriteTime;
				if (bToLocal)
					pFileTime.ToLocal();
				pArray(nFileCnt,5) = pFileTime;

				pArray(nFileCnt,6) = pFileSize = pSearch.Filesize();
				pArray(nFileCnt,7) = (int)pSearch.File.dwFileAttributes;

			} // endif nFileFilter

		} while(pSearch.FindNext());
	}
	else if (nDest & ADIREX_DEST_CURSOR) // destination is cursor ...
	{
		do 
		{
			if (fpFilterFunc(pSearch.File.dwFileAttributes,nFileFilter))
			{

				if (!bEnumFakeDirs && pSearch.IsFakeDir())
					continue;

				nFileCnt++;
				pCursor.AppendBlank();
				pCursor(1) = pFileName = pSearch.File.cFileName;
				pCursor(2) = pFileName = pSearch.File.cAlternateFileName;

				pFileTime = pSearch.File.ftCreationTime;
				if (bToLocal)
					pFileTime.ToLocal();
				pCursor(3) = pFileTime;

				pFileTime = pSearch.File.ftLastAccessTime;
				if (bToLocal)
					pFileTime.ToLocal();
				pCursor(4) = pFileTime;

				pFileTime = pSearch.File.ftLastWriteTime;
				if (bToLocal)
					pFileTime.ToLocal();
				pCursor(5) = pFileTime;

				pCursor(6) = pFileSize = pSearch.Filesize();
				pCursor(7) = (int)pSearch.File.dwFileAttributes;

			} // endif nFileFilter

		} while(pSearch.FindNext());
	}
	else // call callback procedure
	{
		V_VALUE(vRetVal);
		double nFileSize;

		do 
		{
			if (fpFilterFunc(pSearch.File.dwFileAttributes,nFileFilter))
			{

			if (!bEnumFakeDirs && pSearch.IsFakeDir())
				continue;
			
			pCreationTime.Convert(pSearch.File.ftCreationTime,bToLocal);
			pAccessTime.Convert(pSearch.File.ftLastAccessTime,bToLocal);
			pWriteTime.Convert(pSearch.File.ftLastWriteTime,bToLocal);
			nFileSize = (double)pSearch.Filesize();
            
			sprintfex(pCallbackCmd,pCallback,pSearch.File.cFileName,pSearch.File.cAlternateFileName,
				(char*)pCreationTime,(char*)pAccessTime,(char*)pWriteTime,nFileSize,pSearch.File.dwFileAttributes);

			Evaluate(vRetVal,pCallbackCmd);
			if (!vRetVal.ev_length)
				break;
			
			} // endif nFileFilter

		} while(pSearch.FindNext());
	}

	Return(nFileCnt);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

bool _stdcall AdirExFilter_All(DWORD nAttributes, DWORD nFilter)
{
	return (nAttributes & nFilter) == nFilter;
}

bool _stdcall AdirExFilter_One(DWORD nAttributes, DWORD nFilter)
{
	return (nAttributes & nFilter) > 0;
}

bool _stdcall AdirExFilter_None(DWORD nAttributes, DWORD nFilter)
{
	return (nAttributes & nFilter) == 0;
}

bool _stdcall AdirExFilter_Exact(DWORD nAttributes, DWORD nFilter)
{
	return nAttributes == nFilter;
}

void _fastcall ADirectoryInfo(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (p2.ev_length > MAXFILESEARCHPARAM)
		throw E_INVALIDPARAMS;

	FoxArray pArray(p1,3,1);
	FoxString pDirectory(p2);
	FoxInt64 pFileSize;
	CStr pSearch(MAX_PATH);

	DIRECTORYINFO sDirInfo = {0,0,0,0};

	pSearch = pDirectory;
	pSearch.AddBs();

	ADirectoryInfoSubRoutine(&sDirInfo,pSearch);

	pArray(1) = sDirInfo.nNumberOfFiles;
	pArray(2) = sDirInfo.nNumberOfSubDirs;
	pArray(3) = pFileSize = sDirInfo.nDirSize;

	Return(1);
}
catch (int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _stdcall ADirectoryInfoSubRoutine(LPDIRECTORYINFO pDirInfo, CStr& pDirectory) throw(int)
{
	FileSearch pSearch;
	CStr pFileSearch(MAX_PATH);

	if (pDirectory.Len() > MAXFILESEARCHPARAM)
	{
		SAVECUSTOMERROR("ADirectoryInfo","Path exceeds MAX_PATH characters.");
		throw E_APIERROR;
	}

	pFileSearch = pDirectory;
	pFileSearch.AddBsWc();

	if (!pSearch.FindFirst(pFileSearch))
		return;

	do 
	{
		if (pSearch.File.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
		{
			if (pSearch.IsFakeDir())
				continue;

			pDirInfo->nNumberOfSubDirs++;

			pFileSearch = pDirectory;
			pFileSearch += pSearch.Filename();
			pFileSearch.AddBs();

			ADirectoryInfoSubRoutine(pDirInfo,pFileSearch);
		}
		else
		{
			pDirInfo->nNumberOfFiles++;
			pDirInfo->nDirSize += pSearch.Filesize();
		}
	} while (pSearch.FindNext());
}

void _fastcall AFileAttributes(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpGetFileAttributesEx)
		throw E_NOENTRYPOINT;

	FoxArray pArray(p1,5,1);
	FoxString pFileName(p2);
	bool bToLocal = PCOUNT() == 2 || !p3.ev_length;
	FoxDateTime pFileTime;
	FoxInt64 pFileSize;
	WIN32_FILE_ATTRIBUTE_DATA sFileAttribs;

	if (!fpGetFileAttributesEx(pFileName.Fullpath(),GetFileExInfoStandard,&sFileAttribs))
	{
		SAVEWIN32ERROR(GetFileAttributesEx,GetLastError());
		throw E_APIERROR;
	}

	pArray(1) = (int)sFileAttribs.dwFileAttributes;
	pArray(2) = pFileSize = Ints2Double(sFileAttribs.nFileSizeLow, sFileAttribs.nFileSizeHigh);
	
	pFileTime = sFileAttribs.ftCreationTime;
	if (bToLocal)
		pFileTime.ToLocal();
	pArray(3) = pFileTime;

	pFileTime = sFileAttribs.ftLastAccessTime;
	if (bToLocal)
		pFileTime.ToLocal();
	pArray(4) = pFileTime;

	pFileTime = sFileAttribs.ftLastWriteTime;
	if (bToLocal)
		pFileTime.ToLocal();
	pArray(5) = pFileTime;

	Return(1);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall AFileAttributesEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	FoxArray pArray(p1,9,1);
	FoxString pFileName(p2);
	bool bToLocal = PCOUNT() == 2 || !p3.ev_length;
	FoxDateTime pFileTime;
	FoxInt64 pFileSize;
	ApiHandle hFile;
	BY_HANDLE_FILE_INFORMATION sFileAttribs;

	hFile = CreateFile(pFileName.Fullpath(),0,0,0,OPEN_EXISTING,FILE_FLAG_BACKUP_SEMANTICS,0);
	if (!hFile)
	{
		SAVEWIN32ERROR(CreateFile,GetLastError());
		throw E_APIERROR;
	}

	if (!GetFileInformationByHandle(hFile,&sFileAttribs))
	{
		SAVEWIN32ERROR(GetFileInformationByHandle,GetLastError());
		throw E_APIERROR;
	}

	pArray(1) = (int)sFileAttribs.dwFileAttributes;
	pArray(2) = pFileSize = Ints2Double(sFileAttribs.nFileSizeLow, sFileAttribs.nFileSizeHigh);

	pFileTime = sFileAttribs.ftCreationTime;
	if (bToLocal)
		pFileTime.ToLocal();
	pArray(3) = pFileTime;

	pFileTime = sFileAttribs.ftLastAccessTime;
	if (bToLocal)
		pFileTime.ToLocal();
	pArray(4) = pFileTime;

	pFileTime = sFileAttribs.ftLastWriteTime;
	if (bToLocal)
		pFileTime.ToLocal();
	pArray(5) = pFileTime;

	pArray(6) = (int)sFileAttribs.nNumberOfLinks - 1;
	pArray(7) = sFileAttribs.dwVolumeSerialNumber;
	pArray(8) = sFileAttribs.nFileIndexLow;
	pArray(9) = sFileAttribs.nFileIndexHigh;

	Return(1);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall GetFileTimes(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (Vartype(r2) != 'R' && Vartype(r2) != '0')
		throw E_INVALIDPARAMS;

	if (PCOUNT() >= 3 && (Vartype(r3) != 'R' && Vartype(r3) != '0'))
		throw E_INVALIDPARAMS;

	if (PCOUNT() >= 4 && (Vartype(r4) != 'R' && Vartype(r4) != '0'))
		throw E_INVALIDPARAMS;

	FoxString pFileName(p1);
	FoxReference pCreationTime(r2), pAccessTime(r3), pWriteTime(r4);
	bool bToLocal = PCOUNT() < 5 || !p5.ev_length;
	FoxDateTime pFileTime;
	ApiHandle hFile;

	FILETIME sCreationTime, sAccessTime, sWriteTime;
	
	hFile = CreateFile(pFileName.Fullpath(),0,0,0,OPEN_EXISTING,FILE_FLAG_BACKUP_SEMANTICS,0);
	if (!hFile)
	{
		SAVEWIN32ERROR(CreateFile,GetLastError());
		throw E_APIERROR;
	}

	if (!GetFileTime(hFile,&sCreationTime,&sAccessTime,&sWriteTime))
	{	
		SAVEWIN32ERROR(GetFileTime,GetLastError());
		throw E_APIERROR;
	}

	if (Vartype(r2) == 'R')
	{
		pFileTime = sCreationTime;
		if (bToLocal)
			pFileTime.ToLocal();
		pCreationTime = pFileTime;
	}

	if (PCOUNT() >= 3 && Vartype(r3) == 'R')
	{
		pFileTime = sAccessTime;
		if (bToLocal)
			pFileTime.ToLocal();
		pAccessTime = pFileTime;
	}

	if (PCOUNT() >= 4 && Vartype(r4) == 'R')
	{
		pFileTime = sWriteTime;
		if (bToLocal)
			pFileTime.ToLocal();
		pWriteTime = pFileTime;
	}

	Return(1);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);	
}
}

void _fastcall SetFileTimes(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	bool  bCreation, bAccess, bWrite;

	if (Vartype(p2) == 'T')
		bCreation = p2.ev_real != 0.0;
	else if (Vartype(p2) == '0')
		bCreation = false;
	else
		throw E_INVALIDPARAMS;

	if (PCOUNT() >= 3)
	{
		if (Vartype(p3) == 'T')
			bAccess = p3.ev_real != 0.0;
		else if (Vartype(p3) == '0')
			bAccess = false;
		else
			throw E_INVALIDPARAMS;
	}
	else
		bAccess = false;

	if (PCOUNT() >= 4)
	{
		if (Vartype(p4) == 'T')
			bWrite = p4.ev_real != 0.0;
		else if (Vartype(p4) == '0')
			bWrite = false;
		else
			throw E_INVALIDPARAMS;
	}
	else
		bWrite = false;

	if (!bCreation && !bAccess && !bWrite)
		throw E_INVALIDPARAMS;

	FoxString pFileName(p1);
	bool bToUTC = PCOUNT() < 5 || p5.ev_length;
	ApiHandle hFile;
	FoxDateTime pTime;

	FILETIME sCreationTime, sAccessTime, sWriteTime;

	hFile = CreateFile(pFileName.Fullpath(),FILE_WRITE_ATTRIBUTES,0,0,
		OPEN_EXISTING,FILE_FLAG_BACKUP_SEMANTICS,0);
	if (!hFile)
	{
		SAVEWIN32ERROR(CreateFile,GetLastError());
		throw E_APIERROR;
	}

	if (bCreation)
	{
		pTime = p2;
		if (bToUTC)
			pTime.ToUTC();
		sCreationTime = pTime;
	}

	if (bAccess)
	{
		pTime = p3;
		if (bToUTC)
			pTime.ToUTC();
		sAccessTime = pTime;
	}
    if (bWrite)
	{
		pTime = p4;
		if (bToUTC)
			pTime.ToUTC();
		sWriteTime = pTime;
	}

	if (!SetFileTime(hFile,
		bCreation ? &sCreationTime : 0,
		bAccess ? &sAccessTime : 0,
		bWrite ? &sWriteTime : 0))
	{
		SAVEWIN32ERROR(SetFileTime,GetLastError());
		throw E_APIERROR;
	}

	Return(1);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall GetFileSizeLib(ParamBlk *parm)
{
try
{
	FoxString pFileName(p1);
	FoxInt64 pFileSize;
	ApiHandle hFile;
	LARGE_INTEGER sSize;

	hFile = CreateFile(pFileName.Fullpath(),0,0,0,OPEN_EXISTING,FILE_FLAG_BACKUP_SEMANTICS,0);
	if (!hFile)
	{
		SAVEWIN32ERROR(CreateFile,GetLastError());
		throw E_APIERROR;
	}

	if (fpGetFileSizeEx)
	{
		if (!fpGetFileSizeEx(hFile,&sSize))
		{
			SAVEWIN32ERROR(GetFileSizeEx,GetLastError());
			throw E_APIERROR;
		}
	}
	else
	{
		sSize.LowPart = GetFileSize(hFile,(LPDWORD)&sSize.HighPart);
		if (sSize.LowPart == INVALID_FILE_SIZE)
		{
			DWORD nLastError = GetLastError();
			if (nLastError != NO_ERROR)
			{
				SAVEWIN32ERROR(GetFileSize,nLastError);
				throw E_APIERROR;
			}
		}
	}

	pFileSize = Ints2Double(sSize.LowPart, sSize.HighPart);
	pFileSize.Return();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall GetFileAttributesLib(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	FoxString pFileName(p1);
	DWORD nAttribs;
    
	nAttribs = GetFileAttributes(pFileName.Fullpath());
	if (nAttribs == INVALID_FILE_ATTRIBUTES)
	{
		SAVEWIN32ERROR(GetFileAttributes,GetLastError());
		throw E_APIERROR;
	}
	Return(nAttribs);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall SetFileAttributesLib(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	FoxString pFileName(p1);

	if (!SetFileAttributes(pFileName.Fullpath(),p2.ev_long))
	{
		SAVEWIN32ERROR(SetFileAttributes,GetLastError());
		throw E_APIERROR;
	}

	Return(1);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall GetFileOwner(ParamBlk *parm)
{
try
{
	FoxString pFileName(p1);
	FoxString pOwner(MAX_PATH);
	FoxString pDomain(MAX_PATH);
	CBuffer pDescBuffer;
	FoxReference pRef;
	ApiHandle hFile;
	int SidType;
	
	DWORD dwSize = SECURITY_DESCRIPTOR_LEN, nLastError;
	BOOL bOwnerDefaulted;
	PSECURITY_DESCRIPTOR pSecDesc;
	PSID pOwnerId;

	hFile = CreateFile(pFileName.Fullpath(),READ_CONTROL,0,0,OPEN_EXISTING,0,0);
	if (!hFile)
	{
		SAVEWIN32ERROR(CreateFile,GetLastError());
		throw E_APIERROR;
	}

	while(1)
	{
		pDescBuffer.Size(dwSize);
		pSecDesc = (PSECURITY_DESCRIPTOR)pDescBuffer.Address();

		if (!fpGetKernelObjectSecurity(hFile,OWNER_SECURITY_INFORMATION,pSecDesc,dwSize,&dwSize))
		{
			nLastError = GetLastError();
			if (nLastError != ERROR_INSUFFICIENT_BUFFER)
			{
				SAVEWIN32ERROR(GetKernelObjectSecurity,nLastError);
				throw E_APIERROR;
			}
		}
		else
			break;
	}

	if (!fpGetSecurityDescriptorOwner(pSecDesc,&pOwnerId,&bOwnerDefaulted))
	{
		SAVEWIN32ERROR(GetSecurityDescriptorOwner,GetLastError());
		throw E_APIERROR;
	}

	DWORD dwOwnerLen = MAX_PATH, dwDomainLen = MAX_PATH;
	if (!fpLookupAccountSidA((LPCSTR)0,pOwnerId,pOwner,&dwOwnerLen,
		pDomain,&dwDomainLen,(PSID_NAME_USE)&SidType))	
	{
		SAVEWIN32ERROR(LookupAccountSid,GetLastError());
		throw E_APIERROR;
	}

	pOwner.Len(dwOwnerLen);
	pDomain.Len(dwDomainLen);

	pRef = r2;
    pRef = pOwner;

	if (PCOUNT() >= 3)
	{
		pRef = r3;
		pRef = pDomain;
	}

	if (PCOUNT() >= 4)
	{
		pRef = r4;
		pRef = SidType;
	}

	Return(1);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall GetLongPathNameLib(ParamBlk *parm)
{
try
{
	if (!fpGetLongPathName)
		throw E_NOENTRYPOINT;

	FoxString pFileName(p1);
	FoxString pLongFileName(MAX_PATH+1);
	
	pLongFileName.Len(fpGetLongPathName(pFileName.Fullpath(),pLongFileName,MAX_PATH+1));
	if (!pLongFileName.Len())
	{
		SAVEWIN32ERROR(GetLongPathName,GetLastError());
		throw E_APIERROR;
	}
	pLongFileName.Return();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall GetShortPathNameLib(ParamBlk *parm)
{
try
{
	FoxString pFileName(p1);
	FoxString pShortName(MAX_PATH+1);

	pShortName.Len(GetShortPathName(pFileName.Fullpath(),pShortName,MAX_PATH+1));
	if (!pShortName.Len())
	{
		SAVEWIN32ERROR(GetShortPathName,GetLastError());
		throw E_APIERROR;
	}

	pShortName.Return();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall CopyFileExLib(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	FoxString pSource(p1);
	FoxString pDest(p2);
	FoxString pCallback(parm,3);
	bool bRetVal;
	FILEPROGRESSPARAM sProgress = {0};

	if (pCallback.Len() > VFP2C_MAX_CALLBACKFUNCTION)
		throw E_INVALIDPARAMS;

	sProgress.bCallback = pCallback.Len() > 0;
	if (pCallback.Len())
		sprintf(sProgress.pFileProgress,"%s(%%I64d,%%I64d,%%.2f)",(char*)pCallback);

	bRetVal = CopyFileProgress(pSource,pDest,&sProgress);
	Return(bRetVal);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall MoveFileExLib(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

 	FoxString pSource(p1);
 	FoxString pDest(p2);
	FoxString pCallback(parm,3);
	bool bCrossVolume, bRetVal;
	FILEPROGRESSPARAM sProgress = {0};

	if (pCallback.Len() > VFP2C_MAX_CALLBACKFUNCTION)
		throw E_INVALIDPARAMS;

	sProgress.bCallback = pCallback.Len() > 0;
	bCrossVolume = !PathIsSameVolume(pSource,pDest);

	// builds the format command to be called back , %% is reduced to one % by sprintf
	if (sProgress.bCallback)
		sprintf(sProgress.pFileProgress,"%s(%%I64d,%%I64d,%%.2f)",(char*)pCallback);

	bRetVal = MoveFileProgress(pSource,pDest,INVALID_FILE_ATTRIBUTES,bCrossVolume,&sProgress);
	Return(bRetVal);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

bool MoveFileProgress(char *pSourceFile, char *pDestFile, DWORD nAttributes, bool bCrossVolume,
				  LPFILEPROGRESSPARAM pProgress) throw(int)
{
	if (bCrossVolume)
	{
 		if (CopyFileProgress(pSourceFile,pDestFile,pProgress))
 			DeleteFileExEx(pSourceFile,nAttributes);
		else
			return false;
	}
	else
	{
		if (!MoveFile(pSourceFile,pDestFile))
		{
			SAVEWIN32ERROR(MoveFile,GetLastError());
			throw E_APIERROR;
		}
	}
	return true;
}


bool _stdcall CopyFileProgress(char *pSource, char *pDest, LPFILEPROGRESSPARAM pProgress) throw(int)
{
	int nBuffSize;
	ApiHandle hSource, hDest;
	CBuffer pReadBuffer;
	__int64 nFileSize, nSize, nBytesCopied = 0;
	DWORD nBytesRead;
	double nPercentCopied;
	BY_HANDLE_FILE_INFORMATION sFileAttribs;

	hSource = CreateFile(pSource,GENERIC_READ,FILE_SHARE_READ,0,OPEN_EXISTING,FILE_FLAG_SEQUENTIAL_SCAN,0);
	if (!hSource)
	{
		SAVEWIN32ERROR(CreateFile,GetLastError());
		throw E_APIERROR;
	}
	
	if (!GetFileInformationByHandle(hSource,&sFileAttribs))
	{
		SAVEWIN32ERROR(GetFileInformationByHandle,GetLastError());
		throw E_APIERROR;
	}

	hDest = CreateFile(pDest,GENERIC_WRITE,0,0,CREATE_ALWAYS,sFileAttribs.dwFileAttributes,0);
	if (!hDest)
	{
		SAVEWIN32ERROR(CreateFile,GetLastError());
		throw E_APIERROR;
	}

	nFileSize = nSize = Ints2Int64(sFileAttribs.nFileSizeLow, sFileAttribs.nFileSizeHigh);

	if (nSize < 1024*1024)
		nBuffSize = MAX_USHORT;
	else if (nSize < 1024*1024*10)
		nBuffSize = MAX_USHORT * 4;
	else if (nSize < 1024*1024*100)
		nBuffSize = MAX_USHORT * 16;
	else if (nSize < 1024*1024*500)
		nBuffSize = MAX_USHORT * 32;
	else 
		nBuffSize = MAX_USHORT * 64;

	pReadBuffer.Size(nBuffSize);

    while (nSize)
	{
		if (nSize > nBuffSize)
			nBytesRead = nBuffSize;
		else
			nBytesRead = (int)nSize;

		nSize -= nBytesRead;

		if (!ReadFile(hSource,pReadBuffer,nBytesRead,&nBytesRead,0))
		{
			SAVEWIN32ERROR(ReadFile,GetLastError());
			throw E_APIERROR;
		}

		if (!WriteFile(hDest,pReadBuffer,nBytesRead,&nBytesRead,0))
		{
			SAVEWIN32ERROR(WriteFile,GetLastError());
			throw E_APIERROR;
		}

		if (pProgress->bCallback)
		{
			nBytesCopied += nBytesRead;		
			nPercentCopied = (double)nBytesCopied / (double)nFileSize * 100;
			sprintf(pProgress->pCallback,pProgress->pFileProgress,nBytesCopied,nFileSize,nPercentCopied);
			Evaluate(pProgress->vRetVal,pProgress->pCallback);
			if (!pProgress->vRetVal.ev_length)
			{
				pProgress->bAborted = true;
				break;
			}
		}
	}

	hSource.Close();
	hDest.Close();

	if (pProgress->bAborted)
		DeleteFileExEx(pDest,INVALID_FILE_ATTRIBUTES);
	return !pProgress->bAborted;
}

void _fastcall CompareFileTimes(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	FoxString pFile1(p1);
	FoxString pFile2(p2);
	int nRetVal;

	nRetVal = CompareFileTimesEx(pFile1.Fullpath(),pFile2.Fullpath());
	Return(nRetVal);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall DeleteFileEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();
	FoxString pFileName(p1);
	DeleteFileExEx(pFileName.Fullpath(),INVALID_FILE_ATTRIBUTES);
	Return(1);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall DeleteDirectory(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();
	FoxString pDirectory(p1);
	DeleteDirectoryEx(pDirectory);
	Return(1);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall SHSpecialFolder(ParamBlk *parm)
{
try
{
	if (!fpGetSpecialFolder)
		throw E_NOENTRYPOINT;

	FoxString pFolder(MAX_PATH+1);
	FoxReference pRef(r2);
	BOOL bCreateDir = PCOUNT() >= 3 ? p3.ev_length : FALSE;

	if (fpGetSpecialFolder(WTopHwnd(),pFolder,p1.ev_long,bCreateDir))
	{
		pFolder.Len(strlen(pFolder));
		pRef = pFolder;
		Return(true);
	}
	else
		Return(false);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall SHCopyFiles(ParamBlk *parm)
{
try
{
	FoxString pFrom(p1,2);
	FoxString pTo(p2,2);
	FoxString pTitle(parm,4);

	SHFILEOPSTRUCT sFileOp = {0};

	sFileOp.wFunc = FO_COPY;
	sFileOp.fFlags = (FILEOP_FLAGS)p3.ev_long;
	sFileOp.hwnd = WTopHwnd();

	sFileOp.pFrom = pFrom;
	sFileOp.pTo = pTo;

	if (pTitle.Len())
	{
		sFileOp.fFlags |= FOF_SIMPLEPROGRESS;
		sFileOp.lpszProgressTitle = pTitle;
	}

	if (SHFileOperation(&sFileOp) == 0)
		Return(1);
	else if (sFileOp.fAnyOperationsAborted)
		Return(0);
	else
		Return(-1);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall SHDeleteFiles(ParamBlk *parm)
{
try
{
	FoxString pFile(p1,2);
	FoxString pTitle(parm,3);

	SHFILEOPSTRUCT sFileOp = {0};

	sFileOp.wFunc = FO_DELETE;
	sFileOp.fFlags = (FILEOP_FLAGS)p2.ev_long;
	sFileOp.hwnd = WTopHwnd();

	sFileOp.pFrom = pFile;

	if (pTitle.Len())
	{
		sFileOp.fFlags |= FOF_SIMPLEPROGRESS;
		sFileOp.lpszProgressTitle = pTitle;
	}

	if (SHFileOperation(&sFileOp) == 0)
		Return(1);
	else if (sFileOp.fAnyOperationsAborted)
		Return(0);
	else
		Return(-1);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall SHMoveFiles(ParamBlk *parm)
{
try
{
	FoxString pFrom(p1,2);
	FoxString pTo(p2,2);
	FoxString pTitle(parm,4);

	SHFILEOPSTRUCT sFileOp = {0};
    
	sFileOp.wFunc = FO_MOVE;
	sFileOp.fFlags = (FILEOP_FLAGS)p3.ev_long;
	sFileOp.hwnd = WTopHwnd();

	sFileOp.pFrom = pFrom;
	sFileOp.pTo = pTo;

	if (pTitle.Len())
	{
		sFileOp.fFlags |= FOF_SIMPLEPROGRESS;
		sFileOp.lpszProgressTitle = pTitle;
	}

	if (SHFileOperation(&sFileOp) == 0)
		Return(1);
	else if (sFileOp.fAnyOperationsAborted)
		Return(0);
	else
		Return(-1);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall SHRenameFiles(ParamBlk *parm)
{
try
{
	FoxString pFrom(p1,2);
	FoxString pTo(p2,2);
	FoxString pTitle(parm,4);

	SHFILEOPSTRUCT sFileOp = {0};

	sFileOp.wFunc = FO_RENAME;
	sFileOp.fFlags = (FILEOP_FLAGS)p3.ev_long;
	sFileOp.hwnd = WTopHwnd();

	sFileOp.pFrom = HandleToPtr(p1);
	sFileOp.pTo = HandleToPtr(p2);

	if (pTitle.Len())
	{
		sFileOp.fFlags |= FOF_SIMPLEPROGRESS;
		sFileOp.lpszProgressTitle = pTitle;
	}

	if (SHFileOperation(&sFileOp) == 0)
		Return(1);
	else if (sFileOp.fAnyOperationsAborted)
		Return(0);
	else
		Return(-1);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall SHBrowseFolder(ParamBlk *parm)
{
try
{
	FoxString pTitle(p1);
	FoxReference pRef(r3);
	FoxWString pRootFolder(parm,4);
	FoxString pCallback(parm,5);
	FoxString pFolder(MAX_PATH);
	CoTaskPtr pIdl, pRootIdl;

	BROWSEINFO sBrow;
	BrowseCallback sCallback;
	CHAR aDisplayName[MAX_PATH];
	HRESULT hr;
	DWORD nRootAttr = 0;

	if (pCallback.Len() > VFP2C_MAX_CALLBACKFUNCTION)
		throw E_INVALIDPARAMS;

	if (PCOUNT() >= 4)
	{
		if (Vartype(p4) == 'I')
			sBrow.pidlRoot = (LPITEMIDLIST)p4.ev_long;
		else if (Vartype(p4) == 'N')
			sBrow.pidlRoot = (LPITEMIDLIST)(UINT)p4.ev_real;
		else if (Vartype(p4) == 'C')
		{
			if (pRootFolder)
			{
				if (fpSHILCreateFromPath)
				{
					hr = fpSHILCreateFromPath(pRootFolder,pRootIdl,&nRootAttr);
					if (FAILED(hr))
					{
						SAVECUSTOMERROREX("SHILCreateFromPath","Function failed. HRESULT: %I",hr);
						throw E_APIERROR;
					}
				}
				else
					pRootIdl = fpSHILCreateFromPathEx(pRootFolder);
			}
			sBrow.pidlRoot = pRootIdl;
		}
		else
			throw E_INVALIDPARAMS;
	}
	else
		sBrow.pidlRoot = 0;

	if (pCallback.Len())
	{
		sCallback.pCallback = pCallback;
		sCallback.pCallback += "(%U,%U,%U)";
	}

	sBrow.lpfn = pCallback.Len() ? SHBrowseCallback : 0;
	sBrow.lParam = pCallback.Len() ? (LPARAM)&sCallback : 0;
	sBrow.iImage = 0;
	sBrow.hwndOwner = WTopHwnd();
	sBrow.pszDisplayName = aDisplayName;
	sBrow.lpszTitle = pTitle;
	sBrow.ulFlags = (UINT)p2.ev_long;

	pIdl = SHBrowseForFolder(&sBrow);

	if (pIdl)
	{
		if (!SHGetPathFromIDList(pIdl,pFolder))
		{
			SAVECUSTOMERROR("SHGetPathFromIDList","Function failed.");
			throw E_APIERROR;
		}
		pRef = pFolder.StringLen();
		Return(true);
	}
	else
		Return(false);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

int _stdcall SHBrowseCallback(HWND hwnd, UINT uMsg, LPARAM lParam, LPARAM lpData)
{
	V_VALUE(vRetVal);
	BrowseCallback *lpBC = (BrowseCallback*)lpData;
	lpBC->pBuffer.Format(lpBC->pCallback, hwnd, uMsg, lParam);

	if (_Evaluate(&vRetVal, lpBC->pBuffer) == 0)
	{
		if (Vartype(vRetVal) == 'I')
			return vRetVal.ev_long;
		else if (Vartype(vRetVal) == 'L')
			return vRetVal.ev_length;
		else if (Vartype(vRetVal) == 'N')
			return (UINT)vRetVal.ev_real;
		else
			ReleaseValue(vRetVal);

		return 0;
	}
	else
		return 0;
}

void _fastcall GetOpenFileNameLib(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	FoxString pFilter(parm,2,2);
	FoxString pFileName(parm,3);
	FoxString pInitialDir(parm,4);
	FoxString pTitle(parm,5);
	FoxArray pArray(parm,7);
	FoxString pCallback(parm,8);
	FoxString pFiles(MAX_OPENFILENAME_BUFFER);
	FoxString pFileBuffer;

	OPENFILENAME sFile = {0};
	OpenfileCallback sCallbackParam;

	if (pFileName.Len() > MAX_OPENFILENAME_BUFFER)
		throw E_INVALIDPARAMS;

	if (pCallback.Len() > VFP2C_MAX_CALLBACKFUNCTION)
		throw E_INVALIDPARAMS;

	if (PCOUNT() >= 1 && p1.ev_long)
		sFile.Flags = p1.ev_long & ~(OFN_ENABLETEMPLATE | OFN_ENABLETEMPLATEHANDLE | OFN_ALLOWMULTISELECT);
	else
		sFile.Flags = OFN_EXPLORER | OFN_NOCHANGEDIR | OFN_NODEREFERENCELINKS | 
			OFN_FILEMUSTEXIST |	OFN_DONTADDTORECENT;

	if (PCOUNT() >= 6)
		sFile.FlagsEx = p6.ev_long;

	if (IS_WIN9X() || IS_WINNT())
		sFile.lStructSize = OPENFILENAME_SIZE_VERSION_400;
	else
		sFile.lStructSize = sizeof(OPENFILENAME);

	sFile.Flags |= OFN_ENABLEHOOK;
	sFile.lpfnHook = &GetFileNameCallback;

	sFile.hwndOwner = WTopHwnd();

	if (pFileName.Len())
		pFiles = pFileName;
	else
		pFiles[0] = '\0';

	sFile.lpstrFile = pFiles; 
	sFile.nMaxFile = pFiles.Size();

	if (pFilter.Len())
		sFile.lpstrFilter = pFilter;
	else if (!(sFile.Flags & OFN_EXPLORER))
		sFile.lpstrFilter = "All\0*.*\0";

	sFile.lpstrInitialDir = pInitialDir;
	sFile.lpstrTitle = pTitle;

	// if an arrayname is passed for multiselect
	if (pArray)
	{
		// allocate memory for the Value structure to store the filenames
		pFileBuffer.Size(MAX_PATH+1);
		// set multiselect flag
		sFile.Flags |= OFN_ALLOWMULTISELECT;
	}

	// if a callback function is passed
	if (pCallback.Len())
	{
		// setup the OPENFILECALLBACK structure
		sFile.lCustData = (LPARAM)&sCallbackParam;
		// build the callback string passed to sprintfex
		sCallbackParam.pCallback = pCallback;
		sCallbackParam.pCallback += "(%I,%U,%I)";
	}

	if (GetOpenFileName(&sFile))
	{
		if (sFile.Flags & OFN_ALLOWMULTISELECT)
		{
			int nFileCount;
			char *pFilePtr = pFiles;
			unsigned int nRow = 0;

			if (sFile.Flags & OFN_EXPLORER)
			{
				nFileCount = pFiles.StringDblCount();
				pArray.Dimension(nFileCount);

				while (nFileCount--)
				{
					nRow++;
					pArray(nRow) = pFileBuffer = pFilePtr;
					// advance pointer by length of string + 1 for nullterminator
					pFilePtr += pFileBuffer.Len() + 1;
				}
			}
			else
			{
				// when OFN_EXPLORER flag is not set, files are seperated by a space character
				nFileCount = pFiles.GetWordCount(' ');
				pArray.Dimension(nFileCount);
				
				while (nFileCount--)
				{
					nRow++;
					pFileBuffer.Len(GetWordNumN(pFileBuffer,pFilePtr,' ',1,MAX_PATH+1));
					pArray(nRow) = pFileBuffer;
					// advance pointer by length of string + 1 for space
					pFilePtr += pFileBuffer.Len() + 1;
				}
			}
			pArray.ReturnRows();
		}
		else
			pFiles.StringLen().Return();
	}
	else
	{
		DWORD nLastError = CommDlgExtendedError();
		if (nLastError)
		{
			SAVECUSTOMERROREX("GetOpenFileName","Function failed: %I",nLastError);
			Return(-1);
		}
		else
			Return(0);
	}
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall GetSaveFileNameLib(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();
	
	FoxString pFilter(parm,2,2);
	FoxString pFileName(parm,3);
	FoxString pInitialDir(parm,4);
	FoxString pTitle(parm,5);
	FoxString pCallback(parm,7);
	FoxString pFiles(MAX_OPENFILENAME_BUFFER);

	OPENFILENAME sFile = {0};
	OpenfileCallback sCallbackParam;

	if (pFileName.Len() > MAX_OPENFILENAME_BUFFER)
		throw E_INVALIDPARAMS;

	if (pCallback.Len() > VFP2C_MAX_CALLBACKFUNCTION)
		throw E_INVALIDPARAMS;

	if (PCOUNT() >= 1 && p1.ev_long)
		sFile.Flags = p1.ev_long & ~(OFN_ENABLETEMPLATE | OFN_ENABLETEMPLATEHANDLE);
	else
		sFile.Flags = OFN_EXPLORER | OFN_NOCHANGEDIR;

	if (PCOUNT() >= 6)
		sFile.FlagsEx = p6.ev_long;

	if (IS_WIN9X() || IS_WINNT())
		sFile.lStructSize = OPENFILENAME_SIZE_VERSION_400;
	else
		sFile.lStructSize = sizeof(OPENFILENAME);

	// set callback procedure 
	sFile.Flags |= OFN_ENABLEHOOK;
	sFile.lpfnHook = &GetFileNameCallback;

	sFile.hwndOwner = WTopHwnd();

	pFiles[0] = '\0';
	sFile.lpstrFile = pFiles;
	sFile.nMaxFile = MAX_OPENFILENAME_BUFFER;

	if (pFilter.Len())
		sFile.lpstrFilter = pFilter;
	else if (!(sFile.Flags & OFN_EXPLORER))
		sFile.lpstrFilter = "All\0*.*\0";

	if (pFileName.Len())
		strcpy(sFile.lpstrFile,pFileName);

	sFile.lpstrInitialDir = pInitialDir;
	sFile.lpstrTitle = pTitle;

	if (pCallback.Len())
	{
		sFile.lCustData = (LPARAM)&sCallbackParam;
		sCallbackParam.pCallback = pCallback;
		sCallbackParam.pCallback += "(%I,%U,%I)";
	}

	if (GetSaveFileName(&sFile))
		pFiles.StringLen().Return();
	else
	{
		DWORD nLastError = CommDlgExtendedError();
		if (nLastError)
		{
			SAVECUSTOMERROREX("GetSaveFileName","Function failed: %I",nLastError);
			Return(-1);
		}
		else
			Return(0);
	}
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

UINT_PTR _stdcall GetFileNameCallback(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	LPOPENFILENAME lpOpfn;
	OpenfileCallback *lpCallback;
	NMHDR *lpHdr;

	if (uMsg == WM_INITDIALOG)
	{
		lpOpfn = (LPOPENFILENAME)lParam;
		if (lpOpfn->lCustData)
			SetWindowLong(hDlg,GWL_USERDATA,(LONG)lpOpfn->lCustData);
	}
	else if (uMsg == WM_NOTIFY)
	{
		lpCallback = (OpenfileCallback*)GetWindowLong(hDlg,GWL_USERDATA);
		if (lpCallback)
		{
			lpHdr = (NMHDR*)lParam;
			lpCallback->pBuffer.Format(lpCallback->pCallback, lpHdr->hwndFrom, lpHdr->idFrom, lpHdr->code);
			lpCallback->nErrorNo = _Evaluate(&lpCallback->vRetVal, lpCallback->pBuffer);
			if (!lpCallback->nErrorNo)
			{
				if (Vartype(lpCallback->vRetVal) == 'I')
					return lpCallback->vRetVal.ev_long;
				else if (Vartype(lpCallback->vRetVal) == 'N')
					return (UINT)lpCallback->vRetVal.ev_real;
				else if (Vartype(lpCallback->vRetVal) == 'L')
					return lpCallback->vRetVal.ev_length;
				else
				{
					ReleaseValue(lpCallback->vRetVal);
					lpCallback->vRetVal.ev_type = '0';
				}
			}
		}
	}
	return FALSE;
}

void _fastcall ADriveInfo(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	FoxArray pArray(p1);
	FoxString pDrive(4);
	ApiHandle hDriveHandle;
	
	STORAGE_DEVICE_NUMBER sDevNo;
	BOOL bApiRet;
	DWORD nDriveMask, nDriveCnt = 0, nMask = 1, dwBytes;	

	char pDriveEx[] = "\\\\.\\X:";
	pDrive = "X:\\";

	nDriveMask = GetLogicalDrives();
	for (unsigned int xj = 0; xj <= 31; xj++)
	{
		if (nDriveMask & nMask)
			nDriveCnt++;
		nMask <<= 1;
	}

	pArray.Dimension(nDriveCnt,4);

	nMask = 1;
	unsigned int nRow = 0;
	for (unsigned int xj = 0; xj <= 31; xj++)
	{
		if (nDriveMask & nMask)
		{
			nRow++;

			pDrive[0] = (char)('A' + xj);
			pArray(nRow,1) = pDrive;
			pArray(nRow,2) = (int)GetDriveType(pDrive);

			if (fpDeviceIoControl)
			{
				// replace X in "\\.\X:" with the drive letter
				pDriveEx[4] = pDrive[0];
				hDriveHandle = CreateFile(pDriveEx,0,0,0,OPEN_EXISTING,0,0);
				if (!hDriveHandle)
				{
					SAVEWIN32ERROR(CreateFile,GetLastError());
					throw E_APIERROR;
				}

				bApiRet = fpDeviceIoControl(hDriveHandle,IOCTL_STORAGE_GET_DEVICE_NUMBER,0,0,
					&sDevNo,sizeof(sDevNo),&dwBytes,0);
				if (bApiRet)
				{
					pArray(nRow,3) = sDevNo.DeviceNumber;
					pArray(nRow,4) = sDevNo.PartitionNumber;
				}
				else
				{
					pArray(nRow,3) = -1;
					pArray(nRow,4) = -1;
				}
			}
			else
			{
				pArray(nRow,3) = -1;
				pArray(nRow,4) = -1;
			}
		}
		nMask <<= 1;
	}

	pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

/*
void _fastcall AVolumeInformation(ParamBlk *parm)
{
	HANDLE hVolume = INVALID_HANDLE_VALUE, hMountPoint = INVALID_HANDLE_VALUE;
	V_STRING(vVolumeName);
	V_STRING(vMountPointName);
	char *pArrayName, *pVolumeName, *pMountPointName;
	Locator lArrayLoc;
	int nErrorNo; BOOL bApiRet; DWORD nLastError;
	UINT nErrorMode = 0xFFFFFFFF;

	if (!fpFindFirstVolume)
		RaiseError(E_NOENTRYPOINT);

	if (!NullTerminateHandle(p1))
		RaiseError(E_INSUFMEMORY);

	LockHandle(p1);
	pArrayName = HandleToPtr(p1);

	if (nErrorNo = DimensionEx(pArrayName,&lArrayLoc,1,5))
		goto ErrorOut;

	if (!AllocHandleEx(vVolumeName,VFP2C_MAX_VOLUME_NAME))
	{
		nErrorNo = E_INSUFMEMORY;
		goto ErrorOut;		
	}
	LockHandle(vVolumeName);
	pVolumeName = HandleToPtr(vVolumeName);

	if (!AllocHandleEx(vMountPointName,VFP2C_MAX_MOUNTPOINT_NAME))
	{
		nErrorNo = E_INSUFMEMORY;
		goto ErrorOut;
	}
	LockHandle(vMountPointName);
	pMountPointName = HandleToPtr(vMountPointName);

	// surpress system error dialog when no disc is inserted in a floppy/CD-ROM drive
    nErrorMode = SetErrorMode(0); // save last errormode
	SetErrorMode(nErrorMode | SEM_FAILCRITICALERRORS); // set SEM_FAIL..

    hVolume = fpFindFirstVolume(pVolumeName,VFP2C_MAX_VOLUME_NAME);
	if (hVolume == INVALID_HANDLE_VALUE)
	{
		nLastError = GetLastError();
		if (nLastError == ERROR_NO_MORE_FILES)
			goto Success;
		else
		{
			SAVEWIN32ERROR(FindFirstVolume,nLastError);
			goto ErrorOut;
		}
	}

	while (1)
	{
		hMountPoint = fpFindFirstVolumeMountPoint(pVolumeName,pMountPointName,VFP2C_MAX_MOUNTPOINT_NAME);

		if (hMountPoint == INVALID_HANDLE_VALUE)
		{
			nLastError = GetLastError();
			if (nLastError != ERROR_NO_MORE_FILES && nLastError != ERROR_NOT_READY)
			{
				SAVEWIN32ERROR(FindFirstVolumeMountPoint,nLastError);
				goto ErrorOut;
			}
		}
		else
		{
			while (1)
			{
				if (nErrorNo = Dimension(pArrayName,++AROW(lArrayLoc),5))
					goto ErrorOut;

				ADIM(lArrayLoc) = 1;
				vVolumeName.ev_length = strlen(pVolumeName);
				if (nErrorNo = STORE(lArrayLoc,vVolumeName))
					goto ErrorOut;
				
				ADIM(lArrayLoc) = 2;
				vMountPointName.ev_length = strlen(pMountPointName);
				if (nErrorNo = STORE(lArrayLoc,vMountPointName))
					goto ErrorOut;

				bApiRet = fpFindNextVolumeMountPoint(hMountPoint,pMountPointName,VFP2C_MAX_MOUNTPOINT_NAME);
				if (!bApiRet)
				{
					nLastError = GetLastError();
					if (nLastError == ERROR_NO_MORE_FILES)
						break;
					else
					{
						SAVEWIN32ERROR(FindNextVolumeMountPoint,nLastError);
						goto ErrorOut;
					}
				}
			}

			bApiRet = fpFindVolumeMountPointClose(hMountPoint);
			if (!bApiRet)
			{
				SAVEWIN32ERROR(FindVolumeMountPointClose,GetLastError());
				goto ErrorOut;
			}
			hMountPoint = INVALID_HANDLE_VALUE;
		}

		bApiRet = fpFindNextVolume(hVolume,pVolumeName,VFP2C_MAX_VOLUME_NAME);
		if (!bApiRet)
		{
			nLastError = GetLastError();
			if (nLastError == ERROR_NO_MORE_FILES)
				break;
			else
			{
				SAVEWIN32ERROR(FindNextVolume,nLastError);
				goto ErrorOut;
			}
		}
	}

	bApiRet = fpFindVolumeClose(hVolume);
	if (!bApiRet)
	{
		SAVEWIN32ERROR(FindVolumeClose,nLastError);
		goto ErrorOut;
	}
	hVolume = INVALID_HANDLE_VALUE;

	// reset error mode
	SetErrorMode(nErrorMode);

	Success:
		FreeHandleEx(vVolumeName);
		FreeHandleEx(vMountPointName);
		UnlockHandle(p1);
		RET_AROWS(lArrayLoc);
		return;

	ErrorOut:
		if (nErrorMode != 0xFFFFFFFF)
			SetErrorMode(nErrorMode);
		if (hMountPoint != INVALID_HANDLE_VALUE)
			fpFindVolumeMountPointClose(hMountPoint);
		if (hVolume != INVALID_HANDLE_VALUE)
			fpFindVolumeClose(hVolume);
		FreeHandleEx(vVolumeName);
		FreeHandleEx(vMountPointName);
		RaiseError(nErrorNo);
}
*/
void _fastcall GetWindowsDirectoryLib(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	FoxString pDir(MAX_PATH+1);

	pDir.Len(GetWindowsDirectory(pDir,MAX_PATH+1));
	if (!pDir.Len())
	{
		SAVEWIN32ERROR(GetWindowsDirectory,GetLastError());
		throw E_APIERROR;
	}

	pDir.Return();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall GetSystemDirectoryLib(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	FoxString pDir(MAX_PATH+1);

	pDir.Len(GetSystemDirectory(pDir,MAX_PATH+1));
    if (!pDir.Len())
	{
		SAVEWIN32ERROR(GetSystemDirectory,GetLastError());
		throw E_APIERROR;
	}

	pDir.Return();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall ExpandEnvironmentStringsLib(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	FoxString pEnvString(p1);
	FoxString pEnvBuffer(MAX_ENVSTRING_BUFFER);

	pEnvBuffer.Len(ExpandEnvironmentStrings(pEnvString,pEnvBuffer,pEnvBuffer.Size()));
	if (!pEnvBuffer.Len())
	{
		SAVEWIN32ERROR(ExpandEnvironmentStrings,GetLastError());
		throw E_APIERROR;
	}
	else if (pEnvBuffer.Len() > MAX_ENVSTRING_BUFFER)
	{
		pEnvBuffer.Size(pEnvBuffer.Len());
		pEnvBuffer.Len(ExpandEnvironmentStrings(pEnvString,pEnvBuffer,pEnvBuffer.Size()));
		if (!pEnvBuffer.Len())
		{
			SAVEWIN32ERROR(ExpandEnvironmentStrings,GetLastError());
			throw E_APIERROR;
		}
	}
	pEnvBuffer.Len(pEnvBuffer.Len()-1); // subtract nullterminator
	pEnvBuffer.Return();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _stdcall CreateDirectoryExEx(const char *pDirectory) throw(int)
{
	if (!FileExists(pDirectory))
	{
		if (!CreateDirectory(pDirectory,0))
		{
			SAVEWIN32ERROR(CreateDirectory,GetLastError());
			throw E_APIERROR;
		}
	}
}

void _stdcall RemoveDirectoryEx(const char *pPath) throw(int)
{
	BOOL bRetVal;
	bRetVal = RemoveDirectory(pPath);
	if (!bRetVal)
	{
		SAVEWIN32ERROR(RemoveDirectory,GetLastError());
		throw E_APIERROR;
	}
}

void _stdcall DeleteDirectoryEx(const char *pDirectory) throw(int)
{
	FileSearch pFileSearch;
	CStr pSearch(MAX_PATH);
	CStr pFile(MAX_PATH);
	CStr pPath(MAX_PATH);

	pSearch = pPath = pDirectory;
	pPath.AddBs();
	pSearch.AddBsWc();
	
	if (!pFileSearch.FindFirst(pSearch))
		return;

	do
	{
		if (pFileSearch.File.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
		{
			if (pFileSearch.IsFakeDir())
				continue;

			pFile = pPath;
			pFile += pFileSearch.Filename();
			DeleteDirectoryEx(pFile);
		}
		else
		{
			pFile = pPath;
			pFile += pFileSearch.Filename();
			DeleteFileExEx(pFile,pFileSearch.File.dwFileAttributes);
		}
	} while (pFileSearch.FindNext());

	RemoveDirectoryEx(pDirectory);
}

void _stdcall DeleteFileExEx(const char *pFileName, DWORD nFileAttribs) throw(int)
{
	RemoveReadOnlyAttrib(pFileName,nFileAttribs);
	if (!DeleteFile(pFileName))
	{
		SAVEWIN32ERROR(DeleteFile,GetLastError());
		throw E_APIERROR;
	}
}

void _stdcall RemoveReadOnlyAttrib(const char *pFileName, DWORD nFileAttribs) throw(int)
{
	if (nFileAttribs == INVALID_FILE_ATTRIBUTES)
	{
		nFileAttribs = GetFileAttributes(pFileName);
		if (nFileAttribs == INVALID_FILE_ATTRIBUTES)
		{
			SAVEWIN32ERROR(GetFileAttributes,GetLastError());
			throw E_APIERROR;
		}
	}
	if (nFileAttribs & FILE_ATTRIBUTE_READONLY)
	{
		if (!SetFileAttributes(pFileName,nFileAttribs & ~FILE_ATTRIBUTE_READONLY))
		{
			SAVEWIN32ERROR(SetFileAttributes,GetLastError());
			throw E_APIERROR;
		}
	}
}

bool _stdcall PathIsSameVolume(const char *pPath1, const char *pPath2) throw(int)
{
	char aMountPoint1[MAX_PATH];
	char aMountPoint2[MAX_PATH];
    /* Win2k und neuere OS's unterstützen MountPoints
    d.h. Man(n) kann beliebige Laufwerke auf beliebige Pfade mounten
    z.b. Laufwerk D: auf C:\DriveD\
    GetVolumePathName gibt den Mountpoint eines Pfades zurück */
	if (IS_WIN9X() || IS_WINNT())
		return PathIsSameRoot(pPath1,pPath2) == TRUE;
	else
	{
		if (!fpGetVolumePathName)
			throw E_NOENTRYPOINT;

		if (!fpGetVolumePathName(pPath1,aMountPoint1,MAX_PATH))
		{
			SAVEWIN32ERROR(GetVolumePathName,GetLastError());
			throw E_APIERROR;
		}
		if (!fpGetVolumePathName(pPath2,aMountPoint2,MAX_PATH))
		{
			SAVEWIN32ERROR(GetVolumePathName,GetLastError());
			throw E_APIERROR;
		}
		return strcmp(aMountPoint1,aMountPoint2) == 0;
	}
}

bool _stdcall FileExists(const char *pFileName) throw(int)
{
	HANDLE hFile;
	DWORD nLastError;

	hFile = CreateFile(pFileName,0,0,0,OPEN_EXISTING,FILE_FLAG_BACKUP_SEMANTICS,0);
	if (hFile != INVALID_HANDLE_VALUE)
		CloseHandle(hFile);
	else
	{
		nLastError = GetLastError();
		if (nLastError == ERROR_FILE_NOT_FOUND || nLastError == ERROR_PATH_NOT_FOUND)
			return false;
	}
	return true;
}

int _stdcall CompareFileTimesEx(const char *pSourceFile, const char *pDestFile) throw(int)
{
	ApiHandle hSource, hDest;
	LARGE_INTEGER sSourceTime, sDestTime;

	hSource = CreateFile(pSourceFile,0,0,0,OPEN_EXISTING,FILE_FLAG_BACKUP_SEMANTICS,0);
	if (!hSource)
	{
		SAVEWIN32ERROR(CreateFile,GetLastError());
		throw E_APIERROR;
	}

	hDest = CreateFile(pDestFile,0,0,0,OPEN_EXISTING,FILE_FLAG_BACKUP_SEMANTICS,0);
	if (!hDest)
	{
		SAVEWIN32ERROR(CreateFile,GetLastError());
		throw E_APIERROR;
	}
	
	if (!GetFileTime(hSource,0,0,(LPFILETIME)&sSourceTime))
	{
		SAVEWIN32ERROR(GetFileTime,GetLastError());
		throw E_APIERROR;
	}

	if (!GetFileTime(hDest,0,0,(LPFILETIME)&sDestTime))
	{
		SAVEWIN32ERROR(GetFileTime,GetLastError());
		throw E_APIERROR;
	}

	if (sSourceTime.QuadPart == sDestTime.QuadPart)
		return 0;
	else if (sSourceTime.QuadPart > sDestTime.QuadPart)
		return 1;
	else
		return 2;
}

void _fastcall FCreateEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();
	FoxString pFileName(p1);

	ApiHandle hFile;
	int nSlot;
	DWORD dwAccess, dwShare, dwFlags;

	// get a free entry in our file handle array
	nSlot = FindFreeFileSlot();

	MapFileAccessFlags(PCOUNT() >= 2 ? p2.ev_long : 0,
									PCOUNT() >= 3 ? p3.ev_long : 2,
									PCOUNT() >= 4 ? p4.ev_long : 0,
									&dwAccess,&dwShare,&dwFlags);

	hFile = CreateFile(pFileName,dwAccess,dwShare,0,CREATE_ALWAYS,dwFlags,0);
	if (!hFile)
	{
		SAVEWIN32ERROR(CreateFile,GetLastError());
		throw E_APIERROR;
	}

	gaFileHandles[nSlot] = hFile.Detach();
	Return(nSlot);
}
catch(int nErrorNo)
{
	if (nErrorNo == E_APIERROR)
		Return(-1);
	else
		RaiseError(nErrorNo);
}
}

void _fastcall FOpenEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	FoxString pFileName(p1);
	int nSlot;
	ApiHandle hFile;
	DWORD dwAccess, dwShare, dwFlags;

	// get a free entry in our file handle array
	nSlot = FindFreeFileSlot();
	pFileName.Fullpath();

	MapFileAccessFlags(PCOUNT() >= 2 ? p2.ev_long : 0,
					PCOUNT() >= 3 ? p3.ev_long : 2,
					PCOUNT() >= 4 ? p4.ev_long : 0,
					&dwAccess,&dwShare,&dwFlags);

	hFile = CreateFile(pFileName,dwAccess,dwShare,0,OPEN_EXISTING,dwFlags,0);
	if (!hFile)
	{
		SAVEWIN32ERROR(CreateFile,GetLastError());
		throw E_APIERROR;
	}

	gaFileHandles[nSlot] = hFile.Detach();
	Return(nSlot);
}
catch(int nErrorNo)
{
	if (nErrorNo == E_APIERROR)
		Return(-1);
	else
		RaiseError(nErrorNo);
}
}

void _fastcall FCloseEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!VFP2C_VALID_FILE_HANDLE(p1.ev_long) && p1.ev_long != -1)
		throw E_INVALIDPARAMS;

	BOOL bApiRet;

	if (p1.ev_long >= 0)
	{
		bApiRet = CloseHandle(gaFileHandles[p1.ev_long]);
		if (!bApiRet)
			SAVEWIN32ERROR(CloseHandle,GetLastError());
		else
			gaFileHandles[p1.ev_long] = 0;
	}
	else
	{
		bApiRet = TRUE;
		for (int xj = 0; xj < VFP2C_MAX_FILE_HANDLES; xj++)
		{
			if (gaFileHandles[xj])
			{
				if (!CloseHandle(gaFileHandles[xj]))
				{
					ADDWIN32ERROR(CloseHandle,GetLastError());
					bApiRet = FALSE;
				}
				else
					gaFileHandles[xj] = 0;
			}
		}
	}

	Return(bApiRet == TRUE);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall FReadEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!VFP2C_VALID_FILE_HANDLE(p1.ev_long) || p2.ev_long < 0)
		throw E_INVALIDPARAMS;

	BOOL bApiRet = TRUE;
	DWORD dwRead;
	FoxString pData(p2.ev_long);

	bApiRet = ReadFile(gaFileHandles[p1.ev_long],pData,pData.Size(),&dwRead,0);
	if (!bApiRet)
		SAVEWIN32ERROR(ReadFile,GetLastError());

	pData.Len(bApiRet ? dwRead : 0); 
	pData.Return();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall FWriteEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!VFP2C_VALID_FILE_HANDLE(p1.ev_long))
		throw E_INVALIDPARAMS;

	if (PCOUNT() == 3 && p3.ev_long < 0)
		throw E_INVALIDPARAMS;

	BOOL bApiRet;
	DWORD dwWritten, dwLength;
	FoxString pData(p2,0);

	if (PCOUNT() == 3 && p2.ev_length >= (DWORD)p3.ev_long)
		dwLength = (DWORD)p3.ev_long;
	else
		dwLength = p2.ev_length;

	bApiRet = WriteFile(gaFileHandles[p1.ev_long],pData,dwLength,&dwWritten,0);
	if (!bApiRet)
		SAVEWIN32ERROR(WriteFile,GetLastError());

	if (bApiRet)
		Return(dwWritten);
	else
		Return(0);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall FGetsEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!VFP2C_VALID_FILE_HANDLE(p1.ev_long))
		throw E_INVALIDPARAMS;

	BOOL bApiRet;
	unsigned char *pData, *pOrigData;
	int dwLen = PCOUNT() == 2 ? p2.ev_long : 256;
	int bCarri = 0;
	LONG dwRead, dwBuffer;
	FoxString pBuffer(dwLen);

	pOrigData = pData = pBuffer;

	dwBuffer = min(dwLen,VFP2C_FILE_LINE_BUFFER);
	while (1)
	{
		bApiRet = ReadFile(gaFileHandles[p1.ev_long],pData,dwBuffer,(LPDWORD)&dwRead,0);
		if (!bApiRet)
		{
			SAVEWIN32ERROR(ReadFile,GetLastError());
			throw E_APIERROR;
		}

		if (dwRead == 0)
			break;

		while (dwRead--)
		{
			if (*pData == '\r') // carriage return detected
			{
				pData++;
				if (*pData == '\n') // skip over linefeeds
				{
					bCarri = 2;
					pData++;
					dwRead--;
				}
				else
					bCarri = 1; // set detect flag
				SetFilePointer(gaFileHandles[p1.ev_long],-dwRead,0,FILE_CURRENT); // position filepointer after carri/linefeed(s)
				break;
			}
			else if (*pData == '\n')
			{
				pData++;
				if (*pData == '\r')
				{
					bCarri = 2;
					pData++;
					dwRead--;
				}
				else
					bCarri = 1;
				SetFilePointer(gaFileHandles[p1.ev_long],-dwRead,0,FILE_CURRENT); // position filepointer after carri/linefeed(s)
				break;
			}
			else
				pData++;
		}

		if (bCarri || (pData - pOrigData >= dwLen))
			break;
	}

	pBuffer.Len(pData - pOrigData - bCarri);
	pBuffer.Return();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall FPutsEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!VFP2C_VALID_FILE_HANDLE(p1.ev_long))
		throw E_INVALIDPARAMS;

	if (PCOUNT() == 3 && p3.ev_long < 0)
		throw E_INVALIDPARAMS;

	BOOL bApiRet;
	DWORD dwWritten, dwLength;
	FoxString pData(p2,2);

	if (PCOUNT() == 3 && pData.Len() >= (DWORD)p3.ev_long)
		dwLength = (DWORD)p3.ev_long;
	else
		dwLength = pData.Len();

	// add carriage return & line feed to data
	pData[dwLength] = '\r';
	pData[dwLength+1] = '\n';

	bApiRet = WriteFile(gaFileHandles[p1.ev_long],pData,dwLength + 2,&dwWritten,0);
	if (!bApiRet)
		SAVEWIN32ERROR(WriteFile,GetLastError());

	if (bApiRet)
		Return(dwWritten);
	else
		Return(0);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall FSeekEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!VFP2C_VALID_FILE_HANDLE(p1.ev_long))
		throw E_INVALIDPARAMS;

	LARGE_INTEGER nFilePos;
	FoxInt64 pNewFilePos;
	DWORD dwMove = PCOUNT() == 3 ? p3.ev_long : FILE_BEGIN;

	nFilePos.QuadPart = (__int64)p2.ev_real;
	nFilePos.LowPart = SetFilePointer(gaFileHandles[p1.ev_long],nFilePos.LowPart,&nFilePos.HighPart,dwMove);
	if (nFilePos.LowPart == INVALID_SET_FILE_POINTER && GetLastError() != NO_ERROR)
	{
		SAVEWIN32ERROR(SetFilePointer,GetLastError());
		throw E_APIERROR;
	}

	pNewFilePos = nFilePos.QuadPart;
	pNewFilePos.Return();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall FEoFEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!VFP2C_VALID_FILE_HANDLE(p1.ev_long))
		throw E_INVALIDPARAMS;

	LARGE_INTEGER nCurr, nEof;
	DWORD nReset;
	HANDLE hFile;

	hFile = gaFileHandles[p1.ev_long];

	nCurr.HighPart = 0;
	nCurr.LowPart = SetFilePointer(hFile,0,&nCurr.HighPart,FILE_CURRENT);
	if (nCurr.LowPart == INVALID_SET_FILE_POINTER && GetLastError() != NO_ERROR)
	{
		SAVEWIN32ERROR(SetFilePointer,GetLastError());
		throw E_APIERROR;
	}

	nEof.HighPart = 0;
	nEof.LowPart = SetFilePointer(hFile,0,&nEof.HighPart,FILE_END);
	if (nEof.LowPart == INVALID_SET_FILE_POINTER && GetLastError() != NO_ERROR)
	{
		SAVEWIN32ERROR(SetFilePointer,GetLastError());
		throw E_APIERROR;
	}

	nReset = SetFilePointer(hFile,nCurr.LowPart,&nCurr.HighPart,FILE_BEGIN);
	if (nReset == INVALID_SET_FILE_POINTER && GetLastError() != NO_ERROR)
	{
		SAVEWIN32ERROR(SetFilePointer,GetLastError());
		throw E_APIERROR;
	}

	Return(nCurr.QuadPart == nEof.QuadPart);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall FChSizeEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!VFP2C_VALID_FILE_HANDLE(p1.ev_long))
		throw E_INVALIDPARAMS;

	BOOL bApiRet;
	HANDLE hFile;
	LARGE_INTEGER nSize;
	LARGE_INTEGER nCurrPos;
	FoxInt64 pFilePos;

	hFile = gaFileHandles[p1.ev_long];
	nSize.QuadPart = (__int64)p2.ev_real;
    
	// save current file pointer
	nCurrPos.HighPart = 0;
	nCurrPos.LowPart = SetFilePointer(hFile,0,&nCurrPos.HighPart,FILE_CURRENT);
	if (nCurrPos.LowPart == INVALID_SET_FILE_POINTER && GetLastError() != NO_ERROR)
	{
		SAVEWIN32ERROR(SetFilePointer,GetLastError());
		throw E_APIERROR;
	}

	// set file pointer to specified size
	nSize.LowPart = SetFilePointer(hFile,nSize.LowPart,&nSize.HighPart,FILE_BEGIN);
	if (nSize.LowPart == INVALID_SET_FILE_POINTER && GetLastError() != NO_ERROR)
	{
		SAVEWIN32ERROR(SetFilePointer,GetLastError());
		throw E_APIERROR;
	}

	// set file size
	bApiRet = SetEndOfFile(hFile);
	if (!bApiRet)
	{
		SAVEWIN32ERROR(SetEndOfFile,GetLastError());
		throw E_APIERROR;
	}

	// reset file pointer to saved position
	nCurrPos.LowPart = SetFilePointer(hFile,0,&nCurrPos.HighPart,FILE_BEGIN);
	if (nCurrPos.LowPart == INVALID_SET_FILE_POINTER && GetLastError() != NO_ERROR)
	{
		SAVEWIN32ERROR(SetFilePointer,GetLastError());
		throw E_APIERROR;
	}

	pFilePos = nSize.QuadPart;
	pFilePos.Return();
}
catch(int nErrorNo)
{
	if (nErrorNo == E_APIERROR)
		Return(0);
	else
		RaiseError(nErrorNo);
}
}

void _fastcall FFlushEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	BOOL bApiRet;

	if (!VFP2C_VALID_FILE_HANDLE(p1.ev_long))
		throw E_INVALIDPARAMS;

	bApiRet = FlushFileBuffers(gaFileHandles[p1.ev_long]);

	if (!bApiRet)
		SAVEWIN32ERROR(FlushFileBuffers,GetLastError());

	Return(bApiRet == TRUE);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall FLockFile(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	BOOL bApiRet;
	LARGE_INTEGER nOffset, nLen;

	if (!VFP2C_VALID_FILE_HANDLE(p1.ev_long))
		throw E_INVALIDPARAMS;

	if (Vartype(p2) == 'I')
		nOffset.QuadPart = (__int64)p2.ev_long;
	else if (Vartype(p2) == 'N')
		nOffset.QuadPart = (__int64)p2.ev_real;
	else
		throw E_INVALIDPARAMS;

	if (Vartype(p3) == 'I')
		nLen.QuadPart = (__int64)p3.ev_long;
	else if (Vartype(p3) == 'N')
		nLen.QuadPart = (__int64)p3.ev_real;
	else
		throw E_INVALIDPARAMS;

	bApiRet = LockFile(gaFileHandles[p1.ev_long],nOffset.LowPart,nOffset.HighPart,nLen.LowPart,nLen.HighPart);

	if (!bApiRet)
		SAVEWIN32ERROR(LockFile,GetLastError());

	Return(bApiRet == TRUE);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall FUnlockFile(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	BOOL bApiRet;
	LARGE_INTEGER nOffset, nLen;

	if (!VFP2C_VALID_FILE_HANDLE(p1.ev_long))
		throw E_INVALIDPARAMS;

	if (Vartype(p2) == 'I')
		nOffset.QuadPart = (__int64)p2.ev_long;
	else if (Vartype(p2) == 'N')
		nOffset.QuadPart = (__int64)p2.ev_real;
	else
		throw E_INVALIDPARAMS;

	if (Vartype(p3) == 'I')
		nLen.QuadPart = (__int64)p3.ev_long;
	else if (Vartype(p3) == 'N')
		nLen.QuadPart = (__int64)p3.ev_real;
	else
		throw E_INVALIDPARAMS;

	bApiRet = UnlockFile(gaFileHandles[p1.ev_long],nOffset.LowPart,nOffset.HighPart,nLen.LowPart,nLen.HighPart);

	if (!bApiRet)
		SAVEWIN32ERROR(UnlockFile,GetLastError());

	Return(bApiRet == TRUE);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall FLockFileEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpLockFileEx)
		throw E_NOENTRYPOINT;

	if (!VFP2C_VALID_FILE_HANDLE(p1.ev_long))
		throw E_INVALIDPARAMS;

	BOOL bApiRet;
	DWORD dwFlags = PCOUNT() == 4 ? p4.ev_long : 0;
	LARGE_INTEGER nOffset, nLen;
	OVERLAPPED sOverlap;

	if (Vartype(p2) == 'I')
		nOffset.QuadPart = (__int64)p2.ev_long;
	else if (Vartype(p2) == 'N')
		nOffset.QuadPart = (__int64)p2.ev_real;
	else
		throw E_INVALIDPARAMS;

	if (Vartype(p3) == 'I')
		nLen.QuadPart = (__int64)p3.ev_long;
	else if (Vartype(p3) == 'N')
		nLen.QuadPart = (__int64)p3.ev_real;
	else
		throw E_INVALIDPARAMS;

	sOverlap.hEvent = 0;
	sOverlap.Offset = nOffset.LowPart;
	sOverlap.OffsetHigh = nOffset.HighPart;

	bApiRet = LockFileEx(gaFileHandles[p1.ev_long],dwFlags,0,nLen.LowPart,nLen.HighPart,&sOverlap);

	if (!bApiRet)
		SAVEWIN32ERROR(LockFileEx,GetLastError());

	Return(bApiRet == TRUE);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall FUnlockFileEx(ParamBlk *parm)
{
try
{
	RESETWIN32ERRORS();

	if (!fpUnlockFileEx)
		throw E_NOENTRYPOINT;

	if (!VFP2C_VALID_FILE_HANDLE(p1.ev_long))
		throw E_INVALIDPARAMS;

	BOOL bApiRet;
	LARGE_INTEGER nOffset, nLen;
	OVERLAPPED sOverlap;

	if (Vartype(p2) == 'I')
		nOffset.QuadPart = (__int64)p2.ev_long;
	else if (Vartype(p2) == 'N')
		nOffset.QuadPart = (__int64)p2.ev_real;
	else
		throw E_INVALIDPARAMS;

	if (Vartype(p3) == 'I')
		nLen.QuadPart = (__int64)p3.ev_long;
	else if (Vartype(p3) == 'N')
		nLen.QuadPart = (__int64)p3.ev_real;
	else
		throw E_INVALIDPARAMS;

	sOverlap.hEvent = 0;
	sOverlap.Offset = nOffset.LowPart;
	sOverlap.OffsetHigh = nOffset.HighPart;

	bApiRet = fpUnlockFileEx(gaFileHandles[p1.ev_long],0,nLen.LowPart,nLen.HighPart,&sOverlap);

	if (!bApiRet)
		SAVEWIN32ERROR(UnlockFileEx,GetLastError());

	Return(bApiRet == TRUE);
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

void _fastcall FHandleEx(ParamBlk *parm)
{
	if (!VFP2C_VALID_FILE_HANDLE(p1.ev_long))
		RaiseError(E_INVALIDPARAMS);
	Return((int)gaFileHandles[p1.ev_long]);
}

void _fastcall AFHandlesEx(ParamBlk *parm)
{
try
{
	FoxArray pArray(p1);	
	unsigned int nHandleCnt = 0;
	int xj;

	for (xj = 0; xj < VFP2C_MAX_FILE_HANDLES; xj++)
	{
		if (gaFileHandles[xj])
			nHandleCnt++;
	}

	if (nHandleCnt == 0)
	{
		Return(0);
		return;
	}

	pArray.Dimension(nHandleCnt,2);

	unsigned int nRow = 0;
	for (xj = 0; xj < VFP2C_MAX_FILE_HANDLES; xj++)
	{
		if (gaFileHandles[xj])
		{
			nRow++;
			pArray(nRow,1) = xj;
			pArray(nRow,2) = (int)gaFileHandles[xj];
		}
	}

	pArray.ReturnRows();
}
catch(int nErrorNo)
{
	RaiseError(nErrorNo);
}
}

int _stdcall FindFreeFileSlot() throw(int)
{
	int xj;
	for (xj = 0; xj < VFP2C_MAX_FILE_HANDLES; xj++)
	{
		if (!gaFileHandles[xj])
			return xj;
	}
	SAVECUSTOMERROR("FCreateEx/FOpenEx","Maximum number of file handles exceeded.");
	throw E_APIERROR;
}

void _stdcall MapFileAccessFlags(int nFileAttribs, int nAccess, int nShare, LPDWORD pAccess, LPDWORD pShare, LPDWORD pFlags) throw(int)
{
	*pAccess = 0;
	*pShare = 0;
	*pFlags = 0;

	switch (nAccess)
	{
		case 0:
			*pAccess = GENERIC_READ;
			break;
		case 1:
			*pAccess = GENERIC_WRITE;
			break;
		case 2:
			*pAccess = GENERIC_READ | GENERIC_WRITE;
			break;
		default:
			throw E_INVALIDPARAMS;
	}

	if (nFileAttribs & ~(FILE_ATTRIBUTE_ARCHIVE | FILE_ATTRIBUTE_ENCRYPTED | 
						FILE_ATTRIBUTE_HIDDEN | FILE_ATTRIBUTE_NORMAL |
						FILE_ATTRIBUTE_NOT_CONTENT_INDEXED | FILE_ATTRIBUTE_OFFLINE |
						FILE_ATTRIBUTE_READONLY | FILE_ATTRIBUTE_SYSTEM |
						FILE_ATTRIBUTE_TEMPORARY | FILE_FLAG_BACKUP_SEMANTICS |
						FILE_FLAG_DELETE_ON_CLOSE | FILE_FLAG_OPEN_NO_RECALL |
						FILE_FLAG_OPEN_REPARSE_POINT | FILE_FLAG_POSIX_SEMANTICS |
						FILE_FLAG_RANDOM_ACCESS | FILE_FLAG_SEQUENTIAL_SCAN |
						FILE_FLAG_WRITE_THROUGH))
		throw E_INVALIDPARAMS;

	*pFlags |= nFileAttribs;

	if (nShare & ~(FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE))
		throw E_INVALIDPARAMS;

	*pShare = nShare;
}