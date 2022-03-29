# Henry Queen, 260916551
#
# -- Encrypt --
# 
# This method iterates over the input string and the key string, at each step shifting the 
# character in the input string by the character in the key string. Whenever the end of the key string is reached, we
# reset the key string iterator and continue.
#
# -- Decrypt --
#
# Same implementation as Encrypt, only difference is in how the input string is shifted by the key string
#
# -- GuessKey --
#
# This method iterates over the input string in step sizes of k, where k is the assumed length of the key. Thus, characters 
# are grouped together in their equivalence class (mod k) based on their index in the string. For each equivalence class, the method 
# counts the frequency of each character, stored in FREQ_ARRAY. Then, it uses the helper method FindMostFreq to determine
# which character was the most frequent in that group (Ties are broken by alphabetical order). Finally, it calculates
# which letter maps the 'most common character' guess to the most frequent character, and adds that letter to the key.


# Menu options
# r - read text buffer from file 
# p - print text buffer
# e - encrypt text buffer
# d - decrypt text buffer
# w - write text buffer to file
# g - guess the key
# q - quit

.data
MENU:              .asciiz "Commands (read, print, encrypt, decrypt, write, guess, quit):"
REQUEST_FILENAME:  .asciiz "Enter file name:"
REQUEST_KEY: 	 .asciiz "Enter key (upper case letters only):"
REQUEST_KEYLENGTH: .asciiz "Enter a number (the key length) for guessing:"
REQUEST_LETTER: 	 .asciiz "Enter guess of most common letter:"
ERROR:		 .asciiz "There was an error.\n"

FILE_NAME: 	.space 256	# maximum file name length, should not be exceeded
KEY_STRING: 	.space 256 	# maximum key length, should not be exceeded

.align 2		# ensure word alignment in memory for text buffer (not important)
TEXT_BUFFER:  	.space 10000
.align 2		# ensure word alignment in memory for other data (probably important)
# TODO: define any other spaces you need, for instance, an array for letter frequencies

FREQ_ARRAY:	.space 104	# array for letter frequencies
.align 2


##############################################################
.text
		move $s1 $0 	# Keep track of the buffer length (starts at zero)
MainLoop:	li $v0 4		# print string
		la $a0 MENU
		syscall
		li $v0 12	# read char into $v0
		syscall
		move $s0 $v0	# store command in $s0			
		jal PrintNewLine

		beq $s0 'r' read
		beq $s0 'p' print
		beq $s0 'w' write
		beq $s0 'e' encrypt
		beq $s0 'd' decrypt
		beq $s0 'g' guess
		beq $s0 'q' exit
		b MainLoop

read:		jal GetFileName
		li $v0 13	# open file
		la $a0 FILE_NAME 
		li $a1 0		# flags (read)
		li $a2 0		# mode (set to zero)
		syscall
		move $s0 $v0
		bge $s0 0 read2	# negative means error
		li $v0 4		# print string
		la $a0 ERROR
		syscall
		b MainLoop
read2:		li $v0 14	# read file
		move $a0 $s0
		la $a1 TEXT_BUFFER
		li $a2 9999
		syscall
		move $s1 $v0	# save the input buffer length
		bge $s0 0 read3	# negative means error
		li $v0 4		# print string
		la $a0 ERROR
		syscall
		move $s1 $0	# set buffer length to zero
		la $t0 TEXT_BUFFER
		sb $0 ($t0) 	# null terminate the buffer 
		b MainLoop
read3:		la $t0 TEXT_BUFFER
		add $t0 $t0 $s1
		sb $0 ($t0) 	# null terminate the buffer that was read
		li $v0 16	# close file
		move $a0 $s0
		syscall
		la $a0 TEXT_BUFFER
		jal ToUpperCase
print:		la $a0 TEXT_BUFFER
		jal PrintBuffer
		b MainLoop	

write:		jal GetFileName
		li $v0 13	# open file
		la $a0 FILE_NAME 
		li $a1 1		# flags (write)
		li $a2 0		# mode (set to zero)
		syscall
		move $s0 $v0
		bge $s0 0 write2	# negative means error
		li $v0 4		# print string
		la $a0 ERROR
		syscall
		b MainLoop
write2:		li $v0 15	# write file
		move $a0 $s0
		la $a1 TEXT_BUFFER
		move $a2 $s1	# set number of bytes to write
		syscall
		bge $v0 0 write3	# negative means error
		li $v0 4		# print string
		la $a0 ERROR
		syscall
		b MainLoop
		write3:
		li $v0 16	# close file
		move $a0 $s0
		syscall
		b MainLoop

