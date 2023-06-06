#####################################################################
#
# CSCB58 Winter 2023 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Chelsea Chan, 1007917676, chanyang, chelseacyy.chan@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4 (update this as needed)
# - Unit height in pixels: 4 (update this as needed)
# - Display width in pixels: 512 (update this as needed)
# - Display height in pixels: 512 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 1 and 2 and 3 (choose the one the applies)
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. health/score [2]
# 2. fail condition [1]
# 3. win conditino [1]
# 4. moving objects [2]
# 5. shoot enemies [2]
# 6. enemies shoot back [2]
#
# Link to video demonstration for final submission:
# - (insert YouTube / MyMedia / other URL here). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - no
#
# Any additional information that the TA needs to know:
# - all functions are labeled as "function" in comments,
#	use ctrl+F for easy marking
#
#####################################################################
# hexcodes for colours
.eqv WHITE		0xD3D3D3
.eqv BLACK		0x000000
.eqv RED		0xFF0000
# positions
# offset = position of pixel from BASE_ADDRESS
.eqv BASE_ADDRESS	0x10008000
.eqv SHIFT_ROW		512	# width of screen
.eqv PLATFORM_A_OFFSET	43108	# offset of the position of Platform A
.eqv PLATFORM_B_OFFSET	26852	# offset of the position of Platform B
.eqv PLATFORM_C_OFFSET	41320	# offset of the position of Platform C
.eqv PLATFORM_LENGTH	84
.eqv ENEMY_BOTTOM_POSITION 48652 # off set of position of enemy at the bottom position
.eqv ENEMY_TOP_POSITION	32268	# off set of position of enemy at the top position
.eqv LIVES_POSITION 	62992
.eqv HP_POSITION	2064
.eqv HEARTUP_POSITION	40328

.eqv GRAVITY_POW	9	# 2^9 = 512 = width of screen * 1
.eqv X_VELOCITY		12
.eqv Y_VELOCITY		-6144	# = -12 * 512
.eqv NEG_Y_VELOCITY	6144

.eqv ENEMY_VELOCITY	2048	# = 4 * 512

.eqv BULLET_START	-12744	# the distance of bullet from the position of bug at start

.eqv MAX_ATk_COUNT	5

.eqv MAX_LIVES		5
.eqv MAX_HP		10

# booleans
.eqv FALSE		0
.eqv TRUE		1

# sprite numbers
.eqv NORMAL_LEFT	0
.eqv NORMAL_RIGHT	1
.eqv ATK_LEFT		2
.eqv ATK_RIGHT		3

# state numbers
.eqv TOP	0	# = at bottom position
.eqv BOTTOM	1	# = at top position
.eqv TTB	3	# = moving from top to bottom
.eqv BTT	4	# = moving from bottom to top

# structs
.data
# just some padding
 Spacer: .space 36000

# Frog info array:
# [0]: current offset
# [1]: previous offset
# [2]: status on whether the frog has moved
# [3]: sprite numer of frog 
# 	- 0: normal facing left
#	- 1: normal facing right
#	- 2: attacking facing left
#	- 3: attacking facing right
# [4]: status on whether the frog is on a platform
# [5]: status on whether the frog is jumping
# [6]: how long the frog has been jumping/falling for
# [7]: previous sprite of frog
Frog: .word	0, 0, 0, 1, 1, 0, 0, 1

# Enemy info array:
# [0]: current offset
# [1]: previous offset
# [2]: states
# 	- 0: top = at bottom position
#	- 1: bottom = at top position
#	- 2: top_to_bottom = moving from top to bottom
#	- 3: bottom_to_top = moving from bottom to top
# [3]: bullet position
# [4]: HP
# [5]: hit: TRUE/FALSE , boolean of being hit or not
Enemy: .word	48652, 48652, 0, 35908, 5, 0

.text
.globl main
#####################################################################
# $s0: array info for Frog
# $s1: array info for Enemy
#
# global variables:
# $s2: attack_counter: counts how many iterations has attacking lasts for
# $s3: tongue leftmost position
# $s4: whether the frog was hit on the last loop
# $s5: lives
# $s6: heartup_chance
#	- 0: heartup chance used already
#	- 1; heartup present now
#	- 2: heartup chance not yet appeared
#
# $t9: temp: used for loading and setting info into arrays
#####################################################################
main:	
	# initiatialization
	la $s0, Frog 
	la $s1, Enemy
	li $s2, 0
	li $s3, 0
	li $s4, FALSE
	li $s5, MAX_LIVES
	li $s6, 2
	
	# initialize info arrays
	addi $t9, $zero, PLATFORM_A_OFFSET	# place player on top of a platform: PLATFORM_A_OFFSET-SHIFT_ROW
	addi $t9, $t9, -SHIFT_ROW
	sw $t9, 0($s0)
	sw $t9, 4($s0)
	li $t9, FALSE
	sw $t9, 8($s0)
	li $t9, NORMAL_RIGHT
	sw $t9, 12($s0)
	li $t9, TRUE
	sw $t9, 16($s0)
	li $t9, FALSE
	sw $t9, 20($s0)
	li $t9, 0
	sw $t9, 24($s0)
	li $t9, NORMAL_RIGHT
	sw $t9, 28($s0)
	
	li $t9, ENEMY_TOP_POSITION
	sw $t9, 0($s1)
	sw $t9, 4($s1)
	li $t9, TOP
	sw $t9, 8($s1)
	li $t9, ENEMY_TOP_POSITION
	addi $t9, $t9, BULLET_START
	sw $t9, 12($s1)
	li $t9, MAX_HP
	sw $t9, 16($s1)
	li $t9, FALSE
	sw $t9, 20($s1)
	
	# draw sprites and platforms at boot
	lw $a0, 0($s0)	# pass player location as parameter
	li $a1, WHITE 		# draw frog in white
	jal draw_frog_right	# draw frog facing right

	li $a0, PLATFORM_A_OFFSET	# draw platform A
	li $a1, PLATFORM_LENGTH
	jal draw_platform
	li $a0, PLATFORM_B_OFFSET	# draw platform B
	li $a1, PLATFORM_LENGTH
	jal draw_platform
	li $a0, PLATFORM_C_OFFSET	# draw platform B
	li $a1, PLATFORM_LENGTH
	jal draw_platform
		
main_loop:
	
	li $t9, FALSE
	sw $t9, 8($s0)	# set player moved status to false
	lw $t9, 0($s0)
	sw $t9, 4($s0)	# save current position offset
	lw $t9, 12($s0)
	sw $t9, 28($s0)	# save current sprite
	lw $t9, 0($s1)
	sw $t9, 4($s1)	# save current enemy position
	
	# if current lives < MAX_LIVES
	# then if heartup_chance == 1
	# place heart at platform C
	blt $s5, MAX_LIVES, check_chance
	j platform_check
check_chance:
	beq $s6, 2, heartup
	j platform_check
	
	# placing the heartup powerup
heartup:
	li $a0, HEARTUP_POSITION
	li $a1, WHITE
	jal draw_heart
	li $s6, 1

