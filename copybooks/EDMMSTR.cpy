      *=================================================================*
      * EDMMSTR - EDM Master Customer Record Layout                   *
      * Used by: EDMMST, EDMORD, EDMSEC, EDMARC transactions          *
      * Episode 3+ - EDM CICS Tutorial Series                         *
      *=================================================================*
       01  EDM-MASTER-RECORD.
      *    -- Primary key (KSDS key field, 8 bytes, leftmost position)
           05  EDM-CLIENT-ID        PIC X(8).
      *    -- Client classification
           05  EDM-CLIENT-TYPE      PIC X(1).
      *        A = Acquisition Specialist
      *        C = Corporate Account
      *        G = Government Liaison
      *        R = Research Division
           05  EDM-ANNOYANCE-RANK   PIC 9(2).
      *        00 = New/Unrated, 01-05 = Compliant, 06-09 = Monitored
      *        10+ = Flagged (see EDMSEC for escalation procedures)
      *    -- Name and contact
           05  EDM-CLIENT-NAME.
               10  EDM-LAST-NAME    PIC X(20).
               10  EDM-FIRST-NAME   PIC X(15).
               10  EDM-TITLE        PIC X(4).
           05  EDM-DEPARTMENT       PIC X(20).
           05  EDM-LOCATION         PIC X(3).
      *        ALB = Albany, SYR = Syracuse, NYC = New York City
      *        RMT = Remote (requires additional verification)
      *    -- Status and dates
           05  EDM-STATUS           PIC X(1).
      *        A = Active, S = Suspended, T = Terminated, P = Pending
           05  EDM-CREATED-DATE     PIC 9(8).
      *        Format: YYYYMMDD
           05  EDM-LAST-ACTIVITY    PIC 9(8).
      *        Format: YYYYMMDD
           05  EDM-LAST-MODIFIED    PIC 9(8).
      *        Format: YYYYMMDD
      *    -- Asset holdings (summary — detail in EDMINV)
           05  EDM-ASSET-COUNT      PIC 9(5).
           05  EDM-ASSET-VALUE      PIC 9(11)V99.
      *    -- Internal flags
           05  EDM-FLAGS.
               10  EDM-FLAG-AUDIT   PIC X(1).
      *            Y = Under audit review
               10  EDM-FLAG-HOLD    PIC X(1).
      *            Y = Account on hold
               10  EDM-FLAG-VIP     PIC X(1).
      *            Y = VIP (CEO contact — do not adjust Annoyance Rank)
               10  FILLER           PIC X(5).
      *    -- Record padding to 128 bytes
           05  FILLER               PIC X(3).
      *
      *  TOTAL RECORD LENGTH: 128 BYTES
