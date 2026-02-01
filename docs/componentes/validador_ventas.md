# Validador de Datos de Ventas
## Propósito
Valida la calidad de los datos de ventas antes del procesamiento, 
asegurando que cumplan criterios mínimos antes de ingresar al pipeline.

## Función Documentada
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

## Parámetros
• 	datos (list[dict]): Lista de diccionarios con registros de ventas.

## Retorna
• 	valido (bool): Indica si todos los registros cumplen las reglas.
• 	errores (list[str]): Lista de errores detectados.
• 	total_filas (int): Cantidad total de registros procesados.

## Reglas de Validación
• 	El campo precio debe ser mayor a 0.
• 	El campo fecha no puede estar vacío.
• 	Campos requeridos: precio,fecha.

## Ejemplo de Uso
datos_ventas = [
    {'precio': 100, 'fecha': '2024-01-01'},
    {'precio': -50, 'fecha': '2024-01-02'}
]

resultado = validar_datos_ventas(datos_ventas)

# resultado:
# {
#     'valido': False,
#     'errores': ['Fila 1: precio inválido'],
#     'total_filas': 2
# }

## Integración en el Pipeline
Este componente se utiliza como paso de validación dentro del DAG de Airflow, 
permitiendo detener el flujo si los datos no cumplen los criterios mínimos de calidad.

## Ubicación en el Proyecto
src/validacion/ventas_validator.py
docs/componentes/validador_ventas.md
examples/ejemplo_validador_ventas.py










