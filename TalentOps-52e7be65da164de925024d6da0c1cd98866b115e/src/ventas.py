def calcular_total_ventas(ventas):
    """Calcula total de ventas por producto"""
    totales = {}
    for venta in ventas:
        producto = venta['producto']
        cantidad = venta['cantidad']
        precio = venta['precio']
        totales[producto] = totales.get(producto, 0) + (cantidad * precio)
    return totales
