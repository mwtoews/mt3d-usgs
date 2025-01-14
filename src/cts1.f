C
      SUBROUTINE CTS1AR(INUNIT)
C **********************************************************************
C THIS SUBROUTINE ALLOCATES SPACE FOR ARRAYS NEEDED IN THE CONTAMINANT 
C TREATMENT SYSTEM PACKAGE.
C **********************************************************************
C
      USE MT3DMS_MODULE, ONLY: INCTS,IOUT,MXCTS,ICTSOUT,NCOL,NROW,NLAY,
     &                         NCOMP,MXCTS,MXEXT,MXINJ,KEXT,IEXT,
     &                         JEXT,KINJ,IINJ,JINJ,IOPTEXT,IOPTINJ,
     &                         CMCHGEXT,CMCHGINJ,CINCTS,CNTE,
     &                         ITRTEXT,ITRTINJ,QINCTS,QOUTCTS,NEXT,NINJ,
     &                         QCTS,CCTS,IWEXT,IWINJ,MXWEL,IWCTS,IFORCE,
     &                         NCTS,NCTSOLD,CEXT2CTS,CGW2CTS,CADDM,
     &                         CCTS2EXT,CCTS2GW,CREMM,ICTSPKG
      INTEGER        ISOLD,ISOLD2 
      INTEGER        INUNIT,I
      LOGICAL        OPND
      CHARACTER*5000 FNM
C--PRINT PACKAGE NAME AND VERSION NUMBER
      WRITE(IOUT,1000) INCTS
 1000 FORMAT(/1X,'CTS1 -- CONTAMINANT TREATMENT SYSTEM,',
     & ' VERSION 1, MAY 2016, INPUT READ FROM UNIT',I3)
C
C--ALLOCATE
      ALLOCATE(MXCTS,ICTSOUT,MXEXT,MXINJ,MXWEL,IFORCE,ICTSPKG)
C
C--READ AND PRINT MAXIMUM NUMBER OF TREATMENT SYSTEMS 
      READ(INCTS,*,ERR=1,IOSTAT=IERR) MXCTS,ICTSOUT,MXEXT,MXINJ,
     &                                MXWEL,IFORCE,ICTSPKG
    1 IF(IERR.NE.0) THEN
        BACKSPACE (INCTS)
        READ(INCTS,'(I10)') MXCTS
      ENDIF
      WRITE(IOUT,1010) MXCTS
1010  FORMAT(1X,'MAXIMUM NUMBER OF CONTAMINANT TREATMENT SYSTEMS =',I10)
C
C--ALLOCATE
      ALLOCATE(NCTS,NCTSOLD,NEXT(MXEXT),NINJ(MXINJ),ITRTEXT(MXCTS),
     &         ITRTINJ(MXCTS),IOPTEXT(NCOMP,MXEXT,MXCTS),
     &         IOPTINJ(NCOMP,MXINJ,MXCTS),CMCHGEXT(NCOMP,MXEXT,MXCTS),
     &         CMCHGINJ(NCOMP,MXINJ,MXCTS),
     &         KEXT(MXEXT,MXCTS),IEXT(MXEXT,MXCTS),JEXT(MXEXT,MXCTS),
     &         KINJ(MXINJ,MXCTS),IINJ(MXINJ,MXCTS),JINJ(MXINJ,MXCTS),
     &         QINCTS(MXCTS),CINCTS(NCOMP,MXCTS),QOUTCTS(MXCTS),
     &         CNTE(NCOMP,MXCTS),IWEXT(MXEXT,MXCTS),IWINJ(MXINJ,MXCTS),
     &         IWCTS(MXWEL),QCTS(MXCTS),CCTS(NCOMP,MXCTS),
     &         CEXT2CTS(NCOMP),CGW2CTS(NCOMP),CADDM(NCOMP),
     &         CCTS2EXT(NCOMP),CCTS2GW(NCOMP),CREMM(NCOMP))
C
      IF(ICTSOUT.GT.0) THEN
        WRITE(IOUT,1020) ICTSOUT
1020    FORMAT(1X,'CONTAMINANT TREATMENT SYSTEM OUTPUT ',
     &            ' WILL BE SAVED IN UNIT:',I3)
        INQUIRE(UNIT=ICTSOUT,OPENED=OPND)
        INQUIRE(UNIT=INCTS,NAME=FNM)
        I=LEN_TRIM(FNM)
        FNM((I-2):I)='CTO'
        IF(.NOT.OPND) OPEN(UNIT=ICTSOUT,FILE=TRIM(FNM))
      ENDIF
      WRITE(IOUT,1030) MXEXT
1030  FORMAT(1X,'MAXIMUM NUMBER OF EXTRACTION WELLS =',I10)
      WRITE(IOUT,1040) MXINJ
1040  FORMAT(1X,'MAXIMUM NUMBER OF INJECTION WELLS  =',I10)
      WRITE(IOUT,1050) MXWEL
1050  FORMAT(1X,'MAXIMUM NUMBER OF WELLS  =',I10)
      IF(ICTSPKG.EQ.0) THEN
        WRITE(IOUT,1060)
      ELSEIF(ICTSPKG.EQ.1) THEN
        WRITE(IOUT,1061)
      ENDIF
1060  FORMAT(1X,'CTS PACKAGE WILL WORK WITH MODFLOW''S MNW2 PACAKGE')
1061  FORMAT(1X,'CTS PACKAGE WILL WORK WITH MODFLOW''S WEL PACAKGE')
C
C--NORMAL RETURN
      RETURN
      END
C
C
      SUBROUTINE CTS1RP(KPER)
C ********************************************************************
C THIS SUBROUTINE READS NODES AND CONCENTRATIONS OF EXTRACTION/INJECTION
C NEEDED BY THE CONTAMINANT TREATMENT SYSTEM (CTS) PACKAGE.
C ********************************************************************
C
      USE MT3DMS_MODULE, ONLY: INCTS,IOUT,NCOL,NROW,NLAY,NCOMP,MXCTS,
     &                         MXEXT,MXINJ,NCTS,KEXT,IEXT,JEXT,KINJ,
     &                         IINJ,JINJ,ITRTEXT,ITRTINJ,IOPTEXT,
     &                         IOPTINJ,NEXT,NINJ,CMCHGEXT,CMCHGINJ,
     &                         CINCTS,CNTE,QINCTS,QOUTCTS,IWEXT,IWINJ,
     &                         IWCTS,MXWEL,IFORCE,NCTSOLD
      IMPLICIT  NONE
      CHARACTER*1000 LINE1
      INTEGER KPER,IN
      INTEGER I,II,JJ,ICTS,ICOMP,IDUMMY