encrypt:		jal GetKey
		la $a0 TEXT_BUFFER
		la $a1 KEY_STRING
		jal EncryptBuffer
		la $a0 TEXT_BUFFER
		jal PrintBuffer
		b MainLoop

decrypt:		jal GetKey
		la $a0 TEXT_BUFFER
		la $a1 KEY_STRING
		jal DecryptBuffer
		la $a0 TEXT_BUFFER
		jal PrintBuffer
		b MainLoop

guess:		li $v0 4		# print string
		la $a0 REQUEST_KEYLENGTH
		syscall
		li $v0 5		# read an integer
		syscall
		move $s2 $v0
		
		li $v0 4		# print string
		la $a0 REQUEST_LETTER
		syscall
		li $v0 12	# read char into $v0
		syscall
		move $s3 $v0	# store command in $s0			
		jal PrintNewLine

		move $a0 $s2
		la $a1 TEXT_BUFFER
		la $a2 KEY_STRING
		move $a3 $s3
		jal GuessKey
		li $v0 4		# print String
		la $a0 KEY_STRING
		syscall
		jal PrintNewLine
		b MainLoop

exit:		li $v0 10 	# exit
		syscall

###########################################################
PrintBuffer:	li $v0 4          # print contents of a0
		syscall
		li $v0 11	# print newline character
		li $a0 '\n'
		syscall
		jr $ra

###########################################################
PrintNewLine:	li $v0 11	# print char
		li $a0 '\n'
		syscall
		jr $ra

###########################################################
PrintSpace:	li $v0 11	# print char
		li $a0 ' '
		syscall
		jr $ra

#######################################################
GetFileName:	addi $sp $sp -4
		sw $ra ($sp)
		li $v0 4		# print string
		la $a0 REQUEST_FILENAME
		syscall
		li $v0 8		# read string
		la $a0 FILE_NAME  # up to 256 characters into this memory
		li $a1 256
		syscall
		la $a0 FILE_NAME 
		jal TrimNewline
		lw $ra ($sp)
		addi $sp $sp 4
		jr $ra

###########################################################
GetKey:		addi $sp $sp -4
		sw $ra ($sp)
		li $v0 4		# print string
		la $a0 REQUEST_KEY
		syscall
		li $v0 8		# read string
		la $a0 KEY_STRING  # up to 256 characters into this memory
		li $a1 256
		syscall
		la $a0 KEY_STRING
		jal TrimNewline
		la $a0 KEY_STRING
		jal ToUpperCase
		lw $ra ($sp)
		addi $sp $sp 4
		jr $ra

###########################################################
# Given a null terminated text string pointer in $a0, if it contains a newline
# then the buffer will instead be terminated at the first newline
TrimNewline:	lb $t0 ($a0)
		beq $t0 '\n' TNLExit
		beq $t0 $0 TNLExit	# also exit if find null termination
		addi $a0 $a0 1
		b TrimNewline
TNLExit:		sb $0 ($a0)
		jr $ra

##################################################
# converts the provided null terminated buffer to upper case
# $a0 buffer pointer
ToUpperCase:	lb $t0 ($a0)
		beq $t0 $zero TUCExit
		blt $t0 'a' TUCSkip
		bgt $t0 'z' TUCSkip
		addi $t0 $t0 -32	# difference between 'A' and 'a' in ASCII
		sb $t0 ($a0)
TUCSkip:		addi $a0 $a0 1
		b ToUpperCase
TUCExit:		jr $ra

###################################################
# END OF PROVIDED CODE... 
# TODO: use this space below to implement required procedures
###################################################


##################################################
# null terminated buffer is in $a0
# null terminated key is in $a1
EncryptBuffer:	

		# free up saved registers
		addi $sp, $sp, -16
		sw $s0, 0($sp)
		sw $s1, 4($sp)
		sw $s2, 8($sp)
		sw $s3, 12($sp)

		la $s0, TEXT_BUFFER	# load the string
		la $s1, KEY_STRING	# load the key
		
		li $s2, 65		# const 65
		li $s3, 90		# const 90
		
		EncryptLoop:
			
				lb $t0, 0($s0)			# load current string char
				lb $t1, 0($s1)			# load current key char
		
				beqz $t0, EncryptEnd		# check for end of string
		
				bnez $t1, Encrypt_Cont 		# check for end of key
				la $s1, KEY_STRING		# reset key iterator
				
				j EncryptLoop			# continue iterating 
		
			Encrypt_Cont:
		
				blt $t0, $s2, Encrypt_Skip	# if char < 65, then skip
				blt $s3, $t0, Encrypt_Skip	# if 90 < char, then skip
		
				addi $t0, $t0, -65		# shift string char by key char
				add $t0, $t0, $t1		# char = (char - 65) + key
		
				ble  $t0, $s3, EStore 		# if char <= 90, then store the char
				addi $t0, $t0, -26		# else, shift by -26 to correct overflow 
		
			EStore:
		
				sb $t0, 0($s0)			# store the shifted string char
		
			Encrypt_Skip:
			
				addi $s0, $s0, 1
				addi $s1, $s1, 1		# increment the iterators
		
			j EncryptLoop
			
		EncryptEnd:
		
		lw $s0, 0($sp)
		lw $s1, 4($sp)
		lw $s2, 8($sp)
		lw $s3, 12($sp)
		addi, $sp, $sp, 16
		
		jr $ra

