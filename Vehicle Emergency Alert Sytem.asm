;praise the lord
;*********************ISR TEMP********************  ;interupt serivice routine temperory data save 
#DEFINE   W_TEMP        20H                         
#DEFINE   STS_TEMP      21H
#DEFINE   FSR_TEMP      22H
;*************************************************
#DEFINE   FLAG_BIT01    23H                         ;flag bit location (8 bits)
#DEFINE   FLAG_BIT02    24H                         
#DEFINE   FLAG_BIT03    25H
;;;
#DEFINE   DELAY_MSB     28H                         ;Delay subroutine                       
#DEFINE   DELAY_LSB     29H
;;;
#DEFINE   SW00_DBOUN    2AH                         ;switch input debouncing counter
#DEFINE   SW01_DBOUN    2BH
#DEFINE   SW02_DBOUN    2CH
#DEFINE   SW03_DBOUN    2DH
#DEFINE   SW04_DBOUN    2EH
#DEFINE   SW05_DBOUN    2FH
;;;
#DEFINE   TIME_CUNT     30H                         ;all timer counters
#DEFINE   BEEP_CUNT     31H
#DEFINE   GPRS_CUNT     32H
#DEFINE   LED_CUNT      33H
#DEFINE   ALM_RUN_CUNT  34H
;***************************************************
          INCLUDE       <p16F72.INC>                 ;controller inc file 
          errorlevel    2,-302                       ;cancelling warnings 
          __CONFIG    _CP_ALL&_BODEN_ON&_WDT_OFF&_PWRTE_ON&_XT_OSC   ;device configuration bit settings(it means what all is used for it to work)
          ORG           0X0000                                       
          GOTO          START                                        ;progrms starts here
          ORG           0X0004                                       
          NOP                                                        ;no operation point
          GOTO          ISR                                          ;goto interupt service routine                                         
START
          BCF           PORTA,5                                      ;bit clear 
          MOVLW         B'00000000'                                  
          MOVWF         INTCON
          CLRF          PORTB
          CLRF          PORTC
          BSF           STATUS,5                                     ;bank 1 selected
          MOVLW         B'00111111'
          MOVWF         TRISA
          MOVLW         B'11000001'
          MOVWF         TRISB
          MOVLW         B'00000000'
          MOVWF         TRISC
          MOVLW         B'00000000'
          MOVWF         ADCON0
          MOVLW         B'00000110'
          MOVWF         ADCON1
          MOVLW         B'00000110'
          MOVWF         OPTION_REG
          BCF           STATUS,5                                      ;bank 0 selected
          MOVLW         B'00000000'
          MOVWF         INTCON
          CLRF          PORTA
          CLRF          PORTB
          CLRF          PORTC
          BSF           PORTB,2
          CLRF          FLAG_BIT01
          CLRF          FLAG_BIT02
          CLRF          FLAG_BIT03
          CLRF          SW00_DBOUN
          CLRF          SW01_DBOUN
          CLRF          SW02_DBOUN
          CLRF          SW03_DBOUN
          CLRF          SW04_DBOUN
          CLRF          SW05_DBOUN
          CLRF          TIME_CUNT
          CLRF          BEEP_CUNT
          CLRF          GPRS_CUNT
          CLRF          LED_CUNT
          CLRF          ALM_RUN_CUNT
          CLRF          TMR0
          MOVLW         B'11100000'
          MOVWF         INTCON
          CALL          DLY50                                          ;delay routine
          CALL          DLY50
          CALL          DLY50
          BSF           PORTB,1  ;LED
          BCF           PORTB,2  ;BUZ
          BSF           PORTB,3  ;GPRS
;****************************************
MAINLP
          BTFSC         FLAG_BIT01,7
          GOTO          ALARM_SET                                       ;alarm subroutine
          BTFSS         FLAG_BIT01,6
          CALL          SWITCH_SET                                      ;all input searching subroutine
          BTFSC         FLAG_BIT01,5
          GOTO          EMERG_CALL                                      ;emergency call subroutine
          BTFSC         FLAG_BIT02,0
          GOTO          SWITCH_EMRG                                     ;human emergency facing input
          GOTO          MAINLP
;****************************************
ALARM_SET                                                               ;alarm set routine 
          BSF           FLAG_BIT01,6
          BCF           FLAG_BIT01,0
          CLRF          TIME_CUNT
          CLRF          ALM_RUN_CUNT