C
C--READ NUMBER OF CONTAMINANT TREATMENT SYSTEMS
      READ(INCTS,*) NCTS
      IF(NCTS.GT.MXCTS) THEN
        WRITE(IOUT,*) 'NCTS EXCEEDS MXCTS'
        CALL USTOP(' ')
      ENDIF
C
C--IF NCTS < 0, TREATMENT SYSTEMS REUSED FROM LAST STRESS PERIOD
      IF(NCTS.LT.0) THEN
        IF(KPER.EQ.1) THEN
          WRITE(IOUT,*) 'ERROR: NCTS < 0 FOR FIRST STRESS PERIOD'
          STOP
        ENDIF
        WRITE(IOUT,1)
        NCTS=NCTSOLD
        GOTO 100
      ELSE !ZERO OUT ALL ARRAYS
        NCTSOLD=NCTS
        NEXT=0
        NINJ=0
        ITRTEXT=0
        ITRTINJ=0
        IOPTEXT=0
        CMCHGEXT=0.0E0
        IOPTINJ=0
        CMCHGINJ=0.0E0
        KEXT=0
        IEXT=0
        JEXT=0
        KINJ=0
        IINJ=0
        JINJ=0
        QINCTS=0.0E0
        CINCTS=0.0E0
        QOUTCTS=0.0E0
        CNTE=0.0E0
        IWEXT=0
        IWINJ=0
        IWCTS=0
      ENDIF
    1 FORMAT(/1X,'CONTAMINANT TREATMENT SYSTEMS',
     &           ' REUSED FROM LAST STRESS PERIOD')
C
C--IF NCTS >= 0, READ TREATMENT SYSTEM INFO 
      WRITE(IOUT,2) KPER
    2 FORMAT(1X,'TREATMENT SYSTEM INFORMATION',
     &          ' WILL BE READ IN STRESS PERIOD',I3)
      WRITE(IOUT,3) NCTS
3     FORMAT(1X,'NUMBER OF TREATMENT SYSTEMS =',I10)
C
C--READ ALL TREATMENT SYSTEMS
      DO I=1,NCTS
C
C--READ HEADER FOR EACH TREATMENT SYSTEM
        READ(INCTS,'(A1000)') LINE1
        READ(LINE1, *) ICTS
        READ(LINE1, *) IDUMMY, NEXT(ICTS), NINJ(ICTS),
     &    ITRTINJ(ICTS)
c-----hardwire to 0
        ITRTEXT(ICTS)=0
c------------------
        WRITE(IOUT,10) ICTS,NEXT(ICTS),NINJ(ICTS),
     &    ITRTINJ(ICTS) 
10      FORMAT(/1X,'TREATMENT SYSTEM # ',I10,
     &         /1X,'------------------------------',
     &         /1X,'NUMBER OF EXTRACTION WELLS    = ',I10,
     &         /1X,'NUMBER OF INJECTION WELLS     = ',I10,
     &         /1X,'TREATMENT OPTION (INJ. WELLS) = ',I10,
     &         /1X,'  = 0 MEANS NO TREATMENT',
     &         /1X,'  = 1 MEANS SAME LEVEL OF TREATMENT FOR ALL WELLS',
     &         /1X,'  = 2 MEANS TREATMENT SPECIFIED FOR EACH WELL')
C
C--CHECK IF NUMBERS EXCEED MAX NUMBERS
        IF(NEXT(ICTS).GT.MXEXT) THEN
          WRITE(IOUT,*) 'NEXT EXCEEDS MXEXT'
          CALL USTOP(' ')
        ENDIF
        IF(NINJ(ICTS).GT.MXINJ) THEN
          WRITE(IOUT,*) 'NINJ EXCEEDS MXINJ'
          CALL USTOP(' ')
        ENDIF
C
C--READ TREATMENT OPTIONS AND CONC/MASS CHANGE IF ITRTEXT=1
        IF(ITRTEXT(ICTS).EQ.1) THEN  !ITRTEXT fixed at 0
          WRITE(IOUT,20) ICTS
          WRITE(IOUT,*) 
          WRITE(IOUT,21)
          DO ICOMP=1,NCOMP
            WRITE(IOUT,22) ICOMP,IOPTEXT(ICOMP,1,ICTS),
     &                     CMCHGEXT(ICOMP,1,ICTS)
          ENDDO
        ENDIF
20      FORMAT(/1X,'TREATMENT APPLIED TO ALL EXTRACTION WELLS FOR CTS #'
     &            ,I10)
21      FORMAT(/1X,'   SPECIES    OPTION NUMBER   CONC/MASS CHANGE ',
     &         /1X,'   -------    -------------   ---------------- ')
22      FORMAT(/1X,2I10,9X,1PG15.6)
C
C--READ EXTRACTION WELLS TO BE TREATED AND THEIR OPTIONS AND CONC/MASS CHANGE
        DO II=1,NEXT(ICTS)
! provision to have separate treatment on each extraction well
          READ(INCTS, *) KEXT(II,ICTS),IEXT(II,ICTS),
     &                   JEXT(II,ICTS),IWEXT(II,ICTS)
          IWCTS(IWEXT(II,ICTS))=1
        ENDDO
C
        WRITE(IOUT,30) ICTS
        WRITE(IOUT,31) 
30      FORMAT(/1X,'     EXTRACTION WELLS FOR TREATMENT SYSTEM ',I10)
31      FORMAT( 1X,'     LAYER       ROW    COLUMN    WELL #',
     &         /1X,'     -----       ---    ------    ------')
32      FORMAT( 1X,'     LAYER       ROW    COLUMN    WELL #',
     &             '    OPTION(I) CONC/MASS CHANGE (I)  I=1,NCOMP',
     &         /1X,'     -----       ---    ------    ------',
     &             '    --------- --------------------')
        DO II=1,NEXT(ICTS)
! provision to have separate treatment on each extraction well
          WRITE(IOUT,35) KEXT(II,ICTS),IEXT(II,ICTS),JEXT(II,ICTS),
     &                   IWEXT(II,ICTS)
        ENDDO
35      FORMAT(1X,4I10)
36      FORMAT(1X,4I10,4X,1000(I10,1PG20.6))
C
C--EXTERNAL SOURCE
        READ(INCTS, *) QINCTS(ICTS),(CINCTS(ICOMP,ICTS),ICOMP=1,NCOMP)
        WRITE(IOUT,40)
        WRITE(IOUT,41) QINCTS(ICTS),
     &        (CINCTS(ICOMP,ICTS),ICOMP=1,NCOMP) 
40      FORMAT(/1X,'     EXTERNAL SOURCE',
     &         /1X,'     FLOW           CONC(I)',
     &         /1X,'     ----           -------') 