##################################################
# null terminated buffer is in $a0
# null terminated key is in $a1
DecryptBuffer:	
		# free up saved registers
		addi $sp, $sp, -16
		sw $s0, 0($sp)
		sw $s1, 4($sp)
		sw $s2, 8($sp)
		sw $s3, 12($sp)

		la $s0, TEXT_BUFFER	# load the string
		la $s1, KEY_STRING	# load the key
		
		li $s2, 65		# const 65
		li $s3, 90		# const 90
		
		DecryptLoop:
			
				lb $t0, 0($s0)			# load current string char
				lb $t1, 0($s1)			# load current key char
		
				beqz $t0, DecryptEnd		# check for end of string
		
				bnez $t1, Decrypt_Cont 		# check for end of key
				la $s1, KEY_STRING		# reset key iterator
				j DecryptLoop			# continue iterating 
		
			Decrypt_Cont:
		
				blt $t0, $s2, Decrypt_Skip	# if char < 65, then skip
				blt $s3, $t0, Decrypt_Skip	# if 90 < char, then skip
		
				addi $t0, $t0, 65		# shift string char by key char
				sub $t0, $t0, $t1		# char = (char + 65) - key
		
				bge  $t0, $s2, DStore 		# if char >= 65, then store the char
				addi $t0, $t0, 26		# else, shift by 26 to correct overflow 
		
			DStore:
		
				sb $t0, 0($s0)			# store the shifted string char
		
			Decrypt_Skip:
			
				addi $s0, $s0, 1
				addi $s1, $s1, 1		# increment the iterators
		
			j DecryptLoop
			
		DecryptEnd:
		
		lw $s0, 0($sp)
		lw $s1, 4($sp)
		lw $s2, 8($sp)
		lw $s3, 12($sp)
		addi, $sp, $sp, 16
		
		jr $ra


###########################################################
# a0 keySize - size of key length to guess
# a1 Buffer - pointer to null terminated buffer to work with
# a2 KeyString - on return will contain null terminated string with guess
# a3 common letter guess - for instance 'E' 
GuessKey:
		# push saved registers to the stack
		addi $sp, $sp, -32
		sw $s0, 0($sp)
		sw $s1, 4($sp)
		sw $s2, 8($sp)
		sw $s3, 12($sp)
		sw $s4, 16($sp)
		sw $s5, 20($sp)
		sw $s6, 24($sp)
		sw $s7, 28($sp)
	
		
		move $s0, $a1		# load string
		move $s1, $a2		# load key
		la $s2, FREQ_ARRAY	# load FREQ_ARRAY

		li $s3, 0 		# iterator (i)
		
		# ~ Let k denote the keySize ($a0)
		
		GuessLoop:
			
			lb $t0, 0($s0)		# get current character
			beqz $t0, Guess_End	# check if we're at end of string
			
			bge $s3, $a0, Guess_End	# if i >= k, then end
			
			addi $sp, $sp, -4
			sw $ra , 0($sp)
			jal ClearFreqArray 	# Clear the frequency array
			lw $ra, 0($sp)
			addi, $sp, $sp, 4
			
			# $t0 - index of current character in string
			# $t1 - current character
			# $t2 - counter of character in FREQ_ARRAY
			
			move $t0, $s0				# get adress of the starting character
			GuessInnerLoop:
			
				lb $t1, 0($t0)			# get current character
				
				beqz $t1, GuessInnerEnd		# check if we're at end of string
				
				addi $t1, $t1, -65		# $t1 = char in {0, 1, ..., 25}
				
				blt $t1, 0, GuessInnerSkip	#
				bgt $t1, 25, GuessInnerSkip	# skip if this character isn't a letter
				
				sll $t1, $t1, 2			# char = 4 * char, to get index of char in FREQ_ARRAY
				
				add $t1, $t1, $s2		# $t1 = memory adress of char index in FREQ_ARRAY
				
				lw $t2, 0($t1)			#
				addi $t2, $t2, 1		# increment the counter by 1 and save in FREQ_ARRAY
				sw $t2, 0($t1)			#
				
			
			GuessInnerSkip:
			
				add $t0, $t0, $a0 		# increment index by k
				
				j GuessInnerLoop
			
			GuessInnerEnd:
				
			addi $sp, $sp, -4	#
			sw $ra , 0($sp)		#
			jal FindMostFreq	# find the most frequent letter in FREQ_ARRAY
			lw $ra, 0($sp)		#
			addi, $sp, $sp, 4	#
			
			move $s7, $v0		# fetch the most freq char from return 
			
			
			# $s4 = [(90 - guess) + (char - 65) + 1] + 65
			# This is the formula for calculating the key character, it can be simplified to
			# $s4 = (char - guess) + 91
			sub $s4, $s7, $a3	# $s4 = char - guess
			addi $s4, $s4, 91	# $s4 = char - guess + 91
			
			ble $s4, 90, Save	# check if we have overflow, subtract 26 if so
			addi $s4, $s4, -26
						
			
			Save:
			
			add $t5, $a2, $s3	# $t5 = i + key array adress = current key index
			sb $s4, 0($t5)		# Save the key character
				
			addi $s3, $s3, 1	# increment the iterators
			addi $s0, $s0, 1
		
		j GuessLoop
		
		Guess_End:
		
		add $s3, $s3, $a2
		sb $zero, 0($s3)	# put null character at end of key string
		
		
		# pop saved registers from stack
		lw $s0, 0($sp)
		lw $s1, 4($sp)
		lw $s2, 8($sp)
		lw $s3, 12($sp)
		lw $s4, 16($sp)
		lw $s5, 20($sp)
		lw $s6, 24($sp)
		lw $s7, 28($sp)
		addi, $sp, $sp, 32

		jr $ra
		
