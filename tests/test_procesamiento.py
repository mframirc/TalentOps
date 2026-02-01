from src.procesamiento import procesar_datos_rapido

def test_procesamiento_rapido():
    datos = [
        {'precio': 10, 'cantidad': 2},
        {'precio': 5, 'cantidad': 3},
    ]

    resultado = procesar_datos_rapido(datos)

    assert resultado[0]['total'] == 20
    assert resultado[1]['total'] == 15
