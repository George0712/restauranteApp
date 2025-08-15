# Configuración de Firebase para el Controlador de Mesas

## Problema de Permisos

Si estás recibiendo errores de permisos al crear mesas, sigue estos pasos:

### 1. Configurar Reglas de Firestore

Ve a la consola de Firebase (https://console.firebase.google.com) y sigue estos pasos:

1. Selecciona tu proyecto
2. Ve a **Firestore Database** en el menú lateral
3. Haz clic en la pestaña **Rules**
4. Reemplaza las reglas existentes con las siguientes:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Reglas para la colección de mesas
    match /mesas/{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Reglas para usuarios
    match /usuario/{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Reglas para productos
    match /producto/{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Reglas para categorías
    match /categoria/{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Reglas para adicionales
    match /adicional/{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Reglas para combos
    match /combo/{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Reglas para pedidos
    match /pedido/{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Reglas para órdenes
    match /orden/{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

5. Haz clic en **Publish**

### 2. Verificar Autenticación

Asegúrate de que el usuario esté autenticado antes de intentar crear mesas:

- El usuario debe estar logueado en la aplicación
- Verifica que el login esté funcionando correctamente
- Revisa la consola de Firebase para ver si hay errores de autenticación

### 3. Verificar Configuración de Firebase

1. Asegúrate de que el archivo `google-services.json` (Android) esté actualizado
2. Verifica que el archivo `GoogleService-Info.plist` (iOS) esté actualizado
3. Confirma que las dependencias de Firebase estén correctamente configuradas en `pubspec.yaml`

### 4. Probar la Conexión

Puedes agregar este código temporal para probar la conexión:

```dart
// En el controlador de mesas, agrega este método de prueba
Future<void> testConnection() async {
  try {
    final testDoc = await _firestore.collection('test').add({
      'timestamp': DateTime.now().toIso8601String(),
    });
    print('Conexión exitosa. Documento creado: ${testDoc.id}');
    await testDoc.delete(); // Limpiar el documento de prueba
  } catch (e) {
    print('Error de conexión: $e');
  }
}
```

### 5. Reglas de Desarrollo (Solo para desarrollo)

Si estás en desarrollo y quieres permitir todo el acceso temporalmente:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

**⚠️ IMPORTANTE: No uses estas reglas en producción.**

### 6. Verificar Colección

Asegúrate de que la colección `mesas` exista en Firestore:

1. Ve a **Firestore Database** > **Data**
2. Si no existe la colección `mesas`, créala manualmente agregando un documento de prueba
3. O simplemente intenta crear una mesa desde la app (se creará automáticamente)

### 7. Logs de Depuración

El controlador ahora incluye logs detallados. Revisa la consola de Flutter para ver:
- Si la mesa se crea exitosamente
- Errores específicos de permisos o conexión
- IDs de documentos creados

## Solución Rápida

Si necesitas una solución rápida para desarrollo:

1. Ve a Firebase Console > Firestore Database > Rules
2. Cambia temporalmente las reglas a:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if true;
       }
     }
   }
   ```
3. Haz clic en **Publish**
4. Prueba crear una mesa
5. **Recuerda cambiar las reglas de vuelta antes de subir a producción**
