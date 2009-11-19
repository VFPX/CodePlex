*-- SubFox Project Class --*
*-- SubFox Translation Classes --*
*-- (c) 2008 Holden Data Systems

#include SubFox.h

*******************************************************************************
DEFINE CLASS SubFoxProject AS Custom && OLEPUBLIC
*-- Properties --*
	s_PjxName = "" && file name to "normal" VFP project file "MyProject.pjx"
	s_RootPath = ""
	s_ExtraCursorFields = ""
	o_Util = NULL

*-- Methods --*
FUNCTION Init(sFName AS String) AS Boolean
	this.o_Util = NEWOBJECT( "SubFoxUtilities", "SubFox Utility Class.prg" )
	IF VARTYPE( sFName ) == 'O'
		LOCAL o
		o = sFName && it's really an object... is a PROJECT object?
		IF !ISNULL( o ) AND PEMSTATUS( o, "Name", 5 ) AND FILE( o.Name )
			this.s_PjxName = LOWER( o.Name )
		ENDIF
	ELSE
		IF !EMPTY( sFName ) AND FILE( sFName )
			this.s_PjxName = LOWER( sFName )
		ENDIF
	ENDIF
ENDFUNC && Init
*******************************************************************************
FUNCTION Open(sFName AS String) AS Boolean
	LOCAL i,s,o, sProjRoot
	IF VARTYPE( sFName ) == 'O'
		o = sFName && it's really an object... is a PROJECT object?
		sFName = ""
		IF !ISNULL( o ) AND PEMSTATUS( o, "Name", 5 ) AND FILE( o.Name )
			this.s_PjxName = LOWER( o.Name )
		ENDIF
	ELSE
		IF !EMPTY( sFName ) AND FILE( sFName )
			this.s_PjxName = LOWER( sFName )
		ENDIF
	ENDIF
	IF EMPTY( this.s_PjxName )
		IF _VFP.StartMode != 0
			MESSAGEBOX( "No Project specified in OPEN function.", 16, "Parameter Required" )
			RETURN .F.
		ENDIF
