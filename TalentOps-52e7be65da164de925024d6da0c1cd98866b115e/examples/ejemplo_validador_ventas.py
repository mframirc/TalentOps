from src.validacion.ventas_validator import validar_datos_ventas

datos_ventas = [
    {'precio': 100, 'fecha': '2024-01-01'},
    {'precio': -50, 'fecha': '2024-01-02'}
]

if __name__ == "__main__":
    resultado = validar_datos_ventas(datos_ventas)
    print(resultado)
