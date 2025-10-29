# Guía de Actualización de Formularios

## ✅ Mejoras Implementadas

He actualizado `CustomInputField` con las siguientes características:

### 🎨 Diseño Mejorado
- **Floating Labels**: Los labels flotan automáticamente al escribir
- **Validaciones Visuales**: Bordes rojos para errores, verdes para campos enfocados
- **Campos Requeridos**: Indicador de asterisco (*) automático con `isRequired: true`
- **Iconos**: Soporte para `prefixIcon` y `suffixIcon`

### 🔧 Nuevas Propiedades

```dart
CustomInputField(
  hintText: 'Nombre',          // Texto de placeholder
  label: 'Nombre',             // Label (opcional, usa hintText si no se especifica)
  controller: controller,
  isRequired: true,            // Muestra * después del label
  validator: (value) => ...,   // Validación con mensajes de error
  
  // Iconos
  prefixIcon: Icon(Icons.person_outline, color: Color(0xFF34D399)),
  suffixIcon: IconButton(...),
  
  // Configuración de texto
  keyboardType: TextInputType.text,
  textCapitalization: TextCapitalization.words,
  maxLines: 1,
  maxLength: 100,
  obscureText: false,
  
  // Estados
  enabled: true,
  readOnly: false,
  
  // Callbacks
  onTap: () => {},
  onChanged: (value) => {},
  
  // Personalización de colores
  fillColor: Colors.white.withValues(alpha: 0.08),
  borderColor: Colors.white.withValues(alpha: 0.12),
  focusedBorderColor: Color(0xFF34D399),
)
```

## 📋 Formularios Actualizados

### ✅ Ya Actualizados:
1. **create_mesero_screen.dart** - Formulario de contacto de mesero
2. **create_credentials_mesero.dart** - Credenciales de mesero

### 📝 Pendientes de Actualizar:

#### Admin - Usuarios
- [ ] `create_cocinero_screen.dart`
- [ ] `create_credentials_cocinero.dart`

#### Admin - Productos y Categorías
- [ ] `create_item_producto_screen.dart`
- [ ] `create_producto_screen.dart`
- [ ] `create_item_category_screen.dart`
- [ ] `create_item_additional_screen.dart`
- [ ] `create_item_combo_screen.dart`

#### Admin - Mesas
- [ ] `create_mesa_screen.dart`

## 🎯 Patrón de Actualización

### Antes:
```dart
CustomInputField(
  hintText: 'Nombre',
  controller: nombreController,
  validator: (value) => value == null || value.isEmpty 
    ? 'Campo requerido' 
    : null,
)
```

### Después:
```dart
CustomInputField(
  hintText: 'Nombre',
  controller: nombreController,
  isRequired: true,
  textCapitalization: TextCapitalization.words,
  prefixIcon: const Icon(
    Icons.person_outline,
    color: Color(0xFF34D399),
    size: 22,
  ),
  validator: (value) => value == null || value.isEmpty 
    ? 'Campo requerido' 
    : null,
)
```

## 🎨 Iconos Sugeridos por Tipo de Campo

```dart
// Información personal
Icons.person_outline          // Nombre, Apellidos
Icons.badge_outlined          // ID, Documento
Icons.cake_outlined           // Fecha de nacimiento

// Contacto
Icons.phone_outlined          // Teléfono
Icons.email_outlined          // Email
Icons.location_on_outlined    // Dirección

// Credenciales
Icons.alternate_email         // Username
Icons.lock_outline           // Contraseña

// Productos
Icons.inventory_2_outlined    // Producto
Icons.shopping_bag_outlined   // Categoría
Icons.attach_money           // Precio
Icons.numbers                // Cantidad, Stock

// Mesas
Icons.table_restaurant       // Mesa
Icons.people_outline         // Capacidad

// General
Icons.description_outlined    // Descripción
Icons.calendar_today         // Fecha
Icons.access_time           // Hora
```

## 🔴 Validaciones Comunes

### Nombre/Apellido
```dart
validator: (value) => value == null || value.isEmpty
  ? 'Por favor ingrese un nombre'
  : AppConstants.nameRegex.hasMatch(value)
    ? null
    : 'El nombre no es válido',
```

