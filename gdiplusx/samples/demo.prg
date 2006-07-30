PUBLIC goGDIPlusXSamples
*!* Testing Source Control
LOCAL lcPath

lcPath = ADDBS(JUSTPATH(SYS(16)))

SET PATH TO (lcPath) ADDITIVE
SET PATH TO (lcPath+"..\source\") ADDITIVE

DO FORM samples

**goGDIPlusXSamples=NEWOBJECT("_main","gdipsamples")
**goGDIPlusXSamples.Show( IIF(_VFP.StartMode>=2,1,0) )