*--			IF _VFP.Projects.Count > 1
*--				MESSAGEBOX( "There are multiple projects open at this time." + CR ;
*--						  + "For the sake of clarity, SubFox only works" + CR ;
*--						  + "with one project at a time?", 64, "Multiple Active Projects" )
*--				RETURN .F.
*--			ENDIF
		IF _VFP.Projects.Count == 0
			IF MESSAGEBOX( "There are no projects open at this time." + CR ;
						  + "Would you like to open one now?", 4 + 32, "No Active Project" ) == 7
				RETURN .F.
			ENDIF
			*sFName = LOWER( GETFILE( "Foxpro Project:pjx;Subfox Project:pjx." + SUBFOX_PRIVATE_EXT, "Project:" ) )
			sFName = LOWER( GETFILE( "Subfox Project:pjx." + SUBFOX_PRIVATE_EXT + ";Foxpro Project:pjx", "Project:" ) )
			IF EMPTY( sFName ) OR !FILE( sFName )
				RETURN .F.
			ENDIF
			IF JUSTEXT( sFName ) == SUBFOX_PRIVATE_EXT
				s = LEFT( sFName, RAT( ".", sFName ) - 1 )
				o = NEWOBJECT( "SubFoxTranslator", "SubFox Translation Classes.prg" )
				IF !FILE(s) OR o.FDateTime(s) != o.FDateTime(sFName)
					o.RestoreToTable( sFName, s )
				ENDIF
				sFName = s
			ENDIF
			this.s_PjxName = LOWER( sFName )
			* Do we really want to OPEN IN VFP??? -- yes!
			MODIFY PROJECT (sFName) NOWAIT
			IF _VFP.Projects.Count == 0
				RETURN .F.
			ENDIF
		ENDIF
	ENDIF
	IF EMPTY( this.s_PjxName ) AND _VFP.Projects.Count > 0
		this.s_PjxName = LOWER( _VFP.ActiveProject.Name ) && _VFP.Projects(1).Name )
	ENDIF
	*-- if previously opened, project may need to be SAVED to disk...
	TRY
		o = _VFP.Projects( this.s_PjxName )
		* let's hope this is unnecessary... o.CleanUp() && force in-memory updates to disk
		o.Refresh() && force in-memory updates to disk
	CATCH
		*-- I guess we just don't do the cleanup
	ENDTRY
	o = NULL
	*-- Encoded Updates may have been downloaded...
	IF !this.FreshenUpProject()
		RETURN .F.
	ENDIF
	*-- attempt to open the project as a table
	TRY
		USE (this.s_PjxName) AGAIN IN 0 SHARED ALIAS cPjx NOUPDATE
		o = NULL
	CATCH TO o
		s = MESSAGE()
	ENDTRY
	IF !ISNULL( o )
		MESSAGEBOX( "Error accessing VFP project file:" + CR ;
				  + TRANSFORM( o.ErrorNo ) + " - " + s, 16, "Program Error" )
		RETURN .F.
	ENDIF
	SELECT cPjx
	LOCATE FOR !DELETED('cPjx') && aka GO TOP
	* sProjRoot = LOWER( STRTRAN( cPjx.HomeDir, CHR(0), "" ) )
	sProjRoot = this.o_Util.FullPath( STRTRAN( cPjx.HomeDir, CHR(0), "" ), JUSTPATH( this.s_PjxName ) )
	this.s_RootPath = sProjRoot
	s = [k_RecKey C(10) DEFAULT SYS(2015), k_Parent C(10), n_RecNo I, s_FName C(128), ] ;
	  + [s_Path C(MAX_VFP_FLD_LEN), e_Type C(1), l_InBuild L, l_Versioned L, l_Encoded L, l_Flagged L]  ;
	  + IIF( EMPTY( this.s_ExtraCursorFields ), "", ", " + this.s_ExtraCursorFields )
	CREATE CURSOR cFile (&s)
		INDEX ON k_RecKey TAG k_RecKey
		INDEX ON k_Parent TAG k_Parent
		INDEX ON PADR(s_FName,MAX_VFP_IDX_LEN) TAG s_FName COLLATE "GENERAL"
	*-- project file itself
	SELECT cPjx
	LOCATE FOR Type == FILETYPE_PROJECT AND !DELETED('cPjx')
	INSERT INTO cFile  (n_RecNo, s_FName, s_Path, e_Type, l_InBuild, l_Versioned, l_Encoded) ;
				VALUES (RECNO('cPjx'), JUSTFNAME(this.s_PjxName), JUSTPATH(this.s_PjxName), ;
						FILETYPE_PROJECT, .T., .T., .T.)
	*-- load "everything" else
	LOCAL sIconFName, nIconRecNo
	sIconFName = ""
	SELECT cPjx
	SCAN FOR !INLIST( cPjx.Type, PJX_RECTYPE_HOME, FILETYPE_DATABASE, FILETYPE_DBTABLE, ;
					  FILETYPE_APILIB, FILETYPE_APPLICATION, FILETYPE_PRJHOOK ) AND !DELETED('cPjx')
		s = this.o_Util.FullPath( ALLTRIM( STRTRAN( cPjx.Name, CHR(0), "" ) ), sProjRoot )
		IF cPjx.Type == FILETYPE_ICON
			sIconFName = s
			nIconRecNo = RECNO('cPjx')
			LOOP
		ENDIF
		INSERT INTO cFile  (n_RecNo, s_FName, s_Path, e_Type, l_Versioned, l_Encoded) ;
					VALUES (RECNO('cPjx'), JUSTFNAME(s), JUSTPATH(s), cPjx.Type, ;
							(!cPjx.Exclude OR ATC( "versioned", cPjx.User ) > 0), ;
							INLIST( cPjx.Type, FILETYPE_DATABASE, FILETYPE_FREETABLE, FILETYPE_DBTABLE, ;
									FILETYPE_PROJECT, FILETYPE_FORM, FILETYPE_REPORT, FILETYPE_LABEL, ;
									FILETYPE_CLASSLIB, FILETYPE_MENU ))
	ENDSCAN
	IF !EMPTY( sIconFName )
		IF !this.SeekFName( sIconFName )
			INSERT INTO cFile  (n_RecNo, s_FName, s_Path, e_Type, l_Versioned) ;
						VALUES (nIconRecNo, JUSTFNAME(sIconFName), JUSTPATH(sIconFName), FILETYPE_OTHER, .T.)
		ENDIF
	ENDIF
	*-- load databases
	LOCAL lUnversioned, aSDT[1], kDBC
	ALINES( aSDT, SDT_META_TABLES, .T., "," )
	SELECT cPjx
	SCAN FOR cPjx.Type == FILETYPE_DATABASE AND !DELETED('cPjx')
		s = this.o_Util.FullPath( ALLTRIM( STRTRAN( STRTRAN( cPjx.Name, CHR(0), "" ), "_", " " ) ), sProjRoot )
		lUnversioned = (ATC( "unversioned", cPjx.User ) > 0)
		sVsndTbls = IIF( lUnversioned, "", STREXTRACT( cPjx.User, "Versioned=[", "]" ) )
		INSERT INTO cFile  (n_RecNo, s_FName, s_Path, e_Type, l_InBuild, l_Versioned, l_Encoded) ;
					VALUES (RECNO('cPjx'), JUSTFNAME(s), JUSTPATH(s), FILETYPE_DATABASE, ;
							!cPjx.Exclude, !lUnversioned, .T.)
		kDBC = cFile.k_RecKey
		IF !this.GetTablesInDBC( s, cFile.k_RecKey, sVsndTbls )
			RETURN .F.
		ENDIF
		IF !lUnversioned && 11-19-2009 -- Why pickup SdtMeta.dbf in the folder of a DBC that IS NOT VERSIONED???
			s = ADDBS( JUSTPATH( s ) )
			FOR i = 1 TO ALEN( aSDT )
				ss = s + FORCEEXT( aSDT[i], "dbf" )
				IF FILE( ss ) AND !this.SeekFName( ss )
					INSERT INTO cFile  (k_Parent, s_FName, s_Path, e_Type, l_Versioned, l_Encoded) ;
								VALUES (kDBC, JUSTFNAME(ss), JUSTPATH(ss), FILETYPE_FREETABLE, .T., .T.)
				ENDIF
			ENDFOR
		ENDIF
		SEEK kDBC IN cFile ORDER k_RecKey
		GOTO cFile.n_RecNo IN cPjx
	ENDSCAN
	USE IN cPjx
