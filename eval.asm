%include "io.inc"

%define MAX_INPUT_SIZE 4096

section .data
	end_of_string db '', 0

section .bss
	expr: resb MAX_INPUT_SIZE

section .data
	mult dd 10
	length dw 0
	is_negative db 0

section .text

buildNumberFromDigits:
	xor eax, eax ; initializeaza eax cu 0
	xor ecx, ecx ; initializeaza ecx cu 0

	mov [is_negative], byte 0

construct_number:            
	movsx ebx, byte [esi + ecx] ; copiaza caracterul curent sign extended
	cmp ebx, dword '-'
	jnz continue

	mov [is_negative], byte 1
	jmp increment

continue:
	sub ebx, '0'  ; converteste la integer

	mul dword [mult]  ; inmulteste eax cu 10
	add eax, ebx      ; adauga cifra

increment:        
	inc ecx ; incrementeaza ecx

	cmp ecx, edi ; in edi avem numarul de cifre din numar
	jl construct_number   ; am terminat de construit numarul

return: 
	cmp [is_negative], byte 1
	jnz final

	not eax
	add eax, 1

final:                 
	ret

getStringLength:
	cld 
	mov ecx, MAX_INPUT_SIZE
	mov al, 0
	mov edi, esi
	repne scasb      

	sub edi, esi
	dec edi
	mov [length], edi

ret

global CMAIN
CMAIN:
	mov ebp, esp; for correct debugging
	push ebp
	mov ebp, esp

	GET_STRING expr, MAX_INPUT_SIZE
	mov esi, expr
	cld 

tokenize_string:
	;determina lungimea secventei si o plaseaza in ecx
	call getStringLength
	mov ecx, [length]

	;cauta primul spatiu din secventa
	mov al, ' ' 
	mov edi, esi  
	repne scasb

	;edi o sa puncteze la sub-secventa aflata dupa spatiu,
	;adica la subsecventa in care o sa se faca urmatoarea cautare
	;trebuie salvata valoarea
	push edi

	;determina numarul de caractere din subsirul gasit
	sub edi, esi
	dec edi

	;daca ecx este 0 atunci repne nu a mai gasit un spatiu
	;suntem la ultima sub-secventa, care o sa fie mereu un operator
	jecxz check_for_operator

	;daca nu suntem la final, dar subsirul are lungimea 1
	;este posibil sa fie un operator
	cmp edi, 1
	jne build_number

check_for_operator:    
	;incarca primul octet de la adresa la care puncteaza esi   
	mov al, byte [esi]

	;Verifica daca este + - * /
	cmp al, '+'
	je handle_plus

	cmp al, '-'
	je handle_minus

	cmp al, '*'
	je handle_mul

	cmp al, '/'
	je handle_div

	;Daca nu este un operator, atunci este o cifra
	;Construieste un numar dintr-o cifra sau mai multe
build_number:
	call buildNumberFromDigits

	pop esi
	push eax

check_sequence_end:
	;Incarca un byte si verifica daca este delimitatorul de sir sau newline
	mov al, byte [esi]
	cmp al, 0
	je print_final_answer 

	mov al, byte [esi]
	cmp al, 10
	je print_final_answer    

	;Inca exista subsecvente in sir
	jmp tokenize_string   

handle_plus:
	pop esi
	pop ebx
	pop ecx

	add ebx, ecx
	push ebx

	jmp check_sequence_end

handle_minus:
	pop esi
	pop ebx
	pop ecx

	sub ecx, ebx
	push ecx

	jmp check_sequence_end 

handle_mul:    
	pop esi
	pop eax
	pop ecx

	imul ecx

	push eax

	jmp check_sequence_end

handle_div:
	pop esi
	pop ecx
	pop eax

	cdq
	idiv ecx
	push eax

	jmp check_sequence_end                                                                                

print_final_answer:  
	pop eax
	PRINT_DEC 4, eax
	NEWLINE

	xor eax, eax
	pop ebp
ret