41      FORMAT(2X,1000(1PG15.6))
C
C--READ TREATMENT OPTIONS AND CONC/MASS CHANGE IF ITRTINJ=1
        IF(ITRTINJ(ICTS).EQ.1) THEN
          READ(INCTS, *) (IOPTINJ(ICOMP,1,ICTS),CMCHGINJ(ICOMP,1,ICTS),
     &                    ICOMP=1,NCOMP)
          WRITE(IOUT,50) ICTS
          WRITE(IOUT,*) 
          WRITE(IOUT,51)
          DO ICOMP=1,NCOMP
            WRITE(IOUT,52) 
     &        ICOMP,IOPTINJ(ICOMP,1,ICTS),CMCHGINJ(ICOMP,1,ICTS)
          ENDDO
        ENDIF
50      FORMAT(/1X,'TREATMENT APPLIED TO ALL INJECTION WELLS FOR CTS #'
     &            ,I10)
51      FORMAT(/1X,'   SPECIES    OPTION NUMBER   CONC/MASS CHANGE ',
     &         /1X,'   -------    -------------   ---------------- ')
52      FORMAT(1X,2I10,9X,1PG15.6)
C
C--READ NOT-TO-EXCEED-CONC
        IF(IFORCE.EQ.0) THEN
          READ(INCTS, *) (CNTE(ICOMP,ICTS),ICOMP=1,NCOMP)
          WRITE(IOUT,55) (CNTE(ICOMP,ICTS),ICOMP=1,NCOMP)
55        FORMAT(/1X,'   NOT-TO-EXCEED CONCENTRATION (1,NCOMP)',
     &         /1X,1000(1PG15.6))
        ENDIF
C
C--READ INJECTION WELLS TO BE TREATED AND THEIR OPTIONS AND CONC/MASS CHANGE
        DO II=1,NINJ(ICTS)
          IF(ITRTINJ(ICTS).EQ.0 .OR. ITRTINJ(ICTS).EQ.1) THEN
            READ(INCTS, *) KINJ(II,ICTS),IINJ(II,ICTS),
     &        JINJ(II,ICTS),IWINJ(II,ICTS)
          ELSEIF(ITRTINJ(ICTS).EQ.2) THEN
            READ(INCTS, *) 
     &        KINJ(II,ICTS),IINJ(II,ICTS),JINJ(II,ICTS),IWINJ(II,ICTS),
     &        (IOPTINJ(ICOMP,II,ICTS),
     &        CMCHGINJ(ICOMP,II,ICTS),ICOMP=1,NCOMP)
          ELSE
            WRITE(IOUT,110) 
            CALL USTOP(' ')
          ENDIF
          IWCTS(IWINJ(II,ICTS))=1
        ENDDO
C
        WRITE(IOUT,60) ICTS
        IF(ITRTINJ(ICTS).EQ.0 .OR. ITRTINJ(ICTS).EQ.1) THEN
          WRITE(IOUT,61) 
        ELSEIF(ITRTINJ(ICTS).EQ.2) THEN
          WRITE(IOUT,62) 
        ENDIF
60      FORMAT(/1X,'     INJECTION WELLS FOR TREATMENT SYSTEM ',I10)
61      FORMAT( 1X,'     LAYER       ROW    COLUMN    WELL #',
     &         /1X,'     -----       ---    ------    ------')
62      FORMAT( 1X,'     LAYER       ROW    COLUMN    WELL #',
     &             '    OPTION(I) CONC/MASS CHANGE (I)  I=1,NCOMP',
     &         /1X,'     -----       ---    ------    ------',
     &             '    --------- --------------------')
        DO II=1,NINJ(ICTS)
          IF(ITRTINJ(ICTS).EQ.0 .OR. ITRTINJ(ICTS).EQ.1) THEN
            WRITE(IOUT,65) KINJ(II,ICTS),IINJ(II,ICTS),JINJ(II,ICTS),
     &        IWINJ(II,ICTS)
          ELSEIF(ITRTINJ(ICTS).EQ.2) THEN
            WRITE(IOUT,66) KINJ(II,ICTS),IINJ(II,ICTS),JINJ(II,ICTS),
     &        IWINJ(II,ICTS),
     &      (IOPTINJ(ICOMP,II,ICTS),
     &       CMCHGINJ(ICOMP,II,ICTS),ICOMP=1,NCOMP)
          ENDIF
        ENDDO
65      FORMAT(1X,4I10)
66      FORMAT(1X,4I10,4X,1000(I10,1PG20.6))
C
C--EXTERNAL SINK
        READ(INCTS, *) QOUTCTS(ICTS)
        WRITE(IOUT,70) QOUTCTS(ICTS)
70      FORMAT(/1X,'     EXTERNAL SINK FLOW = ',1PG15.6)
C
      ENDDO
C
110   FORMAT(/1X,'ERROR: INVALID TREATMENT OPTION',
     &       /1X,'       ITRTINJ MUST BE SET TO 0, 1, OR 2') 
C
100   CONTINUE
C
C--RETURN
      RETURN
      END
C
C
      SUBROUTINE CTS1FM(ICOMP)
C ******************************************************************
C THIS SUBROUTINE FORMULATES MATRIX COEFFICIENTS FOR THE TREATMENT 
C SYSTEM TERMS UNDER THE IMPLICIT FINITE-DIFFERENCE SCHEME.
C ******************************************************************
C
      USE MIN_SAT, ONLY: QC7,DRYON
      USE MT3DMS_MODULE, ONLY: NCOL,NROW,NLAY,NCOMP,DELR,DELC,
     &                         DH,CNEW,ISS,A,RHS,NODES,UPDLHS,
     &                         MIXELM,SS,MXSS,NCTS,KEXT,IEXT,
     &                         JEXT,KINJ,IINJ,JINJ,IOPTEXT,IOPTINJ,
     &                         ITRTEXT,ITRTINJ,NEXT,NINJ,QINCTS,
     &                         QOUTCTS,CMCHGEXT,CMCHGINJ,CINCTS,
     &                         CNTE,MXEXT,MXINJ,MXCTS,QCTS,CCTS,
     &                         IOUT,IWEXT,IWINJ,ICBUND,IFORCE
      IMPLICIT  NONE
      INTEGER   ICOMP
      INTEGER   I,J,IW,ICTS,KK,II,JJ,N,IQ,IWELL
      REAL      CTEMP,TOTQ,TOTQC,Q,C,CEXT,CINJ,VOLAQU
C
C--ZERO OUT CUMULATIVE TERMS
      QCTS=0.0E0
      CCTS=0.0E0
C
C--ALL TREATMENT SYSTEMS
      DO ICTS=1,NCTS
