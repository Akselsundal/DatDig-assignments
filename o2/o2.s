.thumb
.syntax unified

.include "gpio_constants.s"     // Register-adresser og konstanter for GPIO
.include "sys-tick_constants.s" // Register-adresser og konstanter for SysTick

.text
	.global Start



Start:
	// Fra basen vil eg sette opp SYSTICK-registrene

	ldr r0, = FREQUENCY/10
	ldr r1, =SYSTICK_BASE + SYSTICK_LOAD
	str r0, [r1]

	ldr r1, =SYSTICK_BASE + SYSTICK_VAL
	str r0, [r1]

	ldr r0, =SYSTICK_BASE
	ldr r1, [r0]
	orr r1, r1, #0b110
	str r1, [r0]

	//Setter opp GOIO-button interrupt
	ldr r0, =GPIO_BASE + GPIO_EXTIPSELH
	ldr r1, [r0]
	and r1, ~(0b1111 << 4)
	orr r1, 0b0001 << 4
	str r1, [r0]

	ldr r0, =GPIO_BASE+GPIO_EXTIFALL
	ldr r1, [r0]
	orr r1, 1 << BUTTON_PIN
	str r1, [r0]

	ldr r0, =GPIO_BASE+GPIO_IEN
	ldr r1, [r0]
	orr r1, 1 << BUTTON_PIN
	str r1, [r0]



loop:

	wfi //'wait for interrupt'
	B loop



.global SysTick_Handler
.thumb_func

SysTick_Handler:

// legger til ein i tenths
	ldr r0, =tenths
	ldr r1, [r0]
	add r1, #1

	cmp r1, #10		//Sjekker om tiendedelssekunder er blitt satt til 10
	bne Tenths

	ldr r1, =0

//Legger til ein i seconds-register
	ldr r2, =seconds
	ldr r3, [r2]
	add r3, #1
	//Får her LED-en til å blinke:
	ldr r7, =GPIO_BASE + LED_PORT * PORT_SIZE + GPIO_PORT_DOUTTGL //Finner porten
	ldr r8, =1<<LED_PIN //setter led høg
	str r8, [r7]


	cmp r3, #60 //Skjekker om dete er gått 60 sek
	bne Seconds
	ldr r3, =0


//Legger til ein i minutes og endrer lagrer verdien
	ldr r5, =minutes
	ldr r6, [r5]
	add r6, #1
	str r6, [r5]



Seconds:
	str r3, [r2]	//Lagrer den nye verdien in seconds

Tenths:
	str r1, [r0] //lagrer den nye verdien i tenths
	bx lr


.global GPIO_ODD_IRQHandler
.thumb_func

GPIO_ODD_IRQHandler:
	// Toggler klokka
	ldr r0, =SYSTICK_BASE
	ldr r1, [r0]
	eor r1, #SysTick_CTRL_ENABLE_Msk
	str r1, [r0]

	// Reset interrupt flag
	ldr r0, =GPIO_BASE+GPIO_IFC //Loader clear register
	ldr r1, =1<<BUTTON_PIN
	str r1, [r0]

	bx lr






NOP
