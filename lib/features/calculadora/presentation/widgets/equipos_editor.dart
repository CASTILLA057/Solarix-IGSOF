import 'package:flutter/material.dart';

import '../../../../core/formato.dart';
import '../../../../core/widgets/solarix_ui.dart';
import '../../domain/catalogos.dart';
import '../../domain/modelos.dart';
import 'campos.dart';

/// Lista editable de electrodomésticos con el consumo diario total.
class EquiposEditor extends StatelessWidget {
  const EquiposEditor({
    super.key,
    required this.equipos,
    required this.onChanged,
  });

  final List<Equipo> equipos;
  final ValueChanged<List<Equipo>> onChanged;

  Future<void> _agregar(BuildContext context) async {
    final elegido = await showModalBottomSheet<Equipo?>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, scroll) => ListView(
          controller: scroll,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Otro equipo…'),
              subtitle: const Text('Escribe su potencia y horas de uso'),
              onTap: () => Navigator.pop(
                context,
                const Equipo(nombre: '', potenciaW: 0),
              ),
            ),
            const Divider(),
            for (final e in equiposBase)
              ListTile(
                title: Text(e.nombre),
                subtitle: Text(_detalle(e)),
                onTap: () => Navigator.pop(context, e),
              ),
          ],
        ),
      ),
    );
    if (elegido == null || !context.mounted) return;
    // "Otro equipo" abre el formulario vacío; los de la lista se agregan tal cual.
    final equipo = elegido.nombre.isEmpty
        ? await mostrarDialogoEquipo(context)
        : elegido;
    if (equipo != null) onChanged([...equipos, equipo]);
  }

  Future<void> _editar(BuildContext context, int indice) async {
    final editado = await mostrarDialogoEquipo(
      context,
      inicial: equipos[indice],
    );
    if (editado != null) {
      onChanged([...equipos]..[indice] = editado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalWh = equipos.fold<double>(0, (s, e) => s + e.whDia);
    final ancho = esAncho(context);
    final agregar = OutlinedButton.icon(
      onPressed: () => _agregar(context),
      icon: const Icon(Icons.add),
      label: const Text('Agregar equipo'),
    );
    final total = Aviso(
      tono: TonoBurbuja.verde,
      icono: Icons.bolt_outlined,
      texto: 'Consumo total: ${Formato.numero(totalWh / 1000, 2)} kWh/día',
      detalle: '≈ ${Formato.numero(totalWh / 1000 * 30)} kWh al mes',
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (equipos.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ancho ? _tabla(context) : _lista(context),
          ),
        if (ancho)
          Row(
            children: [
              agregar,
              const SizedBox(width: 16),
              Expanded(child: total),
            ],
          )
        else ...[
          agregar,
          const SizedBox(height: 12),
          total,
        ],
      ],
    );
  }

  /// Celular: los equipos en una tarjeta, separados por líneas.
  Widget _lista(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      children: [
        for (final (i, e) in equipos.indexed) ...[
          if (i > 0) const Divider(height: 1),
          ListTile(
            title: Text(e.nombre, style: tema.textTheme.titleMedium),
            subtitle: Text(
              _detalleConCantidad(e),
              style: tema.textTheme.labelMedium?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
            onTap: () => _editar(context, i),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${Formato.numero(e.whDia)} Wh',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  tooltip: 'Quitar',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onChanged([...equipos]..removeAt(i)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Web: tabla con una columna por dato.
  Widget _tabla(BuildContext context) {
    final tema = Theme.of(context);
    final encabezado = tema.textTheme.labelMedium?.copyWith(
      color: tema.colorScheme.onSurfaceVariant,
    );
    Widget celda(String texto, {TextStyle? estilo, bool fin = true}) => Text(
      texto,
      style: estilo,
      textAlign: fin ? TextAlign.end : TextAlign.start,
    );
    Widget fila(List<Widget> celdas, {VoidCallback? alTocar, Color? fondo}) =>
        InkWell(
          onTap: alTocar,
          child: Container(
            color: fondo,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(child: celdas[0]),
                for (final (k, ancho) in const [
                  90.0,
                  110.0,
                  110.0,
                  110.0,
                ].indexed)
                  SizedBox(width: ancho, child: celdas[k + 1]),
                SizedBox(width: 48, child: celdas[5]),
              ],
            ),
          ),
        );
    return Column(
      children: [
        fila([
          celda('EQUIPO', estilo: encabezado, fin: false),
          celda('CANTIDAD', estilo: encabezado),
          celda('POTENCIA', estilo: encabezado),
          celda('USO AL DÍA', estilo: encabezado),
          celda('CONSUMO', estilo: encabezado),
          const SizedBox.shrink(),
        ], fondo: tema.colorScheme.surface),
        for (final (i, e) in equipos.indexed) ...[
          const Divider(height: 1),
          fila([
            celda(e.nombre, fin: false),
            celda('${e.cantidad}'),
            celda('${Formato.numero(e.potenciaW)} W'),
            celda(
              e.kwhDia != null
                  ? '${Formato.corto(e.kwhDia!)} kWh'
                  : '${Formato.corto(e.horasDia)} h',
            ),
            celda(
              '${Formato.numero(e.whDia)} Wh',
              estilo: const TextStyle(fontWeight: FontWeight.w600),
            ),
            IconButton(
              tooltip: 'Quitar',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => onChanged([...equipos]..removeAt(i)),
            ),
          ], alTocar: () => _editar(context, i)),
        ],
      ],
    );
  }
}

/// "4 × 9 W · 5 h/día", como el mockup.
String _detalleConCantidad(Equipo e) => e.kwhDia != null
    ? '${e.cantidad} × ${Formato.numero(e.potenciaW)} W · '
          '${Formato.corto(e.kwhDia!)} kWh/día'
    : '${e.cantidad} × ${Formato.numero(e.potenciaW)} W · '
          '${Formato.corto(e.horasDia)} h/día';

String _detalle(Equipo e) => e.kwhDia != null
    ? '${Formato.numero(e.potenciaW)} W · ${Formato.numero(e.kwhDia!, 1)} kWh/día'
    : '${Formato.numero(e.potenciaW)} W · ${Formato.numero(e.horasDia, 1)} h/día';

/// Formulario de un equipo. Devuelve `null` si se cancela.
Future<Equipo?> mostrarDialogoEquipo(BuildContext context, {Equipo? inicial}) =>
    showDialog<Equipo>(
      context: context,
      builder: (context) => _DialogoEquipo(inicial: inicial),
    );

class _DialogoEquipo extends StatefulWidget {
  const _DialogoEquipo({this.inicial});

  final Equipo? inicial;

  @override
  State<_DialogoEquipo> createState() => _DialogoEquipoState();
}

class _DialogoEquipoState extends State<_DialogoEquipo> {
  final _form = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.inicial?.nombre);
  late final _potencia = TextEditingController(
    text: _texto(widget.inicial?.potenciaW),
  );
  late final _horas = TextEditingController(
    text: _texto(widget.inicial?.horasDia),
  );
  late final _kwhDia = TextEditingController(
    text: _texto(widget.inicial?.kwhDia),
  );
  late final _cantidad = TextEditingController(
    text: '${widget.inicial?.cantidad ?? 1}',
  );
  late bool _porCiclos = widget.inicial?.kwhDia != null;
  late bool _conMotor = (widget.inicial?.factorArranque ?? 1) > 1;

  static String _texto(double? v) =>
      v == null || v == 0 ? '' : Formato.numero(v, v % 1 == 0 ? 0 : 1);

  @override
  void dispose() {
    for (final c in [_nombre, _potencia, _horas, _kwhDia, _cantidad]) {
      c.dispose();
    }
    super.dispose();
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    final factorPrevio = widget.inicial?.factorArranque ?? 1;
    Navigator.pop(
      context,
      Equipo(
        nombre: _nombre.text.trim(),
        potenciaW: Formato.leer(_potencia.text)!,
        horasDia: _porCiclos ? 0 : Formato.leer(_horas.text)!,
        kwhDia: _porCiclos ? Formato.leer(_kwhDia.text) : null,
        cantidad: Formato.leer(_cantidad.text)!.round(),
        factorArranque: _conMotor ? (factorPrevio > 1 ? factorPrevio : 3) : 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.inicial == null ? 'Nuevo equipo' : 'Editar equipo'),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombre,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Escribe el nombre.' : null,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 12),
              CampoNumero(
                controller: _potencia,
                etiqueta: 'Potencia',
                sufijo: 'W',
                ayuda: 'Está en la etiqueta del equipo.',
                minimo: 1,
                maximo: 20000,
              ),
              const SizedBox(height: 12),
              CampoNumero(
                controller: _cantidad,
                etiqueta: 'Cantidad',
                minimo: 1,
                maximo: 100,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Funciona por ciclos'),
                subtitle: const Text('Como la nevera: se indica kWh/día'),
                value: _porCiclos,
                onChanged: (v) => setState(() => _porCiclos = v),
              ),
              if (_porCiclos)
                CampoNumero(
                  controller: _kwhDia,
                  etiqueta: 'Consumo diario por unidad',
                  sufijo: 'kWh/día',
                  minimo: 0.01,
                  maximo: 50,
                )
              else
                CampoNumero(
                  controller: _horas,
                  etiqueta: 'Horas de uso al día',
                  sufijo: 'h',
                  minimo: 0.1,
                  maximo: 24,
                ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tiene motor'),
                subtitle: const Text(
                  'Nevera, bomba, lavadora: piden más potencia al arrancar',
                ),
                value: _conMotor,
                onChanged: (v) => setState(() => _conMotor = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }
}
