PUBLIC goGDIPlusXSamples
LOCAL lcPath

lcPath = ADDBS(JUSTPATH(SYS(16)))

SET PATH TO (lcPath) ADDITIVE
SET PATH TO (lcPath+"..\source\") ADDITIVE


goGDIPlusXSamples=NEWOBJECT("_main","gdipsamples")
goGDIPlusXSamples.Show( IIF(_VFP.StartMode>=2,1,0) )