C--FOR EXTRACTION WELLS - FILLING [A] AND [RHS] NOT NEEDED - THIS IS ALREADY DONE IN SSM
C--EXTRACTION WELLS NEEDED TO CALCULATE MASS/CONC COMING TO TREATMENT SYSTEMS
        TOTQ=0.0E0
        TOTQC=0.0E0
        DO I=1,NEXT(ICTS)
          KK=KEXT(I,ICTS)
          II=IEXT(I,ICTS)
          JJ=JEXT(I,ICTS)
          IW=IWEXT(I,ICTS)
C
C---------GET Q FROM SS ARRAY
          DO IWELL=1,MXSS
            IF(IW.EQ.SS(8,IWELL)) THEN
              IF(KK.NE.SS(1,IWELL) .OR.
     &           II.NE.SS(2,IWELL) .OR.
     &           JJ.NE.SS(3,IWELL)) THEN
                WRITE(IOUT,*) KK,II,JJ,IW
                WRITE(IOUT,*) 'MISMATCH IN CTS WELL AND WEL FILE'
                CALL USTOP(' ')
              ENDIF
C
              VOLAQU=DELR(JJ)*DELC(II)*DH(JJ,II,KK)
              IF(ABS(VOLAQU).LE.1.E-8) VOLAQU=1.E-8
              IF(ICBUND(JJ,II,KK,1).EQ.0.OR.VOLAQU.LE.0) THEN
                IF(DRYON) THEN
                  Q=SS(5,IWELL)*ABS(VOLAQU)
                ELSE
                  Q=0.
                ENDIF
              ELSE
                Q=SS(5,IWELL)*VOLAQU
              ENDIF
C              
              IQ=SS(6,IWELL)
              IF(Q.GT.0.0E0) THEN
                WRITE(IOUT,'(4I10)') KK,II,JJ,IW
                WRITE(IOUT,*) 'INPUT ERROR: EXTRACTION WELL IS EXPECTED'
                CALL USTOP(' ')
              ENDIF
              EXIT
            ENDIF
            IF(IWELL.EQ.MXSS) THEN
              WRITE(IOUT,'(4I10)') KK,II,JJ,IW
              WRITE(IOUT,*) 'WELL NOT FOUND'
              CALL USTOP(' ')
            ENDIF
          ENDDO
C
C--SKIP IF NOT ACTIVE CELL
          IF(ICBUND(JJ,II,KK,ICOMP).LE.0.OR.IQ.LE.0) THEN !EXTRACTION IS FORMULATED IN SSM PACKAGE
            IF(ICBUND(JJ,II,KK,ICOMP).EQ.0.AND.IQ.GT.0) THEN
              IF(DRYON) THEN
                Q=SS(5,IWELL)*DELR(JJ)*DELC(II)*ABS(DH(JJ,II,KK))
                TOTQ=TOTQ+Q 
              ENDIF
            ENDIF
          ELSE
            C=CNEW(JJ,II,KK,ICOMP)
            TOTQ=TOTQ+Q 
            TOTQC=TOTQC+(Q*C)
          ENDIF
        ENDDO
C--ADD EXTERNAL SOURCE
        TOTQ=TOTQ+(-QINCTS(ICTS))
        TOTQC=TOTQC+(-QINCTS(ICTS)*CINCTS(ICOMP,ICTS))
C--CALCULATE MIXED CONC IN CCTS
        IF(ABS(TOTQ).LT.1.0E-20) THEN
          WRITE(IOUT,*) '***WARNING: FLOW SET TO 1E-20 FOR CTS ',ICTS
          TOTQ=-1.0E-20
        ENDIF
        QCTS(ICTS)=TOTQ
        CCTS(ICOMP,ICTS)=TOTQC/TOTQ
C--APPLY TREATMENT TO INJECTION WELLS AND FILL MATRIX
        IF(ITRTINJ(ICTS).EQ.0) THEN               !NO TREATMENT
          CINJ=CCTS(ICOMP,ICTS)
        ELSEIF(ITRTINJ(ICTS).EQ.1) THEN           !SAME TREATMENT TO ALL
          IF(IOPTINJ(ICOMP,1,ICTS).EQ.1) THEN     !PERCENT REMOVAL/ADDITION
            CINJ=CCTS(ICOMP,ICTS)*(1.0E0+CMCHGINJ(ICOMP,1,ICTS))
          ELSEIF(IOPTINJ(ICOMP,1,ICTS).EQ.2) THEN !CONC REMOVAL/ADDITION
            CINJ=CCTS(ICOMP,ICTS)+CMCHGINJ(ICOMP,1,ICTS)
          ELSEIF(IOPTINJ(ICOMP,1,ICTS).EQ.3) THEN !MASS REMOVAL/ADDITION
            CTEMP=CCTS(ICOMP,ICTS)*(-QCTS(ICTS))+CMCHGINJ(ICOMP,1,ICTS)
            CINJ=CTEMP/(-QCTS(ICTS))
          ELSEIF(IOPTINJ(ICOMP,1,ICTS).EQ.4) THEN !SET CONC
            CINJ=CMCHGINJ(ICOMP,1,ICTS)
          ELSE
            WRITE(IOUT,*) 'IOPT MUST BE SET TO 1,2,3, OR 4'
            CALL USTOP(' ')
          ENDIF
          IF(CINJ.LE.0.0E0) CINJ=0.0E0
          IF(IFORCE.EQ.0) THEN
            IF(CCTS(ICOMP,ICTS).LT.CNTE(ICOMP,ICTS))THEN
              CINJ=CCTS(ICOMP,ICTS)
            ENDIF
          ENDIF
        ENDIF
        DO I=1,NINJ(ICTS)
          KK=KINJ(I,ICTS)
          II=IINJ(I,ICTS)
          JJ=JINJ(I,ICTS)
          IW=IWINJ(I,ICTS)
C
C---------GET Q FROM SS ARRAY
          DO IWELL=1,MXSS
            IF(IW.EQ.SS(8,IWELL)) THEN
              IF(KK.NE.SS(1,IWELL) .OR.
     &           II.NE.SS(2,IWELL) .OR.
     &           JJ.NE.SS(3,IWELL)) THEN
                WRITE(IOUT,*) KK,II,JJ,IW
                WRITE(IOUT,*) 'MISMATCH IN CTS WELL AND WEL FILE'
                CALL USTOP(' ')
              ENDIF
C
              VOLAQU=DELR(JJ)*DELC(II)*DH(JJ,II,KK)
              IF(ABS(VOLAQU).LE.1.E-8) VOLAQU=1.E-8
              IF(ICBUND(JJ,II,KK,1).EQ.0.OR.VOLAQU.LE.0) THEN
                IF(DRYON) THEN
                  Q=SS(5,IWELL)*ABS(VOLAQU)
                ELSE
                  Q=0.
                ENDIF
              ELSE
                Q=SS(5,IWELL)*VOLAQU
              ENDIF
