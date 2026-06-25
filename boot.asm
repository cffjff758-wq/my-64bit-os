; ==========================================
; MULTIBOOT 2 HEADER (For 64-bit boot)
; ==========================================
section .multiboot_header
align 8
multiboot_start:
    dd 0xe85250d6                        ; Magic number for Multiboot 2
    dd 0                                 ; Architecture 0 (protected mode i386)
    dd multiboot_end - multiboot_start   ; Header length
    dd 0x100000000 - (0xe85250d6 + 0 + (multiboot_end - multiboot_start)) ; Checksum

    ; End tag
    dw 0
    dw 0
    dd 8
multiboot_end:

; ==========================================
; 64-BIT BOOTLOADER CODE
; ==========================================
section .text
bits 32
global _start
extern kernel_main

_start:
    ; Update stack pointer
    mov esp, stack_top

    ; Check if CPU supports 64-bit (Long Mode)
    call check_cpuid
    call check_long_mode

    ; Enable Paging and Switch to 64-bit Long Mode
    call setup_page_tables
    call enable_paging

    ; Load 64-bit Global Descriptor Table
    lgdt [gdt64.pointer]

    ; Long jump to 64-bit code segment
    jmp gdt64.code:start64

bits 64
start64:
    ; Reset segment registers for 64-bit
    mov ax, 0
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax

    ; Call the 64-bit C Kernel function
    call kernel_main

    ; Halt the CPU if kernel returns
.hang:
    cli
    hlt
    jmp .hang

; ==========================================
; HELPER FUNCTIONS (32-bit setup)
; ==========================================
bits 32
check_cpuid:
    pushfd
    pop eax
    mov ecx, eax
    xor eax, 1 << 21
    push eax
    popfd
    pushfd
    pop eax
    push ecx
    popfd
    cmp eax, ecx
    je .no_cpuid
    ret
.no_cpuid:
    mov al, "1"
    jmp error

check_long_mode:
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    jb .no_long_mode
    mov eax, 0x80000001
    cpuid
    test edx, 1 << 29
    jz .no_long_mode
    ret
.no_long_mode:
    mov al, "2"
    jmp error

error:
    mov dword [0xb8000], 0x4f524f45
    mov byte  [0xb8004], al
    hlt

setup_page_tables:
    ; Map first P4 entry to P3 table
    mov eax, page_table_p3
    or eax, 0b11 ; present + writable
    mov [page_table_p4], eax

    ; Map first P3 entry to P2 table
    mov eax, page_table_p2
    or eax, 0b11 ; present + writable
    mov [page_table_p3], eax

    ; Map each P2 entry to a huge 2MiB page
    mov ecx, 0 ; counter
.map_p2_table:
    mov eax, 0x200000 ; 2MiB
    mul ecx
    or eax, 0b10000011 ; present + writable + huge page
    mov [page_table_p2 + ecx * 8], eax
    inc ecx
    cmp ecx, 512
    jne .map_p2_table
    ret

enable_paging:
    ; Pass page table location to CPU
    mov eax, page_table_p4
    mov cr3, eax

    ; Enable PAE (Physical Address Extension)
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; Set long mode bit in EFER MSR
    mov ecx, 0xc0000080
    rdmsr
    or eax, 1 << 8
    wrmsr

    ; Enable paging in CR0
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax
    ret

; ==========================================
; DATA STRUCTURES & TABLES
; ==========================================
section .bss
align 4096
page_table_p4:
    resb 4096
page_table_p3:
    resb 4096
page_table_p2:
    resb 4096
stack_bottom:
    resb 4096 * 4
stack_top:

section .rodata
gdt64:
    dq 0 ; zero entry
.code: equ $ - gdt64
    dq (1 << 43) | (1 << 44) | (1 << 47) | (1 << 53) ; code segment descriptor
.pointer:
    dw $ - gdt64 - 1
    dq gdt64