platform_check:
	# check if the frog is on a platform
	jal on_platform
	
	# check key press
	li $a1, 0xffff0000
	lw $t9, 0($a1)
	bne $t9, 1, after_keypress_check	# if key pressed, respond
	jal keypress

after_keypress_check:
	bgt $s2, 0, attacking	# if attack_counter>0, attacking
	j check_frog_status
attacking:
	addi $s2, $s2, 1	# increment attack_counter by 1
	# if the sprite is already an attacking sprite, no need to change
	# else, change to an attacking sprite
	lw $t9, 12($s0)
	beq $t9, NORMAL_LEFT, set_atk_left
	beq $t9, NORMAL_RIGHT, set_atk_right
	j attacking_cont
set_atk_left:
	li $t9, ATK_LEFT
	sw $t9, 12($s0)
	j attacking_cont
set_atk_right:
	li $t9, ATK_RIGHT
	sw $t9, 12($s0)
attacking_cont:
	# if attack_counter == MAX_ATk_COUNT, set to 0
	beq $s2, MAX_ATk_COUNT, reset_atk_count
	j set_to_moved
reset_atk_count:
	li $s2, 0	# set attack_counter to 0
	beq $t9, ATK_LEFT, set_normal_left
set_normal_right:
	li $t9, NORMAL_RIGHT
	sw $t9, 12($s0)
	j set_to_moved
set_normal_left:
	li $t9, NORMAL_LEFT
	sw $t9, 12($s0)
set_to_moved:
	li $t9, TRUE
	sw $t9, 8($s0)		# set frog moved status to true

### attacking ends here
	
check_frog_status:
check_frog_attacked:
	beq $s2, FALSE, check_frog_jump
	# check if the tongue collided with the bug
	lw $a0, 0($s1)	# load position of enemy as argument
	move $a1, $s3
	jal enemy_collision	# check if the leftmost pixel of tongue collide with enemy
	beq $v0, TRUE, hit_enemy
	j moved_frog
hit_enemy:
	# reduces enemy HP by 1
	lw $t9, 16($s1)	#load original HP
	addi $t9, $t9, -1
	sw $t9, 16($s1) #save new HP

	j moved_frog
	
check_frog_jump:
	li $t9, FALSE
	sw $t9, 20($s1)	# set enemy to not hit
	# check if frog jumping, then redraw frog
	lw $t9, 20($s0)
	beq $t9, FALSE, check_frog_fall
	jal jump
	j moved_frog
check_frog_fall:
	# check if frog falling
	lw $t9, 16($s0)				# if on platform -> not falling
	beq $t9, TRUE, check_frog_moved
	lw $t9, 20($s0)				# if jumping -> not falling
	beq $t9, TRUE, check_frog_moved
	jal fall
	j moved_frog
	
check_frog_moved:
	# check if our frog moves
	lw $t9, 8($s0)
	beq $t9, FALSE, draw	# frog not moved then do not earase anything
	
moved_frog:
	# check if the frog touches the bottom
	# if yes instant fail
	
	lw $t7, 0($s0)	# set $t8 to the position of frog
	# we are using a loop to go to the last row cuz the offset
	# number is too big and out of boundary
	### at this point I am just writing comments for myself
	### FROGGO's name is FRODDO!
	li $t9, 0	# $t9 will be all the positions on the last row
	li $t8, 0	# loop counter
to_last_row:
	addi $t8, $t8, 1
	bgt $t8, 127, check_bottom
	addi $t9, $t9, SHIFT_ROW
	j to_last_row
check_bottom:
	# $t9 at the start of the last row
	# if $t9 <= player position, the player is at the bottom row
	ble $t7, $t9, check_edge
	j fail
	
check_edge:	
	### loop through every single pixel on the edge cuz I'm out of time to do a cleverer way
	# check if collided with frog
	# if yes, instant fail
	# don't check the top cuz froggo would never reach there	
	li $t8, 0	# initiate loop counter
	li $t9, 0	# initiate the first pixel on edges to be checked
	lw $t7, 0($s0)	# set $t7 to the position of frog
	# in this loop, $t9 = pixel to be checked
check_edge_loop:
	move $a0, $t7	# set argument 1 to position of frog
	move $a1, $t9
	addi, $sp, $sp, -4
	sw $t8, 0($sp)	# save value of $t8 into stack
	addi, $sp, $sp, -4
	sw $t9, 0($sp)	# save value of $t9 into stack
	jal collision
	lw $t9, 0($sp)		# load value of $t9, $t8 back from stack
	lw $t8, 4($sp)
	addi, $sp, $sp, 8			# clean stack
	beq $v0, TRUE, fail	# if collided with edge, game fails
	
	addi $t9, $t9, 508	# check last pixel of the row
	move $a0, $t7	# set argument 1 to position of frog
	move $a1, $t9
	addi, $sp, $sp, -4
	sw $t8, 0($sp)	# save value of $t8 into stack
	addi, $sp, $sp, -4
	sw $t9, 0($sp)	# save value of $t9 into stack
	jal collision
	lw $t9, 0($sp)		# load value of $t9, $t8 back from stack
	lw $t8, 4($sp)
	addi, $sp, $sp, 8			# clean stack
	beq $v0, TRUE, fail	# if collided with edge, game fails

	addi $t9, $t9, 4	# go to the next row
	addi $t8, $t8, 1	# increment loop counter
	bgt $t8, 127, draw_prev
	j check_edge_loop
	
draw_prev:
	# erase frog at previous position by filling in background colour
	lw $a0, 4($s0)	# pass player previous location as parameter
	li $a1, BLACK
	# check previous sprite and paint it black in previous position
	lw $t9, 28($s0)
	beq $t9, NORMAL_LEFT, draw_prev_left
	
	beq $t9, ATK_LEFT, draw_prev_atk_left
	beq $t9, ATK_RIGHT, draw_perv_atk_right
draw_prev_right:
	jal draw_frog_right
	j draw
draw_prev_left:
	jal draw_frog_left
	
	j draw
draw_prev_atk_left:
	jal draw_atk_frog_left
	j draw
draw_perv_atk_right:
	jal draw_atk_frog_right
	
draw:

draw_bullet:
	# if state of enemy = top to bottom or bottom to top, do nothing
	lw $t9, 8($s1)
	beq $t9, BTT, draw_enemy
	beq $t9, TTB, draw_enemy
	# erase previous bullet
	li $t8, BLACK
	lw $t9, 12($s1)
	addi $t9, $t9, BASE_ADDRESS
	sw $t8, ($t9)
	sw $t8, 4($t9)
	
	# if the bullet is on last column
	# then don't draw the bullet
	# and set the bug to a moving state
	
	### I should not have hard coded this but here it is:
	### at the BOTTOM position, the right most offset of the row
	### = (ENEMY_BOTTOM_POSITION + BULLET_START)//SHIFT_ROW * SHIFT_ROW + SHIFT_ROW - 4
	### = (ENEMY_BOTTOM_POSITION -12744)//512 * 512 + 508
	### = 36348
	### similarly we get the at the TOP position, the right most offset of the row
	### = 19964
	addi $t9, $t9, 4
	addi $t9, $t9, -BASE_ADDRESS
	beq $t9, 36348, set_enemy_BTT
	beq $t9, 19964, set_enemy_TTB
	addi $t9, $t9, BASE_ADDRESS
	
