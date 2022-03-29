# Henry Queen, 260916551

.data
TestNumber:	.word 2	# TODO: Which test to run!
				# 0 compare matrices stored in files Afname and Bfname
				# 1 test Proc using files A through D named below
				# 2 compare MADD1 and MADD2 with random matrices of size Size
				
Proc:		MADD2 	 	# Procedure used by test 2, set to MADD1 or MADD2		
				
Size:		.word 64	# matrix size (MUST match size of matrix loaded for test 0 and 1)

Afname: 	.asciiz "A64.bin"
Bfname: 	.asciiz "B64.bin"
Cfname:		.asciiz "C64.bin"
Dfname:	 	.asciiz "D64.bin"

ZERO: .float 0.0	# zero float constant

#################################################################
# Main function for testing assignment objectives.
# Modify this function as needed to complete your assignment.
# Note that the TA will ultimately use a different testing program.
.text
main:		la $t0 TestNumber
		lw $t0 ($t0)
		beq $t0 0 compareMatrix
		beq $t0 1 testFromFile
		beq $t0 2 compareMADD
		li $v0 10 # exit if the test number is out of range
        		syscall	

compareMatrix:	la $s7 Size	
		lw $s7 ($s7)		# Let $s7 be the matrix size n

		move $a0 $s7
		jal mallocMatrix		# allocate heap memory and load matrix A
		move $s0 $v0		# $s0 is a pointer to matrix A
		la $a0 Afname
		move $a1 $s7
		move $a2 $s7
		move $a3 $s0
		jal loadMatrix
	
		move $a0 $s7
		jal mallocMatrix		# allocate heap memory and load matrix B
		move $s1 $v0		# $s1 is a pointer to matrix B
		la $a0 Bfname
		move $a1 $s7
		move $a2 $s7
		move $a3 $s1
		jal loadMatrix
	
		move $a0 $s0
		move $a1 $s1
		move $a2 $s7
		jal check
		
		li $v0 10      	# load exit call code 10 into $v0
        		syscall         	# call operating system to exit	

testFromFile:	la $s7 Size	
		lw $s7 ($s7)		# Let $s7 be the matrix size n

		move $a0 $s7
		jal mallocMatrix		# allocate heap memory and load matrix A
		move $s0 $v0		# $s0 is a pointer to matrix A
		la $a0 Afname
		move $a1 $s7
		move $a2 $s7
		move $a3 $s0
		jal loadMatrix
	
		move $a0 $s7
		jal mallocMatrix		# allocate heap memory and load matrix B
		move $s1 $v0		# $s1 is a pointer to matrix B
		la $a0 Bfname
		move $a1 $s7
		move $a2 $s7
		move $a3 $s1
		jal loadMatrix
	
		move $a0 $s7
		jal mallocMatrix		# allocate heap memory and load matrix C
		move $s2 $v0		# $s2 is a pointer to matrix C
		la $a0 Cfname
		move $a1 $s7
		move $a2 $s7
		move $a3 $s2
		jal loadMatrix
	
		move $a0 $s7
		jal mallocMatrix		# allocate heap memory and load matrix A
		move $s3 $v0		# $s3 is a pointer to matrix D
		la $a0 Dfname
		move $a1 $s7
		move $a2 $s7
		move $a3 $s3
		jal loadMatrix		# D is the answer, i.e., D = AB+C 
	
		# TODO: add your testing code here
		move $a0, $s0	# A
		move $a1, $s1	# B
		move $a2, $s2	# C
		move $a3, $s7	# n
				
		
		la $ra ReturnHere
		la $t0 Proc	# function pointer
		lw $t0 ($t0)	
		jr $t0		# like a jal to MADD1 or MADD2 depending on Proc definition

ReturnHere:	move $a0 $s2	# C	# move $a0 $s2	# C
		move $a1 $s3	# D	# move $a1 $s3	# D
		move $a2 $s7	# n
		jal check	# check the answer

		li $v0, 10      	# load exit call code 10 into $v0
	        	syscall         	# call operating system to exit	

