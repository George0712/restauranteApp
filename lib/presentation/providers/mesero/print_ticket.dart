import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:restaurante_app/core/helpers/snackbar_helper.dart';

/// Servicio para imprimir tickets de pedidos
class PrintTicketService {
  static final NumberFormat _currency = NumberFormat.currency(symbol: r'$');

  /// Imprime un ticket de pedido en formato POS (80mm)
  static Future<void> printTicket({
    required Map<String, dynamic> pedidoData,
    required String pedidoId,
    String? ticketId,
    String? mesaId,
    String? mesaNombre,
    String? clienteNombre,
  }) async {
    try {
      final pdf = pw.Document();

      final logoImage =
          await rootBundle.load('assets/images/logo-restautante.png');
      final logoBytes = logoImage.buffer.asUint8List();
      final logo = pw.MemoryImage(logoBytes);

      final items = (pedidoData['items'] as List?) ?? const [];
      final subtotal = _asDouble(pedidoData['subtotal']);
      final descuento = _asDouble(pedidoData['descuento']);
      final total = _asDouble(pedidoData['total']);
      final estado = (pedidoData['status'] ?? 'pendiente').toString();
      final mesaNombreVisible =
          _decodeIfNeeded(mesaNombre) ?? (pedidoData['mesaNombre']?.toString());
      final clienteVisible = _decodeIfNeeded(clienteNombre) ??
          (pedidoData['clienteNombre']?.toString());
      final ticketNumero = ticketId ??
          (pedidoData['ultimoTicket']?.toString() ?? 'Ticket provisional');
      final shortId = pedidoId.length > 8 ? pedidoId.substring(0, 8) : pedidoId;
      final fecha = DateTime.now();
      final fechaFormateada = DateFormat('dd/MM/yyyy HH:mm').format(fecha);

      // Crear PDF tipo POS (80mm de ancho)
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.roll80,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Logo
                pw.Container(
                  width: 60,
                  height: 60,
                  child: pw.Image(logo),
                ),
                pw.SizedBox(height: 8),

                // Nombre del restaurante
                pw.Text(
                  'LA CENTRAL',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'TICKET DEL PEDIDO',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
                pw.Divider(thickness: 1),

                // Información del pedido
                pw.Container(
                  width: double.infinity,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Pedido:',
                              style: const pw.TextStyle(fontSize: 9)),
                          pw.Text(shortId,
                              style: pw.TextStyle(
                                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Ticket:',
                              style: const pw.TextStyle(fontSize: 9)),
                          pw.Text(ticketNumero,
                              style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Fecha:',
                              style: const pw.TextStyle(fontSize: 9)),
                          pw.Text(fechaFormateada,
                              style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Mesa:',
                              style: const pw.TextStyle(fontSize: 9)),
                          pw.Text(mesaNombreVisible ?? 'Sin asignar',
                              style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Cliente:',
                              style: const pw.TextStyle(fontSize: 9)),
                          pw.Text(clienteVisible ?? 'Consumidor final',
                              style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Estado:',
                              style: const pw.TextStyle(fontSize: 9)),
                          pw.Text(_estadoLegible(estado),
                              style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.Divider(thickness: 1),

                // Productos
                pw.Container(
                  width: double.infinity,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PRODUCTOS',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 6),
                      ...items.map((item) {
                        final data = item as Map<String, dynamic>;
                        final quantity = data['quantity'] ?? 1;
                        final name = (data['name'] ?? 'Producto').toString();
                        final price = _itemTotal(data);
                        final notas = (data['notes'] ?? '').toString();
                        final adicionales =
                            (data['adicionales'] as List?) ?? const [];

                        return pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Expanded(
                                  child: pw.Text(
                                    '${quantity}x $name',
                                    style: pw.TextStyle(
                                        fontSize: 9,
                                        fontWeight: pw.FontWeight.bold),
                                  ),
                                ),
                                pw.Text(
                                  _currency.format(price),
                                  style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                              ],
                            ),
                            // Adicionales
                            if (adicionales.isNotEmpty) ...[
                              pw.SizedBox(height: 2),
                              ...adicionales.map((adicional) {
                                final adicionalData =
                                    adicional as Map<String, dynamic>;
                                final adicionalName = (adicionalData['name'] ??
                                        adicionalData['nombre'] ??
                                        'Extra')
                                    .toString();
                                final adicionalPrice =
                                    _toDouble(adicionalData['price']);
                                return pw.Padding(
                                  padding: const pw.EdgeInsets.only(
                                      left: 10, top: 1),
                                  child: pw.Text(
                                    '+ $adicionalName (${_currency.format(adicionalPrice)})',
                                    style: const pw.TextStyle(
                                        fontSize: 8, color: PdfColors.grey700),
                                  ),
                                );
                              }).toList(),
                            ],
                            // Notas
                            if (notas.isNotEmpty) ...[
                              pw.SizedBox(height: 2),
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(left: 10),
                                child: pw.Text(
                                  'Nota: $notas',
                                  style: const pw.TextStyle(
                                      fontSize: 8, color: PdfColors.grey700),
                                ),
                              ),
                            ],
                            pw.SizedBox(height: 6),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
                pw.Divider(thickness: 1),

                // Totales
                pw.Container(
                  width: double.infinity,
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Subtotal:',
                              style: const pw.TextStyle(fontSize: 9)),
                          pw.Text(_currency.format(subtotal),
                              style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                      if (descuento > 0) ...[
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Descuento:',
                                style: const pw.TextStyle(fontSize: 9)),
                            pw.Text('- ${_currency.format(descuento)}',
                                style: const pw.TextStyle(fontSize: 9)),
                          ],
                        ),
                      ],
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('TOTAL:',
                              style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text(_currency.format(total),
                              style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.Divider(thickness: 1),

                // Pie de página
                pw.SizedBox(height: 8),
                pw.Text(
                  '¡Gracias por su preferencia!',
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  fechaFormateada,
                  style:
                      const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            );
          },
        ),
      );

      // Mostrar diálogo de impresión
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Ticket_$shortId.pdf',
        format: PdfPageFormat.roll80,
      );
    } catch (e) {
      SnackbarHelper.showError('Error al imprimir: ${e.toString()}');
    }
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static String? _decodeIfNeeded(String? value) {
    if (value == null || value.isEmpty) {
      return value;
    }
    try {
      return Uri.decodeComponent(value);
    } catch (_) {
      return value;
    }
  }

  static String _estadoLegible(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'preparacion':
      case 'preparando':
      case 'en_preparacion':
        return 'En preparacion';
      case 'terminado':
        return 'Terminado';
      case 'listo':
        return 'Listo';
      case 'cancelado':
        return 'Cancelado';
      case 'entregado':
        return 'Entregado';
      default:
        return estado.isEmpty ? 'Pendiente' : estado;
    }
  }

