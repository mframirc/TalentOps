def validar_datos_ventas(datos):
    """
    Valida que los datos de ventas cumplan criterios básicos.

    Parámetros
    ----------
    datos : list[dict]
        Lista de registros de ventas. Cada registro debe incluir
        al menos los campos 'precio' y 'fecha'.

    Retorna
    -------
    dict
        {
            'valido': bool,
            'errores': list[str],
            'total_filas': int
        }
    """
    errores = []
    
    for i, fila in enumerate(datos):
        if fila.get('precio', 0) <= 0:
            errores.append(f"Fila {i}: precio inválido")
        if not fila.get('fecha'):
            errores.append(f"Fila {i}: fecha faltante")
    
    return {
        'valido': len(errores) == 0,
        'errores': errores,
        'total_filas': len(datos)
    }