compareMADD:	la $s7 Size
		lw $s7 ($s7)	# n is loaded from Size
		mul $s4 $s7 $s7	# n^2
		sll $s5 $s4 2	# n^2 * 4

		move $a0 $s5
		li   $v0 9	# malloc A
		syscall	
		move $s0 $v0
		move $a0 $s5	# malloc B
		li   $v0 9
		syscall
		move $s1 $v0
		move $a0 $s5	# malloc C1
		li   $v0 9
		syscall
		move $s2 $v0
		move $a0 $s5	# malloc C2
		li   $v0 9
		syscall
		move $s3 $v0	
	
		move $a0 $s0	# A
		move $a1 $s4	# n^2
		jal  fillRandom	# fill A with random floats
		move $a0 $s1	# B
		move $a1 $s4	# n^2
		jal  fillRandom	# fill A with random floats
		move $a0 $s2	# C1
		move $a1 $s4	# n^2
		jal  fillZero	# fill A with random floats
		move $a0 $s3	# C2
		move $a1 $s4	# n^2
		jal  fillZero	# fill A with random floats

		move $a0 $s0	# A
		move $a1 $s1	# B
		move $a2 $s2	# C1	# note that we assume C1 to contain zeros !
		move $a3 $s7	# n
		jal MADD1

		move $a0 $s0	# A
		move $a1 $s1	# B
		move $a2 $s3	# C2	# note that we assume C2 to contain zeros !
		move $a3 $s7	# n
		jal MADD2

		move $a0 $s2	# C1
		move $a1 $s3	# C2
		move $a2 $s7	# n
		jal check	# check that they match
	
		li $v0 10      	# load exit call code 10 into $v0
        		syscall         	# call operating system to exit	

###############################################################
# mallocMatrix( int N )
# Allocates memory for an N by N matrix of floats
# The pointer to the memory is returned in $v0	
mallocMatrix: 	mul  $a0, $a0, $a0	# Let $s5 be n squared
		sll  $a0, $a0, 2		# Let $s4 be 4 n^2 bytes
		li   $v0, 9		
		syscall			# malloc A
		jr $ra
	
###############################################################
# loadMatrix( char* filename, int width, int height, float* buffer )
.data
errorMessage: .asciiz "FILE NOT FOUND" 
.text
loadMatrix:	mul $t0 $a1 $a2 	# words to read (width x height) in a2
		sll $t0 $t0  2	  	# multiply by 4 to get bytes to read
		li $a1  0     		# flags (0: read, 1: write)
		li $a2  0     		# mode (unused)
		li $v0  13    		# open file, $a0 is null-terminated string of file name
		syscall
		slti $t1 $v0 0
		beq $t1 $0 fileFound
		la $a0 errorMessage
		li $v0 4
		syscall		  	# print error message
		li $v0 10         	# and then exit
		syscall		
fileFound:	move $a0 $v0     	# file descriptor (negative if error) as argument for read
  		move $a1 $a3     	# address of buffer in which to write
		move $a2 $t0	  	# number of bytes to read
		li  $v0 14       	# system call for read from file
		syscall           	# read from file
		# $v0 contains number of characters read (0 if end-of-file, negative if error).
                	# We'll assume that we do not need to be checking for errors!
		# Note, the bitmap display doesn't update properly on load, 
		# so let's go touch each memory address to refresh it!
		move $t0 $a3	# start address
		add $t1 $a3 $a2  	# end address
loadloop:	lw $t2 ($t0)
		sw $t2 ($t0)
		addi $t0 $t0 4
		bne $t0 $t1 loadloop		
		li $v0 16	# close file ($a0 should still be the file descriptor)
		syscall
		jr $ra	

##########################################################
# Fills the matrix $a0, which has $a1 entries, with random numbers
fillRandom:	li $v0 43
		syscall		# random float, and assume $a0 unmodified!!
		swc1 $f0 0($a0)
		addi $a0 $a0 4
		addi $a1 $a1 -1
		bne  $a1 $zero fillRandom
		jr $ra

##########################################################
# Fills the matrix $a0 , which has $a1 entries, with zero
fillZero:	sw $zero 0($a0)	# $zero is zero single precision float
		addi $a0 $a0 4
		addi $a1 $a1 -1
		bne  $a1 $zero fillZero
		jr $ra



######################################################
# TODO: void subtract( float* A, float* B, float* C, int N )  C = A - B 
# $a0 - A
# $a1 - B
# $a2 - C
# $a3 - N
subtract: 	
	
	# Push saved registers to the stack
	subi $sp, $sp, 28
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	
	s.s $f0, 16($sp)
	s.s $f1, 20($sp)
	s.s $f2, 24($sp)
	
	mult $a3, $a3
	mflo $t0	# $t0 = n^2
	sll $t0, $t0, 2	# $t0 = 4 * n^2, so that it can be compared to a byte iterator
	
	li $s0, 0	# iterator
	
	
	SubLoop:
	
		bge $s0, $t0, SubLoopExit 	# Check if i >= N^2	
	
		add $s1, $a0, $s0
		l.s $f0, 0($s1) 			# $f0 = A[i][j]
	
		add $s2, $a1, $s0
		l.s $f1, 0($s2) 			# $f1 = B[i][j]
	
		add $s3, $a2, $s0			# adress of C[i][j]
		
		sub.s $f2, $f0, $f1			# #t2 = A[i][j] - B[i][j]
	
		s.s $f2, 0($s3)				# save the result in C[i][j]

		addi $s0, $s0, 4			# increment the iterator
	
		j SubLoop
	
	SubLoopExit:
	
	# Pop saved registers from the stack
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	
	l.s $f0, 16($sp)
	l.s $f1, 20($sp)
	l.s $f2, 24($sp)
	addi $sp, $sp, 28
	
	jr $ra
	

