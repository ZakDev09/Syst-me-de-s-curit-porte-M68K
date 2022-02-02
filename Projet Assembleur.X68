*-----------------------------------------------------------
* Title      : Door's Security System
* Written by : Zakaria Ziani + Imane ElMaksour + Mounim Saadioui + Salma Garmouti
* Date       :
* Description: 
*-----------------------------------------------------------
NOON	EQU	12*60*60*100	noon in 100's of a second

* Delay for hundredths of a second in param 1
DELAY	MACRO
	move.b	#23,d0			trap task 23
	move.l	#\1,d1			delay amount
	trap	#15
	ENDM
	
	
    ORG    $1000
START:
   
    MOVE.L  #VALIDCODE,$07C         INTERRUPTION 7 USED ONLY BY SECURITY (1st from left)
    MOVE.L  #CHECK_OUT,$064         INTERRUPTION 1 USED TO START THE CHECK-OUT WITH CODE (1st from right)


	MOVE.B	#32,D0	 
	MOVE.B	#0,D1    
	TRAP	#15	     HARDWARE WINDOW DISPLAYED
	
	MOVE.B	#1,D1    
	TRAP	#15	     
	MOVE.L	D1,A4	 A4 = ADDRESS OF 7-SEGMENT DISPLAY 
	
	
	MOVE.B	#2,D1    
	TRAP	#15	     
	MOVE.L	D1,A3	 A3 = ADDRESS OF LEDS
	
	
	
    
	
*--------------------------------------MAIN PROGRAM-------------------------------
    LEA PILE(PC),A7


MAIN
    MOVE #00,(A3)   LEDS OFF
    


*--------------------------------------TIME DISPLAYING----------------------------


CLOCK
    MOVE.B (A6),D2

REALTIME
	MOVE.L	A4,A2
	REPEAT
		MOVE.B	#8,D0			READ TIMER, GET 100THS OF A SECOND SINCE MIDNIGHT IN D1.L
	  	TRAP	#15
		IF.L D1 <HS> #NOON THEN.S
			SUB.L #NOON,D1		TIME = TIME - NOON
		ENDI
		* CALCULATE TOTAL MINUTES (D5), MINUTES THIS HOUR (D6), SECONDS (D7)
		DIVU	#100,D1			CONVERT TO SECONDS
		MOVE.L	D1,D4			SAVE FRACTIONAL SECONDS
		ANDI.L	#$0000FFFF,D1	DISCARD FRACTIONAL SECONDS
		DIVU	#60,D1			CONVERT TO MINUTES
		MOVE.L	D1,D7
		MOVE.L	#16,D0	
		LSR.L	D0,D7			D7 = SECONDS
		ANDI.L	#$0000FFFF,D1	DISCARD SECONDS FROM D1
		MOVE.L	D1,D5			D5 = TOTAL MINUTES
		DIVU	#60,D1			CONVERT TO HOURS
		MOVE.L	D1,D6
		MOVE.L	#16,D0
		LSR.L	D0,D6			MINUTES THIS HOUR TO D6

		DELAY	1				1/100 SEC DELAY TO REDUCE CPU WORKLOAD
	UNTIL.W D7 <NE> SECONDS	DO	UNTIL A SECOND HAS ELAPSED

* UPDATE THE DISPLAY ON THE 7-SEGMENT READOUTS

* DISPLAY HOUR AS DIGITS
	DIVU	#60,D5			HOURS AS 1-11 WITH 0 FOR 12
	IF.W D5 <EQ> #0 THEN.S	IF HOURS = 0
		MOVE.W	#12,D5		HOURS AS 1-12
	ENDI
	MOVE.B	#10,D3			BLANK DIGIT CODE
	IF.B D5 <HI> #9 THEN.S	IF HOURS > 9
		SUB	#10,D5		
		MOVE.B	#1,D3		DISPLAY A 1
	ENDI
	BSR	SEGMENT7			HOUR 10S DIGIT
	MOVE.W	D5,D3
	BSR	SEGMENT7			HOUR 1S DIGIT

* DASH AFTER HOURS
	MOVE.B	#11,D3			DASH DIGIT CODE
	BSR	SEGMENT7			DISPLAY DASH

* DISPLAY MINUTES AS DIGITS
	MOVE.B	D6,D0
	BSR	HEX2BCD
	MOVE.B	#0,D3			0 DIGIT CODE
	IF.B D0 <HI> #9 THEN.S	IF MINUTES > 9
		MOVE.B	D0,D3
		LSR.B	#4,D3		10'S MINUTE DIGIT
	ENDI
	BSR	SEGMENT7
	MOVE.B	D0,D3
	AND.B	#$F,D3			1'S MINUTE DIGIT
	BSR	SEGMENT7

* DASH AFTER MINUTES
	MOVE.B	#11,D3			DASH DIGIT CODE
	BSR	SEGMENT7			DISPLAY DASH

