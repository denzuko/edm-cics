//EDMHELO  JOB (EDM),'COMPILE EDMHELO',
//             CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* EDMHELO - Translate, Compile, Link-Edit
//* Episode 1 - EDM CICS Tutorial Series
//* Steps: CICS Translate -> COBOL Compile -> Link Edit
//*
//******************************************************************
//* STEP 1: CICS TRANSLATE
//*   Converts EXEC CICS commands to CALL statements
//******************************************************************
//CICSTRN  EXEC PGM=DFHECP1$,
//             PARM='COBOL2,APOST'
//STEPLIB  DD DSN=BRICKS.LOADLIB,DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DSN=EDM.SOURCE(EDMHELO),DISP=SHR
//SYSLIN   DD DSN=&&TRNSRC,
//            DISP=(NEW,PASS),
//            UNIT=SYSDA,
//            SPACE=(CYL,(1,1))
//*
//******************************************************************
//* STEP 2: COBOL COMPILE
//******************************************************************
//COBOLC   EXEC PGM=IGYCRCTL,
//             PARM='NODYNAM,RENT,RES,APOST',
//             COND=(5,LT,CICSTRN)
//STEPLIB  DD DSN=IGY.V4R2M0.SIGYCOMP,DISP=SHR
//SYSLIB   DD DSN=EDM.COPYLIB,DISP=SHR
//         DD DSN=BRICKS.COPYLIB,DISP=SHR
//         DD DSN=SYS1.MACLIB,DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DSN=&&TRNSRC,DISP=(OLD,DELETE)
//SYSLIN   DD DSN=&&OBJLIB,
//            DISP=(NEW,PASS),
//            UNIT=SYSDA,
//            SPACE=(CYL,(1,1))
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT2   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT3   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT4   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT5   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT6   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT7   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//*
//******************************************************************
//* STEP 3: LINK EDIT
//******************************************************************
//LKED     EXEC PGM=IEWL,
//             PARM='XREF,LIST,LET,AC=1',
//             COND=(5,LT,COBOLC)
//SYSLIB   DD DSN=BRICKS.LOADLIB,DISP=SHR
//         DD DSN=CEE.SCEELKED,DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSLMOD  DD DSN=EDM.LOADLIB(EDMHELO),
//            DISP=SHR
//SYSLIN   DD DSN=&&OBJLIB,DISP=(OLD,DELETE)
//         DD *
 INCLUDE SYSLIB(DFHELII)
 NAME EDMHELO(R)
/*