  static double _itemTotal(Map<String, dynamic> item) {
    final quantity = (item['quantity'] ?? 1) as int;
    final price = _toDouble(item['price']);
    final adicionales = (item['adicionales'] as List?) ?? const [];
    final adicionalesTotal = adicionales.fold<double>(
      0,
      (total, adicional) =>
          total + _toDouble((adicional as Map<String, dynamic>)['price']),
    );
    return (price + adicionalesTotal) * quantity;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  /// Genera una imagen PNG del ticket en formato POS (80mm)
  static Future<Uint8List> generateTicketImage({
    required Map<String, dynamic> pedidoData,
    required String pedidoId,
    String? ticketId,
    String? mesaNombre,
    String? clienteNombre,
  }) async {
    final items = (pedidoData['items'] as List?) ?? const [];
    final subtotal = _asDouble(pedidoData['subtotal']);
    final descuento = _asDouble(pedidoData['descuento']);
    final total = _asDouble(pedidoData['total']);
    final estado = (pedidoData['status'] ?? 'pendiente').toString();

    final mesaNombreVisible = _decodeIfNeeded(mesaNombre) ??
        pedidoData['mesaNombre']?.toString() ??
        'Sin asignar';
    final clienteVisible = _decodeIfNeeded(clienteNombre) ??
        pedidoData['clienteNombre']?.toString() ??
        'Consumidor final';

    final ticketNumero = ticketId ??
        pedidoData['ultimoTicket']?.toString() ??
        'Ticket provisional';

    final shortId = pedidoId.length > 8 ? pedidoId.substring(0, 8) : pedidoId;
    final fecha = DateTime.now();
    final fechaFormateada = DateFormat('dd/MM/yyyy HH:mm').format(fecha);

    // 📌 Tamaño real POS 80mm convertido a px
    const width = 384.0; // 80mm estándar térmica = 384px
    double yPos = 20.0;
    const double paddingHorizontal = 20.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Fondo blanco
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, width, 2000),
      Paint()..color = const Color.fromARGB(255, 255, 255, 255),
    );

    // 🎨 Cargar logo igual que el PDF
    final logoBytes =
        (await rootBundle.load('assets/images/logo-restautante.png'))
            .buffer
            .asUint8List();
    final logoImage = await decodeImageFromList(logoBytes);

