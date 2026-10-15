#pragma once
#include <stddef.h>
#include <stdint.h>

/// Minimal UART transport for the GDB stub.
///
/// Wraps ESP-IDF's UART driver so the Swift side needs no ESP-IDF headers:
/// pulling `driver/uart.h` through the Clang importer would cascade into the
/// hal/soc/FreeRTOS header tree.
void gdb_uart_init(void);
int gdb_uart_read(uint8_t *buffer, size_t length, uint32_t timeout_ms);
int gdb_uart_write(const uint8_t *buffer, size_t length);
