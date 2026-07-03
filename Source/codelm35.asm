$NOMOD51
$INCLUDE (8051.MCU)

MODE_FLAG BIT 00H

org 0000h
jmp main

org 0100h

main:
    mov sp, #50h
    clr MODE_FLAG
    lcall lcd_init

    mov tmod, #20h
    mov th1, #0fdh
    mov scon, #50h
    setb tr1

loop:
    jb p0.0, read_data
    jnb p0.0, mode
mode:
    cpl MODE_FLAG
    jnb p0.0, $
    jmp loop
wait_release:
    jnb p0.0, wait_release

read_data:
    lcall read_adc
    cjne a, #100, check_max
    mov a, #99
check_max:
    jc save_c
    mov a, #99
save_c:
    mov r0, a
    mov a, r0
    jmp start_conv
start_conv:
    mov a, r0
    jnb MODE_FLAG, split_digits
    
    mov b, #2
    mul ab	
    mov r1, a
    mov b, #10
    div ab
    mov r2, a
    
    mov a, r1
    clr c
    subb a, r2
    add a, #32

split_digits:
    mov b, #100
    div ab
    mov r2, a
    mov a, b
    mov b, #10
    div ab
    mov r3, a
    mov r4, b

    mov a, #80h
    lcall lcd_cmd
    
    mov a, #'T'
    lcall lcd_data
    mov a, #'e'
    lcall lcd_data
    mov a, #'m'
    lcall lcd_data
    mov a, #'p'
    lcall lcd_data
    mov a, #':'
    lcall lcd_data
    mov a, #' '
    lcall lcd_data

    mov a, r2
    cjne a, #0, print_h
    mov a, #' '
    jmp out_h
print_h:
    add a, #30h
out_h:
    lcall lcd_data

    mov a, r3
    add a, #30h
    lcall lcd_data
    
    mov a, r4
    add a, #30h
    lcall lcd_data

    mov a, #0dfh
    lcall lcd_data
    
    jb MODE_FLAG, show_f
    mov a, #'C'
    lcall lcd_data
    jmp uart_send
show_f:
    mov a, #'F'
    lcall lcd_data

uart_send:
    mov a, r2
    cjne a, #0, u_print_h
    mov a, #' '
    jmp u_out_h
u_print_h:
    add a, #30h
u_out_h:
    lcall send_uart

    mov a, r3
    add a, #30h
    lcall send_uart
    
    mov a, r4
    add a, #30h
    lcall send_uart
    
    jb MODE_FLAG, uart_f
    mov a, #'C'
    jmp uart_br
uart_f:
    mov a, #'F'
uart_br:
    lcall send_uart
    
    mov a, #0dh
    lcall send_uart
    mov a, #0ah
    lcall send_uart

    lcall delay_1s
    jmp loop

send_uart:
    mov sbuf, a
wait_ti:
    jnb ti, wait_ti
    clr ti
    ret

read_adc:
    mov p1, #0ffh
    clr p2.3
    clr p2.5
    nop
    setb p2.5
wait_adc:
    jb p2.6, wait_adc
    clr p2.4
    nop
    mov a, p1
    setb p2.4
    setb p2.3
    ret

lcd_init:
    lcall delay_20ms
    mov a, p3
    anl a, #0fh
    orl a, #30h
    mov p3, a
    clr p2.0
    clr p2.1
    setb p2.2
    nop
    clr p2.2
    lcall delay_20ms
    mov a, p3
    anl a, #0fh
    orl a, #30h
    mov p3, a
    setb p2.2
    nop
    clr p2.2
    lcall delay_20ms
    mov a, p3
    anl a, #0fh
    orl a, #30h
    mov p3, a
    setb p2.2
    nop
    clr p2.2
    lcall delay_20ms
    mov a, p3
    anl a, #0fh
    orl a, #20h
    mov p3, a
    setb p2.2
    nop
    clr p2.2
    lcall delay_20ms
    
    mov a, #28h
    lcall lcd_cmd
    mov a, #0ch
    lcall lcd_cmd
    mov a, #06h
    lcall lcd_cmd
    mov a, #01h
    lcall lcd_cmd
    ret

lcd_cmd:
    clr p2.0
    clr p2.1
    jmp lcd_write

lcd_data:
    setb p2.0
    clr p2.1
    jmp lcd_write

lcd_write:
    mov r5, a
    anl a, #0f0h
    mov r6, a
    mov a, p3
    anl a, #0fh
    orl a, r6
    mov p3, a
    setb p2.2
    nop
    clr p2.2
    mov a, r5
    swap a
    anl a, #0f0h
    mov r6, a
    mov a, p3
    anl a, #0fh
    orl a, r6
    mov p3, a
    setb p2.2
    nop
    clr p2.2
    lcall delay_20ms
    ret

delay_20ms:
    mov r6, #40
d_wait:
    mov r7, #250
    djnz r7, $
    djnz r6, d_wait
    ret

delay_1s:
    mov r5, #50
wait_1s:
    lcall delay_20ms
    djnz r5, wait_1s
    ret

end