#include "gdb_uart.h"

#include "driver/uart.h"
#include "freertos/FreeRTOS.h"

// UART0 is the console; serve the debugger on UART1.
#define GDB_UART_PORT UART_NUM_1
#define GDB_UART_BUF 2048

void gdb_uart_init(void) {
    uart_config_t config = {
        .baud_rate = 115200,
        .data_bits = UART_DATA_8_BITS,
        .parity = UART_PARITY_DISABLE,
        .stop_bits = UART_STOP_BITS_1,
        .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
        .source_clk = UART_SCLK_DEFAULT,
    };
    uart_driver_install(GDB_UART_PORT, GDB_UART_BUF, GDB_UART_BUF, 0, NULL, 0);
    uart_param_config(GDB_UART_PORT, &config);
}

int gdb_uart_read(uint8_t *buffer, size_t length, uint32_t timeout_ms) {
    return uart_read_bytes(GDB_UART_PORT, buffer, length, pdMS_TO_TICKS(timeout_ms));
}

int gdb_uart_write(const uint8_t *buffer, size_t length) {
    return uart_write_bytes(GDB_UART_PORT, (const char *)buffer, length);
}
