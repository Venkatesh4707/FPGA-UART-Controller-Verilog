# UART Automated Loopback Test
# Author: P. Venkatesh Sagar
# Usage: python uart_loopback_test.py --port COM3 --baud 115200

import serial, time, argparse, sys

def run_loopback_test(port, baud_rate, timeout=2):
    print("=" * 50)
    print("  UART Automated Loopback Test")
    print("  Author: P. Venkatesh Sagar")
    print(f"  Port: {port}  Baud: {baud_rate}")
    print("=" * 50)
    pass_count = 0
    fail_count = 0
    failed_bytes = []
    try:
        ser = serial.Serial(port=port, baudrate=baud_rate,
                            bytesize=serial.EIGHTBITS,
                            parity=serial.PARITY_NONE,
                            stopbits=serial.STOPBITS_ONE,
                            timeout=timeout)
        time.sleep(0.1)
        ser.flushInput()
        ser.flushOutput()
        print("
[TEST] Full 0x00-0xFF sweep...
")
        for byte_val in range(256):
            ser.write(bytes([byte_val]))
            rx_byte = ser.read(1)
            if len(rx_byte) == 0:
                print(f"  FAIL | Sent: 0x{byte_val:02X} | Timeout")
                fail_count += 1
                failed_bytes.append(byte_val)
            elif rx_byte[0] == byte_val:
                pass_count += 1
                if byte_val % 16 == 0:
                    print(f"  PASS | 0x{byte_val:02X}-0x{min(byte_val+15,255):02X} verified")
            else:
                print(f"  FAIL | Sent: 0x{byte_val:02X} | Got: 0x{rx_byte[0]:02X}")
                fail_count += 1
                failed_bytes.append(byte_val)
        ser.close()
        print(f"
RESULTS: {pass_count} PASSED | {fail_count} FAILED")
        if fail_count == 0:
            print("ALL 256 BYTES VERIFIED - UART WORKING CORRECTLY")
        return fail_count == 0
    except serial.SerialException as e:
        print(f"[ERROR] Cannot open port {port}: {e}")
        sys.exit(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", default="COM3")
    parser.add_argument("--baud", default=115200, type=int)
    args = parser.parse_args()
    sys.exit(0 if run_loopback_test(args.port, args.baud) else 1)