ENDFUNC && Open
*******************************************************************************
FUNCTION SeekFName(sFName AS String) AS Boolean
	LOCAL i,b,s,ss
	s = LOWER( JUSTFNAME( sFName ) )
	b = SEEK( PADR(s,MAX_VFP_IDX_LEN), 'cFile', 's_FName' )
	IF b
		i = SELECT(0)
		SELECT cFile
		SET ORDER TO s_FName
		LOCATE FOR RTRIM( s_Path ) == LOWER( JUSTPATH( sFName ) ) REST WHILE RTRIM( s_FName ) == s
		b = FOUND()
		IF !b AND !EOF()
			GO BOTTOM
			IF !EOF()
				SKIP
			ENDIF
		ENDIF
		SELECT (i)
	ENDIF
	RETURN b
ENDFUNC && SeekFName
*******************************************************************************
FUNCTION GetTablesInDBC(sDBC AS String, kDBC AS String, sVsndTbls AS String) AS Boolean
	LOCAL i,ii,s,o, a[1], aVsndTbls[1], nVsndTblCnt, lPreOpened
	lPreOpened = DBUSED( sDBC )
	IF !lPreOpened
		TRY
			OPEN DATABASE (sDBC) SHARED NOUPDATE
			o = NULL
		CATCH TO o
			s = MESSAGE()
		ENDTRY
		IF !ISNULL( o )
			MESSAGEBOX( "Error accessing database container" + CR + SPACE(6) + LOWER( sDBC ) + CR ;
					  + CR + TRANSFORM( o.ErrorNo ) + " - " + s, 16, "Access Error" )
			RETURN .F.
		ENDIF
	ENDIF
	nVsndTblCnt = ALINES( aVsndTbls, LOWER( sVsndTbls ), 5, "," )
	SET DATABASE TO (sDBC)
	sDBC = LOWER( DBC() )
	FOR i = 1 TO ADBOBJECTS( a, "TABLE" )
		s = DBGETPROP( a[i], "TABLE", "Path" )
		s = this.o_Util.FullPath( s, JUSTPATH( sDBC ) )
		ii = IIF( nVsndTblCnt == 0, 0, ASCAN( aVsndTbls, JUSTSTEM(s), 1, nVsndTblCnt, 1, 7 ) )
		INSERT INTO cFile  (n_RecNo, k_Parent, s_FName, s_Path, e_Type, l_Versioned, l_Encoded) ;
					VALUES (RECNO('cPjx'), kDBC, JUSTFNAME(s), JUSTPATH(s), FILETYPE_DBTABLE, (ii>0), .T.)
	ENDFOR
	IF !lPreOpened
		SET DATABASE TO (sDBC)
		CLOSE DATABASES && just this one
	ENDIF
ENDFUNC && GetTablesInDBC
*******************************************************************************
FUNCTION FreshenUpProject() AS Boolean
	LOCAL i,s,t1,t2, sEncodedFName, oTranslator
	sEncodedFName = this.s_PjxName + "." + SUBFOX_PRIVATE_EXT
	IF !FILE( sEncodedFName )
		RETURN
	ENDIF
	oTranslator = NEWOBJECT( "SubFoxTranslator", "SubFox Translation Classes.prg" )
	IF FILE( this.s_PjxName )
		t1 = oTranslator.FDateTime( this.s_PjxName )
		t2 = oTranslator.FDateTime( sEncodedFName )
		IF t1 == t2 && t1 >= t2
			RETURN
		ENDIF
		IF t1 < t2
			i = MESSAGEBOX( "The encoded version of this project is NEWER than" + CHR(13) ;
						  + "the current project file." + CHR(13) + CHR(13) ;
						  + "Would you like to Decode this file and install the updates?", ;
							3 + 32, "Project Updates Available" )
		ELSE
			i = 7 && no
