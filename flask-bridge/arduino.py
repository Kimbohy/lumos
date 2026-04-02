import serial
import serial.tools.list_ports
import os
import time

_connection = None

def get_connection():
    global _connection
    if _connection is None or not _connection.is_open:
        port = os.getenv("SERIAL_PORT", "/dev/ttyACM0")
        baud = int(os.getenv("SERIAL_BAUDRATE", "9600"))
        _connection = serial.Serial(port, baud, timeout=2)
        time.sleep(2)  # attendre que l'Arduino se réinitialise
    return _connection

def send_command(pin: int, action: str) -> bool:
    try:
        conn = get_connection()
        command = f"{pin}:{action}\n"   # ex: "8:ON\n"
        conn.write(command.encode())
        response = conn.readline().decode().strip()
        return response == "OK"
    except Exception as e:
        print(f"Erreur série : {e}")
        return False