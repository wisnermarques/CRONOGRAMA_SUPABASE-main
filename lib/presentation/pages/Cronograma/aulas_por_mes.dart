import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../data/models/aula_model.dart';
import '../../../data/models/turma_model.dart';

class AulasPorMesPage extends StatefulWidget {
  const AulasPorMesPage({super.key});

  @override
  State<AulasPorMesPage> createState() => _AulasPorMesPageState();
}

class _AulasPorMesPageState extends State<AulasPorMesPage> {
  final supabase = Supabase.instance.client;

  List<Turma> turmas = [];
  Turma? turmaSelecionada;

  List<int> ucs = [];
  int? ucSelecionada;

  DateTime? mesSelecionado;
  List<Aulas> aulasDoMes = [];

  @override
  void initState() {
    super.initState();
    carregarTurmas();
  }

  Future<void> carregarTurmas() async {
    final response = await supabase.from('turma').select();
    setState(() {
      turmas = (response as List).map((map) => Turma.fromMap(map)).toList();
    });
  }

  Future<void> carregarUCs() async {
    if (turmaSelecionada?.idturma == null) return;

    final List response = await supabase
        .from('aulas')
        .select('iduc')
        .eq('idturma', turmaSelecionada!.idturma!)
        .order('iduc', ascending: true);

    setState(() {
      ucs = response.map((e) => e['iduc'] as int).toSet().toList();
    });
  }

  Future<void> buscarAulas() async {
    if (turmaSelecionada == null || ucSelecionada == null || mesSelecionado == null) return;

    final inicio = DateTime(mesSelecionado!.year, mesSelecionado!.month, 1);
    final fim = DateTime(mesSelecionado!.year, mesSelecionado!.month + 1, 0);

    try {
      final idTurma = turmaSelecionada!.idturma!;
      final idUc = ucSelecionada!;

      final response = await supabase
          .from('aulas')
          .select()
          .gte('data', inicio.toIso8601String())
          .lte('data', fim.toIso8601String())
          .eq('idturma', idTurma)
          .eq('iduc', idUc);

      setState(() {
        aulasDoMes = (response as List)
            .map((map) => Aulas.fromMap(map as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      // print('Erro ao buscar aulas: $e');
    }
  }

  Future<void> exportarPDF() async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Cronograma de Aulas', style: const pw.TextStyle(fontSize: 22)),
            pw.SizedBox(height: 10),
            if (turmaSelecionada != null)
              pw.Text('Turma: ${turmaSelecionada!.turmanome}'),
            if (ucSelecionada != null)
              pw.Text('UC: $ucSelecionada'),
            if (mesSelecionado != null)
              pw.Text('Mês: ${DateFormat('MM/yyyy').format(mesSelecionado!)}'),
            pw.Divider(),
            ...aulasDoMes.map(
              (aula) => pw.Text(
                '${dateFormat.format(aula.data)} - ${aula.horario} - ${aula.horas}h - ${aula.status}',
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aulas por Mês'),
        actions: [
          if (aulasDoMes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Exportar para PDF',
              onPressed: exportarPDF,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<Turma>(
              hint: const Text('Selecione a turma'),
              value: turmaSelecionada,
              isExpanded: true,
              items: turmas.map((turma) {
                return DropdownMenuItem(
                  value: turma,
                  child: Text(turma.turmanome),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  turmaSelecionada = value;
                  ucSelecionada = null;
                  aulasDoMes.clear();
                  carregarUCs();
                });
              },
            ),
            const SizedBox(height: 10),
            DropdownButton<int>(
              hint: const Text('Selecione a UC'),
              value: ucSelecionada,
              isExpanded: true,
              items: ucs.map((id) {
                return DropdownMenuItem(
                  value: id,
                  child: Text('UC $id'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  ucSelecionada = value;
                  aulasDoMes.clear();
                });
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final selecionado = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  helpText: 'Selecione o mês',
                  locale: const Locale('pt', 'BR'),
                );
                if (selecionado != null) {
                  setState(() => mesSelecionado = selecionado);
                  buscarAulas();
                }
              },
              child: Text(mesSelecionado == null
                  ? 'Selecionar mês'
                  : 'Mês: ${dateFormat.format(mesSelecionado!)}'),
            ),
            const SizedBox(height: 20),
            if (aulasDoMes.isNotEmpty) ...[
              const Text('Aulas agendadas:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: aulasDoMes.length,
                  itemBuilder: (context, index) {
                    final aula = aulasDoMes[index];
                    return ListTile(
                      title: Text(DateFormat('dd/MM/yyyy').format(aula.data)),
                      subtitle: Text('${aula.horario} - ${aula.status} - ${aula.horas}h'),
                    );
                  },
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
