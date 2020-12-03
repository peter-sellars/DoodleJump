	#####################################################################
#
# CSC258H5S Fall 2020 Assembly Final Project
# University of Toronto, St. George
#
# Student: Peter Sellars, Student Number: 1006389926
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1/2/3/4/5 (choose the one the applies)
#
# Which approved additional features have been implemented?
# (See the assignment handout for the list of additional features)
# 1. (fill in the feature, if any)
# 2. (fill in the feature, if any)
# 3. (fill in the feature, if any)
# ... (add more if necessary)
#
# Any additional information that the TA needs to know:
# - (write here, if any)
#
#####################################################################

.data

	red: .word 0xe74c3c
	skyBlue: .word 0xaed6f1
	green: .word 0x2ecc71
	displayAddress: .word 0x10008000	#upper left unit of bitmap display
	bufferAddress: .word 0x10009000	#upper left unit of buffer 
	doodler_location: .word 0x10008cc0	#must be a multiple of 4, refers to uppermost block of doodler
	doodler_x: .word 16		#doodler's x coordinate
	doodler_y: .word 25		#doodler's y coordinate (REMEMBER +Y is lower on display!)
				# 0 <= x <= 31
				# 0 <= y <= 31
	up_momentum: .word 0		#by default this is 0 (i.e. the doodler falls down)
				#is greater than 0 after doodler lands on platform
				#if non-zero and doodler is above a certain y, platforms move down
	normPlat_xy: .space 24		#6 slots for 3 platforms (x,y)
	normPlat_hex: .word 0:28		#28 slots for 4 platforms' hexadecimal locations (on buffer)
				#platforms are numbered 0 -> 3
	up_threshold: .word 8		#when doodler_y == up_threshold && up_momentum > 0, move platforms
				#down instead of moving doodler up
	
.text
	lw $s0, displayAddress	#$s0 = base address of bitmap display
	lw $s1, red		#$s1 = red colour of doodler
	lw $s2, skyBlue	#$s2 = blue colour of sky
	lw $s3, green	#$s3 = green color of regular platforms
	lw $s4, bufferAddress	#$s4 = base address of buffer display
	
	
	
	# HOME SCREEN	#set background color, platforms and doodler
	add $t0, $zero, $zero	#i=0 (background color loop)
	addi $t1, $zero, 1024	#32x32 display 
HSL_BEGIN:	beq $t0, $t1, HSL_END	#end loop when all units have been iterated over
	sw $s2, 0($s4)
	addi $s4, $s4, 4
	addi $t0, $t0, 1
	j HSL_BEGIN	
HSL_END:	lw $s4, bufferAddress	#reset $s0 to store bufferAddress again

	li $a0, 13		#draw base platform
	li $a1, 29
	#li $a0, 268471988
	add $a2, $zero, $s3
	add $a3,$zero,$zero
	jal draw_regplat_func
	
	li $a0, 5		#draw base platform 2
	li $a1, 9
	#li $a0, 268470860
	add $a2, $zero, $s3
	addi $a3,$zero,1
	jal draw_regplat_func
	
	li $a0, 19		#draw base platform 3
	li $a1, 19
	#li $a0, 268469908
	add $a2, $zero, $s3
	addi $a3,$zero,2
	jal draw_regplat_func
	
	lw $a0,doodler_x	#draw doodler
	lw $a1,doodler_y
	lw $a2,red	
	lw $a3,bufferAddress 
	jal draw_doodler_func
	jal draw_bitmap_func
	#j GL_END
GL_BEGIN:	# GAME LOOP	
	# LAST PART OF GL --> sleep	
	li $v0, 32		
	li $a0, 50
	syscall
	# Draw blue at location of doodler and platforms
	lw $a0,doodler_x
	lw $a1,doodler_y
	lw $a2,skyBlue
	lw $a3,bufferAddress
	jal draw_doodler_func	
	lw $t0,up_momentum	#$t0 = up_momentum
	la $t1,up_momentum	#$t1 = mem address of up_momentum
	beq $t0,$zero,FALL_DOWN	#if up_momentum is zero, fall down and check for collision
	addi $t0,$t0,-1	#else,decrement up_momentum and move doodler up
	sw $t0,0($t1)	#decrement up_momentum and store it
	lw $t0,doodler_y	#increment doodler's y-value
	la $t1,doodler_y
	addi $t0,$t0,-1	#a lower y-value means a higher row on the display
	sw $t0,0($t1)
	j UP_MOM_END		#skip the else block (FALL_DOWN)
		
FALL_DOWN:	lw $t0,doodler_y
	la $t1,doodler_y
	addi $t0,$t0,1	#a higher y-value means a lower row on the display
	sw $t0,0($t1)
	lw $a0, doodler_x
	lw $a1, doodler_y
	jal regPlatDet_func
	beq $v0,1,ADD_REG_MOM
	beq $v0,0,UP_MOM_END
ADD_REG_MOM:	lw $t0,up_momentum
	la $t1,up_momentum
	addi $t0,$t0,13
	sw $t0,0($t1)
UP_MOM_END:
	
	
	#lw $t0,doodler_y
	#la $t1,doodler_y
	#addi $t0,$t0,-1
	#sw $t0,0($t1)
	lw $a0,doodler_x
	lw $a1,doodler_y
	lw $a2,red
	lw $a3, bufferAddress
	jal draw_doodler_func
	jal draw_bitmap_func
	j GL_BEGIN
	
GL_END:	li $v0, 10
	syscall	