draw_new_bullet:	
	# draw new bullet
	li $t8, WHITE
	sw $t8, ($t9)
	sw $t8, 4($t9)
	# save new bullet position
	addi $t9, $t9, -BASE_ADDRESS
	sw $t9, 12($s1)
	
	### collision logic
	lw $a0, 0($s0)	# load position of frog as argument
	move $a1, $t9
	jal collision	# check if the bullet collide with frog
	beq $v0, TRUE, hit_frog
	# frog is not hit
	li $s4, FALSE
	j heartup_check
hit_frog:
	# if $s4 == TRUE, the frog was hit already on the previous loop
	# then do not further reduce lives
	# else, set frog to hit and reduce lives by one
	beq $s4, TRUE, heartup_check
	li $s4, TRUE
	addi $s5, $s5, -1
#	# if lives == 0, fail
#	beq $s5, FALSE, end
	j heartup_check
	
# set the bug into moving
set_enemy_BTT:
	li $t8, BTT
	sw $t8, 8($s1)
	j heartup_check
set_enemy_TTB:
	li $t8, TTB
	sw $t8, 8($s1)
# end of draw_bullet

# check for power up
heartup_check:
	beq $s6, 1, heartup_event	# if the heartup is present, check collision
	j draw_enemy
heartup_event:
	# repaint in case of being erased by bullet
	li $a0, HEARTUP_POSITION
	li $a1, WHITE
	jal draw_heart
	# check collision
	lw $a0, 0($s0)
	li $a1, HEARTUP_POSITION
	jal collision
	beq $v0, 1, heartup_success
	j draw_enemy
	# collided, i.e. frog reached powerup
heartup_success:	
	li $a0, HEARTUP_POSITION	# erase the heart
	li $a1, BLACK
	jal draw_heart
	li $s6, 0			# set heartup chance as used up
	addi $s5, $s5, 1		# increase lives by 1
	
### try draw enemy
### position to call draw our bug found!!!!
draw_enemy:
	lw $t9, 8($s1) # load the state of enemy
	# if at a stable state, no need to erase last frame
	beq $t9, TOP, repaint_enemy
	beq $t9, BOTTOM, repaint_enemy
	lw $a0, 4($s1)
	li $a1, BLACK
	jal draw_bug
# check which way is the enemy going
	beq $t9, TTB, enemy_go_down
	beq $t9, BTT, enemy_go_up
	
enemy_go_down:
	lw $t9, 0($s1)		# laod the current position
	addi $t9, $t9, ENEMY_VELOCITY
	sw $t9, 0($s1)		# save new position
	beq $t9, ENEMY_BOTTOM_POSITION, set_enemy_BOTTOM # if reaches desired position, set new state
	j repaint_enemy
	
set_enemy_BOTTOM:
	li $t9, BOTTOM
	sw $t9, 8($s1)
	li $t9, ENEMY_BOTTOM_POSITION
	addi $t9, $t9, BULLET_START
	sw $t9, 12($s1)
	j repaint_enemy
	
enemy_go_up:
	lw $t9, 0($s1)		# laod the current position
	addi $t9, $t9, -ENEMY_VELOCITY
	sw $t9, 0($s1)		# save new position
	beq $t9, ENEMY_TOP_POSITION, set_enemy_TOP # if reaches desired position, set new state
	j repaint_enemy
	
set_enemy_TOP:
	li $t9, TOP
	sw $t9, 8($s1)
	li $t9, ENEMY_TOP_POSITION
	addi $t9, $t9, BULLET_START
	sw $t9, 12($s1)
	j repaint_enemy

repaint_enemy:
	lw $a0, 0($s1)
	li $a1, WHITE
	jal draw_bug
	
draw_frog:
	# draw frog at current position
	lw $a0, 0($s0)	# pass player location as parameter
	li $a1, WHITE
	# check sprite number and paint corresponding sprite
	lw $t9, 12($s0)
	beq $t9, NORMAL_LEFT, draw_left
	
	beq $t9, ATK_LEFT, draw_atk_left
	beq $t9, ATK_RIGHT, draw_atk_right
	
draw_right:	
	jal draw_frog_right
	j display_stats
draw_left:
	jal draw_frog_left
	
	j display_stats
draw_atk_left:
	jal draw_atk_frog_left
	j display_stats
draw_atk_right:
	jal draw_atk_frog_right
	
display_stats:
enemy_health_bar:
# draw black bars
	li $t8, HP_POSITION
	li $t9, MAX_HP	# loop for MAX_HP times
empty_bars:
	move $a0, $t8
	li $a1, BLACK
	jal draw_bar
	addi $t8, $t8, 8
	addi $t9, $t9, -1
	bgt $t9, 0, empty_bars
	
	lw $t9, 16($s1)	#load enemy HP
	beq $t9, 0, win
	
	li $t8, HP_POSITION	# draw the hearts
filled_bars:
	move $a0, $t8
	li $a1, WHITE
	jal draw_bar
	addi $t8, $t8, 8
	addi $t9, $t9, -1
	bgt $t9, 0, filled_bars

frog_health_bar:	
	# draw 5 black hearts
	li $t8, LIVES_POSITION
	li $t9, MAX_LIVES	# loop for 5 times
empty_hearts:
	move $a0, $t8
	li $a1, BLACK
	jal draw_heart
	addi $t8, $t8, 32
	addi $t9, $t9, -1
	bgt $t9, 0, empty_hearts
	
	beq $s5, 0, fail		# if lives == 0, fail game
	
	li $t8, LIVES_POSITION	# draw the hearts
	move $t9, $s5
filled_hearts:
	move $a0, $t8
	li $a1, WHITE
	jal draw_heart
	addi $t8, $t8, 32
	addi $t9, $t9, -1
	bgt $t9, 0, filled_hearts

end_loop:
	# sleep for 33 ms til the next iteration
	li $v0, 32
	li $a0, 33
	syscall
	j main_loop
##################
end:	
	# check key press
	li $a1, 0xffff0000
	lw $t9, 0($a1)
	bne $t9, 1, end_cont	# if key pressed, respond
	lw $t0, 4($a1)
	beq $t0, 0x70, respond_p	# ASCII code of 'p' is 0x70
	
end_cont:
	# sleep for 33 ms til the next iteration
	li $v0, 32
	li $a0, 33
	syscall
	j end