* DISPLAY SECONDS AS DIGITS
	MOVE.W	D7,SECONDS		SAVE SECONDS
	MOVE.W	D7,D0
	BSR	HEX2BCD
	MOVE.B	#0,D3			0 DIGIT CODE
	IF.B D0 <HI> #9 THEN.S
		MOVE.B	D0,D3
		LSR.B	#4,D3		10'S SECONDS DIGIT
	ENDI
	BSR	SEGMENT7
	MOVE.B	D0,D3
	AND.B	#$F,D3			1'S SECOND DIGIT
	BSR	SEGMENT7
    
    CMP.B (A6),D2
    BEQ REALTIME
    
    
    RTS
    
    
    
*-----------------------------------
* Convert 2 digit Hex to 2 digit BCD
* Pre:  D0.B 2 digit Hex
* Post: D0.B 2 digit BCD
Hex2BCD:
	movem.l	d1,-(a7)		save registers
	clr	d1
	and.l	#$00FF,d0
	divu	#10,d0
	move.l	d0,d1
	asl.w	#4,d0			shift tens to proper location
	swap	d1				put units in proper location
	or.b	d1,d0			combine units with tens
	movem.l	(a7)+,d1		restore registers
	rts








*-------------------------------------CHECK_OUT-----------------------------------
CHECK_OUT

    MOVE.L  STORAGE(PC),A0
    MOVE #3,D6

REPEAT    
*Will repeat the message of putting a code until the user is wrong 3 times or it's valid  
    LEA ENTREZ(PC),A1
    MOVE #14,D0
    TRAP #15
    
    MOVE.L D6,D1
    MOVE #3,D0
    TRAP #15
    
    LEA TENTATIVES(PC),A1
    MOVE #14,D0
    TRAP #15
   
    CLR D7
    BSR USER
    
    LEA ACCES_LIST(PC),A5
    MOVE.L STORAGE(PC),A0

    BSR COMPARE
    
    MOVE #14,D0
    TRAP #15
    
    SIMHALT          
    
 
USER   
        MOVE #5,D0
        TRAP #15
        MOVE.B D1,(A0)+
        ADDQ #1,D7
        CMP.B #4,D7
        BNE USER
        RTS
        
        

COMPARE 
        MOVE.L (A5)+,D4
        MOVE.L (A0),D3
        CMP.L D4,D3
        BEQ VALIDCODE
        CMP.B #0,(A5)
        BEQ WRONGCODE
        BNE COMPARE
        
        

WRONGCODE 
        SUBQ #1,D6
        CMP #0,D6
        BNE REPEAT            In case we still not in the 3rd attempts failed, we'll repeat
        BSR CLOSE             Else, CLOSEd is displayed
        BSR SECONDS_3         for 3 seconds !
        BSR MAIN


VALIDCODE 
        BSR OPEN             In case it's a valid code, OPEn is displayed
        

PUSHTHEDOOR   *------------------Verify is switch 0 is ON (door pushed) before starting the 5sec counter------------*
     
        MOVE.B  #32,D0
        MOVE.B  #3,D1
	    TRAP    #15
	    MOVE.L  D1,A6        A6 = ADRESS OF SWITCH
        CMP.B #1,(A6)
        BNE PUSHTHEDOOR
        
        BSR SECONDS_5       5 seconds starts !
        BSR MAIN
      
      



*------------Display OPEn in Segment7----------
OPEN    
        MOVE.L A4,A2 (SEGMENT7 ADRESS)

        MOVE.B	#20,D3	  		
	    BSR	SEGMENT7
	
	    MOVE.B	#21,D3			
	    BSR	SEGMENT7
	
	    MOVE.B	#14,D3	 		
	    BSR	SEGMENT7
	
	    MOVE.B	#18,D3			
	    BSR	SEGMENT7

	    MOVE.B	#10,D3			
	    BSR	SEGMENT7

	    MOVE.B	#10,D3			
	    BSR	SEGMENT7

	    MOVE.B	#10,D3		
	    BSR	SEGMENT7    

	    MOVE.B	#10,D3			
	    BSR	SEGMENT7
	    
	    MOVE.B #3,(A3)          2 LEDS RIGHT 
        
  	    RTS
*------------Display CLOSEd in Segment7----------
CLOSE   
        MOVE.L A4,A2 (SEGMENT7 ADRESS)

        MOVE.B	#13,D3	  		    
        BSR	SEGMENT7
	
	    MOVE.B	#17,D3			
	    BSR	SEGMENT7
	
	    MOVE.B	#20,D3	 		
	    BSR	SEGMENT7
	
	    MOVE.B	#23,D3			
	    BSR	SEGMENT7

	    MOVE.B	#14,D3			
	    BSR	SEGMENT7

	    MOVE.B	#26,D3			
	    BSR	SEGMENT7

	    MOVE.B	#10,D3			
	    BSR	SEGMENT7

	    MOVE.B	#10,D3			
	    BSR	SEGMENT7
        
        MOVE.B #192,(A3)         2 LEDS LEFT
        
        RTS
        
        
