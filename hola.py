## @file hola.py
#  @brief Modulo de ejemplo utilizado en la etapa Build del pipeline.
#  @author Diego Otarola


## @brief Construye el saludo del proyecto.
#  @param nombre Nombre a saludar.
#  @return Cadena con el saludo.
def saludar(nombre='mundo'):
    return f"Hola, {nombre}!"


if __name__ == '__main__':
    print(saludar('DevSecOps'))
