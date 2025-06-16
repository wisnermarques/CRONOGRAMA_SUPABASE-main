import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AgendarAulasPage extends StatefulWidget {
  final Set<DateTime> selectedDays;
  final Map<String, Map<String, dynamic>> periodoConfig;

  const AgendarAulasPage({
    super.key,
    required this.selectedDays,
    required this.periodoConfig,
  });

  @override
  State<AgendarAulasPage> createState() => _AgendarAulasPageState();
}

class _AgendarAulasPageState extends State<AgendarAulasPage> {
  int? _selectedTurmaId;
  int? _selectedUcId;
  String _periodo = 'Matutino';
  int _horasAula = 1;
  TimeOfDay? _horaInicio;
  List<Map<String, dynamic>> _turmas = [];
  List<Map<String, dynamic>> _ucs = [];
  List<Map<String, dynamic>> _ucsFiltradas = [];
  final Map<int, int> _cargaHorariaUc = {};
  bool _isLoading = false;
  bool _hasExistingScheduling = false;
  int _currentCargaHoraria = 0;

  // Calcula o horário no formato "19:00-22:00"
  String? get _horarioFormatado {
    if (_horaInicio == null) return null;
    final horaFinal = _horaInicio!.replacing(
      hour: _horaInicio!.hour + _horasAula,
      minute: _horaInicio!.minute,
    );
    return '${_formatTimeOfDay(_horaInicio!)}-${_formatTimeOfDay(horaFinal)}';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  int get _cargaHorariaRestante {
    if (_selectedUcId == null) return 0;

    // Se já tem agendamento, retorna a carga atual menos o que está sendo agendado agora
    if (_hasExistingScheduling) {
      return _currentCargaHoraria - (_horasAula * widget.selectedDays.length);
    }

    // Caso contrário, retorna a carga total da UC menos o que está sendo agendado agora
    return (_cargaHorariaUc[_selectedUcId] ?? 0) -
        (_horasAula * widget.selectedDays.length);
  }

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // Buscar turmas
      final turmasResponse = await supabase.from('turma').select();
      if (turmasResponse.isEmpty) throw Exception('Nenhuma turma encontrada');

      // Buscar UCs
      final ucsResponse = await supabase.from('unidades_curriculares').select();
      if (ucsResponse.isEmpty) throw Exception('Nenhuma UC encontrada');

      // Mapear carga horária das UCs
      final cargaHorariaMap = <int, int>{};
      for (final uc in ucsResponse) {
        cargaHorariaMap[uc['iduc'] as int] = (uc['cargahoraria'] ?? 0) as int;
      }

      if (mounted) {
        setState(() {
          _turmas = turmasResponse;
          _ucs = ucsResponse;
          _ucsFiltradas = [];
          _cargaHorariaUc.addAll(cargaHorariaMap);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _getUcSchedulingInfo() async {
    if (_selectedUcId == null || _selectedTurmaId == null) {
      return {'hasScheduling': false, 'cargaHoraria': 0};
    }

    try {
      final response = await Supabase.instance.client
          .from('aulas_carga')
          .select('*')
          .eq('iduc', _selectedUcId!)
          .eq('idturma', _selectedTurmaId!)
          .single();

      final data = response;

      final cargaHoraria = data['cargahorariauc'] != null
          ? _cargaHorariaUc[_selectedUcId]! - (data['cargahorariauc'] as int)
          : _cargaHorariaUc[_selectedUcId];

      return {
        'hasScheduling': (data['cargahorariauc'] != null),
        'cargaHoraria': cargaHoraria,
      };
    } catch (e) {
      return {
        'hasScheduling': false,
        'cargaHoraria': _cargaHorariaUc[_selectedUcId] ?? 0,
      };
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaInicio ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _horaInicio) {
      setState(() {
        _horaInicio = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxHoras = widget.periodoConfig[_periodo]!['maxHoras'] as int;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar Aulas'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _podeSalvar() && !_isLoading ? _salvarAulas : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Card de Dias Selecionados
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dias Selecionados',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: widget.selectedDays.map((day) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Chip(
                                  label: Text(DateFormat('EEEE, dd/MM', 'pt_BR')
                                      .format(day)),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                  onDeleted: () {
                                    setState(() {
                                      widget.selectedDays.remove(day);
                                    });
                                  },
                                  backgroundColor: colorScheme.primaryContainer,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total de horas a agendar: ${_horasAula * widget.selectedDays.length}',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Card de Configuração das Aulas
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          'Configuração das Aulas',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Dropdown de Turma
                        DropdownButtonFormField<int>(
                          value: _selectedTurmaId,
                          decoration: InputDecoration(
                            labelText: 'Turma',
                            prefixIcon:
                                Icon(Icons.group, color: colorScheme.primary),
                            border: const OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: colorScheme.primary),
                            ),
                          ),
                          items: _turmas.map((turma) {
                            return DropdownMenuItem<int>(
                              value: turma['idturma'] as int,
                              child: Text(turma['turmanome'] as String),
                            );
                          }).toList(),
                          onChanged: (value) async {
                            if (value == null) return;

                            final response = await Supabase.instance.client
                                .from('turma')
                                .select()
                                .eq('idturma', value)
                                .limit(1)
                                .single();

                            if (mounted) {
                              setState(() {
                                _selectedTurmaId = value;
                                _selectedUcId = null;
                                _ucsFiltradas = _ucs
                                    .where((uc) =>
                                        uc['idcurso'] == response['idcurso'])
                                    .toList();
                                _hasExistingScheduling = false;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        // Dropdown de Unidade Curricular
                        if (_selectedTurmaId != null) ...[
                          DropdownButtonFormField<int>(
                            isExpanded: true,
                            value: _selectedUcId,
                            decoration: InputDecoration(
                              labelText: 'Unidade Curricular',
                              prefixIcon: Icon(Icons.school,
                                  color: colorScheme.primary),
                              border: const OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: colorScheme.primary),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                            ),
                            selectedItemBuilder: (_) {
                              return _ucsFiltradas.map((uc) {
                                return Text(
                                  uc['nomeuc'] as String,
                                  softWrap: true,
                                  maxLines: 2,
                                  overflow: TextOverflow.visible,
                                  style: const TextStyle(fontSize: 14),
                                );
                              }).toList();
                            },
                            items: _ucsFiltradas.map((uc) {
                              final cargaHoraria =
                                  _cargaHorariaUc[uc['iduc'] as int] ?? 0;
                              return DropdownMenuItem<int>(
                                value: uc['iduc'] as int,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      uc['nomeuc'] as String,
                                      softWrap: true,
                                      maxLines: 2,
                                      overflow: TextOverflow.visible,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$cargaHoraria horas',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) async {
                              if (value == null || !mounted) return;

                              setState(() {
                                _selectedUcId = value;
                                _hasExistingScheduling = false;
                                _currentCargaHoraria = 0;
                              });

                              final schedulingInfo =
                                  await _getUcSchedulingInfo();
                              if (mounted) {
                                setState(() {
                                  _hasExistingScheduling =
                                      schedulingInfo['hasScheduling'];
                                  _currentCargaHoraria =
                                      schedulingInfo['cargaHoraria'] as int;
                                });
                              }
                            },
                            validator: (value) => value == null
                                ? 'Selecione uma unidade curricular'
                                : null,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Dropdown de Período
                        if (_selectedUcId != null) ...[
                          DropdownButtonFormField<String>(
                            value: _periodo,
                            decoration: InputDecoration(
                              labelText: 'Período',
                              prefixIcon: Icon(Icons.schedule,
                                  color: colorScheme.primary),
                              border: const OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: colorScheme.primary),
                              ),
                            ),
                            items: widget.periodoConfig.keys.map((periodo) {
                              return DropdownMenuItem<String>(
                                value: periodo,
                                child: Row(
                                  children: [
                                    Icon(widget.periodoConfig[periodo]!['icon']
                                        as IconData),
                                    const SizedBox(width: 12),
                                    Text(periodo),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (String? novoPeriodo) {
                              if (novoPeriodo == null || !mounted) return;

                              final config = widget.periodoConfig[novoPeriodo];
                              if (config == null) return;

                              final maxHoras = config['maxHoras'] is int
                                  ? config['maxHoras'] as int
                                  : 1;

                              setState(() {
                                _periodo = novoPeriodo;
                                if (_horasAula > maxHoras) {
                                  _horasAula = maxHoras;
                                }
                                _horaInicio =
                                    null; // Reseta a hora ao mudar período
                              });
                            },
                          ),
                          const SizedBox(height: 20),

                          // Seletor de horas
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Horas por aula: $_horasAula',
                                style: theme.textTheme.bodyLarge,
                              ),
                              Slider(
                                value: _horasAula.toDouble(),
                                min: 1,
                                max: maxHoras.toDouble(),
                                divisions: maxHoras > 1 ? maxHoras - 1 : 1,
                                label:
                                    '$_horasAula hora${_horasAula > 1 ? 's' : ''}',
                                onChanged: (value) {
                                  if (mounted) {
                                    setState(() {
                                      _horasAula = value.toInt();
                                      _horaInicio =
                                          null; // Reseta a hora ao mudar carga horária
                                    });
                                  }
                                },
                                activeColor: colorScheme.primary,
                                inactiveColor:
                                    colorScheme.primary.withOpacity(0.3),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Seletor de hora de início (só aparece após definir carga horária)
                          if (_horasAula > 0) ...[
                            InkWell(
                              onTap: () => _selectTime(context),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Hora de Início',
                                  prefixIcon: Icon(Icons.access_time,
                                      color: colorScheme.primary),
                                  border: const OutlineInputBorder(),
                                  errorText:
                                      _podeSalvar() && _horaInicio == null
                                          ? 'Selecione a hora de início'
                                          : null,
                                ),
                                child: Text(
                                  _horaInicio != null
                                      ? _formatTimeOfDay(_horaInicio!)
                                      : 'Selecione a hora',
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Exibição do horário formatado
                            if (_horaInicio != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Horário agendado: $_horarioFormatado',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ],
                        ],
                      ],
                    ),
                  ),
                ),

                // Resumo e Botão de Salvar
                if (_selectedUcId != null) ...[
                  const SizedBox(height: 24),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.9,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading:
                                  Icon(Icons.info, color: colorScheme.primary),
                              title: Text(
                                'Resumo do Agendamento',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            const Divider(),
                            _buildInfoRow('Período:', _periodo, theme),
                            if (_horaInicio != null)
                              _buildInfoRow(
                                  'Horário:', _horarioFormatado!, theme),
                            _buildInfoRow(
                                'Horas por aula:', '$_horasAula', theme),
                            _buildInfoRow('Total de aulas:',
                                '${widget.selectedDays.length}', theme),
                            _buildInfoRow(
                                'Total de horas:',
                                '${_horasAula * widget.selectedDays.length}',
                                theme,
                                isBold: true),
                            _buildInfoRow(
                              _hasExistingScheduling
                                  ? 'Carga horária restante:'
                                  : 'Carga horária total:',
                              '${_cargaHorariaRestante >= 0 ? _cargaHorariaRestante : 0} horas',
                              theme,
                              isAlert: _cargaHorariaRestante < 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _podeSalvar() && !_isLoading ? _salvarAulas : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.save, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'Salvar Agendamento',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme,
      {bool isBold = false, bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isAlert ? Colors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _podeSalvar() {
    return _selectedTurmaId != null &&
        _selectedUcId != null &&
        widget.selectedDays.isNotEmpty &&
        _horaInicio != null;
  }

  Future<void> _salvarAulas() async {
    if (!_podeSalvar()) return;

    setState(() => _isLoading = true);

    try {
      final cargaTotalNecessaria = _horasAula * widget.selectedDays.length;
      final cargaAtual = _cargaHorariaUc[_selectedUcId] ?? 0;

      if (!_hasExistingScheduling && cargaAtual < cargaTotalNecessaria) {
        throw Exception('Carga horária insuficiente para esta UC');
      }

      // Inserção de aulas com o horário no formato "19:00-22:00"
      final List<Map<String, dynamic>> aulasParaInserir =
          widget.selectedDays.map((dia) {
        return {
          'iduc': _selectedUcId,
          'idturma': _selectedTurmaId,
          'data': DateFormat('yyyy-MM-dd').format(dia),
          'horario': _horarioFormatado,
          'status': 'Agendada',
          'horas': _horasAula
        };
      }).toList();

      await Supabase.instance.client.from('aulas').insert(aulasParaInserir);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao agendar aulas: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }
}
