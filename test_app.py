## @file test_app.py
#  @brief Pruebas unitarias ejecutadas en la etapa Test del pipeline.

import unittest

from hola import saludar


class TestSaludo(unittest.TestCase):
    """Pruebas del modulo hola."""

    def test_saludo_por_defecto(self):
        self.assertEqual(saludar(), 'Hola, mundo!')

    def test_saludo_con_nombre(self):
        self.assertEqual(saludar('Diego'), 'Hola, Diego!')

    def test_saludo_devuelve_cadena(self):
        self.assertIsInstance(saludar('DevSecOps'), str)


if __name__ == '__main__':
    unittest.main()