# Resets the FreqArray to all 0's			
ClearFreqArray:
		
		# push saved registers to stack
		addi $sp, $sp, -12
		sw $s0, 0($sp)
		sw $s1, 4($sp)
		sw $s2, 8($sp)
		
		la $s0 FREQ_ARRAY # load the array
		li $s1, 0	
		
		# s0 - base array adress
		# s1 - iterator
		# s2 - current index
		
		ResetLoop:
		
			bge $s1, 104, ResetLoopEnd 	# if at end of array, end loop
		
			add $s2, $s0, $s1		# get current adress
		
			sw $zero, 0($s2)		# set current index to 0

			addi $s1, $s1, 4		# increment iterator
	
			j ResetLoop
		
		ResetLoopEnd:
		
		# pop saved registers from the stack
		lw $s0, 0($sp)
		lw $s1, 4($sp)
		lw $s2, 8($sp)
		addi $sp, $sp, 12
		
		jr $ra		
		

FindMostFreq:

		# push saved registers to the stack
		addi $sp, $sp, -24
		sw $s0, 0($sp)
		sw $s1, 4($sp)
		sw $s2, 8($sp)
		sw $s3, 12($sp)
		sw $s4, 16($sp)
		sw $s5, 20($sp)
		
		# s0 - base array adress
		# s1 - iterator
		# s2 - current adress
		# s3 - current char
		# s4 - index of most freq char
		# s5 - frequency of most freq char
		
		la $s0, FREQ_ARRAY
		li $s5, 0		# initialize largest freq to 0
		
		li $s1, 0		# iterator
		
		FreqLoop:
		
			beq $s1, 104, FreqLoopEnd	# if at end of array, end loop
		
			add $s2, $s1, $s0		# current adress
		
			lw $s3, 0($s2)			# current char
		
			blt $s3, $s5, FreqLoopSkip	# if this char is less freq, skip
		
			move $s4, $s1			# Else, store this index as the most freq char
			move $s5, $s3			# update largest frequency
		
			FreqLoopSkip:
			addi $s1, $s1, 4		# increment iterator

			j FreqLoop
		
		FreqLoopEnd:
						# return the most freq char
		srl $s4, $s4, 2			# divide index by 4 to get index in {0, 1, ..., 25}		
		add $v0, $s4, 65		# add 65 to get ASCII value of the character	

		
		# pop saved registers from the stack
		lw $s0, 0($sp)
		lw $s1, 4($sp)
		lw $s2, 8($sp)
		lw $s3, 12($sp)
		lw $s4, 16($sp)
		lw $s5, 20($sp)
		addi $sp, $sp, 24
		
		jr $ra
