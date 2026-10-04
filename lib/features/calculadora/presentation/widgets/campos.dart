import 'package:flutter/material.dart';

import '../../../../core/formato.dart';

/// Campo numérico con unidad y validación de rango. Acepta números escritos
/// a la colombiana (`1.500.000`, `4,5`).
class CampoNumero extends StatelessWidget {
  const CampoNumero({
    super.key,
    required this.controller,
    required this.etiqueta,
    this.sufijo,
    this.ayuda,
    this.minimo,
    this.maximo,
    this.onChanged,
  });

  final TextEditingController controller;
  final String etiqueta;
  final String? sufijo;
  final String? ayuda;
  final double? minimo;
  final double? maximo;
  final ValueChanged<String>? onChanged;

  String? _validar(String? texto) {
    final valor = Formato.leer(texto);
    if (valor == null) return 'Escribe un número.';
    if (minimo != null && valor < minimo!) {
      return 'Debe ser al menos ${Formato.corto(minimo!)}.';
    }
    if (maximo != null && valor > maximo!) {
      return 'Debe ser como máximo ${Formato.corto(maximo!)}.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: _validar,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: etiqueta,
        suffixText: sufijo,
        helperText: ayuda,
        helperMaxLines: 2,
      ),
    );
  }
}
