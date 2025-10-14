# Instrucciones para Crear Índices de Firestore

## Problema Actual
El historial de pedidos funciona pero usa ordenamiento en el cliente. Para mejorar el rendimiento, se pueden crear índices compuestos en Firestore.

## Índices Recomendados

### 1. Índice para Pedidos En Curso
**Colección:** `pedido`
**Campos:**
- `status` (Ascending)
- `createdAt` (Descending)

### 2. Índice para Pedidos Completados
**Colección:** `pedido`
**Campos:**
- `status` (Ascending)  
- `createdAt` (Descending)

## Cómo Crear los Índices

### Opción 1: Firebase Console (Recomendado)
1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. Ve a `Firestore Database` → `Indexes`
4. Haz clic en `Create Index`
5. Configura el índice:
   - **Collection ID:** `pedido`
   - **Fields:**
     - Field: `status`, Order: `Ascending`
     - Field: `createdAt`, Order: `Descending`
6. Haz clic en `Create`
7. Repite el proceso para crear un segundo índice igual (Firebase puede optimizar automáticamente)

### Opción 2: Usando Firebase CLI
```bash
# Instalar Firebase CLI si no lo tienes
npm install -g firebase-tools

# Inicializar Firestore en tu proyecto
firebase login
firebase init firestore

# Agregar índices al archivo firestore.indexes.json
```

**Contenido para `firestore.indexes.json`:**
```json
{
  "indexes": [
    {
      "collectionGroup": "pedido",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        }
      ]
    }
  ],
  "fieldOverrides": []
}
```

```bash
# Desplegar los índices
firebase deploy --only firestore:indexes
```

### Opción 3: Automáticamente desde el Error
1. Cuando ejecutes la app con las consultas optimizadas, Firestore te dará un enlace en el error
2. Haz clic en el enlace para crear automáticamente el índice
3. Espera a que se complete la creación (puede tomar varios minutos)

## Código Optimizado (Para Después de Crear los Índices)

Después de crear los índices, puedes reemplazar el código actual con este para mejor rendimiento:

```dart
// Para pedidos en curso
stream: _firestore
  .collection('pedido')
  .where('status', whereIn: ['pendiente', 'preparando', 'en_preparacion'])
  .orderBy('createdAt', descending: true)
  .limit(50)
  .snapshots(),

// Para pedidos completados  
stream: _firestore
  .collection('pedido')
  .where('status', whereIn: ['terminado', 'cancelado', 'completado', 'entregado', 'pagado', 'finalizado', 'cerrado'])
  .orderBy('createdAt', descending: true)
  .limit(100)
  .snapshots(),
```

## Estado Actual
✅ **Funcionando:** Ordenamiento en el cliente (solución temporal)
⏳ **Pendiente:** Crear índices para mejor rendimiento
🚀 **Futuro:** Paginación avanzada

## Notas Importantes
- Los índices pueden tomar tiempo en crearse (especialmente si tienes muchos documentos)
- Una vez creados, las consultas serán mucho más rápidas
- El ordenamiento en el cliente actual funciona perfectamente como solución temporal
- Los índices son gratuitos en el plan de Firebase, solo afectan el rendimiento

## Alternativa Simple
Si no quieres crear índices ahora, el código actual funciona perfectamente. Solo que:
- ✅ Funciona bien con hasta ~1000 pedidos
- ⚠️ Puede ser más lento con miles de pedidos
- 💡 Se puede optimizar más adelante cuando sea necesario