ALARM_LOOP1
          BTFSC         FLAG_BIT02,5
          GOTO          ALARM_OUT
          BTFSS         FLAG_BIT01,0
          GOTO          ALARM_LOOP1
          BSF           PORTB,3      ;GPSR
          BCF           FLAG_BIT01,0
          CLRF          TIME_CUNT
          BSF           FLAG_BIT01,1 ;LED
          INCF          ALM_RUN_CUNT,W
          SUBLW         0X08
          BTFSC         STATUS,Z
          GOTO          ALM_RUN_SET
          INCF          ALM_RUN_CUNT,F
          GOTO          ALARM_LOOP1
ALM_RUN_SET
          CLRF          ALM_RUN_CUNT
          BSF           FLAG_BIT01,2 ;BUZ
          GOTO          ALARM_LOOP1
ALARM_OUT 
          BCF           FLAG_BIT01,7
          BCF           FLAG_BIT01,6
          BCF           FLAG_BIT01,1 ;LED
          BCF           FLAG_BIT01,2 ;BUZ
          BCF           FLAG_BIT01,3 ;GPRS
          BSF           PORTB,1      ;LED
          BCF           PORTB,2      ;BUZ
          BSF           PORTB,3      ;GPRS
            GOTO          MAINLP   
;********************************************************
EMERG_CALL                                                               ;emergency call subroutine
          BCF           PORTB,1      ;LED
          BSF           PORTB,2      ;BUZ
          BCF           FLAG_BIT01,0
          CLRF          TIME_CUNT
          CLRF          ALM_RUN_CUNT
EMERG_LOOP1
          BTFSC         FLAG_BIT02,5
          GOTO          EMERG_OUT
          BTFSS         FLAG_BIT01,0
          GOTO          EMERG_LOOP1
          BTFSC         FLAG_BIT02,0
          GOTO          EMG_RUN_SET
          BCF           FLAG_BIT01,0
          CLRF          TIME_CUNT
          INCF          ALM_RUN_CUNT,W
          SUBLW         0X15
          BTFSC         STATUS,Z
          GOTO          EMG_RUN_SET
          INCF          ALM_RUN_CUNT,F
          GOTO          EMERG_LOOP1
EMG_RUN_SET
          GOTO          SWITCH_EMRG
EMERG_OUT
          BCF           FLAG_BIT01,5
          BCF           FLAG_BIT01,1   ;LED
          BCF           FLAG_BIT01,2   ;BUZ
          BCF           FLAG_BIT01,3   ;GPRS
          BSF           PORTB,1        ;LED
          BCF           PORTB,2        ;BUZ
          BSF           PORTB,3        ;GPRS
           GOTO           MAINLP
;*********************ISR 20 mS ****************************
ISR                                                                          ;interupt service routine 
          MOVWF         W_TEMP
          SWAPF         STATUS,W
          MOVWF         STS_TEMP
          MOVF          FSR,W
          MOVWF         FSR_TEMP
          BCF           STATUS,5       ;;BANK0
          CALL          INPUT_SCAN
          INCF          TIME_CUNT,W
          SUBLW         0X32
          BTFSC         STATUS,Z
          GOTO          TIMER_SET
          INCF          TIME_CUNT,F
          GOTO          TIMER_OUT
TIMER_SET
          CLRF          TIME_CUNT
          BSF           FLAG_BIT01,0
 TIMER_OUT ;;;*********;;;
          BTFSS         FLAG_BIT01,2  ;BUZ
          GOTO          BEEP_OUT
          BSF           PORTB,2
          INCF          BEEP_CUNT,W
          SUBLW         0X0D
          BTFSC         STATUS,Z
          GOTO          BEEP_SET
          INCF          BEEP_CUNT,F
          GOTO          BEEP_OUT
BEEP_SET
          BCF           PORTB,2
          BCF           FLAG_BIT01,2  ;BUZ
          CLRF          BEEP_CUNT
BEEP_OUT  ;;;********;;;
          BTFSS         FLAG_BIT01,3  ;GPRS
          GOTO          GPRS_OUT
          BCF           PORTB,3
          INCF          GPRS_CUNT,W
          SUBLW         0X10
          BTFSC         STATUS,Z
          GOTO          GPRS_SET 
          INCF          GPRS_CUNT,F
          GOTO          GPRS_OUT
