// ignore_for_file: use_build_context_synchronously, avoid_print, non_constant_identifier_names, library_private_types_in_public_api
import 'package:cronograma/data/models/aula_model.dart';
import 'package:cronograma/data/models/turma_model.dart';
import 'package:cronograma/data/repositories/turma_repository.dart';
import 'package:cronograma/presentation/viewmodels/turma_viewmodels.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'package:cronograma/presentation/pages/Cronograma/agendar_aulas_page.dart';

import '../../../widgets/feriados_dialog.dart';

class CronogramaPage extends StatefulWidget {
  const CronogramaPage({super.key});

  @override
  _CronogramaPageState createState() => _CronogramaPageState();
}

class _CronogramaPageState extends State<CronogramaPage> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  final Set<DateTime> _selectedDays = {};
  final Map<DateTime, List<Aulas>> _events = {};
  final Map<DateTime, List<Aulas>> _filteredEvents = {};
  final Map<DateTime, String> _feriadosNacionais = {};
  final Map<DateTime, String> _feriadosMunicipais = {};
  bool _isLoading = true;
  final Map<int, int> _cargaHorariaUc = {};
  List<Turma> _turmas = [];
  List<Map<String, dynamic>> _cursos = [];
  int? _selectedTurmaId;
  final TurmaViewModel _viewModel = TurmaViewModel(TurmaRepository());
  int _cargaRestante = 0;

  final Map<String, Map<String, dynamic>> _periodoConfig = {
    'Matutino': {
      'maxHoras': 4,
      'horario': '08:00-12:00',
      'icon': Icons.wb_sunny_outlined,
    },
    'Vespertino': {
      'maxHoras': 4,
      'horario': '14:00-18:00',
      'icon': Icons.brightness_5,
    },
    'Noturno': {
      'maxHoras': 3,
      'horario': '19:00-22:00',
      'icon': Icons.nights_stay_outlined,
    },
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = now;
    _carregarFeriadosBrasileiros(); // Removido o parâmetro do ano
    _carregarFeriadosMunicipais();
    _carregarturmas().then((_) => _carregarAulas());
    _carregarCargaHorariaUc();
    _carregarCursos();
  }

  Future<void> _carregarFeriadosMunicipais() async {
    try {
      final response =
          await Supabase.instance.client.from('feriadosmunicipais').select();

      final feriados = response as List<dynamic>;

      setState(() {
        _feriadosMunicipais.clear();
        for (var feriado in feriados) {
          try {
            final dateStr = feriado['data'] as String;
            final date = dateStr.contains('T')
                ? DateTime.parse(dateStr).toLocal()
                : DateTime.parse(dateStr);
            final normalizedDate = DateTime(date.year, date.month, date.day);
            _feriadosMunicipais[normalizedDate] = feriado['nome'] as String;
          } catch (e) {
            print('Erro ao processar feriado: $e');
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar feriados municipais: $e')),
        );
      }
    }
  }

  void _showFeriadosDialog() {
    showDialog(
      context: context,
      builder: (context) => FeriadosDialog(
        feriadosNacionais: _feriadosNacionais,
        feriadosMunicipais: _feriadosMunicipais,
        onFeriadoAdded: () async {
          await _carregarFeriadosMunicipais();
          setState(() {});
        },
      ),
    );
  }

  Future<void> _carregarCursos() async {
    try {
      final response = await Supabase.instance.client.from('cursos').select();

      if (mounted) {
        setState(() {
          _cursos = response;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar cursos: $e')),
        );
      }
    }
  }

  Future<void> _carregarturmas() async {
    try {
      final turmas = await _viewModel.getTurmasNomes();
      if (mounted) {
        setState(() {
          _turmas = turmas;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar turmas: $e')),
        );
      }
    }
  }

  Future<void> _carregarFeriadosBrasileiros() async {
    _feriadosNacionais.clear();

    // Calcula feriados para cada ano de 2020 até 2120 (100 anos de cobertura)
    for (int ano = 2020; ano <= 2120; ano++) {
      // Feriados fixos
      _feriadosNacionais[DateTime(ano, 1, 1)] = '🎉 Ano Novo';
      _feriadosNacionais[DateTime(ano, 4, 21)] = '🎖 Tiradentes';
      _feriadosNacionais[DateTime(ano, 5, 1)] = '👷 Dia do Trabalho';
      _feriadosNacionais[DateTime(ano, 9, 7)] = '🇧🇷 Independência do Brasil';
      _feriadosNacionais[DateTime(ano, 10, 12)] = '🙏 Nossa Senhora Aparecida';
      _feriadosNacionais[DateTime(ano, 11, 2)] = '🕯 Finados';
      _feriadosNacionais[DateTime(ano, 11, 15)] = '🏛 Proclamação da República';
      _feriadosNacionais[DateTime(ano, 12, 25)] = '🎄 Natal';

      // Feriados móveis baseados na Páscoa
      final pascoa = _calcularPascoa(ano);
      _feriadosNacionais[pascoa] = '🐣 Páscoa';
      _feriadosNacionais[pascoa.subtract(const Duration(days: 2))] =
          '✝ Sexta-Feira Santa';
      _feriadosNacionais[pascoa.subtract(const Duration(days: 47))] =
          '🎭 Carnaval';
      _feriadosNacionais[pascoa.add(const Duration(days: 60))] =
          '🍞 Corpus Christi';
    }
  }

  DateTime _calcularPascoa(int ano) {
    final a = ano % 19;
    final b = ano ~/ 100;
    final c = ano % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final mes = (h + l - 7 * m + 114) ~/ 31;
    final dia = (h + l - 7 * m + 114) % 31 + 1;

    return DateTime(ano, mes, dia);
  }

  Future<void> _carregarAulas() async {
    try {
      final response = await Supabase.instance.client.from('aulas').select();

      final Map<DateTime, List<Aulas>> events = {};
      for (var aula in response as List<dynamic>) {
        try {
          final date = DateTime.parse(aula['data'] as String);
          final normalizedDate = DateTime(date.year, date.month, date.day);

          final aulaObj = Aulas(
            idaula: aula['idaula'] as int,
            iduc: aula['iduc'] as int,
            idturma: aula['idturma'] as int,
            data: date,
            horario: aula['horario'] as String,
            status: aula['status'] as String,
            horas: aula['horas'] as int? ?? 1,
          );

          events.putIfAbsent(normalizedDate, () => []).add(aulaObj);
        } catch (e) {
          print('Erro ao processar aula: $e');
        }
      }

      if (mounted) {
        setState(() {
          _events.clear();
          _events.addAll(events);
          _aplicarFiltroTurma();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar aulas: $e')),
        );
      }
    }
  }

  void _aplicarFiltroTurma() {
    _filteredEvents.clear();

    if (_selectedTurmaId == null) {
      _filteredEvents.addAll(_events);
      return;
    }

    for (var entry in _events.entries) {
      final filteredAulas = entry.value
          .where((aula) => aula.idturma == _selectedTurmaId)
          .toList();

      if (filteredAulas.isNotEmpty) {
        _filteredEvents[entry.key] = filteredAulas;
      }
    }
  }

  Future<void> _carregarCargaHorariaUc() async {
    try {
      final response = await Supabase.instance.client
          .from('unidades_curriculares')
          .select('iduc, cargahoraria');

      if (mounted) {
        setState(() {
          _cargaHorariaUc.clear();
          for (var uc in response as List<dynamic>) {
            _cargaHorariaUc[uc['iduc'] as int] =
                (uc['cargahoraria'] ?? 0) as int;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar carga horária: $e')),
        );
      }
    }
  }

  bool _isFeriado(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    return _feriadosNacionais.containsKey(normalizedDate) ||
        _feriadosMunicipais.containsKey(normalizedDate);
  }

  bool _isDiaUtil(DateTime day) {
    if (day.weekday == 7) return false; // Apenas domingo não é dia útil
    if (_isFeriado(day)) return false; // Feriados também não são dias úteis
    return true;
  }

  Future<void> _adicionarAula() async {
    try {
      if ((_selectedDays.isEmpty && _selectedDay == null) || !mounted) return;

      final diasParaAgendar =
          _selectedDays.isNotEmpty ? _selectedDays : {_selectedDay!};

      final diasInvalidos =
          diasParaAgendar.where((day) => !_isDiaUtil(day)).toList();

      if (diasInvalidos.isNotEmpty) {
        final formatados =
            diasInvalidos.map((d) => DateFormat('dd/MM').format(d)).join(', ');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Não é possível agendar em domingos ou feriados: $formatados'),
            ),
          );
        }
        return;
      }

      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => AgendarAulasPage(
            selectedDays: diasParaAgendar,
            periodoConfig: _periodoConfig,
          ),
        ),
      );

      if (result == true) {
        await _carregarAulas();
        await _carregarCargaHorariaUc();

        if (mounted) {
          setState(() {
            _selectedDays.clear();
            _selectedDay = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aulas agendadas com sucesso!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar aula: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _imprimirCronogramaWindows() async {
    if (_selectedTurmaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma turma para imprimir')),
      );
      return;
    }

    // Get the selected turma details
    final turma = _turmas.firstWhere((t) => t.idturma == _selectedTurmaId);
    final curso = _cursos.firstWhere(
      (c) => c['idcurso'] == turma.cursos?.idcurso,
      orElse: () => {'nomecurso': 'Curso não encontrado'},
    );

    // Filter events for the focused month and selected turma
    final monthEvents = _filteredEvents.entries.where((entry) {
      return entry.key.year == _focusedDay.year &&
          entry.key.month == _focusedDay.month;
    }).toList();

    // Sort events by date
    monthEvents.sort((a, b) => a.key.compareTo(b.key));

    // Pre-fetch all aula details with proper error handling
    final List<Map<String, dynamic>> aulaDetails = [];
    for (var entry in monthEvents) {
      for (var aula in entry.value) {
        try {
          final details = await _getAulaDetails(aula.idaula!);
          aulaDetails.add({
            'idaula': aula.idaula,
            'data': aula.data,
            'horario': aula.horario,
            'status': aula.status,
            'nomeuc': details['nomeuc'],
          });
        } catch (e) {
          aulaDetails.add({
            'idaula': aula.idaula,
            'data': aula.data,
            'horario': aula.horario,
            'status': aula.status,
            'nomeuc': 'Erro ao carregar',
          });
        }
      }
    }

    // Create PDF document
    final pdf = pw.Document();

    // Add a page with the calendar and events
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            // Header with turma and month info
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Cronograma de Aulas',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text('Curso: ${curso['nomecurso']}'),
                  pw.Text('Turma: ${turma.turmanome}'),
                  pw.Text(
                      'Mês: ${DateFormat('MMMM yyyy', 'pt_BR').format(_focusedDay)}'),
                  pw.Divider(),
                ],
              ),
            ),

            // Calendar table
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              headers: ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'],
              data: _buildCalendarTableData(),
            ),

            pw.SizedBox(height: 20),

            // Events list
            pw.Header(
              level: 1,
              child: pw.Text('Aulas Agendadas',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ),

            if (monthEvents.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('Nenhuma aula agendada para este mês'),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.5),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Data',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Unidade Curricular',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Horário',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Status',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...aulaDetails.map((detail) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                              DateFormat('dd/MM/yyyy').format(detail['data'])),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(detail['nomeuc']),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(detail['horario']),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(detail['status']),
                        ),
                      ],
                    );
                  }),
                ],
              ),
          ];
        },
      ),
    );

    // Save and launch the PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  List<List<String>> _buildCalendarTableData() {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    // Calculate the weekday of the first day (0=Sunday, 6=Saturday)
    int startingWeekday = firstDayOfMonth.weekday % 7;

    List<List<String>> weeks = [];
    List<String> currentWeek = List.filled(7, '');

    // Fill the days before the first day of the month
    for (int i = 0; i < startingWeekday; i++) {
      currentWeek[i] = '';
    }

    // Fill the days of the month
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      int weekday = (startingWeekday + day - 1) % 7;
      currentWeek[weekday] = day.toString();

      // Check if this day has events
      final date = DateTime(_focusedDay.year, _focusedDay.month, day);
      if (_filteredEvents.containsKey(date)) {
        currentWeek[weekday] += '*'; // Add marker for days with events
      }

      // Check if this day is a holiday
      if (_isFeriado(date)) {
        currentWeek[weekday] += '†'; // Add marker for holidays
      }

      // If we've reached Saturday or the end of the month, add the week
      if (weekday == 6 || day == lastDayOfMonth.day) {
        weeks.add(List.from(currentWeek));
        if (day != lastDayOfMonth.day) {
          currentWeek = List.filled(7, '');
        }
      }
    }

    return weeks;
  }

  Future<void> _removerAula(
      int idAula, int idUc, String horario, int horas) async {
    try {
      // 1. Buscar a aula e suas horas
      final response = await Supabase.instance.client
          .from('aulas')
          .select('horas')
          .eq('idaula', idAula)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        throw Exception('Aula não encontrada.');
      }

      final int horasAula =
          response['horas'] as int? ?? (horario == '19:00-22:00' ? 3 : 4);

      // 2. Remover a aula
      await Supabase.instance.client
          .from('aulas')
          .delete()
          .eq('idaula', idAula);

      // 3. Restaurar carga horária no estado local
      setState(() {
        _cargaHorariaUc[idUc] = (_cargaHorariaUc[idUc] ?? 0) + horasAula;
      });

      // 4. Atualizar visualmente e notificar usuário
      if (mounted) {
        await _carregarAulas();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Aula removida com sucesso! ($horasAula horas restauradas)'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover aula: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  List<Aulas> _getEventsForDay(DateTime day) {
    if (_selectedTurmaId == null) {
      return _events[DateTime(day.year, day.month, day.day)] ?? [];
    } else {
      return _filteredEvents[DateTime(day.year, day.month, day.day)] ?? [];
    }
  }

  String? _getFeriadoForDay(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    return _feriadosNacionais[normalizedDate] ??
        _feriadosMunicipais[normalizedDate];
  }

  Widget _buildEventList() {
    if (_selectedDay == null && _selectedDays.isEmpty) return const SizedBox();

    if (_selectedDay != null && _selectedDays.isEmpty) {
      final events = _getEventsForDay(_selectedDay!);
      final feriado = _getFeriadoForDay(_selectedDay!);

      return _buildDayEvents(_selectedDay!, events, feriado);
    }

    return ListView(
      children: _selectedDays.map((day) {
        final events = _getEventsForDay(day);
        final feriado = _getFeriadoForDay(day);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                DateFormat('EEEE, dd/MM', 'pt_BR').format(day),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            _buildDayEvents(day, events, feriado),
            const Divider(),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDayEvents(DateTime day, List<Aulas> events, String? feriado) {
    return Column(
      children: [
        if (feriado != null)
          Card(
            color: Colors.amber[100],
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: const Icon(Icons.celebration, color: Colors.orange),
              title: Text(feriado),
            ),
          ),
        if (events.isEmpty && feriado == null)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Nenhuma aula agendada'),
          ),
        ...events.map((aula) => _buildAulaCard(aula)),
      ],
    );
  }

  Widget _buildAulaCard(Aulas aulas) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 10,
          height: 40,
          color: _getColorByStatus(aulas.status),
        ),
        title: FutureBuilder<Map<String, dynamic>>(
          future: _getAulaDetails(aulas.idaula!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Carregando...');
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Text('Erro ao carregar dados');
            }
            final data = snapshot.data!;
            return Text('${data['nomeuc']} - ${data['turma']}');
          },
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: _getAulaDetails(aulas.idaula!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Carregando...');
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text('Erro ao carregar dados');
                }
                final data = snapshot.data!;
                // print(data);
                if (data['cargahorariauc'] != null &&
                    data['cargahorariaucagendada'] != null) {
                  _cargaRestante =
                      data['cargahorariauc'] - data['cargahorariaucagendada'] ??
                          0;
                }
                return Text('Instrutor: ${data['nomeinstrutor']}');
              },
            ),
            Text('Horário: ${aulas.horario} - ${aulas.horas}h'),
            Text('Status: ${aulas.status}'),
            FutureBuilder<Map<String, dynamic>>(
              future: _getAulaDetails(aulas.idaula!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Carregando...');
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text('Erro ao carregar dados');
                }

                return Text('Carga horária restante: $_cargaRestante horas');
              },
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _removerAula(
              aulas.idaula!, aulas.iduc, aulas.horario, aulas.horas),
        ),
      ),
    );
  }

  Color _getColorByStatus(String status) {
    switch (status) {
      case 'Realizada':
        return Colors.green;
      case 'Cancelada':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Future<Map<String, dynamic>> _getAulaDetails(int idAula) async {
    try {
      // Consulta da aula com dados relacionados (UC, turma, instrutor)
      final response = await Supabase.instance.client.from('aulas').select('''
      idaula,
      iduc,
      idturma,
      horario,
      status,
      horas,
      unidades_curriculares(nomeuc, cargahoraria),
      turma(
        turmanome,
        instrutores(nomeinstrutor)
      )
    ''').eq('idaula', idAula).single();

      final int selectedUcId = response['iduc'];
      final int selectedTurmaId = response['idturma'];

      // Consulta da carga horária total da UC na turma
      final response2 = await Supabase.instance.client
          .from('aulas_carga')
          .select('cargahorariauc')
          .eq('iduc', selectedUcId)
          .eq('idturma', selectedTurmaId)
          .single();

      final int cargaHorariaUc = response2['cargahorariauc'] != null
          ? (response2['cargahorariauc'] as num).toInt()
          : 0;

      // Verifica se 'instrutores' é lista ou mapa
      String nomeInstrutor = 'Não encontrado';
      final instrutores = response['turma']?['instrutores'];
      if (instrutores is List && instrutores.isNotEmpty) {
        nomeInstrutor = instrutores.first['nomeinstrutor'] ?? 'Não encontrado';
      } else if (instrutores is Map) {
        nomeInstrutor = instrutores['nomeinstrutor'] ?? 'Não encontrado';
      }

      final Map<String, dynamic> resultado = {
        'nomeuc':
            response['unidades_curriculares']?['nomeuc'] ?? 'Não encontrado',
        'turma': response['turma']?['turmanome'] ?? 'Não encontrada',
        'nomeinstrutor': nomeInstrutor,
        'cargahorariauc':
            response['unidades_curriculares']?['cargahoraria'] ?? 0,
        'horario': response['horario'] ?? '',
        'status': response['status'] ?? '',
        'horas': response['horas'] ?? 0,
        'cargahorariaucagendada': cargaHorariaUc,
      };

      print('Resultado: $resultado');

      return resultado;
    } catch (e) {
      return {
        'nomeuc': 'Erro: $e',
        'turma': 'Erro: $e',
        'nomeinstrutor': 'Erro: $e',
        'horario': '',
        'status': '',
        'horas': 0,
        'cargahorariauc': 0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronograma de Aulas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _imprimirCronogramaWindows,
            // onPressed: () {
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (context) => const AulasPorMesPage()),
            //   );
            // },
          ),
          IconButton(
            icon: const Icon(Icons.event),
            onPressed: _showFeriadosDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarAula,
        tooltip: 'Agendar aulas',
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: _selectedTurmaId,
                    decoration: InputDecoration(
                      labelText: 'Filtrar por Turma',
                      prefixIcon:
                          Icon(Icons.filter_list, color: colorScheme.primary),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Todas as Turmas'),
                      ),
                      ..._turmas.map((turma) {
                        final curso = _cursos.firstWhere(
                          (c) => c['idcurso'] == turma.cursos?.idcurso,
                          orElse: () => {'nomecurso': 'Curso não encontrado'},
                        );
                        return DropdownMenuItem<int>(
                          value: turma.idturma as int,
                          child: Text(
                              '${curso['nomecurso']} - ${turma.turmanome}'),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedTurmaId = value;
                        _aplicarFiltroTurma();
                      });
                    },
                  ),
                ),
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) {
                    return _selectedDays.contains(day) ||
                        isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                      final isShiftPressed = HardwareKeyboard
                          .instance.logicalKeysPressed
                          .any((key) =>
                              key == LogicalKeyboardKey.shiftLeft ||
                              key == LogicalKeyboardKey.shiftRight);
                      final isCtrlPressed = HardwareKeyboard
                          .instance.logicalKeysPressed
                          .any((key) =>
                              key == LogicalKeyboardKey.controlLeft ||
                              key == LogicalKeyboardKey.controlRight);

                      if (isShiftPressed || isCtrlPressed) {
                        if (_selectedDays.contains(selectedDay)) {
                          _selectedDays.remove(selectedDay);
                        } else {
                          _selectedDays.add(selectedDay);
                        }
                        _selectedDay = null;
                      } else {
                        _selectedDays.clear();
                        _selectedDay = selectedDay;
                      }
                    });
                  },
                  onPageChanged: (focusedDay) =>
                      setState(() => _focusedDay = focusedDay),
                  eventLoader: _getEventsForDay,
                  calendarStyle: CalendarStyle(
                    weekendTextStyle: const TextStyle(color: Colors.red),
                    holidayTextStyle: TextStyle(color: Colors.red[800]),
                    markerDecoration: BoxDecoration(
                      color: Colors.blue[400],
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    outsideDaysVisible: false,
                  ),
                  headerStyle: HeaderStyle(
                    titleTextFormatter: (date, locale) =>
                        DateFormat('MMMM yyyy', 'pt_BR')
                            .format(date)
                            .toUpperCase(),
                    formatButtonVisible: false,
                    leftChevronIcon: const Icon(Icons.chevron_left),
                    rightChevronIcon: const Icon(Icons.chevron_right),
                    formatButtonDecoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    formatButtonTextStyle: const TextStyle(color: Colors.white),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
                    weekendStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    dowBuilder: (context, day) {
                      final text = DateFormat.EEEE('pt_BR').format(day);
                      return Center(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: day.weekday == 6 || day.weekday == 7
                                ? Colors.red
                                : null,
                          ),
                        ),
                      );
                    },
                    defaultBuilder: (context, date, _) {
                      final isFeriado = _isFeriado(date);
                      final isDomingo = date.weekday == 7;
                      final isSabado = date.weekday == 6;
                      final isToday = isSameDay(date, DateTime.now());
                      final isSelected = _selectedDays.contains(date) ||
                          isSameDay(_selectedDay, date);

                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isToday
                              ? Colors.orange.withOpacity(0.3)
                              : isFeriado
                                  ? Colors.red[50]
                                  : isSelected
                                      ? Colors.blue[100]
                                      : null,
                          border: Border.all(
                            color: isToday
                                ? Colors.orange
                                : isFeriado
                                    ? Colors.red
                                    : isSabado
                                        ? Colors.blue
                                            .shade200 // Cor diferente para sábado (não nula)
                                        : isSelected
                                            ? Colors.blue
                                            : Colors.transparent,
                            width: isToday ? 2 : 1,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              color: isFeriado
                                  ? Colors.red[800]
                                  : isDomingo
                                      ? Colors.red
                                      : isSabado
                                          ? Colors.blue
                                              .shade800 // Cor diferente para sábado (não nula)
                                          : isSelected
                                              ? Colors.blue[900]
                                              : null,
                              fontWeight: isFeriado || isSelected
                                  ? FontWeight.bold
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_selectedDays.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '${_selectedDays.length} dia(s) selecionado(s)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                Expanded(
                  child: _buildEventList(),
                ),
              ],
            ),
    );
  }
}