C              
              IQ=SS(6,IWELL)
              IF(Q.LT.0.0E0) THEN
                WRITE(IOUT,'(4I10)') KK,II,JJ,IW
                WRITE(IOUT,*) 'INPUT ERROR: INJECTION WELL IS EXPECTED'
                CALL USTOP(' ')
              ENDIF
              EXIT
            ENDIF
            IF(IWELL.EQ.MXSS) THEN
              WRITE(IOUT,'(4I10)') KK,II,JJ,IW
              WRITE(IOUT,*) 'WELL NOT FOUND'
              CALL USTOP(' ')
            ENDIF
          ENDDO
C
          IF(ITRTINJ(ICTS).EQ.2) THEN               !SEPARATE TREATMENT TO EACH INJ WELL
            IF(IOPTINJ(ICOMP,I,ICTS).EQ.1) THEN     !PERCENT REMOVAL/ADDITION
              CINJ=CCTS(ICOMP,ICTS)*(1.0E0+CMCHGINJ(ICOMP,I,ICTS))
            ELSEIF(IOPTINJ(ICOMP,I,ICTS).EQ.2) THEN !CONC REMOVAL/ADDITION
              CINJ=CCTS(ICOMP,ICTS)+CMCHGINJ(ICOMP,I,ICTS)
            ELSEIF(IOPTINJ(ICOMP,I,ICTS).EQ.3) THEN !MASS REMOVAL/ADDITION
              IF(ABS(Q).LT.1.0E-20) THEN
                WRITE(IOUT,*) '***WARNING: FLOW SET TO 1E-20 FOR CTS',
     &            ICTS
                Q=1.0E-20
              ENDIF
              CTEMP=CCTS(ICOMP,ICTS)*(-Q)+CMCHGINJ(ICOMP,I,ICTS)
              CINJ=CTEMP/(-Q)
            ELSEIF(IOPTINJ(ICOMP,I,ICTS).EQ.4) THEN !SET CONC
              CINJ=CMCHGINJ(ICOMP,I,ICTS)
            ELSE
              WRITE(IOUT,*) 'IOPT MUST BE SET TO 1,2,3, OR 4'
              CALL USTOP(' ')
            ENDIF
            IF(CINJ.LE.0.0E0) CINJ=0.0E0
            IF(IFORCE.EQ.0) THEN
              IF(CCTS(ICOMP,ICTS).LT.CNTE(ICOMP,ICTS))THEN
                CINJ=CCTS(ICOMP,ICTS)
              ENDIF
            ENDIF
          ENDIF
C
C--SKIP IF NOT ACTIVE CELL
          IF(ICBUND(JJ,II,KK,ICOMP).LE.0.OR.IQ.LE.0) THEN
            IF(ICBUND(JJ,II,KK,ICOMP).EQ.0.AND.IQ.GT.0) THEN
              IF(DRYON) THEN
                Q=SS(5,IWELL)*DELR(JJ)*DELC(II)*ABS(DH(JJ,II,KK))
                IF(Q.LT.0) THEN
                  QC7(JJ,II,KK,9)=QC7(JJ,II,KK,9)-Q
                ELSE
                  QC7(JJ,II,KK,7)=QC7(JJ,II,KK,7)-Q*CINJ
                  QC7(JJ,II,KK,8)=QC7(JJ,II,KK,8)-Q
                ENDIF
              ENDIF
            ENDIF
          ELSE
C
C--ADD CONTRIBUTIONS TO MATRICES [A] AND [RHS]        
            N=(KK-1)*NCOL*NROW+(II-1)*NCOL+JJ
            IF(Q.LT.0) THEN
              IF(UPDLHS) A(N)=A(N)+Q 
            ELSE
              RHS(N)=RHS(N)-Q*CINJ 
            ENDIF        
          ENDIF
        ENDDO 
      ENDDO 
C
C--DONE WITH EULERIAN SCHEMES
      GOTO 2000
C
C--FORMULATE [A] AND [RHS] MATRICES FOR EULERIAN-LAGRANGIAN SCHEMES
 1000 CONTINUE
C*** NOT CODED FOR EULERIAN-LAGRANGIAN SCHEMES
C
C--DONE WITH EULERIAN-LAGRANGIAN SCHEMES
 2000 CONTINUE
C
C--RETURN
      RETURN
      END
C
C
      SUBROUTINE CTS1BD(KSTP,KPER,ICOMP,DTRANS,NTRANS)
C ********************************************************************
C THIS SUBROUTINE CALCULATES MASS BUDGETS ASSOCIATED WITH CTS TERMS.
C THIS ALSO WRITES BUDGETS FOR ALL TREATMENT SYSTEMS SIMULATED.
C ********************************************************************
C
      USE MIN_SAT, ONLY: QC7,DRYON
      USE MT3DMS_MODULE, ONLY: NCOL,NROW,NLAY,NCOMP,DELR,DELC,
     &                         DH,CNEW,ISS,NODES,MIXELM,SS,MXSS,NCTS,
     &                         KEXT,IEXT,JEXT,KINJ,IINJ,JINJ,IOPTEXT,
     &                         IOPTINJ,ITRTEXT,ITRTINJ,QINCTS,QOUTCTS,
     &                         CMCHGEXT,CMCHGINJ,NEXT,NINJ,CINCTS,CNTE,
     &                         MXEXT,MXINJ,MXCTS,RMASIO,QCTS,
     &                         CCTS,IWEXT,IWINJ,IOUT,ICBUND,
     &                         CEXT2CTS,CGW2CTS,CADDM,CCTS2EXT,
     &                         CCTS2GW,CREMM,ICTSOUT,IFORCE,PRTOUT
      IMPLICIT  NONE
      INTEGER   KPER,KSTP,ICOMP,ICTS,I,II,JJ,KK,IW,IWELL,IQ
      INTEGER   NTRANS
      REAL      DTRANS
      REAL      CTEMP,TOTQ,TOTQC,Q,C,CEXT,CINJ,Q1,Q2,COUTCTS
      REAL      EXT2CTS,GW2CTS,ADDM,CTS2EXT,CTS2GW,REMM
      REAL      CTOTINCTS,TOTINCTS,CTOTOUTCTS,TOTOUTCTS,CDIFF,
     &          DIFF,CPERC,PERC,VOLAQU
C
C--ZERO OUT ARRAYS
      QCTS=0.0E0
      CCTS=0.0E0
      Q1=0.0E0
      Q2=0.0E0
