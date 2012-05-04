#include <avr/io.h>
#include <stdio.h>
#include "uart.h"

#define F_CPU 16000000 // Atmega128 clock freq. 16MHz
#define USART_BAUDRATE 38400
#define BAUD_PRESCALE (((F_CPU / (USART_BAUDRATE * 16UL) )) - 1)

FILE mystdout = FDEV_SETUP_STREAM(uart_putchar, NULL, _FDEV_SETUP_WRITE);

void initUART(void)
{
  // Set baud rate
  UBRR0H = (unsigned char)BAUD_PRESCALE >> 8;
  UBRR0L = (unsigned char)BAUD_PRESCALE & 0xFF;

  // Enable RX, TX and RX complete interrupt
  UCSR0B = (1 << RXEN0) | (1 << TXEN0) | (1<<RXCIE0);

  // Set frame format: 8 data bits, 1 stop bit, no parity
  UCSR0C = 3 << UCSZ00;

  // Redirect STDOUT
  stdout = &mystdout;
}

int uart_putchar(char c, FILE *stream)
{
  if (c == '\n') uart_putchar('\r', stream);
  // Wait for an empty transmit buffer
  while (!(UCSR0A & (1 << UDRE0)));
  UDR0 = c;

  return 0;
}
