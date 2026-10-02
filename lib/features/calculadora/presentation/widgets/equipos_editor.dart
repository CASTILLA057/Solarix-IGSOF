import 'package:flutter/material.dart';

import '../../../../core/formato.dart';
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
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, e) in equipos.indexed)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                e.cantidad > 1 ? '${e.nombre} × ${e.cantidad}' : e.nombre,
              ),
              subtitle: Text(
                '${_detalle(e)} → ${Formato.numero(e.whDia)} Wh/día',
              ),
              onTap: () => _editar(context, i),
              trailing: IconButton(
                tooltip: 'Quitar',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onChanged([...equipos]..removeAt(i)),
              ),
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => _agregar(context),
          icon: const Icon(Icons.add),
          label: const Text('Agregar equipo'),
        ),
        const SizedBox(height: 12),
        Text(
          'Consumo total: ${Formato.numero(totalWh / 1000, 2)} kWh/día '
          '(${Formato.numero(totalWh / 1000 * 30)} kWh/mes)',
          style: tema.textTheme.titleSmall,
        ),
      ],
    );
  }
}

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