#################################################
# TODO: float frobeneousNorm( float* A, int N )
# $a0 - A
# $a1 - N
frobeneousNorm: 

	
	# Push saved registers to the stack
	subi $sp, $sp, 20
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	
	s.s $f1, 16($sp)
	
	mult $a1, $a1
	mflo $t0	# $t0 = n^2
	sll $t0, $t0, 2	# $t0 = 4 * n^2, so that it can be compared to a byte iterator
	
	li $s0, 0	# iterator
	l.s $f0, ZERO	# sum = 0
	
	NormLoop:
	
		bge $s0, $t0, NormLoopExit 	# Check if i >= N^2
		
		add $s1, $s0, $a0		# get current adress
		
		l.s $f1, 0($s1)			# $f0 = A[i][j]
		
		mul.s $f1, $f1, $f1		# A[i][j]^2
		
		add.s $f0, $f0, $f1		# add to sum

		
		addi $s0, $s0, 4	# increment the iterator	
		j NormLoop
	
	NormLoopExit:	
	
	sqrt.s $f0, $f0		# find square root of sum
	
	# Pop saved registers from the stack
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	
	l.s $f1, 16($sp)
	
	addi $sp, $sp, 20

	jr $ra

#################################################
# TODO: void check ( float* C, float* D, int N )
# Print the forbeneous norm of the difference of C and D
# $a0 - C
# $a1 - D
# $a2 - N
check: 	
	
	subi $sp, $sp, 8
	sw $a3, 0($sp)
	sw $ra, 4($sp)
	
	move $a3, $a2	# move N to $a3
	move $a2, $a0	# copy C to $a2
	 
	jal subtract	# C = C-D
	
	move $a2, $a3	# restore N to $a2
	
	lw $a3, 0($sp)
	lw $ra, 4($sp)
	addi $sp, $sp, 8
	
	move $a1, $a2	# move N to $a1
	
	subi $sp, $sp, 4
	sw $ra, 0($sp)
	
	jal frobeneousNorm	# compute norm
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	li $v0, 2
	mov.s $f12, $f0	
	syscall

	jr $ra

##############################################################
# TODO: void MADD1( float*A, float* B, float* C, N )
# $a0 - A
# $a1 - B
# $a2 - C
# $a3 - N
MADD1: 		

	# Push saved registers to the stack
	subi $sp, $sp, 32
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	
	s.s $f1, 16($sp)
	s.s $f2, 20($sp)
	s.s $f3, 24($sp)
	s.s $f4, 28($sp)
	
	mult $a3, $a3	# n^2
	mflo $t0	# $t0 = n^2
	sll $t0, $t0, 2	# $t0 = 4 * n^2, so that it can be compared to a byte iterator
	
	sll $t1, $a3, 2 # $t1 = 4*n
	
	
	li $s0, 0	# iterator to track row of A
	
	AMultLoop:
	
		bge $s0, $t0, AMultLoopExit	# check if we are past (n-1)th row of A
	
		add $t2, $s0, $a0		# adress of current row in A
		
		
		li $s1, 0	# iterator to track the column of B
		nop
		BMultLoop:
		
			bge $s1, $t1, BMultLoopExit	# check if we are past nth column of B
			
			add $t3, $s1, $a1		# adress of current column in B
			
			li $s2, 0	# iterator for A-row
			li $s3, 0	# iterator for B-column
			
			InnerMultLoop:
			
				bge $s2, $t1, InnerLoopExit	# check if we are past nth row of B
					
				add $t4, $t2, $s2		# $t4 = adress of current element of A-row
				l.s $f1, 0($t4)			# $f1 = A[i][k]
				
				add $t4, $t3, $s3		# $t4 = adress of current element of B-column
				l.s $f2, 0($t4)			# $t2 = B[k][j]
				
				mul.s $f3, $f1, $f2		# $f3 = A[i][k] * B[k][j]
				
				add $t4, $s0, $s1		# $t4 = i + j
				add $t4, $t4, $a2		# $t4 = adress of C[i][j]
				l.s $f4, 0($t4)			# $f3 = C[i][j]
				
				add.s $f4, $f3, $f4		# $f4 = ab+c
				
				s.s $f4, 0($t4)			# save result in C
				
				addi $s2, $s2, 4		# $s2 += 4 (go over a column)
				add $s3, $s3, $t1		# $s3 += 4n (go down a row)
				j InnerMultLoop
				
			InnerLoopExit: 	
			
			addi $s1, $s1, 4		# $s1 += 4 (go over a column)
			j BMultLoop
			
		BMultLoopExit:
		nop
		
		add $s0, $s0, $t1	# $s0 += 4n (go down a row)
		j AMultLoop
		
	AMultLoopExit:	
		

	# Pop saved registers from the stack
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	
	l.s $f1, 16($sp)
	l.s $f2, 20($sp)
	l.s $f3, 24($sp)
	l.s $f4, 28($sp)
	
	addi $sp, $sp, 32

	jr $ra