# FUNCTIONS

#Behaviour: Draws the doodler given the location of the doodler's uppermost block in (x,y) coordinates
draw_doodler_func:	addi $sp,$sp,-4	#$a0 = x-value	$a2 = color  	   
		sw $ra,0($sp)	#$a1 = y-value	$a3 = base address -> bitmap or buffer
		add $t5,$zero,$a2	#store color in a temp variable, since convXY requires address as $a2
		add $a2,$zero,$a3	#store address in $a2
		jal convXY_func
		add $a2,$zero,$t5	#restore color to $a2
		sw $a2,0($v0)	
		addi $v0, $v0, 124	
		sw $a2,0($v0)	
		addi $v0, $v0, 4
		sw $a2,0($v0)
		addi $v0, $v0, 4
		sw $a2,0($v0)
		addi $v0, $v0, 120
		sw $a2,0($v0)
		addi $v0, $v0, 8
		sw $a2,0($v0)
		
		lw $ra,0($sp)	#pop off stack
		addi $sp,$sp,4	#move stack pointer back down
		jr $ra

#Behaviour: Draws a normal platform given the location of the platform's leftmost block	
draw_regplat_func:			#$a0 = x-value, $a1 = y-value, $a2 = color,$a3 = identity
		addi $sp,$sp,-4	#prepare stack pointer for pushing
		sw $ra,0($sp)	#push $ra onto stack
		add $t5,$zero,$a2	#store color in temporary variable
		lw $a2,bufferAddress
		jal convXY_func
		addi $t0,$zero,0	#count
		addi $t1, $zero,7	#loop limit
		add $a2,$zero,$t5	#restore color to $a2
		la $t2,normPlat_hex	#load address of normal platforms' hex array
DRID_BEGIN:		beq $t0,$a3,DRID_END	
		addi $t2,$t2,28	#determine offset for updating hex values
		addi $t0,$t0,1
		j DRID_BEGIN
DRID_END:		add $t0,$zero,$zero	#count
DRPL_BEGIN:		beq $t0,$t1, DRPL_END	
		sw $a2, 0($v0)
		sw $v0, 0($t2)
		addi $t0, $t0, 1
		addi $v0, $v0, 4
		addi $t2,$t2,4
		j DRPL_BEGIN
		
DRPL_END:		lw $ra,0($sp)	#pop original $ra
		addi $sp,$sp,4	#restore stack pointer
		jr $ra		#return no values
				
#Behaviour: Draws the contents of the buffer on the bitmap display
draw_bitmap_func:	addi $t0,$zero,0	#$t0 = 0 (loop counter)
		addi $t1,$zero,1024	#$t1 = 1024 (loop limit)
		lw $t2,displayAddress	#$t2 = display address
		lw $t3,bufferAddress	#$t3 = buffer address
		lw $t4,0($t3)	#$t4 = contents of buffer address
		
DBL_BEGIN:		beq $t0,$t1,DBL_END
		sw $t4, 0($t2)	#store contents of buffer in corresponding display slot
		addi $t2, $t2, 4
		addi $t3,$t3,4	#move buffer address to next slot
		lw $t4,0($t3)	#update $t4 with contents of next buffer slot
		addi $t0,$t0,1	#increment counter
		j DBL_BEGIN		#loop

DBL_END:		jr $ra

# Behaviour: Converts (x,y) into hexadecimal, given a base address (buffer or bitmap)
convXY_func:		add $t0,$zero,$a2	#a0 = x-value
		add $t1,$zero,$zero	#a1 = y-value
		add $t2, $zero,$zero	#a2 = address
CONVXL_BEGIN:	beq $t1,$a0,CONVXL_END	
		addi $t0,$t0,4
		addi $t1, $t1,1
		j CONVXL_BEGIN
CONVXL_END:		beq $t2, $a1,CONVYL_END
		addi $t0,$t0,128
		addi $t2, $t2,1
		j CONVXL_END
CONVYL_END:		add $v0,$zero,$t0	#return $v0 = hex address
		jr $ra

# Behaviour: Given doodler's x and y, determine if doodler is on top of a regular platform
# $a0 = x-value	$a1 = y-value
regPlatDet_func:	addi $sp,$sp,-4	
		sw $ra,0($sp)	#push $ra on stack, since nested call occurring
		lw $a2,bufferAddress	
		jal convXY_func
		addi $t0,$v0,-4
		addi $t1,$v0,4
		addi $t0,$t0,384	#$t0 = unit on buffer directly below doodler's left foot
		addi $t1,$t1,384	#$t1 = unit on buffer directly below doodler's right foot
		add $t5,$zero,$zero	#loop counter
		addi $t6,$zero,28	#loop limit
		lw $ra,0($sp)	#restore $ra
		addi $sp,$sp,4
		la $t2,normPlat_hex	#array memory address
		lw $t3,0($t2)	#contents of first element in array
RPDL_BEGIN:		beq $t5,$t6,RPD_NO	#loop over hex addresses of platforms
		beq $t0,$t3,RPD_YES	#if doodler is standing on platform, return yes
		beq $t1,$t3,RPD_YES
		addi $t2,$t2,4	#move to next address of hex address
		lw $t3,0($t2)	#update contents of hex address variable
		addi $t5,$t5,1
		j RPDL_BEGIN
RPD_NO:		li $v0,0		#return 0 iff doodler is not standing on regular platform
		jr $ra
RPD_YES:		li $v0,1		#return 1 iff doodler is standing on regular platform
		jr $ra		
		
		