GPRS_SET 
          BSF           PORTB,3
          BCF           FLAG_BIT01,3  ;GPRS
          CLRF          GPRS_CUNT
          ;;;************;;;
GPRS_OUT
          BTFSS         FLAG_BIT01,1  ;LED
          GOTO          ISR_OUT
          BCF           PORTB,1
          INCF          LED_CUNT,W
          SUBLW         0X10
          BTFSC         STATUS,Z
          GOTO          LED_SET
          INCF          LED_CUNT,F
          GOTO          ISR_OUT
LED_SET
          BSF           PORTB,1
          BCF           FLAG_BIT01,1  ;LED
          CLRF          LED_CUNT
ISR_OUT   ;;;**********;;;
          MOVLW         0X64
        MOVWF        TMR0
          BCF           INTCON,T0IF
          ;;;
          MOVF          FSR_TEMP,W
          MOVWF         FSR
          SWAPF         STS_TEMP,W
          MOVWF         STATUS
          SWAPF         W_TEMP,F
          SWAPF         W_TEMP,W
          RETFIE
;*************************************************
SWITCH_EMRG
          BCF           PORTB,1        ;LED
          BSF           PORTB,2        ;BUZ
          BCF           PORTB,3        ;GPRS
          CALL          DLY50
          CALL          DLY50
          CALL          DLY50
          CALL          DLY50
          BSF           PORTB,1        ;LED
          BCF           PORTB,2        ;BUZ
          BSF           FLAG_BIT01,7
           GOTO           MAINLP
;*************************************************
SWITCH_SET
           CALL          SWITCH_IN1
           CALL          SWITCH_IN2
           CALL          SWITCH_IN3 
           CALL          SWITCH_IN4
           RETURN
;*************************************************
EMERG_SET
           BSF           FLAG_BIT01,5
           RETURN
;*************************************************
SWITCH_IN1
           BTFSS         FLAG_BIT02,1
           GOTO          SWITCH_IN1A
           CALL          EMERG_SET
SWITCH_IN1A
           RETURN
;*************************************************
SWITCH_IN2
           BTFSS         FLAG_BIT02,2
           GOTO          SWITCH_IN2A
           CALL          EMERG_SET
SWITCH_IN2A 
           RETURN
;*************************************************
SWITCH_IN3
           BTFSS         FLAG_BIT02,3
           GOTO          SWITCH_IN3A
           CALL          EMERG_SET
SWITCH_IN3A
           RETURN
;*************************************************
SWITCH_IN4
           BTFSS         FLAG_BIT02,4
           GOTO          SWITCH_IN4A
           CALL          EMERG_SET
SWITCH_IN4A
           RETURN
;*************************************************
INPUT_SCAN
           BTFSC         PORTA,0
           GOTO          SCAN0B_OUT
           INCF          SW00_DBOUN,W
           SUBLW         0X0A
           BTFSS         STATUS,Z
           GOTO          SCAN0A_OUT
           BSF           FLAG_BIT02,0
           GOTO          SCAN0_OUT
SCAN0A_OUT                                               ;human interface
           INCF          SW00_DBOUN,F
           GOTO          SCAN0_OUT
SCAN0B_OUT                                               
           BTFSS         PORTA,0
           GOTO          SCAN0_OUT
           DECF          SW00_DBOUN,W
           SUBLW         0XFF
           BTFSS         STATUS,Z
           GOTO          SCAN0C_OUT
           BCF           FLAG_BIT02,0
           GOTO          SCAN0_OUT
SCAN0C_OUT
           DECF          SW00_DBOUN,F
SCAN0_OUT ;;;***********;;;                               ;airbag explotion
           BTFSC         PORTA,1
           GOTO          SCAN1B_OUT
           INCF          SW01_DBOUN,W
           SUBLW         0X0A
           BTFSS         STATUS,Z
           GOTO          SCAN1A_OUT
           BSF           FLAG_BIT02,1
           GOTO          SCAN1_OUT
SCAN1A_OUT
           INCF          SW01_DBOUN,F
           GOTO          SCAN1_OUT
SCAN1B_OUT
           BTFSS         PORTA,1
           GOTO          SCAN1_OUT
           DECF          SW01_DBOUN,W
           SUBLW         0XFF
           BTFSS         STATUS,Z
           GOTO          SCAN1C_OUT
           BCF           FLAG_BIT02,1
           GOTO          SCAN1_OUT