#########################################################
# TODO: void MADD2( float*A, float* B, float* C, N )
# $a0 - A
# $a1 - B
# $a2 - C
# $a3 - N
MADD2: 		

	# Push saved registers to the stack
	subi $sp, $sp, 52
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	sw $s3, 12($sp)
	sw $s4, 16($sp)
	sw $s5, 20($sp)
	sw $s6, 24($sp)
	sw $s7, 28($sp)
	
	s.s $f1, 32($sp)
	s.s $f2, 36($sp)
	s.s $f3, 40($sp)
	s.s $f4, 44($sp)
	s.s $f5, 48($sp)
	s.s $f6, 52($sp)
	
	mult $a3, $a3	# n^2
	mflo $t0	# $t0 = n^2
	sll $t0, $t0, 2	# $t0 = 4 * n^2, so that it can be compared to a byte iterator
	
	sll $t1, $a3, 2 # $t1 = 4*n
	
	li $t2, 4
	
	# $t0 = 4n^2
	# $t1 = 4n
	# $t2 = 4
	
	# $s0 - jj $t0 - 
	# $s1 - kk
	# $s2 - i
	# $s3 - j
	# $s4 - k
	
	li $s0, 0 # jj
	Loop1:
		
		bge $s0, $a3, Loop1End		#  check that jj < n
		addi $t0, $s0, 4		# $t0 = jj + 4

		li $s1, 0 # kk
		Loop2:
		
			bge $s1, $a3, Loop2End		#  check that kk < n
			addi $s7, $s1, 4		# $s7 = kk + 4
			
			li $s2, 0 # i
			Loop3:
			
				bge $s2, $a3, Loop3End		#  check that i < n
				
				move $s3, $s0 #j
				Loop4:
				
					bge $s3, $t0, Loop4End	# check that j < min{n, jj+4}
					bge $s3, $a3, Loop4End
									
					mult $t1, $s2
					mflo $t3	# $t3 = 4n * i = current row of A and C
				
					sll $t4, $s3, 2	# $t6 = 4 * j = current column of B and C
					
					move $s4, $s1 	# k
					l.s $f1, ZERO	# $f1 = sum = 0
					
					Loop5:
					
						bge $s4, $s7, Loop5End	# check that k < min{n, kk+4}
						bge $s4, $a3, Loop5End
	
						sll $t5, $s4, 2   # $t5 = current column of A
						
						mult $s4, $t1	
						mflo $t6	  # $t6 = current row of B
						
						add $t7, $t5, $t3 # index of current element in A
						add $t7, $t7, $a0 # adress of current element in A
						l.s $f2, 0($t7)   # current element of A
						
						add $t7, $t6, $t4 # index of current element in B
						add $t7, $t7, $a1 # adress of current element in B
						l.s $f3, 0($t7)   # current element in B
						
						mul.s $f4, $f2, $f3
						add.s $f1, $f1, $f4 # add to sum
					
						addi $s4, $s4, 1	# increment k by 1
						j Loop5
						
					Loop5End:
					
					add $t6, $t3, $t4	# $t6 = index of current element of C
					add $t6, $t6, $a2	# $t6 = adress of current element of C
					l.s $f4, 0($t6)		# $f5 = current element of C
					
					add.s $f4, $f4, $f1	# C[i][j] += sum
					s.s $f4, 0($t6)
					
					addi $s3, $s3, 1	# increment j by 1
					j Loop4
					
				Loop4End:
	
				addi $s2, $s2, 1	# increment i by 1
				j Loop3
				
			Loop3End:
		
			addi $s1, $s1, 4	# increment kk by 4
			j Loop2
			
		Loop2End:
	
		addi $s0, $s0, 4	# increment jj by 4
		j Loop1
		
	Loop1End:
	
	

	# Pop saved registers from the stack
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp)
	lw $s3, 12($sp)
	lw $s4, 16($sp)
	lw $s5, 20($sp)
	lw $s6, 24($sp)
	lw $s7, 28($sp)
	
	l.s $f1, 32($sp)
	l.s $f2, 36($sp)
	l.s $f3, 40($sp)
	l.s $f4, 44($sp)
	l.s $f5, 48($sp)
	l.s $f6, 52($sp)
	
	addi $sp, $sp, 52
	
	jr   $ra
