//EDMALLOC JOB (EDM),'EDM LIBRARY ALLOCATION',
//             CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1)
//*
//* EDMALLOC - Allocate EDM development partitioned datasets
//* Episode 0 - EDM CICS Tutorial Series
//* Ellison Digital Minerals Systems Administration
//*
//STEP1    EXEC PGM=IEFBR14
//*
//* COBOL source library
//EDMSRC   DD DSN=EDM.SOURCE,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,
//            SPACE=(CYL,(5,2,50)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=3200)
//*
//* Load library (compiled + link-edited programs)
//EDMLOAD  DD DSN=EDM.LOADLIB,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,
//            SPACE=(CYL,(10,5)),
//            DCB=(RECFM=U,BLKSIZE=32760)
//*
//* Copybook library (shared record layouts)
//EDMCOPY  DD DSN=EDM.COPYLIB,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,
//            SPACE=(CYL,(2,1,30)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=3200)
//*
//* BMS map library (3270 screen definitions)
//EDMMAP   DD DSN=EDM.MAPLIB,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,
//            SPACE=(CYL,(2,1,30)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=3200)
//*
//* VSAM cluster definitions (batch definitions only)
//EDMVSAM  DD DSN=EDM.VSAM.CLUSTER,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,
//            SPACE=(CYL,(5,2)),
//            DCB=(RECFM=FB,LRECL=80,BLKSIZE=3200)