SCAN1C_OUT
           DECF          SW01_DBOUN,F
SCAN1_OUT  ;;;************;;;                               ;vibration sensing
           BTFSC         PORTA,2
           GOTO          SCAN2B_OUT
           INCF          SW02_DBOUN,W
           SUBLW         0X0A
           BTFSS         STATUS,Z
           GOTO          SCAN2A_OUT
           BSF           FLAG_BIT02,2
           GOTO          SCAN2_OUT
SCAN2A_OUT
           INCF          SW02_DBOUN,F
           GOTO          SCAN2_OUT
SCAN2B_OUT
           BTFSS         PORTA,2
           GOTO          SCAN2_OUT
           DECF          SW02_DBOUN,W
           SUBLW         0XFF
           BTFSS         STATUS,Z
           GOTO          SCAN2C_OUT
           BCF           FLAG_BIT02,2
           GOTO          SCAN2_OUT
SCAN2C_OUT
           DECF          SW02_DBOUN,F
SCAN2_OUT  ;;;***********;;;                             ;glass breaking
           BTFSC         PORTA,3
           GOTO          SCAN3B_OUT
           INCF          SW03_DBOUN,W
           SUBLW         0X0A
           BTFSS         STATUS,Z
           GOTO          SCAN3A_OUT
           BSF           FLAG_BIT02,3
           GOTO          SCAN3_OUT
SCAN3A_OUT
           INCF          SW03_DBOUN,F
           GOTO          SCAN3_OUT
SCAN3B_OUT
           BTFSS         PORTA,3
           GOTO          SCAN3_OUT
           DECF          SW03_DBOUN,W
           SUBLW         0XFF
           BTFSS         STATUS,Z
           GOTO          SCAN3C_OUT
           BCF           FLAG_BIT02,3
           GOTO          SCAN3_OUT
SCAN3C_OUT
           DECF          SW03_DBOUN,F
SCAN3_OUT   ;;;***********;;;                             ;fire detection
           BTFSC         PORTA,4
           GOTO          SCAN4B_OUT
           INCF          SW04_DBOUN,W
           SUBLW         0X0A
           BTFSS         STATUS,Z
           GOTO          SCAN4A_OUT
           BSF           FLAG_BIT02,4
           GOTO          SCAN4_OUT
SCAN4A_OUT
           INCF          SW04_DBOUN,F
           GOTO          SCAN4_OUT
SCAN4B_OUT
           BTFSS         PORTA,4
           GOTO          SCAN4_OUT
           DECF          SW04_DBOUN,W
           SUBLW         0XFF
           BTFSS         STATUS,Z
           GOTO          SCAN4C_OUT
           BCF           FLAG_BIT02,4
           GOTO          SCAN4_OUT
SCAN4C_OUT
           DECF          SW04_DBOUN,F
SCAN4_OUT  ;;;***********;;;                          ;voice assistent
           BTFSC         PORTA,5
           GOTO          SCAN5B_OUT
           INCF          SW05_DBOUN,W
           SUBLW         0X0A
           BTFSS         STATUS,Z 
           GOTO          SCAN5A_OUT
           BSF           FLAG_BIT02,5
           GOTO          SCAN5_OUT
SCAN5A_OUT
           INCF          SW05_DBOUN,F
           GOTO          SCAN5_OUT
SCAN5B_OUT
           BTFSS         PORTA,5
           GOTO          SCAN5_OUT
           DECF          SW05_DBOUN,W
           SUBLW         0XFF
           BTFSS         STATUS,Z
           GOTO          SCAN5C_OUT
           BCF           FLAG_BIT02,5
           GOTO          SCAN5_OUT
SCAN5C_OUT
           DECF          SW05_DBOUN,F
SCAN5_OUT                                              ;reset and acknowlegement
           RETURN
;************DELAYS********************
DLY50                                                  ;DELAY
           MOVLW         0XFF
           MOVWF         DELAY_MSB
D1
           MOVLW         0XFF
           MOVWF         DELAY_LSB
D2         
           CLRWDT      
           DECFSZ        DELAY_LSB,F
           GOTO          D2
           DECFSZ        DELAY_MSB,F
           GOTO          D1
           RETURN
;**************************************
               END
;**************************************  