C
C--ZERO OUT OTHER VARIABLES
      IF(KPER.EQ.1 .AND. KSTP.EQ.1.AND.NTRANS.EQ.1) THEN
        CEXT2CTS(ICOMP)=0.0E0
        CGW2CTS(ICOMP)=0.0E0
        CADDM(ICOMP)=0.0E0
        CCTS2EXT(ICOMP)=0.0E0
        CCTS2GW(ICOMP)=0.0E0
        CREMM(ICOMP)=0.0E0
        EXT2CTS=0.0E0
        GW2CTS=0.0E0
        ADDM=0.0E0
        CTS2EXT=0.0E0
        CTS2GW=0.0E0
        REMM=0.0E0
      ELSE
        EXT2CTS=0.0E0
        GW2CTS=0.0E0
        ADDM=0.0E0
        CTS2EXT=0.0E0
        CTS2GW=0.0E0
        REMM=0.0E0
      ENDIF
C
C--WRITE HEADER TO ICTSOUT FILE
      IF(KPER.EQ.1 .AND. KSTP.EQ.1.AND.NTRANS.EQ.1.AND.ICTSOUT.GT.0)THEN
        WRITE(ICTSOUT,*) 
     &  ' WELL-BY-WELL BUDGET SUMMARY OF CONTAMINANT TREATMENT SYSTEMS'
        WRITE(ICTSOUT,5)
5       FORMAT('    STRESS      TSTP',
     &         ' TRAN-STEP       DELT          CTS#     IWELL',
     &         '     LAYER       ROW    COLUMN   SPECIES FLOW[L3/T] ',
     &         '    CONC[M/L3]    FLOW*CONC[M/T]',/,
     &         '    ------      ----',
     &         ' ---------       ----          ----     -----',
     &         '     -----       ---    ------   ------- ---------- ',
     &         '    ----------    -------------- ')
      ENDIF
C
C--EXTRACTION WELLS AND EXTERNAL SOURCE FEEDING A TREATMENT SYSTEM
      DO ICTS=1,NCTS
        TOTQ=0.0E0
        TOTQC=0.0E0
        DO I=1,NEXT(ICTS)
          KK=KEXT(I,ICTS)
          II=IEXT(I,ICTS)
          JJ=JEXT(I,ICTS)
          IW=IWEXT(I,ICTS)
C
C---------GET Q FROM SS ARRAY
          DO IWELL=1,MXSS
            IF(IW.EQ.SS(8,IWELL)) THEN
              IF(KK.NE.SS(1,IWELL) .OR.
     &           II.NE.SS(2,IWELL) .OR.
     &           JJ.NE.SS(3,IWELL)) THEN
                WRITE(IOUT,*) KK,II,JJ,IW
                WRITE(IOUT,*) 'MISMATCH IN CTS WELL AND WEL FILE'
                CALL USTOP(' ')
              ENDIF
C
              VOLAQU=DELR(JJ)*DELC(II)*DH(JJ,II,KK)
              IF(ABS(VOLAQU).LE.1.E-8) VOLAQU=1.E-8
              IF(ICBUND(JJ,II,KK,1).EQ.0.OR.VOLAQU.LE.0) THEN
                IF(DRYON) THEN
                  Q=SS(5,IWELL)*ABS(VOLAQU)
                ELSE
                  Q=0.
                ENDIF
              ELSE
                Q=SS(5,IWELL)*VOLAQU
              ENDIF
C              
              IQ=SS(6,IWELL)
              IF(Q.GT.0.0E0) THEN
                WRITE(IOUT,'(4I10)') KK,II,JJ,IW
                WRITE(IOUT,*) 'INPUT ERROR: EXTRACTION WELL IS EXPECTED'
                CALL USTOP(' ')
              ENDIF
              EXIT
            ENDIF
            IF(IWELL.EQ.MXSS) THEN
              WRITE(IOUT,'(4I10)') KK,II,JJ,IW
              WRITE(IOUT,*) 'WELL NOT FOUND'
              CALL USTOP(' ')
            ENDIF
          ENDDO
C
C--SKIP IF NOT ACTIVE CELL
          IF(ICBUND(JJ,II,KK,ICOMP).LE.0.OR.IQ.LE.0) THEN
            IF(ICBUND(JJ,II,KK,ICOMP).EQ.0.AND.IQ.GT.0) THEN
              IF(DRYON) THEN
                C=0.
                Q=SS(5,IWELL)*DELR(JJ)*DELC(II)*ABS(DH(JJ,II,KK))
                TOTQ=TOTQ+Q
                QC7(JJ,II,KK,9)=QC7(JJ,II,KK,9)-Q
                IF (ICTSOUT.GT.0) WRITE(ICTSOUT,7) KPER,KSTP,NTRANS,
     &          DTRANS,ICTS,IW,KK,II,JJ,ICOMP,Q,C,Q*C
              ENDIF
            ENDIF
          ELSE
C
            C=CNEW(JJ,II,KK,ICOMP)
            TOTQ=TOTQ+Q 
            TOTQC=TOTQC+(Q*C)
            GW2CTS=GW2CTS+(Q*C)
C
C--IN FM FORMULATION IS DONE IN SSM; IN BD BUDGET IS DONE HERE
            RMASIO(11,2,ICOMP)=RMASIO(11,2,ICOMP)+Q*C*DTRANS
            IF (ICTSOUT.GT.0) WRITE(ICTSOUT,7) KPER,KSTP,NTRANS,DTRANS,
     &                                    ICTS,IW,KK,II,JJ,ICOMP,Q,C,Q*C
C
          ENDIF
        ENDDO
C--ADD EXTERNAL SOURCE
        TOTQ=TOTQ+(-QINCTS(ICTS))
        TOTQC=TOTQC+(-QINCTS(ICTS)*CINCTS(ICOMP,ICTS))
        Q1=Q1+TOTQ
        EXT2CTS=EXT2CTS+(-QINCTS(ICTS)*CINCTS(ICOMP,ICTS))
        IF (ICTSOUT.GT.0) WRITE(ICTSOUT,7) KPER,KSTP,NTRANS,DTRANS,
     &                                ICTS,0,0,0,0,ICOMP,-QINCTS(ICTS),
     &                                CINCTS(ICOMP,ICTS),
     &                                (-QINCTS(ICTS)*CINCTS(ICOMP,ICTS))
C--CALCULATE MIXED CONC IN CTS
        IF(ABS(TOTQ).LT.1.0E-20) THEN
          WRITE(IOUT,*) '***WARNING: FLOW SET TO 1E-20 FOR CTS ',ICTS
          TOTQ=-1.0E-20
        ENDIF
        QCTS(ICTS)=TOTQ
        CCTS(ICOMP,ICTS)=TOTQC/TOTQ