    void drawImage(ui.Image img, double maxSize) {
  final originalWidth = img.width.toDouble();
  final originalHeight = img.height.toDouble();

  // Mantener proporción
  final aspectRatio = originalWidth / originalHeight;

  double drawWidth;
  double drawHeight;

  if (aspectRatio >= 1) {
    // Imagen horizontal o cuadrada
    drawWidth = maxSize;
    drawHeight = maxSize / aspectRatio;
  } else {
    // Imagen vertical
    drawHeight = maxSize;
    drawWidth = maxSize * aspectRatio;
  }

  // Centrar verticalmente respecto al maxSize
  final dx = (width - drawWidth) / 2;
  final dy = yPos + (maxSize - drawHeight) / 2;

  canvas.drawImageRect(
    img,
    Rect.fromLTWH(0, 0, originalWidth, originalHeight),
    Rect.fromLTWH(dx, dy, drawWidth, drawHeight),
    Paint()
    ..isAntiAlias = true
    ..filterQuality = FilterQuality.high,
  );

  // Avanzar el espacio vertical completo
  yPos += maxSize + 10;
}

    // 🖼 Logo
    drawImage(logoImage, 60);

    // 🎨 Helpers de texto con estilo similar al PDF
    TextPainter painter(String text,
        {double size = 12, bool bold = false, double maxWidth = width - 40}) {
      return TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: size,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        maxLines: 5,
      )..layout(maxWidth: maxWidth);
    }

    void drawText(String text,
        {double size = 12, bool bold = false, bool center = false}) {
      final tp = painter(text, size: size, bold: bold);
      double dx = center ? (width - tp.width) / 2 : paddingHorizontal;
      tp.paint(canvas, Offset(dx, yPos));
      yPos += tp.height + 4;
    }

    void drawDivider() {
      canvas.drawLine(
        Offset(paddingHorizontal, yPos),
        Offset(width - paddingHorizontal, yPos),
        Paint()..color = const Color(0xFFC7C7C7),
      );
      yPos += 10;
    }

    void drawSpaceDivider() {
      canvas.drawLine(
        Offset(paddingHorizontal, yPos),
        Offset(width - paddingHorizontal, yPos),
        Paint()..color = const ui.Color.fromARGB(0, 199, 199, 199),
      );
      yPos += 10;
    }

    void drawRow(String label, String value, bool bold) {
      final tpLabel = painter(label, size: 10, bold: bold);
      final tpValue = painter(value, size: 10, bold: bold);

      tpLabel.paint(canvas, Offset(paddingHorizontal, yPos));
      tpValue.paint(canvas, Offset(width - tpValue.width - paddingHorizontal, yPos));
      yPos += tpLabel.height + 4;
    }

    // 🧾 Títulos
    drawText("LA CENTRAL", size: 16, bold: true, center: true);
    drawText("TICKET DEL PEDIDO", size: 12, bold: true, center: true);
    drawSpaceDivider();
    drawDivider();
    

    // 🧾 Datos
    drawRow("Pedido:", shortId, false);
    drawRow("Ticket:", ticketNumero, false);
    drawRow("Fecha:", fechaFormateada, false);
    drawRow("Mesa:", mesaNombreVisible, false);
    drawRow("Cliente:", clienteVisible, false);
    drawRow("Estado:", _estadoLegible(estado), false);
    drawDivider();
    // 📦 Productos
    drawText("PRODUCTOS", size: 12, bold: true);
    drawSpaceDivider();

    for (var item in items) {
      final data = item as Map<String, dynamic>;
      final quantity = data['quantity'] ?? 1;
      final name = data['name']?.toString() ?? "Producto";
      final notas = data['notes']?.toString() ?? "";
      final adicionales = (data['adicionales'] as List?) ?? [];
      final price = _itemTotal(data);

      // Nombre y precio
      drawRow("$quantity x $name", _currency.format(price), true);

      // Adicionales
      for (var add in adicionales) {
        final addName = add['name'] ?? "Extra";
        final addPrice = _toDouble(add['price']);
        drawText("+ $addName (${_currency.format(addPrice)})", size: 10);
      }

      // Notas
      if (notas.isNotEmpty) {
        drawText("Nota: $notas", size: 10);
      }

      yPos += 6;
    }

    drawDivider();

    // 🧮 Totales (igual al PDF)
    drawRow("Subtotal:", _currency.format(subtotal), false);
    drawRow("Descuento:", "-${_currency.format(descuento)}", false);
    drawRow("TOTAL:", _currency.format(total), true);
    drawDivider();

    // 📝 Footer
    drawText("¡Gracias por su preferencia!", size: 10, center: true, bold: true);
    drawText(fechaFormateada, size: 9, center: true);

    // 🌟 Finalizar
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), (yPos + 40).toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }
}
