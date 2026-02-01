def procesar_datos_lento(datos):
    """Procesamiento ineficiente"""
    resultado = []
    for fila in datos:
        fila_procesada = fila.copy()
        fila_procesada['total'] = fila['precio'] * fila['cantidad']
        resultado.append(fila_procesada)
    return resultado


def procesar_datos_rapido(datos):
    """Procesamiento optimizado con comprensión de listas"""
    return [
        {**fila, 'total': fila['precio'] * fila['cantidad']}
        for fila in datos
    ]