####################
win:
	jal clear_screen
	li $a0, 33520
	li $a1, WHITE
	jal draw_frog_right
	sw $a1, -4($a0)
	sw $a1, -8($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	sw $a1, 20($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 0($a0)
	sw $a1, 12($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	addi $a0, $a0, SHIFT_ROW
	addi $a0, $a0, SHIFT_ROW
	addi $a0, $a0, SHIFT_ROW
	addi $a0, $a0, SHIFT_ROW
	addi $a0, $a0, SHIFT_ROW
	addi $a0, $a0, SHIFT_ROW
	addi $a0, $a0, SHIFT_ROW
	addi $a0, $a0, SHIFT_ROW
	li $a1, BLACK
	sw $a1, -4($a0)
	j end
	
fail:
	jal clear_screen
	li $a0, 33520
	li $a1, WHITE
	jal draw_frog_right
	addi $a0, $a0, SHIFT_ROW
	addi $a0, $a0, SHIFT_ROW
	addi $a0, $a0, SHIFT_ROW
	addi $a0, $a0, SHIFT_ROW
	addi $a0, $a0, SHIFT_ROW
	addi $a0, $a0, SHIFT_ROW
	li $a1, BLACK
	sw $a1, -4($a0)
	j end
	
#####################################################################
# function: respond to key press
# Recieves: $a1
# Uses: $t9
#####################################################################
keypress:
	lw $t0, 4($a1)
	
	lw $t9, 20($s0)			# load jumping status
	beq $t9, TRUE, end_press	# do nothing if the frog is already jumping
	lw $t9, 16($s0)
	beq $t9, FALSE, end_press	# do nothing if the frog is not on a platform
	
	beq $t0, 0x61, respond_a	# ASCII code of 'a' is 0x61
	beq $t0, 0x64, respond_d	# ASCII code of 'd' is 0x64
	beq $t0, 0x77, respond_w	# ASCII code of 'w' is 0x77
	beq $t0, 0x70, respond_p	# ASCII code of 'p' is 0x70
	beq $t0, 0x20, respond_space	# ASCII code of ' ' is 0x20
	j end_press

respond_space:
	# do nothing if it is already attacking
	bgt $s2, 0, end_press
	# else, set attack_counter to 1
	li $s2, 1
	j end_press

respond_a:
	# if attacking, set sprite to ATk_LEFT
	bgt $s2, 0, set_ATK_LEFT
	li $t9, NORMAL_LEFT
	sw $t9, 12($s0)	# else, set current spr to NORMAL_LEFT
	j go_left
set_ATK_LEFT:
	li $t9, ATK_LEFT
	sw $t9, 12($s0)
go_left:
	# go left
	lw $t9, 0($s0)		
	addi $t9, $t9, -X_VELOCITY
	sw $t9, 0($s0)		# set new position
	
	li $t9, TRUE
	sw $t9, 8($s0)		# set frog moved status to true
	j end_press
	
respond_d:
	# if attacking, set sprite to ATk_RIGHT
	bgt $s2, 0, set_ATK_RIGHT
	li $t9, NORMAL_RIGHT
	sw $t9, 12($s0)	# else, set current sprite to NORMAL_RIGHT
	j go_right
set_ATK_RIGHT:
	li $t9, ATK_RIGHT
	sw $t9, 12($s0)
go_right:
	# go right	
	lw $t9, 0($s0)
	addi $t9, $t9, X_VELOCITY
	sw $t9, 0($s0)		# set new position
	
	li $t9, TRUE
	sw $t9, 8($s0)		# set frog moved status to true	
	j end_press
	
respond_w:
	# do nothing if it is already attacking
	bgt $s2, 0, end_press
	# jump
	li $t0, 0			# set jumping time to 0
	sw $t0, 24($s0)
	li $t9, TRUE			# set frog jumping status to TRUE
	sw $t9, 20($s0)
	j end_press
	
respond_p:
	jal clear_screen
	j main
	
end_press:
	jr $ra
#####################################################################
clear_screen:
	li $t9, BASE_ADDRESS
	li $t8, 65532
	li $t7, BLACK
clear_screen_loop:
	sw $t7, ($t9)
	addi $t9, $t9, 4
	addi $t8, $t8, -4
	bltz $t8, clear_screen_loop_end
	j clear_screen_loop
clear_screen_loop_end:
	jr $ra
#####################################################################

#####################################################################
# function: to check whether a pixel collides with the frog
#	at specified position
# Arguments and Return Value:
#	- $a0 = position offset of frog to be checked
#	- $a1 = offset of pixel to be checked (pix)
#	- $v0 = return value (boolean)
# Uses:
#	- $t9 = sprite of frog and ending position of each row
# 	- $t8 = loop counter
#####################################################################
collision:
	# checks direction of the frog to determine the starting position of
	# hitbox
	lw $t9, 12($s0)
	beq $t9, NORMAL_RIGHT, right_hitbox
	beq $t9, ATK_RIGHT, right_hitbox
left_hitbox:
	# moves $a0 6 units to the left as starting position of
	# hitbox
	addi $a0, $a0, -24
	j hitbox_checking
right_hitbox:
	# moves $a0 4 units to the left as starting position of
	# hitbox
	addi $a0, $a0, -16
hitbox_checking:
	li $t8, 0 # initiate loop counter
hitbox_checking_loop:
	# checking whether the pixel to check is within the row of
	# hitbox we are checking
	addi $t9, $a0, 40 # calculate ending position of hit box at this row
	ble $a0, $a1, collision_check_b	# check if starting position of the row of hitbox <= pix
	j hitboc_check_loop_cont
collision_check_b:
	ble $a1, $t9, collided	# if row starting position <= pix <= row ending position, collided
hitboc_check_loop_cont:
	addi $a0,$a0, -SHIFT_ROW # check the above row
	addi $t8, $t8, 1	# increment loop counter
	bgt $t8,18, not_collided	# loop for 19 iterations
	j hitbox_checking_loop

collided:
	li $v0, TRUE
	jr $ra
not_collided:
	li $v0, FALSE
	jr $ra


#####################################################################
# function: handles jumping
# uses:	- 24($s0): time counter for jumping
# 	- 0($s0): current position offset
#	- 4($s0): old position offset
#	- 20($s0): jumping status
#	- $t1 = gravity*deltaTime
#	- $t2 = offset of change in position
#####################################################################
jump:
	
	lw $t0, 24($s0) # $t0 stores jumping time - 1
	addi $t0, $t0, -1
	
	# calculate $t1 = gravity*deltaTime
	sll $t1, $t0, 11
	# calculate $t2 = offset of change in position = Y_VELOCITY + $t1
	li $t2, Y_VELOCITY
	add $t2, $t2, $t1
	
	# if $t2 == 0, then ends jump
	beq $t2, 0, end_jump
	
	# set new position
	lw $t9, 0($s0)	# get current position offset
	add $t9, $t2, $t9	# calculate new offset
	lw $t8, 12($s0)	# load direction of jump
	beq $t8, 1, jump_right
jump_left:
	addi $t9, $t9, -X_VELOCITY
	j set_jump
jump_right:
	addi $t9, $t9, X_VELOCITY
set_jump:
	sw $t9, 0($s0)	# set new position
	
	addi $t0, $t0, 2
	sw $t0, 24($s0)	# increment jumping time by 1
	
	jr $ra
	
end_jump:
	
	li $t9, FALSE	# set from jumping status to FALSE
	sw $t9, 20($s0)
	li $t0, 0	# set falling time to 0
	sw $t0, 24($s0)
	jr $ra

#####################################################################
# function: handles falling
# uses:	- 24($s0): time counter for falling
# 	- 0($s0): current position offset
#	- 4($s0): old position offset
#	- $t0 = falling time
#	- $t1 = offset of change in position
#	- $t8 = direction of fall
#####################################################################
fall:
	lw $t0, 24($s0) # $t0 stores falling time
	# calculate $t1 = gravity*deltaTime
	sll $t1, $t0, 11
	
	# set terminal verlocity to -Y_VELOCITY ONLY
	blt $t1, NEG_Y_VELOCITY, cal_new_position
set_terminal_spd:
	li $t1, NEG_Y_VELOCITY
	
cal_new_position:	
	# set new position
	lw $t9, 0($s0)	# get current position offset
	add $t1, $t1, $t9	# calculate new offset
	lw $t8, 12($s0)	# load direction of fall
	beq $t8, 1, fall_right
fall_left:
	addi $t1, $t1, -X_VELOCITY
	j check_fall
fall_right:
	addi $t1, $t1, X_VELOCITY
check_fall:
	# check if the position would collide with a platform
	# loop through every pixel of each platform
	# check if thit collided with the character
	# if collided, set the new position to the checked pixel instead
check_fall_A:
	li $a1, PLATFORM_A_OFFSET	# set $a1
	# set loop counter
	li $t2, PLATFORM_LENGTH
check_fall_loop_A:
	addi $sp, $sp, -4	# save $ra and $t1 in stack
	sw $ra, 0($sp)
	addi $sp, $sp, -4
	sw $t1, 0($sp)
	jal collision
	lw $t1, 0($sp)		# load $t1 from stack
	lw $ra, 4($sp)		# load $ra from stack
	addi $sp, $sp, 8	# clean stack
	beq $v0, TRUE, set_fall_collided	# if collided, go to set_fall_collided
	
	addi $a1, $a1, 4			# check next pixel on platform
	addi $t2, $t2, -4			# updating loop counter by -4
	beq $t2, 0, check_fall_B		# if counter==0, loop terminates
	j check_fall_loop_A
### I should have written a function for this but sorry I'm too lazy and done now
check_fall_B:
	li $a1, PLATFORM_B_OFFSET	# set $a1
	# set loop counter
	li $t2, PLATFORM_LENGTH
check_fall_loop_B:
	addi $sp, $sp, -4	# save $ra and $t1 in stack
	sw $ra, 0($sp)
	addi $sp, $sp, -4
	sw $t1, 0($sp)
	move $a0, $t1		# set $a0 as new offset calculated
	jal collision
	lw $t1, 0($sp)		# load $t1 from stack
	lw $ra, 4($sp)		# load $ra from stack
	addi $sp, $sp, 8	# clean stack
	beq $v0, TRUE, set_fall_collided	# if collided, go to set_fall_collided
	
	addi $a1, $a1, 4			# check next pixel on platform
	addi $t2, $t2, -4			# updating loop counter by -4
	beq $t2, 0, check_fall_C			# if counter==0, loop terminates
	j check_fall_loop_B
	
check_fall_C:
	li $a1, PLATFORM_C_OFFSET	# set $a1
	# set loop counter
	li $t2, PLATFORM_LENGTH
check_fall_loop_C:
	addi $sp, $sp, -4	# save $ra and $t1 in stack
	sw $ra, 0($sp)
	addi $sp, $sp, -4
	sw $t1, 0($sp)
	move $a0, $t1		# set $a0 as new offset calculated
	jal collision
	lw $t1, 0($sp)		# load $t1 from stack
	lw $ra, 4($sp)		# load $ra from stack
	addi $sp, $sp, 8	# clean stack
	beq $v0, TRUE, set_fall_collided	# if collided, go to set_fall_collided
	
	addi $a1, $a1, 4			# check next pixel on platform
	addi $t2, $t2, -4			# updating loop counter by -4
	beq $t2, 0, set_fall			# if counter==0, loop terminates
	j check_fall_loop_C
	
set_fall_collided:
	
	# set new position to collided platform pixel + SHIFT_ROW
	addi $a1, $a1, -SHIFT_ROW
	sw $a1, 0($s0)
	
	jr $ra
	
set_fall:
	sw $t1, 0($s0)	# set new position
	
	addi $t0, $t0, 1
	sw $t0, 24($s0)	# increment falling time by 1
	
	jr $ra
	
#####################################################################
# function: to check whether a pixel collides with the enemy
#	at specified position
# Arguments and Return Value:
#	- $a0 = position offset of enemy to be checked
#	- $a1 = offset of pixel to be checked (pix)
#	- $v0 = return value (boolean)
# Uses:
#	- $t9 = ending position of each row
# 	- $t8 = loop counter
#####################################################################
enemy_collision:
	# set hit box starting position by loop
	li $t8, 0 # initiate loop counter
set_enemy_hitbox:
	addi $a0, $a0, -SHIFT_ROW
	addi $t8, $t8, 1
	bgt $t8, 7, end_set_enemy_hitbox
	j set_enemy_hitbox
end_set_enemy_hitbox:
	li $t8, 0 # initiate loop counter
enemy_hitbox_checking:
	# checking whether the pixel to check is within the row of
	# hitbox we are checking
	addi $t9, $a0, 52 # calculate ending position of hit box at this row
	ble $a0, $a1, enemy_collision_check_b	# check if starting position of the row of hitbox <= pix
	j enemy_hitbox_check_loop_cont
enemy_collision_check_b:
	ble $a1, $t9, enemy_collided	# if row starting position <= pix <= row ending position, collided
enemy_hitbox_check_loop_cont:
	addi $a0,$a0, -SHIFT_ROW # check the above row
	addi $t8, $t8, 1	# increment loop counter
	bgt $t8,24, enemy_not_collided	# loop for 25 iterations
	j enemy_hitbox_checking

enemy_collided:
	li $v0, TRUE
	lw $t9, 20($s1)	# $t9  is the status of whether enemy was hit on the previous loop
	# if it is hit on the previous loop, there is no new collision
	beq $t9, FALSE, new_enemy_collision
	sw $v0, 20($s1)	# set enemy to hit
	li $v0, FALSE	# return FALSE
	jr $ra
new_enemy_collision:
	sw $v0, 20($s1)	# set enemy to hit
	jr $ra
enemy_not_collided:
	li $v0, FALSE
	sw $v0, 20($s1)	# set enemy to not hit
	jr $ra
					
#####################################################################
# function: to draw platforms
# Arguments:
#   $a0 - Platform offset
#   $a1 - Platform length
# Uses:
# $t0 = colour white
# $t1 = loop counter
# $t2 = pixel to be filled starting from leftmost
#####################################################################
draw_platform:
    	li $t0, WHITE           # Load color value to $t0
    	li $t1, 0              # Initialize loop counter to 0

    platform_loop:
        addi $t2, $a0, BASE_ADDRESS # Calculate memory address by adding BASE_ADDRESS to platform offset
        add $t2, $t2, $t1    # Add $t1 to the memory address
        sw $t0, ($t2)        # Store $t0 (WHITE) at the memory address
        addi $t1, $t1, 4     # Increment $t1 by 4 to move to the next memory address
        blt $t1, $a1, platform_loop  # Branch to platform_loop if $t1 < platform length

    jr $ra                  # Return to calling function

#####################################################################	
# function: detects whether the frog is on a platform by checking
#		if player position is directly above a platform,
#		updates the its status when needed
# $t0, $t1, $t4: pixels directly above a platform
# $t2: loop counter
# $t3: frog position
# 16($s0): whether the frog is on a platform
#####################################################################
on_platform:
	
	# calculate $t0, $t1 by the position of platform - width of screen
	li $t0, PLATFORM_A_OFFSET
	addi $t0, $t0, -SHIFT_ROW
	li $t1, PLATFORM_B_OFFSET
	addi $t1, $t1, -SHIFT_ROW
	li $t4, PLATFORM_C_OFFSET
	addi $t4, $t4, -SHIFT_ROW
	# set $t9 to position of frog
	lw $t3, 0($s0) 
	# initiate loop counter as length of platforms
	li $t2, PLATFORM_LENGTH
	
on_platform_loop:
	# if the player position equals to pixels directly above a platform, return true
	beq $t3, $t0, on_platform_true
	beq $t3, $t1, on_platform_true
	beq $t3, $t4, on_platform_true
	# incrementing the pixels $t0 and $t1 to next pixels directly above each 
	# platform for checking next loop
	addi $t0, $t0, 4			
	addi $t1, $t1, 4
	addi $t4, $t4, 4			
	addi $t2, $t2, -4			# updating loop counter by -4
	beq $t2, 0, on_platform_false		# if counter==0, loop terminates, all pixels above
						#  platform checked, return False
	j on_platform_loop

on_platform_true:
	li $t9, 1	# set frog on_platform status to true
	sw $t9, 16($s0)
	j on_platform_end
on_platform_false:
	li $t9, 0	# set frog on_platform status to false
	sw $t9, 16($s0)
	j on_platform_end
on_platform_end:
	jr $ra
	
#####################################################################	
# function: draws the frog starting at bottom left position $a0
# parameters: $a1 = color, $a0 = position to draw
#####################################################################
draw_frog_right:
	addi, $a0, $a0, BASE_ADDRESS
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 0($a0)
	sw $a1, 8($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 0($a0)
	sw $a1, 8($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 0($a0)
	sw $a1, 8($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -16($a0)
	sw $a1, 0($a0)
	sw $a1, 8($a0)
	sw $a1, 20($a0)
	sw $a1, 24($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -16($a0)
	sw $a1, -8($a0)
	sw $a1, -4($a0)
	sw $a1, 0($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	sw $a1, 20($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -16($a0)
	sw $a1, -12($a0)
	sw $a1, -8($a0)
	sw $a1, -4($a0)
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	sw $a1, 20($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -12($a0)
	sw $a1, -8($a0)
	sw $a1, -4($a0)
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	sw $a1, 16($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -12($a0)
	sw $a1, -8($a0)
	sw $a1, -4($a0)
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	sw $a1, 16($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -12($a0)
	sw $a1, -8($a0)
	sw $a1, -4($a0)
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 16($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -8($a0)
	sw $a1, -4($a0)
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -8($a0)
	sw $a1, -4($a0)
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	sw $a1, 16($a0)
	sw $a1, 20($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -12($a0)
	sw $a1, -8($a0)
	sw $a1, -4($a0)
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	sw $a1, 16($a0)
	sw $a1, 20($a0)
	sw $a1, 24($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -12($a0)
	sw $a1, -8($a0)
	sw $a1, -4($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -12($a0)
	sw $a1, -8($a0)
	sw $a1, -4($a0)
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	sw $a1, 16($a0)
	sw $a1, 20($a0)
	sw $a1, 24($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -12($a0)
	sw $a1, -8($a0)
	sw $a1, -4($a0)
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	sw $a1, 16($a0)
	sw $a1, 20($a0)
	sw $a1, 24($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -8($a0)
	sw $a1, -4($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	sw $a1, 20($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -4($a0)
	sw $a1, 4($a0)
	sw $a1, 12($a0)
	sw $a1, 20($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 0($a0)
	sw $a1, 16($a0)
		
	jr $ra
	
draw_frog_left:
	addi, $a0, $a0, BASE_ADDRESS
	sw $a1, 0($a0)	
	sw $a1, -4($a0)
	sw $a1, -8($a0)
	sw $a1, -12($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 0($a0)
	sw $a1, -8($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 0($a0)
	sw $a1, -8($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 0($a0)
	sw $a1, -8($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 16($a0)
	sw $a1, 0($a0)
	sw $a1, -8($a0)
	sw $a1, -20($a0)
	sw $a1, -24($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 16($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 0($a0)
	sw $a1, -8($a0)
	sw $a1, -12($a0)
	sw $a1, -20($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 16($a0)
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 0($a0)
	sw $a1, -4($a0)
	sw $a1, -8($a0)
	sw $a1, -12($a0)
	sw $a1, -20($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 0($a0)
	sw $a1, -4($a0)
	sw $a1, -8($a0)
	sw $a1, -12($a0)
	sw $a1, -16($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 0($a0)
	sw $a1, -4($a0)
	sw $a1, -8($a0)
	sw $a1, -12($a0)
	sw $a1, -16($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 0($a0)
	sw $a1, -4($a0)
	sw $a1, -8($a0)
	sw $a1, -16($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 0($a0)
	sw $a1, -4($a0)
	sw $a1, -8($a0)
	sw $a1, -12($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 0($a0)
	sw $a1, -4($a0)
	sw $a1, -8($a0)
	sw $a1, -12($a0)
	sw $a1, -16($a0)
	sw $a1, -20($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 0($a0)
	sw $a1, -4($a0)
	sw $a1, -8($a0)
	sw $a1, -12($a0)
	sw $a1, -16($a0)
	sw $a1, -20($a0)
	sw $a1, -24($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 0($a0)
	sw $a1, -4($a0)
	sw $a1, -8($a0)
	sw $a1, -12($a0)
	sw $a1, -16($a0)
	sw $a1, -20($a0)
	sw $a1, -24($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 0($a0)
	sw $a1, -4($a0)
	sw $a1, -8($a0)
	sw $a1, -12($a0)
	sw $a1, -16($a0)
	sw $a1, -20($a0)
	sw $a1, -24($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, -4($a0)
	sw $a1, -8($a0)
	sw $a1, -12($a0)
	sw $a1, -20($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 4($a0)
	sw $a1, -4($a0)
	sw $a1, -12($a0)
	sw $a1, -20($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 0($a0)
	sw $a1, -16($a0)
		
	jr $ra
	
#####################################################################	
# function: draws the frog attacking starting at bottom left position $a0
# parameters: $a1 = color, $a0 = position to draw
#####################################################################
draw_atk_frog_right:
	addi, $a0, $a0, BASE_ADDRESS
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 0($a0)
	sw $a1, 8($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 0($a0)
	sw $a1, 8($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 0($a0)
	sw $a1, 8($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -16($a0)
	sw $a1, 0($a0)
	sw $a1, 8($a0)
	sw $a1, 20($a0)
	sw $a1, 24($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -16($a0)
	sw $a1, -8($a0)
	sw $a1, -4($a0)
	sw $a1, 0($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	sw $a1, 20($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -16($a0)
	sw $a1, -12($a0)
	sw $a1, -8($a0)
	sw $a1, -4($a0)
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	sw $a1, 20($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -12($a0)
	sw $a1, -8($a0)
	sw $a1, -4($a0)
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	sw $a1, 16($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -12($a0)
	sw $a1, -8($a0)
	sw $a1, -4($a0)
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	sw $a1, 16($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -12($a0)
	sw $a1, -8($a0)
	sw $a1, -4($a0)
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 16($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -8($a0)
	sw $a1, -4($a0)
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -8($a0)
	sw $a1, -4($a0)
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	sw $a1, 16($a0)
	sw $a1, 20($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -12($a0)
	sw $a1, -8($a0)
	sw $a1, -4($a0)
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	sw $a1, 16($a0)
	sw $a1, 20($a0)
	sw $a1, 24($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -12($a0)
	sw $a1, -8($a0)
	sw $a1, -4($a0)
	
	### ok here's where the mouth starts
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	sw $a1, 16($a0)
	sw $a1, 20($a0)
	sw $a1, 24($a0)
	### and the tongue starts sticking out!
	### draw an 13 pixel long tongue!
	sw $a1, 28($a0)	# 1
	sw $a1, 32($a0)	# 2
	sw $a1, 36($a0)	# 3
	sw $a1, 40($a0)	# 4
	sw $a1, 44($a0)	# 5
	sw $a1, 48($a0)	# 6
	sw $a1, 52($a0)	# 7
	sw $a1, 56($a0)	# 8
	sw $a1, 60($a0)	# 9
	sw $a1, 64($a0)	# 10
	sw $a1, 68($a0)	# 11
	sw $a1, 72($a0)	# 12
	sw $a1, 76($a0)	# 13
	
	### perhaps I should have done a loop instead
	# store the position of the leftmost position of tongue
	addi $s3, $a0, 76
	addi $s3, $s3, -BASE_ADDRESS
	
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -12($a0)
	sw $a1, -8($a0)
	sw $a1, -4($a0)
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	sw $a1, 16($a0)
	sw $a1, 20($a0)
	sw $a1, 24($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -12($a0)
	sw $a1, -8($a0)
	sw $a1, -4($a0)
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	sw $a1, 16($a0)
	sw $a1, 20($a0)
	sw $a1, 24($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -8($a0)
	sw $a1, -4($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	sw $a1, 20($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, -4($a0)
	sw $a1, 4($a0)
	sw $a1, 12($a0)
	sw $a1, 20($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 0($a0)
	sw $a1, 16($a0)
		
	jr $ra

draw_atk_frog_left:
	addi, $a0, $a0, BASE_ADDRESS
	sw $a1, 0($a0)	
	sw $a1, -4($a0)
	sw $a1, -8($a0)
	sw $a1, -12($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 0($a0)
	sw $a1, -8($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 0($a0)
	sw $a1, -8($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 0($a0)
	sw $a1, -8($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 16($a0)
	sw $a1, 0($a0)
	sw $a1, -8($a0)
	sw $a1, -20($a0)
	sw $a1, -24($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 16($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 0($a0)
	sw $a1, -8($a0)
	sw $a1, -12($a0)
	sw $a1, -20($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 16($a0)
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 0($a0)
	sw $a1, -4($a0)
	sw $a1, -8($a0)
	sw $a1, -12($a0)
	sw $a1, -20($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 0($a0)
	sw $a1, -4($a0)
	sw $a1, -8($a0)
	sw $a1, -12($a0)
	sw $a1, -16($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 0($a0)
	sw $a1, -4($a0)
	sw $a1, -8($a0)
	sw $a1, -12($a0)
	sw $a1, -16($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 0($a0)
	sw $a1, -4($a0)
	sw $a1, -8($a0)
	sw $a1, -16($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 0($a0)
	sw $a1, -4($a0)
	sw $a1, -8($a0)
	sw $a1, -12($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 0($a0)
	sw $a1, -4($a0)
	sw $a1, -8($a0)
	sw $a1, -12($a0)
	sw $a1, -16($a0)
	sw $a1, -20($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 0($a0)
	sw $a1, -4($a0)
	sw $a1, -8($a0)
	sw $a1, -12($a0)
	sw $a1, -16($a0)
	sw $a1, -20($a0)
	sw $a1, -24($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	### tongue starts!!!
	sw $a1, 0($a0)
	sw $a1, -4($a0)
	sw $a1, -8($a0)
	sw $a1, -12($a0)
	sw $a1, -16($a0)
	sw $a1, -20($a0)
	sw $a1, -24($a0)
	### tongue sticking out
	sw $a1, -28($a0)	# 1 
	sw $a1, -32($a0)	# 2
	sw $a1, -36($a0)	# 3
	sw $a1, -40($a0)	# 4
	sw $a1, -44($a0)	# 5
	sw $a1, -48($a0)	# 6
	sw $a1, -52($a0)	# 7
	sw $a1, -56($a0)	# 8
	sw $a1, -60($a0)	# 9
	sw $a1, -64($a0)	# 10
	sw $a1, -68($a0)	# 11
	sw $a1, -72($a0)	# 12
	sw $a1, -76($a0)	# 13
	
	# store the position of the leftmost position of tongue
	addi $s3, $a0, -76
	addi $s3, $s3, -BASE_ADDRESS
	
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 0($a0)
	sw $a1, -4($a0)
	sw $a1, -8($a0)
	sw $a1, -12($a0)
	sw $a1, -16($a0)
	sw $a1, -20($a0)
	sw $a1, -24($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 0($a0)
	sw $a1, -4($a0)
	sw $a1, -8($a0)
	sw $a1, -12($a0)
	sw $a1, -16($a0)
	sw $a1, -20($a0)
	sw $a1, -24($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, -4($a0)
	sw $a1, -8($a0)
	sw $a1, -12($a0)
	sw $a1, -20($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 4($a0)
	sw $a1, -4($a0)
	sw $a1, -12($a0)
	sw $a1, -20($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 0($a0)
	sw $a1, -16($a0)
		
	jr $ra
	
#####################################################################	
# function: draws a heart at $a0
# parameters: $a1 = color, $a0 = position to draw
###############8######################################################
draw_heart:
	addi, $a0, $a0, BASE_ADDRESS
	sw $a1, 12($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	sw $a1, 16($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	sw $a1, 16($a0)
	sw $a1, 20($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	sw $a1, 16($a0)
	sw $a1, 20($a0)
	sw $a1, 24($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 0($a0)
	sw $a1, 4($a0)
	sw $a1, 8($a0)
	sw $a1, 16($a0)
	sw $a1, 24($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 4($a0)
	sw $a1, 20($a0)
	
	jr $ra
#####################################################################
draw_bar:
	addi, $a0, $a0, BASE_ADDRESS
	sw $a1, 0($a0)
	addi $a0, $a0, SHIFT_ROW
	sw $a1, 0($a0)
	addi $a0, $a0, SHIFT_ROW
	sw $a1, 0($a0)
	addi $a0, $a0, SHIFT_ROW
	sw $a1, 0($a0)
	addi $a0, $a0, SHIFT_ROW
	sw $a1, 0($a0)
	addi $a0, $a0, SHIFT_ROW
	sw $a1, 0($a0)
	addi $a0, $a0, SHIFT_ROW

	jr $ra

#####################################################################	
# function: draws the king bug at $a0
# parameters: $a1 = color, $a0 = position to draw
###############8######################################################
draw_bug:
	addi, $a0, $a0, BASE_ADDRESS
	
	sw $a1, 16($a0)
	sw $a1, 40($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 16($a0)
	sw $a1, 40($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 16($a0)
	sw $a1, 40($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 16($a0)
	sw $a1, 12($a0)
	sw $a1, 40($a0)
	sw $a1, 44($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 12($a0)
	sw $a1, 44($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 8($a0)
	sw $a1, 12($a0)
	sw $a1, 44($a0)
	sw $a1, 48($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 8($a0)
	sw $a1, 48($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 28($a0)
	sw $a1, 24($a0)
	sw $a1, 20($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 32($a0)
	sw $a1, 36($a0)
	sw $a1, 48($a0)
	sw $a1, 52($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 28($a0)
	sw $a1, 24($a0)
	sw $a1, 20($a0)
	sw $a1, 16($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 32($a0)
	sw $a1, 36($a0)
	sw $a1, 40($a0)
	sw $a1, 48($a0)
	sw $a1, 52($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 20($a0)
	sw $a1, 16($a0)
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 36($a0)
	sw $a1, 40($a0)
	sw $a1, 44($a0)
	sw $a1, 48($a0)
	sw $a1, 52($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 16($a0)
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 40($a0)
	sw $a1, 44($a0)
	sw $a1, 48($a0)
	sw $a1, 52($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 28($a0)
	sw $a1, 24($a0)
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 32($a0)
	sw $a1, 44($a0)
	sw $a1, 48($a0)
	sw $a1, 52($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 28($a0)
	sw $a1, 24($a0)
	sw $a1, 20($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 32($a0)
	sw $a1, 36($a0)
	sw $a1, 48($a0)
	sw $a1, 52($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 28($a0)
	sw $a1, 4($a0)
	sw $a1, 20($a0)
	sw $a1, 16($a0)
	sw $a1, 8($a0)
	sw $a1, 24($a0)
	sw $a1, 32($a0)
	sw $a1, 36($a0)
	sw $a1, 40($a0)
	sw $a1, 48($a0)
	sw $a1, 52($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 28($a0)
	sw $a1, 24($a0)
	sw $a1, 20($a0)
	sw $a1, 16($a0)
	sw $a1, 12($a0)
	sw $a1, 32($a0)
	sw $a1, 36($a0)
	sw $a1, 40($a0)
	sw $a1, 44($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 28($a0)
	sw $a1, 24($a0)
	sw $a1, 20($a0)
	sw $a1, 16($a0)
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 32($a0)
	sw $a1, 36($a0)
	sw $a1, 40($a0)
	sw $a1, 44($a0)
	sw $a1, 48($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 28($a0)
	sw $a1, 24($a0)
	sw $a1, 20($a0)
	sw $a1, 16($a0)
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 32($a0)
	sw $a1, 36($a0)
	sw $a1, 40($a0)
	sw $a1, 44($a0)
	sw $a1, 48($a0)
	sw $a1, 52($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 20($a0)
	sw $a1, 16($a0)
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 36($a0)
	sw $a1, 40($a0)
	sw $a1, 44($a0)
	sw $a1, 48($a0)
	sw $a1, 52($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 16($a0)
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 40($a0)
	sw $a1, 44($a0)
	sw $a1, 48($a0)
	sw $a1, 52($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 24($a0)
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 32($a0)
	sw $a1, 44($a0)
	sw $a1, 48($a0)
	sw $a1, 52($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 24($a0)
	sw $a1, 20($a0)
	sw $a1, 8($a0)
	sw $a1, 32($a0)
	sw $a1, 36($a0)
	sw $a1, 48($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 24($a0)
	sw $a1, 20($a0)
	sw $a1, 16($a0)
	sw $a1, 32($a0)
	sw $a1, 36($a0)
	sw $a1, 40($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 24($a0)
	sw $a1, 20($a0)
	sw $a1, 16($a0)
	sw $a1, 12($a0)
	sw $a1, 32($a0)
	sw $a1, 36($a0)
	sw $a1, 40($a0)
	sw $a1, 44($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 24($a0)
	sw $a1, 20($a0)
	sw $a1, 16($a0)
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 32($a0)
	sw $a1, 36($a0)
	sw $a1, 40($a0)
	sw $a1, 44($a0)
	sw $a1, 48($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 24($a0)
	sw $a1, 20($a0)
	sw $a1, 16($a0)
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 32($a0)
	sw $a1, 36($a0)
	sw $a1, 40($a0)
	sw $a1, 44($a0)
	sw $a1, 48($a0)
	sw $a1, 52($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 24($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 32($a0)
	sw $a1, 48($a0)
	sw $a1, 52($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 24($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 32($a0)
	sw $a1, 48($a0)
	sw $a1, 52($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 24($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 32($a0)
	sw $a1, 48($a0)
	sw $a1, 52($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 24($a0)
	sw $a1, 20($a0)
	sw $a1, 16($a0)
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 32($a0)
	sw $a1, 36($a0)
	sw $a1, 40($a0)
	sw $a1, 44($a0)
	sw $a1, 48($a0)
	sw $a1, 52($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 20($a0)
	sw $a1, 16($a0)
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 36($a0)
	sw $a1, 40($a0)
	sw $a1, 44($a0)
	sw $a1, 48($a0)
	sw $a1, 52($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 16($a0)
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 40($a0)
	sw $a1, 44($a0)
	sw $a1, 48($a0)
	sw $a1, 52($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 12($a0)
	sw $a1, 8($a0)
	sw $a1, 4($a0)
	sw $a1, 44($a0)
	sw $a1, 48($a0)
	sw $a1, 52($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 4($a0)
	sw $a1, 52($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 4($a0)
	sw $a1, 52($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 4($a0)
	sw $a1, 52($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 4($a0)
	sw $a1, 52($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 4($a0)
	sw $a1, 52($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 4($a0)
	sw $a1, 52($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 8($a0)
	sw $a1, 48($a0)
	addi $a0, $a0, -SHIFT_ROW
	sw $a1, 12($a0)
	sw $a1, 44($a0)
	
	jr $ra
