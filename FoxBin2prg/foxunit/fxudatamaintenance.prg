***********************************************************************
*	FoxUnit is Copyright (c) 2004 - 2005, Visionpace
*	All rights reserved.
*
*	Redistribution and use in source and binary forms, with or
*	without modification, are permitted provided that the following
*	conditions are met:
*
*		*	Redistributions of source code must retain the above
*			copyright notice, this list of conditions and the
*			following disclaimer.
*
*		*	Redistributions in binary form must reproduce the above
*			copyright notice, this list of conditions and the
*			following disclaimer in the documentation and/or other
*			materials provided with the distribution.
*
*		*	The names Visionpace and Vision Data Solutions, Inc.
*			(including similar derivations thereof) as well as
*			the names of any FoxUnit contributors may not be used
*			to endorse or promote products which were developed
*			utilizing the FoxUnit software unless specific, prior,
*			written permission has been obtained.
*
*	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
*	"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
*	LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
*	FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
*	COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
*	INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
*	BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
*	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
*	CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
*	LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
*	ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
*	POSSIBILITY OF SUCH DAMAGE.
***********************************************************************


RETURN CREATEOBJECT("FxuDataMaintenance")

**********************************************************************
DEFINE CLASS FxuDataMaintenance AS FxuCustom OF FxuCustom.prg
	**********************************************************************

	#IF .F.
		LOCAL THIS AS FxuDataMaintenance OF FxuDataMaintenance.prg
	#ENDIF

	icDataPath = ''
	icResultsTable = 'FXUResults'

	********************************************************************
	FUNCTION INIT(tcResultsTable)
		********************************************************************
		THIS.icResultsTable = EVL(tcResultsTable,THIS.icResultsTable)
		THIS.icResultsTable = JUSTSTEM(THIS.icResultsTable)

		********************************************************************
	FUNCTION CreateNewTestResultTable(tcDataPath, tcResultsTable)
		********************************************************************

		tcDataPath = EVL(ADDBS(tcDataPath),CURDIR())

		IF !DIRECTORY(tcDataPath)
			tcDataPath = CURDIR()
		ENDIF

		THIS.icDataPath = tcDataPath

		THIS.icResultsTable = EVL(tcResultsTable,'FXUResults')

		* Added path field. HAS
		*-- FDBOZZO. 01/10/2011. Field length expansion.
		*-- 	Expanded TClass C(80) to C(110) ==> So the Unit Test file name can be 'ut_libraryName__className__methodName.prg'
		*-- 	Expanded TName C(100) to C(130) ==> So the method name can be 'SHOULD_DoSomething__WHEN_SomeConditions'
		CREATE TABLE (tcDataPath + THIS.icResultsTable) ;
			(TClass C(110), ;
			TPath C(120), ;
			TName C(130), ;
			Location I, ;
			Success L, ;
			TLastRun T, ;
			Telapsed N(10,3), ;
			TRUN L, ;
			Fail_Error M, ;
			MESSAGES M )

		SELECT (THIS.icResultsTable)

		THIS.BuildIndexes()

		USE IN SELECT(THIS.icResultsTable)


		********************************************************************
	ENDFUNC
	********************************************************************

	********************************************************************
	FUNCTION BuildIndexes
		********************************************************************
		INDEX ON UPPER(TClass) TAG TClass_U
		INDEX ON UPPER(TName) TAG TName_U
		INDEX ON UPPER(TClass) + UPPER(TName) TAG TCLName CANDIDATE FOR NOT DELETED()
		INDEX ON UPPER(TClass) + STR(Location) TAG TCLoc

		********************************************************************
	ENDFUNC
	********************************************************************

	********************************************************************
	FUNCTION ReBuildIndexes
		********************************************************************

		LOCAL lcSetSafety
		lcSetSafety = SET('safety')
		SET SAFETY OFF

		SELECT (THIS.icResultsTable)
		DELETE TAG ALL

		THIS.BuildIndexes()

		SET SAFETY &lcSetSafety

		RETURN

		********************************************************************
	ENDFUNC
	********************************************************************

	********************************************************************
	FUNCTION ReIndexResultsTable(tlExhaustive)
		********************************************************************

		THIS.OpenResultsTable(.T.)
		SELECT (THIS.icResultsTable)
		PACK

		IF !EMPTY(tlExhaustive)
			THIS.ReBuildIndexes()
		ELSE
			SELECT (THIS.icResultsTable)
			REINDEX
		ENDIF

		THIS.OpenResultsTable(.F.)

		********************************************************************
	ENDFUNC
	********************************************************************

	********************************************************************
	FUNCTION OpenResultsTable(tlExclusive)
		********************************************************************

		LOCAL lcExclusive
		lcExclusive = ''

		IF !EMPTY(tlExclusive)
			lcExclusive = ' EXCL '
		ELSE
			lcExclusive = ' SHARED '
		ENDIF

		IF USED(THIS.icResultsTable)
			USE IN SELECT(THIS.icResultsTable)
		ENDIF

		LOCAL llSuccess
		llSuccess = .T.
		TRY
			USE (THIS.icDataPath + THIS.icResultsTable) IN 0 &lcExclusive
		CATCH
			llSuccess = .F.
		ENDTRY

		IF m.llSuccess
			SELECT (THIS.icResultsTable)
		ENDIF

		RETURN m.llSuccess

		********************************************************************
	ENDFUNC
	********************************************************************

	**********************************************************************
ENDDEFINE && CLASS
**********************************************************************
