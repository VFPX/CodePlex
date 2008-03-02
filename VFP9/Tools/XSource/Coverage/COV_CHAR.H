* COV_CHAR.H
* character constants in use by Coverage app

#DEFINE C_TAB                       CHR(9)
* tab character
#DEFINE C_NULL                      CHR(0)
* null character
#DEFINE C_TAB_REPLACEMENT           REPL("#",5)
* we may need to replace tabs during processing
#DEFINE C_INLINECOMMENT             CHR(38)+CHR(38)
* double ampersand
#DEFINE C_COMMENT                   CHR(42)
* asterisk
#DEFINE C_DEFINE                    CHR(35)
* hash or pound sign
#DEFINE C_CR                        CHR(13)
* carriage return
#DEFINE C_DOUBLE_CR                 CHR(13)+CHR(13)
* double carriage return
#DEFINE C_CONTINUATION_SYMBOL       CHR(59)
* semi-colon
