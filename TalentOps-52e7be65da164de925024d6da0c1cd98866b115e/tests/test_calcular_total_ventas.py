from src.ventas import calcular_total_ventas

def test_calculo_totales():
    ventas = [
        {'producto': 'A', 'cantidad': 2, 'precio': 10},
        {'producto': 'B', 'cantidad': 1, 'precio': 20},
        {'producto': 'A', 'cantidad': 3, 'precio': 10},
    ]

    resultado = calcular_total_ventas(ventas)

    assert resultado['A'] == 50
    assert resultado['B'] == 20