C--APPLY TREATMENT TO INJECTION WELLS AND FILL MATRIX
        IF(ITRTINJ(ICTS).EQ.0) THEN               !NO TREATMENT
          CINJ=CCTS(ICOMP,ICTS)
        ELSEIF(ITRTINJ(ICTS).EQ.1) THEN           !SAME TREATMENT TO ALL
          IF(IOPTINJ(ICOMP,1,ICTS).EQ.1) THEN     !PERCENT REMOVAL/ADDITION
            CINJ=CCTS(ICOMP,ICTS)*(1.0E0+CMCHGINJ(ICOMP,1,ICTS))
          ELSEIF(IOPTINJ(ICOMP,1,ICTS).EQ.2) THEN !CONC REMOVAL/ADDITION
            CINJ=CCTS(ICOMP,ICTS)+CMCHGINJ(ICOMP,1,ICTS)
          ELSEIF(IOPTINJ(ICOMP,1,ICTS).EQ.3) THEN !MASS REMOVAL/ADDITION
            CTEMP=CCTS(ICOMP,ICTS)*(-QCTS(ICTS))+CMCHGINJ(ICOMP,1,ICTS)
            CINJ=CTEMP/(-QCTS(ICTS))
          ELSEIF(IOPTINJ(ICOMP,1,ICTS).EQ.4) THEN !SET CONC
            CINJ=CMCHGINJ(ICOMP,1,ICTS)
          ENDIF
          IF(CINJ.LE.0.0E0) CINJ=0.0E0
          IF(IFORCE.EQ.0) THEN
            IF(CCTS(ICOMP,ICTS).LT.CNTE(ICOMP,ICTS))THEN
              CINJ=CCTS(ICOMP,ICTS)
            ENDIF
          ENDIF
        ENDIF
        DO I=1,NINJ(ICTS)
          KK=KINJ(I,ICTS)
          II=IINJ(I,ICTS)
          JJ=JINJ(I,ICTS)
          IW=IWINJ(I,ICTS)
C
C---------GET Q FROM SS ARRAY
          DO IWELL=1,MXSS
            IF(IW.EQ.SS(8,IWELL)) THEN
              IF(KK.NE.SS(1,IWELL) .OR.
     &           II.NE.SS(2,IWELL) .OR.
     &           JJ.NE.SS(3,IWELL)) THEN
                WRITE(IOUT,*) KK,II,JJ,IW
                WRITE(IOUT,*) 'MISMATCH IN CTS WELL AND WEL FILE'
                CALL USTOP(' ')
              ENDIF
C
              VOLAQU=DELR(JJ)*DELC(II)*DH(JJ,II,KK)
              IF(ABS(VOLAQU).LE.1.E-8) VOLAQU=1.E-8
              IF(ICBUND(JJ,II,KK,1).EQ.0.OR.VOLAQU.LE.0) THEN
                IF(DRYON) THEN
                  Q=SS(5,IWELL)*ABS(VOLAQU)
                ELSE
                  Q=0.
                ENDIF
              ELSE
                Q=SS(5,IWELL)*VOLAQU
              ENDIF
C              
              IQ=SS(6,IWELL)
              IF(Q.LT.0.0E0) THEN
                WRITE(IOUT,'(4I10)') KK,II,JJ,IW
                WRITE(IOUT,*) 'INPUT ERROR: INJECTION WELL IS EXPECTED'
                CALL USTOP(' ')
              ENDIF
              EXIT
            ENDIF
            IF(IWELL.EQ.MXSS) THEN
              WRITE(IOUT,'(4I10)') KK,II,JJ,IW
              WRITE(IOUT,*) 'WELL NOT FOUND'
              CALL USTOP(' ')
            ENDIF
          ENDDO
C
C
          IF(ITRTINJ(ICTS).EQ.2) THEN               !SEPARATE TREATMENT TO EACH INJ WELL
            IF(IOPTINJ(ICOMP,I,ICTS).EQ.1) THEN     !PERCENT REMOVAL/ADDITION
              CINJ=CCTS(ICOMP,ICTS)*(1.0E0+CMCHGINJ(ICOMP,I,ICTS))
            ELSEIF(IOPTINJ(ICOMP,I,ICTS).EQ.2) THEN !CONC REMOVAL/ADDITION
              CINJ=CCTS(ICOMP,ICTS)+CMCHGINJ(ICOMP,I,ICTS)
            ELSEIF(IOPTINJ(ICOMP,I,ICTS).EQ.3) THEN !MASS REMOVAL/ADDITION
              IF(ABS(Q).LT.1.0E-20) THEN
                WRITE(IOUT,*) '***WARNING: FLOW SET TO 1E-20 FOR CTS',
     &                        ICTS
                Q=1.0E-20
              ENDIF
              CTEMP=CCTS(ICOMP,ICTS)*(-Q)+CMCHGINJ(ICOMP,I,ICTS)
              CINJ=CTEMP/(-Q)
            ELSEIF(IOPTINJ(ICOMP,I,ICTS).EQ.4) THEN !SET CONC
              CINJ=CMCHGINJ(ICOMP,I,ICTS)
            ENDIF
            IF(CINJ.LE.0.0E0) CINJ=0.0E0
            IF(IFORCE.EQ.0) THEN
              IF(CCTS(ICOMP,ICTS).LT.CNTE(ICOMP,ICTS))THEN
                CINJ=CCTS(ICOMP,ICTS)
              ENDIF
            ENDIF
          ENDIF
C
C--SKIP IF NOT ACTIVE CELL
          IF(ICBUND(JJ,II,KK,ICOMP).LE.0.OR.IQ.LE.0) THEN
            IF(ICBUND(JJ,II,KK,ICOMP).EQ.0.AND.IQ.GT.0) THEN
              IF(DRYON) THEN
                Q=SS(5,IWELL)*DELR(JJ)*DELC(II)*ABS(DH(JJ,II,KK))
                Q2=Q2+Q
                CTS2GW=CTS2GW+Q*CINJ
                IF((Q*CINJ).GE.(Q*CCTS(ICOMP,ICTS)-1.0E-10)) THEN
                  ADDM=ADDM+(Q*CINJ)-(Q*CCTS(ICOMP,ICTS))
                ELSE
                  REMM=REMM+(Q*CCTS(ICOMP,ICTS))-(Q*CINJ)
                ENDIF
                RMASIO(11,1,ICOMP)=RMASIO(11,1,ICOMP)+Q*CINJ*DTRANS
                IF (ICTSOUT.GT.0) WRITE(ICTSOUT,7) KPER,KSTP,NTRANS,
     &                            DTRANS,ICTS,IW,KK,II,JJ,ICOMP,Q,
     &                            CINJ,Q*CINJ
C
                QC7(JJ,II,KK,7)=QC7(JJ,II,KK,7)-Q*CINJ
                QC7(JJ,II,KK,8)=QC7(JJ,II,KK,8)-Q
              ENDIF
            ENDIF
          ELSE
