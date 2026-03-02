from typing import Dict
from datetime import datetime

class DataVersionManager:
    """Gestor de versionado de datos y esquemas"""
    
    def __init__(self):
        self.schemas = self._load_schemas()
    
    def _load_schemas(self) -> Dict:
        """Cargar definiciones de esquemas por versión"""
        return {
            1: {
                'fields': ['id', 'name', 'created_at'],
                'types': {'id': str, 'name': str, 'created_at': str}
            },
            2: {
                'fields': ['id', 'name', 'email', 'created_at', 'updated_at'],
                'types': {'id': str, 'name': str, 'email': str, 'created_at': str, 'updated_at': str}
            },
            3: {
                'fields': ['id', 'name', 'email', 'phone', 'created_at', 'updated_at'],
                'types': {'id': str, 'name': str, 'email': str, 'phone': str, 'created_at': str, 'updated_at': str}
            }
        }
    
    def validate_schema(self, data: Dict, version: int = None) -> Dict:
        """Validar que datos cumplan esquema de versión específica"""
        
        if version is None:
            version = data.get('schema_version', 1)
        
        if version not in self.schemas:
            return {'valid': False, 'error': f'Versión {version} no soportada'}
        
        schema = self.schemas[version]
        errors = []
        
        # Verificar campos requeridos
        for field in schema['fields']:
            if field not in data:
                errors.append(f'Campo faltante: {field}')
        
        # Verificar tipos (permitir None como valor inicial)
        for field, expected_type in schema['types'].items():
            if field in data and data[field] is not None and not isinstance(data[field], expected_type):
                errors.append(f'Tipo incorrecto para {field}: esperado {expected_type.__name__}')
        
        return {
            'valid': len(errors) == 0,
            'version': version,
            'errors': errors
        }
    
    def upgrade_data(self, data: Dict, target_version: int) -> Dict:
        """Upgrade datos a versión más nueva"""
        
        current_version = data.get('schema_version', 1)
        
        while current_version < target_version:
            data = self._upgrade_one_version(data, current_version)
            current_version += 1
            data['schema_version'] = current_version
        
        return data
    
    def _upgrade_one_version(self, data: Dict, from_version: int) -> Dict:
        """Upgrade de una versión a la siguiente"""
        
        if from_version == 1:
            # V1 → V2: Agregar email y updated_at
            data['email'] = ""  # cadena vacía en vez de None
            data['updated_at'] = data.get('created_at')
            data['schema_version'] = 2
        
        elif from_version == 2:
            # V2 → V3: Agregar phone
            data['phone'] = ""  # cadena vacía en vez de None
            data['schema_version'] = 3
        
        return data
    
    def create_migration_script(self, from_version: int, to_version: int) -> str:
        """Generar script de migración para base de datos"""
        
        migrations = {
            (1, 2): """
            -- Migración V1 → V2
            ALTER TABLE users ADD COLUMN email VARCHAR(255);
            ALTER TABLE users ADD COLUMN updated_at TIMESTAMP;
            UPDATE users SET updated_at = created_at WHERE updated_at IS NULL;
            """,
            (2, 3): """
            -- Migración V2 → V3  
            ALTER TABLE users ADD COLUMN phone VARCHAR(50);
            """
        }
        
        return migrations.get((from_version, to_version), 
                            f"-- No migration script available for {from_version} → {to_version}")

# Uso del version manager
if __name__ == "__main__":
    version_manager = DataVersionManager()

    # Datos de ejemplo versión 1
    legacy_data = {
        'id': '123',
        'name': 'Juan Pérez',
        'created_at': '2024-01-01T10:00:00'
    }

    # Validar versión actual
    validation = version_manager.validate_schema(legacy_data)
    print(f"Datos válidos: {validation['valid']}")
    if not validation['valid']:
        print(f"Errores: {validation['errors']}")

    # Upgrade a versión más nueva
    upgraded_data = version_manager.upgrade_data(legacy_data.copy(), 3)
    print(f"Datos upgradeados a versión: {upgraded_data['schema_version']}")

    # Validar versión upgradeada
    validation_upgraded = version_manager.validate_schema(upgraded_data)
    print(f"Datos upgradeados válidos: {validation_upgraded['valid']}")
    if not validation_upgraded['valid']:
        print(f"Errores: {validation_upgraded['errors']}")