### Email
```dart
validator: (value) => value == null || value.isEmpty
  ? 'Por favor ingrese un email'
  : AppConstants.emailRegex.hasMatch(value)
    ? null
    : 'El email no es válido',
```

### Teléfono
```dart
validator: (value) => value == null || value.isEmpty
  ? 'Por favor ingrese un teléfono'
  : AppConstants.phoneRegex.hasMatch(value)
    ? null
    : 'El teléfono no es válido',
```

### Campo requerido simple
```dart
validator: (value) => value == null || value.trim().isEmpty
  ? 'Este campo es obligatorio'
  : null,
```

### Número/Precio
```dart
validator: (value) {
  if (value == null || value.isEmpty) return 'Ingrese un valor';
  final number = double.tryParse(value);
  if (number == null) return 'Ingrese un número válido';
  if (number <= 0) return 'El valor debe ser mayor a 0';
  return null;
},
```

## 📦 Widgets Especializados Disponibles

He creado widgets especializados en `custom_text_field.dart`:

### CurrencyTextField
```dart
CurrencyTextField(
  controller: precioController,
  label: 'Precio',
  isRequired: true,
  validator: (value) => ...,
)
```

### NumberTextField
```dart
NumberTextField(
  controller: cantidadController,
  label: 'Cantidad',
  isRequired: true,
  maxValue: 100, // Opcional
  validator: (value) => ...,
)
```

### EmailTextField
```dart
EmailTextField(
  controller: emailController,
  validator: (value) => ...,
)
```

### PasswordTextField
```dart
PasswordTextField(
  controller: passwordController,
  label: 'Contraseña',
  validator: (value) => ...,
)
```

### PhoneTextField
```dart
PhoneTextField(
  controller: phoneController,
  isRequired: true,
  validator: (value) => ...,
)
```

## 🚀 Cómo Actualizar Otros Formularios

1. **Identificar los campos** del formulario
2. **Agregar `isRequired: true`** a campos obligatorios
3. **Agregar iconos** apropiados con `prefixIcon`
4. **Agregar `textCapitalization`** donde corresponda:
   - `TextCapitalization.words` para nombres
   - `TextCapitalization.sentences` para descripciones
   - `TextCapitalization.none` para emails/usernames
5. **Aumentar spacing** entre campos de 12 a 16 (`SizedBox(height: 16)`)
6. **Mantener validaciones** existentes

## 🎨 Colores del Sistema

- **Primary Green**: `Color(0xFF34D399)` - Usado en iconos y bordes enfocados
- **Error Red**: `Color(0xFFEF4444)` - Errores de validación
- **Background**: `Colors.white.withValues(alpha: 0.08)` - Fondo de inputs
- **Border**: `Colors.white.withValues(alpha: 0.12)` - Borde normal

## 💡 Ejemplo Completo: Formulario de Producto

```dart
Form(
  key: _formKey,
  child: Column(
    children: [
      CustomInputField(
        hintText: 'Nombre del producto',
        controller: nombreController,
        isRequired: true,
        textCapitalization: TextCapitalization.words,
        prefixIcon: const Icon(
          Icons.inventory_2_outlined,
          color: Color(0xFF34D399),
          size: 22,
        ),
        validator: (value) => value == null || value.isEmpty
          ? 'Ingrese el nombre del producto'
          : null,
      ),
      const SizedBox(height: 16),
      
      CurrencyTextField(
        controller: precioController,
        label: 'Precio',
        isRequired: true,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Ingrese el precio';
          final price = double.tryParse(value);
          if (price == null || price <= 0) return 'Precio inválido';
          return null;
        },
      ),
      const SizedBox(height: 16),
      
      CustomInputField(
        hintText: 'Descripción',
        controller: descripcionController,
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
        prefixIcon: const Icon(
          Icons.description_outlined,
          color: Color(0xFF34D399),
          size: 22,
        ),
      ),
    ],
  ),
)
```

## ✨ Resultado Visual

Los inputs ahora tienen:
- ✅ Label flotante que se anima al enfocar
- ✅ Indicador visual de campo requerido (*)
- ✅ Borde verde al enfocar
- ✅ Borde rojo si hay error con mensaje descriptivo
- ✅ Iconos visuales para identificar rápidamente el tipo de campo
- ✅ Mejor espaciado y legibilidad
