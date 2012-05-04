#ifndef _UART_H
#define _UART_H

#include <stdio.h>

extern FILE mystdout;

void initUART(void);
int uart_putchar(char c, FILE *stream);

#endif // _UART_H
