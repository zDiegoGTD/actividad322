#!/usr/bin/env python3
"""Ejecuta comandos en una sesion interactiva real de bash sobre un pseudo-terminal.

El prompt, el comando y su salida se muestran en la consola exactamente como en
una sesion manual. Se usa para registrar las evidencias del laboratorio.

Uso: python3 sesion.py <segundos_por_comando> <comando> [comando ...]
"""
import fcntl
import os
import pty
import select
import signal
import struct
import subprocess
import sys
import termios
import time

BANDERA = '/mnt/c/Users/deint/AppData/Local/Temp/claude/45a0b889dbe5ba4c/a0d24618-f1ef-4865-9bc4-e02419e05269/scratchpad/terminal-listo.flag'


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 1

    espera = float(sys.argv[1])
    if sys.argv[2] == '--file':
        with open(sys.argv[3], encoding='utf-8-sig') as f:
            comandos = [l.rstrip('\n').rstrip('\r') for l in f if l.strip()]
    else:
        comandos = sys.argv[2:]

    try:
        os.remove(BANDERA)
    except OSError:
        pass

    columnas = int(os.environ.get('SESION_COLS', '132'))
    filas = int(os.environ.get('SESION_ROWS', '32'))

    maestro, esclavo = pty.openpty()
    fcntl.ioctl(esclavo, termios.TIOCSWINSZ,
                struct.pack('HHHH', filas, columnas, 0, 0))
    entorno = dict(os.environ)
    entorno['COLUMNS'] = str(columnas)
    entorno['LINES'] = str(filas)
    entorno['TERM'] = 'xterm-256color'
    entorno['PS1'] = r'\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]$ '

    proc = subprocess.Popen(
        ['bash', '-i'],
        stdin=esclavo, stdout=esclavo, stderr=esclavo,
        preexec_fn=os.setsid, env=entorno, cwd=os.path.expanduser('~/actividad322'),
    )
    os.close(esclavo)

    salida = sys.stdout.buffer

    def volcar(limite):
        fin = time.time() + limite
        while time.time() < fin:
            r, _, _ = select.select([maestro], [], [], 0.2)
            if maestro in r:
                try:
                    datos = os.read(maestro, 65536)
                except OSError:
                    return
                if not datos:
                    return
                salida.write(datos)
                salida.flush()

    # Preparacion silenciosa: desactiva el pegado entre corchetes y limpia la
    # pantalla, de modo que la sesion visible empiece en un prompt limpio.
    volcar(3.0)
    os.write(maestro, b"bind 'set enable-bracketed-paste off'\n")
    volcar(1.5)
    os.write(maestro, b"clear\n")
    volcar(2.0)

    def escribir(texto):
        """Escribe el comando caracter a caracter, como una persona tecleando."""
        for ch in texto:
            os.write(maestro, ch.encode())
            volcar(0.02)

    for c in comandos:
        escribir(c)
        volcar(0.3)
        os.write(maestro, b'\n')
        volcar(espera)

    volcar(1.0)

    with open(BANDERA, 'w') as f:
        f.write('listo')

    # La ventana permanece abierta hasta que la captura termine
    try:
        time.sleep(600)
    except KeyboardInterrupt:
        pass
    finally:
        try:
            os.killpg(os.getpgid(proc.pid), signal.SIGKILL)
        except Exception:
            pass
    return 0


if __name__ == '__main__':
    sys.exit(main())
