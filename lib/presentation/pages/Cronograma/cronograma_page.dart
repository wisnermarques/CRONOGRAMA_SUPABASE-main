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
    final logoImage = pw.MemoryImage(
      (await rootBundle.load('images/logo_senac.png')).buffer.asUint8List(),
    );

    if (_selectedTurmaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma turma para imprimir')),
      );
      return;
    }

    final turma = _turmas.firstWhere((t) => t.idturma == _selectedTurmaId);
    final curso = _cursos.firstWhere(
      (c) => c['idcurso'] == turma.cursos?.idcurso,
      orElse: () => {'nomecurso': 'Curso não encontrado'},
    );

    final monthEvents = _filteredEvents.entries.where((entry) {
      return entry.key.year == _focusedDay.year &&
          entry.key.month == _focusedDay.month;
    }).toList();

    monthEvents.sort((a, b) => a.key.compareTo(b.key));

    final Map<String, List<Map<String, dynamic>>> aulasPorUC = {};
    final Map<String, double> horasPorUC = {};
    final Map<String, String> instrutorPrincipalPorUC = {};
    final Set<int> diasComAulas = {};
    TimeOfDay? menorHorarioInicio;
    TimeOfDay? maiorHorarioTermino;

    for (var entry in monthEvents) {
      for (var aula in entry.value) {
        try {
          final details = await _getAulaDetails(aula.idaula!);
          final nomeUC = details['nomeuc'] ?? 'UC não definida';
          final instrutor = details['nomeinstrutor'] ?? 'Não definido';
          final primeiroNome = instrutor.split(' ').first;
          final duracao = aula.horas.toDouble();

          // Processa os dias da semana
          final dataAula = aula.data;
          diasComAulas.add(dataAula.weekday);

          // Processa os horários
          final horarioParts = aula.horario.split('-');
          if (horarioParts.length == 2) {
            final inicioParts = horarioParts[0].split(':');
            final terminoParts = horarioParts[1].split(':');

            if (inicioParts.length == 2 && terminoParts.length == 2) {
              final inicio = TimeOfDay(
                hour: int.parse(inicioParts[0]),
                minute: int.parse(inicioParts[1]),
              );
              final termino = TimeOfDay(
                hour: int.parse(terminoParts[0]),
                minute: int.parse(terminoParts[1]),
              );

              // Atualiza menor horário de início
              if (menorHorarioInicio == null ||
                  (inicio.hour < menorHorarioInicio.hour ||
                      (inicio.hour == menorHorarioInicio.hour &&
                          inicio.minute < menorHorarioInicio.minute))) {
                menorHorarioInicio = inicio;
              }

              // Atualiza maior horário de término
              if (maiorHorarioTermino == null ||
                  (termino.hour > maiorHorarioTermino.hour ||
                      (termino.hour == maiorHorarioTermino.hour &&
                          termino.minute > maiorHorarioTermino.minute))) {
                maiorHorarioTermino = termino;
              }
            }
          }

          if (!aulasPorUC.containsKey(nomeUC)) {
            aulasPorUC[nomeUC] = [];
            horasPorUC[nomeUC] = 0;
            instrutorPrincipalPorUC[nomeUC] = primeiroNome;
          }

          aulasPorUC[nomeUC]!.add({
            'data': aula.data,
            'horario': aula.horario,
            'status': aula.status,
            'instrutor': primeiroNome,
            'duracao': duracao,
          });

          horasPorUC[nomeUC] = horasPorUC[nomeUC]! + duracao;
        } catch (e) {
          // Handle error
        }
      }
    }

    // Função para formatar dias da semana (mantida do código anterior)
    String formatarDiasDaSemana(Set<int> dias) {
      if (dias.isEmpty) return 'Não há aulas agendadas';

      final List<String> nomesDias = [];
      final sortedDays = dias.toList()..sort();

      for (var dia in sortedDays) {
        switch (dia) {
          case 1:
            nomesDias.add('Segunda');
            break;
          case 2:
            nomesDias.add('Terça');
            break;
          case 3:
            nomesDias.add('Quarta');
            break;
          case 4:
            nomesDias.add('Quinta');
            break;
          case 5:
            nomesDias.add('Sexta');
            break;
          case 6:
            nomesDias.add('Sábado');
            break;
          case 7:
            nomesDias.add('Domingo');
            break;
        }
      }

      if (nomesDias.length == 1) return '${nomesDias.first}-feira';

      String result = '';
      for (int i = 0; i < nomesDias.length; i++) {
        if (i == nomesDias.length - 1) {
          result += ' e ${nomesDias[i]}-feira';
        } else {
          result += '${nomesDias[i]}, ';
        }
      }

      result = result.replaceAll(',  e', ' e');
      return result;
    }

    // Formata o horário dinâmico
    String formatarHorario() {
      if (menorHorarioInicio == null || maiorHorarioTermino == null) {
        return 'Horário não definido';
      }

      // Formata a hora com dois dígitos
      String formatarHora(int hora) => hora.toString().padLeft(2, '0');
      String formatarMinuto(int minuto) => minuto.toString().padLeft(2, '0');

      return '${formatarHora(menorHorarioInicio.hour)}:${formatarMinuto(menorHorarioInicio.minute)} '
          'às ${formatarHora(maiorHorarioTermino.hour)}:${formatarMinuto(maiorHorarioTermino.minute)}';
    }

    final periodoString = formatarDiasDaSemana(diasComAulas);
    final horarioString = formatarHorario();

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(15),
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.robotoRegular(),
          bold: await PdfGoogleFonts.robotoBold(),
        ),
        build: (pw.Context context) {
          return pw.Container(
            decoration: const pw.BoxDecoration(
              color: PdfColors.white,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      height: 250,
                      width: 250,
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          pw.SizedBox(height: 5),
                          pw.Text('SENAC CATALÃO',
                              style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 8),
                          pw.Text('CURSO: ${curso['nomecurso']}',
                              style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 6),
                          pw.Text('TURMA: ${turma.turmanome}',
                              style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 6),
                          pw.Text('PERÍODO: $periodoString',
                              style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 6),
                          pw.Text('HORÁRIO: $horarioString',
                              style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 15),
                        ],
                      ),
                    ),
                  ],
                ),

                // Calendar table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(130), // Largura aumentada
                    for (int i = 1;
                        i <=
                            DateTime(_focusedDay.year, _focusedDay.month + 1, 0)
                                .day;
                        i++)
                      i: pw.FixedColumnWidth(
                          DateTime(_focusedDay.year, _focusedDay.month, i)
                                      .weekday ==
                                  DateTime.sunday
                              ? 32 // Domingo um pouco maior
                              : 24), // Dias de semana com largura mínima de 24
                    DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day +
                        1: const pw.FixedColumnWidth(50),
                  },
                  defaultVerticalAlignment:
                      pw.TableCellVerticalAlignment.middle,
                  children: [
                    // Month and weekday row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            _getMonthName(_focusedDay.month),
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        for (int day = 1;
                            day <=
                                DateTime(_focusedDay.year,
                                        _focusedDay.month + 1, 0)
                                    .day;
                            day++)
                          _buildWeekdayHeader(day, _focusedDay),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Total / Instrutor',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),

                    // Day numbers row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Unidades Curriculares',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        for (int day = 1;
                            day <=
                                DateTime(_focusedDay.year,
                                        _focusedDay.month + 1, 0)
                                    .day;
                            day++)
                          _buildDayNumberCell(day, _focusedDay),
                        pw.Container(
                          decoration: const pw.BoxDecoration(
                            color: PdfColors.grey300,
                          ),
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.SizedBox(),
                        ),
                      ],
                    ),

                    // UC rows
                    for (var ucEntry in aulasPorUC.entries)
                      pw.TableRow(
                        children: [
                          // Célula do nome da UC (com altura dinâmica)
                          pw.Container(
                            width: 115,
                            height: _calculateRowHeight(ucEntry.key),
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.white,
                            ),
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Column(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  ucEntry.key,
                                  style: const pw.TextStyle(
                                    fontSize: 8, // Tamanho aumentado
                                    height: 1.2, // Espaçamento entre linhas
                                  ),
                                  textAlign: pw.TextAlign.left,
                                  maxLines: 10,
                                  //overflow: pw.TextOverflow.clip,
                                ),
                              ],
                            ),
                          ),

                          // Células dos dias (com mesma altura da UC)
                          for (int day = 1;
                              day <=
                                  DateTime(_focusedDay.year,
                                          _focusedDay.month + 1, 0)
                                      .day;
                              day++)
                            _buildDayCellWithDuration(ucEntry.value, day,
                                _focusedDay, _calculateRowHeight(ucEntry.key)),

                          // Célula do total/instrutor (com mesma altura)
                          pw.Container(
                            width: 50,
                            height: _calculateRowHeight(ucEntry.key),
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.white,
                            ),
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Column(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Text(
                                  '${horasPorUC[ucEntry.key]?.toStringAsFixed(1) ?? '0'}h',
                                  style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold),
                                ),
                                pw.Text(
                                  instrutorPrincipalPorUC[ucEntry.key] ?? '',
                                  style: const pw.TextStyle(fontSize: 8),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildWeekdayHeader(int day, DateTime focusedDay) {
    final date = DateTime(focusedDay.year, focusedDay.month, day);
    final weekday =
        DateFormat('E', 'pt_BR').format(date).substring(0, 3).toLowerCase();
    final isSunday = date.weekday == DateTime.sunday;
    final isHoliday = _isFeriado(date);

    return pw.Container(
      width: 24, // Largura fixa mínima para evitar quebra
      decoration: pw.BoxDecoration(
        color: isSunday
            ? PdfColors.red100
            : isHoliday
                ? PdfColors.green100
                : PdfColors.grey300,
      ),
      padding: const pw.EdgeInsets.all(4),
      child: pw.FittedBox(
        // Usar FittedBox para ajustar o texto ao espaço disponível
        fit: pw.BoxFit.scaleDown,
        child: pw.Text(
          weekday,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: isSunday ? PdfColors.red900 : PdfColors.black,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  // Função para calcular a altura necessária baseada no texto da UC
  double _calculateRowHeight(String ucName) {
    final textLength = ucName.length;
    if (textLength <= 30) return 24.0; // Altura mínima aumentada
    if (textLength <= 60) return 36.0;
    return 110.0; // Altura maior para textos longos
  }

  pw.Widget _buildDayNumberCell(int day, DateTime focusedDay) {
    final date = DateTime(focusedDay.year, focusedDay.month, day);
    final isSunday = date.weekday == DateTime.sunday;
    final isHoliday = _isFeriado(date);

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: isSunday
            ? PdfColors.red100
            : isHoliday
                ? PdfColors.green100
                : PdfColors.grey300,
      ),
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        day.toString(),
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: isSunday ? PdfColors.red900 : PdfColors.black,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // Função modificada para construir as células de duração
  pw.Widget _buildDayCellWithDuration(List<Map<String, dynamic>> aulas, int day,
      DateTime focusedDay, double rowHeight) {
    final date = DateTime(focusedDay.year, focusedDay.month, day);
    final isSunday = date.weekday == DateTime.sunday;
    final isHoliday = _isFeriado(date);

    final aula = aulas.firstWhere(
      (a) => (a['data'] as DateTime).day == day,
      orElse: () => {},
    );

    return pw.Container(
      width: isSunday ? 32 : 24,
      height: rowHeight, // Usa a mesma altura da linha
      decoration: pw.BoxDecoration(
        color: isSunday
            ? PdfColors.red50
            : isHoliday
                ? PdfColors.green50
                : aula.isEmpty
                    ? PdfColors.grey200
                    : PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Center(
        child: pw.Text(
          aula.isNotEmpty
              ? aula['duracao'].toStringAsFixed(1)
              : isHoliday
                  ? 'F'
                  : '',
          style: pw.TextStyle(
            fontSize: 10, // Tamanho aumentado
            fontWeight: pw.FontWeight.bold,
            color: isSunday ? PdfColors.red900 : PdfColors.black,
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro'
    ];
    return months[month - 1];
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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Instrutor: ${data['nomeinstrutor']}'),
                    Text('Horário: ${aulas.horario} - ${aulas.horas}h'),
                    Text('Status: ${aulas.status}'),
                    if (data['cargahorariauc'] != null &&
                        data['cargahorariaucagendada'] != null)
                      Text(
                        'Carga horária restante: ${data['cargahorariauc'] - data['cargahorariaucagendada']} horas',
                        style: TextStyle(
                          color: (data['cargahorariauc'] -
                                      data['cargahorariaucagendada']) <
                                  0
                              ? Colors.red
                              : null,
                        ),
                      ),
                  ],
                );
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
          .maybeSingle();

      final int cargaHorariaUc = response2?['cargahorariauc'] != null
          ? (response2!['cargahorariauc'] as num).toInt()
          : 0;

      // Carga horária total da UC
      final int cargaTotalUc =
          response['unidades_curriculares']?['cargahoraria'] ?? 0;

      // Verifica se 'instrutores' é lista ou mapa
      String nomeInstrutor = 'Não encontrado';
      final instrutores = response['turma']?['instrutores'];
      if (instrutores is List && instrutores.isNotEmpty) {
        nomeInstrutor = instrutores.first['nomeinstrutor'] ?? 'Não encontrado';
      } else if (instrutores is Map) {
        nomeInstrutor = instrutores['nomeinstrutor'] ?? 'Não encontrado';
      }

      return {
        'nomeuc':
            response['unidades_curriculares']?['nomeuc'] ?? 'Não encontrado',
        'turma': response['turma']?['turmanome'] ?? 'Não encontrada',
        'nomeinstrutor': nomeInstrutor,
        'cargahorariauc': cargaTotalUc,
        'horario': response['horario'] ?? '',
        'status': response['status'] ?? '',
        'horas': response['horas'] ?? 0,
        'cargahorariaucagendada': cargaHorariaUc,
      };
    } catch (e) {
      return {
        'nomeuc': 'Erro: $e',
        'turma': 'Erro: $e',
        'nomeinstrutor': 'Erro: $e',
        'horario': '',
        'status': '',
        'horas': 0,
        'cargahorariauc': 0,
        'cargahorariaucagendada': 0,
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