*-----------------Display Alarm in Segment7 + Alarm Sound--------------
ALARM 
        MOVE.L A4,A2 (adress of segment7)
        MOVE.B	#12,D3	  		
	    BSR	SEGMENT7
	    MOVE.B	#17,D3			
	    BSR	SEGMENT7
	
	    MOVE.B	#12,D3	 		
	    BSR	SEGMENT7
	
	    MOVE.B	#22,D3			
	    BSR	SEGMENT7

	    MOVE.B	#18,D3			
	    BSR	SEGMENT7

	    MOVE.B	#18,D3			
	    BSR	SEGMENT7

	    MOVE.B	#10,D3			
	    BSR	SEGMENT7

	    MOVE.B	#10,D3			
	    BSR	SEGMENT7
      
        MOVE.B #24,(A3)          2 LEDS IN MIDDLE
      

ALARM_SOUND 
        LEA AlarmSound(PC),A1
        MOVE #70,D0
        TRAP #15
      
        CMP.B #01,(A6)
        BEQ ALARM_SOUND
        RTS
        



	
*----------5seconds(for OPEn) + 3 seconds(for CLOSEd) timers------------------
SECONDS_5
        MOVE.L A4,A2
        ADD #14,A2
        MOVE.B	#5,D3		
	    BSR	SEGMENT7
	    BSR SECOND_1
	   
	    MOVE.L A4,A2
	    ADD #14,A2
	    MOVE.B	#4,D3			
	    BSR	SEGMENT7
	    BSR SECOND_1
	   
SECONDS_3
       MOVE.L A4,A2    
	   ADD #14,A2
	   MOVE.B	#3,D3			
	   BSR	SEGMENT7
	   BSR SECOND_1
	   
	   MOVE.L A4,A2
	   ADD #14,A2
	   MOVE.B	#2,D3			
	   BSR	SEGMENT7
	   BSR SECOND_1
	   
	   MOVE.L A4,A2
	   ADD #14,A2
	   MOVE.B	#1,D3		
	   BSR	SEGMENT7
	   BSR SECOND_1
	   
	   MOVE.L A4,A2
	   ADD #14,A2
	   MOVE.B	#0,D3		
	   BSR	SEGMENT7
	   BSR SECOND_1
	   
	   
	   MOVE.B  #32,D0
       MOVE.B  #3,D1
	   TRAP    #15
	   MOVE.L  D1,A6        A6 = ADRESS OF SWITCH
       CMP.B #1,(A6)
       BEQ ALARM

	   
       RTS
        



*---------1 second (WE NEED FINAL_TIME - INITIAL_TIME = 100ms)------------
SECOND_1  
        CLR.L D1
        CLR.L D0
        CLR.L D2
        MOVE #8,D0
        TRAP #15
    
        MOVE.L D1,D2
        ADD.L #100,D2       D2=100ms + INITIAL_TIME
    
BCL     
        MOVE #8,D0          WE'LL REPEAT UNTIL D1 (FINAL TIME) = D2
        TRAP #15    
        CMP.L D1,D2
        BNE BCL
        
        RTS





             
*------------------------------------
SEGMENT7: 
    MOVEM.L D3/A0,-(A7)     SAVE REGISTERS 
    LEA     digits,A0       STARTING ADDRESS OF BIT PATTERN ARRAY TABLE NOW IN A0 
    AND.L   #$00FF,D3       WE FORCE THE TOP 8 BITS OF D3 TO 0 BY ANDING WITH #$00FF
    MOVE.B  (A0,D3),(A2)    DISPLAY DIGIT BY PLACING IN A2 THE CONTENTS OF A0 POSITION VALUE IN D3 E.G (DIGITS,POS 12)
    ADDA.L  #2,A2 
    MOVEM.L (A7)+,D3/A0     RESTORE REGISTERS 
    RTS  



    
    

digits:*---------------We gonna use this digits label as an array of the needed digits (each digit has his own index)----------

************numbers***************    
    dc.b  $3F           0
    dc.b  $06           1
    dc.b  $5B           2
    dc.b  $4F           3
    dc.b  $66           4
    dc.b  $6D           5
    dc.b  $7D           6
    dc.b  $07           7
    dc.b  $7F           8
    dc.b  $6F           9
    

***********none+underscore**************    
    dc.b  $00           none
    dc.b  $40           underscore
    
    
    
***********needed letters***************    
    dc.b  $77		    A
    dc.b  $39		    C
    dc.b  $79           E
    dc.b  $76           H
    dc.b  $10		    i
    dc.b  $38           L
    dc.b  $54		    n
    dc.b  $5C           o
    dc.b  $3F		    O
    dc.b  $73		    P
    dc.b  $50		    r
    dc.b  $6D		    S
    dc.b  $70		    t
    dc.b  $1C		    u
    dc.b  $5E		    d

    ds.w  0             END OF DIGITS ARRAY



* variables

    DS 100
PILE            DS 1
STORAGE         DC.L $0FF7000
ACCES_LIST      DC.B '0000','1111','2222',0
ENTREZ          DC.B $D,$A,'Enter the valid code (',0
TENTATIVES      DC.B ' ATTEMPS REMAINING): ',0
seconds	        ds.w	1
AlarmSound      DC.B 'alert3.wav',0



    END    START        

















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