*--				i = MESSAGEBOX( "The current project file has been updated since the last interation" + CHR(13) ;
*--							  + "with the Subversion repository." + CHR(13) + CHR(13) ;
*--							  + "Would you like to ROLLBACK to that version of the project?", ;
*--								3 + 32 + 256, "Project Rollback Option" )
		ENDIF
		DO CASE
		CASE i == 2 && cancel
			RETURN .F.
		CASE i == 7 && no
			RETURN .T.
		ENDCASE
	ENDIF
	IF !oTranslator.ConvertFile( sEncodedFName, this.s_PjxName )
		RETURN .F.
	ENDIF
ENDFUNC && FreshenUpProject
*******************************************************************************
FUNCTION Save(lAnyChange AS Boolean) AS Boolean
	LOCAL i,o,s, sVsndTbls
	IF EMPTY( this.s_PjxName ) OR !FILE( this.s_PjxName ) OR !USED( 'cFile' )
		MESSAGEBOX( "Do not call the SAVE function until after calling the OPEN function", ;
					16, "Invalid Function Call" )
		RETURN .F.
	ENDIF
	TRY
		USE (this.s_PjxName) AGAIN IN 0 SHARED ALIAS cPjx
		o = NULL
	CATCH TO o
		s = MESSAGE()
	ENDTRY
	IF !ISNULL( o )
		MESSAGEBOX( "Error accessing VFP project file:" + CHR(13) ;
				  + TRANSFORM( o.ErrorNo ) + " - " + s, 16, "Program Error" )
		RETURN .F.
		ENDIF
	*-- save databases
	 * reopen cFile as cTable *
	USE (DBF('cFile')) AGAIN IN 0 ALIAS cTable
	SET ORDER TO s_FName IN cTable
	lAnyChange = .F.
	SELECT cFile
	SCAN FOR cFile.n_RecNo != 0 AND cFile.e_Type == FILETYPE_DATABASE
		GOTO cFile.n_RecNo IN cPjx
		s = cPjx.User
		s = STRTRAN( s, "unversioned" + CRLF, "", 1, 1, 1 )
		s = STRTRAN( s, "unversioned", "", 1, 1, 1 )
		i = ATC( "Versioned=[", s )
		ii = IIF( i == 0, 0, AT( "]", SUBSTR( s, i ) ) )
		IF ii > 0
			s = STUFF( s, i, ii, "" )
			IF PADR( SUBSTR( s, i ), 2 ) == CRLF
				s = STUFF( s, i, 2, "" ) && remove CRLF too
			ENDIF
		ENDIF
		IF !cFile.l_Versioned
			s = IIF( LEN(s) == 0, "", s + IIF( RIGHT(s,2) == CRLF, "", CRLF ) ) ;
			  + "Unversioned" + CRLF
		ELSE
			sVsndTbls = ""
			SELECT cTable
			SCAN FOR k_Parent == cFile.k_RecKey AND l_Versioned
				sVsndTbls = IIF( EMPTY( sVsndTbls ), "", sVsndTbls + "," ) + JUSTSTEM( RTRIM( cTable.s_FName ) )
			ENDSCAN
			IF !EMPTY( sVsndTbls )
				s = IIF( LEN(s) == 0, "", s + IIF( RIGHT(s,2) == CRLF, "", CRLF ) ) ;
				  + "Versioned=[" + sVsndTbls + "]" + CRLF
			ENDIF
		ENDIF
		IF NOT s == cPjx.User
			REPLACE User WITH s IN cPjx
			lAnyChange = .T.
		ENDIF
	ENDSCAN
	USE IN cTable
	*-- everything else
	SELECT cFile
	SCAN FOR cFile.n_RecNo != 0 AND !INLIST( cFile.e_Type, FILETYPE_DATABASE, FILETYPE_DBTABLE )
		GOTO cFile.n_RecNo IN cPjx
		s = cPjx.User
		s = STRTRAN( s, "versioned" + CRLF, "", 1, 1, 1 )
		s = STRTRAN( s, "versioned", "", 1, 1, 1 )
		IF cFile.l_Versioned
			s = IIF( LEN(s) == 0, "", s + IIF( RIGHT(s,2) == CRLF, "", CRLF ) ) ;
			  + "Versioned" + CRLF
		ENDIF
		IF NOT s == cPjx.User
			REPLACE User WITH s IN cPjx
			lAnyChange = .T.
		ENDIF
	ENDSCAN
	USE IN cPjx
ENDFUNC && Save
*******************************************************************************
ENDDEFINE && SubFoxProject
