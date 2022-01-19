*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG	$1000

START 
            LEA     $FFFFFE,A7
            MOVE.L  #FaireOpen,$064
            MOVE.L  #FaireClose,$068
            MOVE.B  #32,D0
            MOVE.B  #00,D1 
            TRAP    #15
BCL     NOP
        BRA BCL 

        
        SIMHALT
            
FaireClose
            LEA CLOSE(PC),A3
            LEA $E000BE,A4
            BRA BoucleClose
            RTE
            

BoucleClose        
            MOVE.L  (A3)+,(A4)+
            CMP.L   #$E000CE,A4
            BNE     BoucleClose
            RTE
           

FaireOpen   LEA OPEN(PC),A3
            LEA SECUNDAS(PC),A5
            LEA $E000BE,A4
            BRA BoucleOpen
            RTE
            
          
BoucleOpen
            MOVE.L  (A3)+,(A4)+
            CMP.L   #$E000CA,A4
            BNE     BoucleOpen
            MOVE.B  #8,D0
        
Secondes
            TRAP    #15
            MOVE.L  D1,D5
            ADD.L   #100,D5
            MOVE.L  (A5)+,(A4)
            CMP.L   #$10C0,A5 
            BNE     UNESECONDE
            BRA     FaireClose
            RTE 
            
UNESECONDE
            TRAP    #15
            CMP     D5,D1
            BNE     UNESECONDE
            BRA     Secondes
        
       


    
    
OPEN        DC      $3F00,$7300,$7900,$5400,$0000,$0000,$0000,$0000
CLOSE       DC      $3900,$3800,$3F00,$6D00,$7900,$5E00,$0000,$0000
SECUNDAS    DC.L    $6D000000,$66000000,$4F000000,$5B000000,$06000000


    END START

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