C
          Q2=Q2+Q
          CTS2GW=CTS2GW+Q*CINJ
          IF((Q*CINJ).GE.(Q*CCTS(ICOMP,ICTS)-1.0E-10)) THEN
            ADDM=ADDM+(Q*CINJ)-(Q*CCTS(ICOMP,ICTS))
          ELSE
            REMM=REMM+(Q*CCTS(ICOMP,ICTS))-(Q*CINJ)
          ENDIF
C
          RMASIO(11,1,ICOMP)=RMASIO(11,1,ICOMP)+Q*CINJ*DTRANS
C
          IF (ICTSOUT.GT.0) WRITE(ICTSOUT,7) KPER,KSTP,NTRANS,DTRANS,
     &                      ICTS,IW,KK,II,JJ,ICOMP,Q,CINJ,Q*CINJ
          ENDIF
C
        ENDDO 
        Q2=Q2+QOUTCTS(ICTS)
        IF(ITRTINJ(ICTS).EQ.0.OR.ITRTINJ(ICTS).EQ.1) THEN
          COUTCTS=CINJ
        ELSEIF(ITRTINJ(ICTS).EQ.2) THEN
          COUTCTS=CCTS(ICOMP,ICTS)
        ENDIF
        CTS2EXT=CTS2EXT+QOUTCTS(ICTS)*COUTCTS
        IF (ICTSOUT.GT.0) WRITE(ICTSOUT,7) KPER,KSTP,NTRANS,DTRANS,
     &                    ICTS,0,0,0,0,ICOMP,QOUTCTS(ICTS),COUTCTS,
     &                    QOUTCTS(ICTS)*COUTCTS
      ENDDO
C
C
      CEXT2CTS((ICOMP))=CEXT2CTS(ICOMP)-EXT2CTS*DTRANS
      CGW2CTS(ICOMP)=CGW2CTS(ICOMP)-GW2CTS*DTRANS
      CADDM(ICOMP)=CADDM(ICOMP)+ADDM*DTRANS
      CCTS2EXT(ICOMP)=CCTS2EXT(ICOMP)+CTS2EXT*DTRANS
      CCTS2GW(ICOMP)=CCTS2GW(ICOMP)+CTS2GW*DTRANS
      CREMM(ICOMP)=CREMM(ICOMP)+REMM*DTRANS
C
      TOTINCTS=-EXT2CTS-GW2CTS+ADDM
      CTOTINCTS=CEXT2CTS(ICOMP)+CGW2CTS(ICOMP)+CADDM(ICOMP)
      TOTOUTCTS=CTS2EXT+CTS2GW+REMM
      CTOTOUTCTS=CCTS2EXT(ICOMP)+CCTS2GW(ICOMP)+CREMM(ICOMP)
C
      DIFF=TOTINCTS-TOTOUTCTS
      CDIFF=CTOTINCTS-CTOTOUTCTS
      IF(TOTINCTS+TOTOUTCTS.LE.1.0E-10) TOTINCTS=1.0E-10
      PERC=DIFF*100/((TOTINCTS+TOTOUTCTS)/2.0E0)
      IF(CTOTINCTS+CTOTOUTCTS.LE.1.0E-10) CTOTINCTS=1.0E-10
      CPERC=CDIFF*100/((CTOTINCTS+CTOTOUTCTS)/2.0E0)
C
C--WRITE CTS MASS BALANCE TO OUTPUT FILE
      IF(PRTOUT) THEN
        WRITE(IOUT,10) NTRANS,KSTP,KPER,ICOMP
        WRITE(IOUT,20) 
        WRITE(IOUT,30) CEXT2CTS(ICOMP),-EXT2CTS
        WRITE(IOUT,35) CGW2CTS(ICOMP),-GW2CTS
        WRITE(IOUT,40) CADDM(ICOMP),ADDM
        WRITE(IOUT,43)
        WRITE(IOUT,45) CTOTINCTS,TOTINCTS
        WRITE(IOUT,50) CCTS2EXT(ICOMP),CTS2EXT
        WRITE(IOUT,55) CCTS2GW(ICOMP),CTS2GW
        WRITE(IOUT,60) CREMM(ICOMP),REMM
        WRITE(IOUT,43)
        WRITE(IOUT,65) CTOTOUTCTS,TOTOUTCTS
        WRITE(IOUT,70) CDIFF,DIFF
        WRITE(IOUT,75) CPERC,PERC
        WRITE(IOUT,80) (-Q1-Q2)
      ENDIF
7     FORMAT(3I10,1X,G14.7,6I10,3(1X,G14.7))
10    FORMAT(//21X,'OVERALL CTS MASS BUDGETS AT END OF TRANSPORT STEP',
     & I5,', TIME STEP',I5,', STRESS PERIOD',I5,' FOR COMPONENT',I4,
     & /21X,108('-'))
20    FORMAT(/33X,7X,1X,'CUMULATIVE MASS [M]',
     &       8X,13X,15X,'RATES FOR THIS TIME STEP [M/T]',
     &       /41X,19('-'),36X,16('-'))
30    FORMAT(16X,'EXTERNAL SOURCE TO CTS =',G15.7,
     &       16X,'EXTERNAL SOURCE TO CTS =',G15.7)
35    FORMAT(16X,'    GROUNDWATER TO CTS =',G15.7,
     &       16X,'    GROUNDWATER TO CTS =',G15.7)
40    FORMAT(16X,'    CONC/MASS ADDITION =',G15.7,
     &       16X,'    CONC/MASS ADDITION =',G15.7)
43    FORMAT(41X,19('-'),36X,16('-'))
45    FORMAT(16X,'              TOTAL IN =',G15.7,
     &       16X,'              TOTAL IN =',G15.7)
50    FORMAT(/16X,'  CTS TO EXTERNAL SINK =',G15.7,
     &        16X,'  CTS TO EXTERNAL SINK =',G15.7)
55    FORMAT(16X,'    CTS TO GROUNDWATER =',G15.7,
     &       16X,'    CTS TO GROUNDWATER =',G15.7)
60    FORMAT(16X,'     CONC/MASS REMOVAL =',G15.7,
     &       16X,'     CONC/MASS REMOVAL =',G15.7)
65    FORMAT(16X,'             TOTAL OUT =',G15.7,
     &       16X,'             TOTAL OUT =',G15.7)
70    FORMAT(/16X,'        NET (IN - OUT) =',G15.7,
     &        16X,'        NET (IN - OUT) =',G15.7)
75    FORMAT(16X,' DISCREPANCY (PERCENT) =',G15.7,
     &       16X,' DISCREPANCY (PERCENT) =',G15.7)
80    FORMAT(46X,'   NET FLOW (IN - OUT) =',G15.7,' [L3/T]',/)
C
C--RETURN
      RETURN
      END
