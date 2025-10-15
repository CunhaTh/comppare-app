import 'dart:math' as math;

import 'package:application_progress/infra/api_services.dart';
import 'package:flutter/material.dart';

class AdminUserEditPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminUserEditPage({super.key, required this.user});

  @override
  State<AdminUserEditPage> createState() => _AdminUserEditPageState();
}

class _AdminUserEditPageState extends State<AdminUserEditPage> {
  final ApiService _api = ApiService();

  late TextEditingController _cpfController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _nicknameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _birthController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  List<dynamic> _plans = [];
  String? _selectedPlanName;
  int? _selectedPlanId;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _cpfController = TextEditingController(text: (widget.user['cpf'] ?? '').toString());
    _firstNameController = TextEditingController(text: (widget.user['primeiroNome'] ?? '').toString());
    _lastNameController = TextEditingController(text: (widget.user['sobrenome'] ?? '').toString());
    _nicknameController = TextEditingController(text: (widget.user['apelido'] ?? '').toString());
    _emailController = TextEditingController(text: (widget.user['email'] ?? '').toString());
    _phoneController = TextEditingController(text: (widget.user['telefone'] ?? widget.user['telefoneCelular'] ?? '').toString());
    // normalize various backend field names and format for display as dd/mm/yyyy
    final rawBirth = (widget.user['dataNascimento'] ?? widget.user['nascimento'] ?? widget.user['dob'] ?? '').toString();
    _birthController = TextEditingController(text: _formatBirthForDisplay(rawBirth));
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    // format initial values
    _cpfController.text = _formatCpf(_cpfController.text);
    _phoneController.text = _formatPhone(_phoneController.text);

    _loadPlans();
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _onlyDigits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String _formatBirthForDisplay(String raw) {
    if (raw.trim().isEmpty) return '';

    // Try ISO parse first
    try {
      final dt = DateTime.tryParse(raw);
      if (dt != null) {
        return '${_twoDigits(dt.day)}/${_twoDigits(dt.month)}/${dt.year}';
      }
    } catch (_) {}

    // If there's a whitespace/time part, take the first token
    final first = raw.split(' ').first;
    // Common ISO-like patterns yyyy-mm-dd or yyyy/mm/dd
    final isoMatch = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})').firstMatch(first);
    if (isoMatch != null) {
      final y = int.tryParse(isoMatch.group(1) ?? '') ?? 0;
      final m = int.tryParse(isoMatch.group(2) ?? '') ?? 0;
      final d = int.tryParse(isoMatch.group(3) ?? '') ?? 0;
      if (y > 0 && m > 0 && d > 0) return '${_twoDigits(d)}/${_twoDigits(m)}/$y';
    }

    // If it's already in dd/mm/yyyy, normalize it
    final dmY = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(first);
    if (dmY != null) {
      final d = int.tryParse(dmY.group(1) ?? '') ?? 0;
      final m = int.tryParse(dmY.group(2) ?? '') ?? 0;
      final y = int.tryParse(dmY.group(3) ?? '') ?? 0;
      if (y > 0 && m > 0 && d > 0) return '${_twoDigits(d)}/${_twoDigits(m)}/$y';
    }

    // Fallback: try to extract 8+ digit sequence like YYYYMMDD or DDMMYYYY
    final digits = RegExp(r'\d+').allMatches(raw).map((m) => m.group(0)).join();
    if (digits.length >= 8) {
      // prefer YYYYMMDD
      if (digits.length >= 8) {
        final maybeY = digits.length >= 8 ? digits.substring(0, 4) : '';
        final maybeM = digits.length >= 6 ? digits.substring(4, 6) : '';
        final maybeD = digits.length >= 8 ? digits.substring(6, 8) : '';
        final y = int.tryParse(maybeY ?? '') ?? 0;
        final m = int.tryParse(maybeM ?? '') ?? 0;
        final d = int.tryParse(maybeD ?? '') ?? 0;
        if (y > 0 && m > 0 && d > 0) return '${_twoDigits(d)}/${_twoDigits(m)}/$y';
      }
    }

    // Give up: return the raw trimmed string
    return raw.trim();
  }

  String _formatCpf(String raw) {
    final d = _onlyDigits(raw);
    if (d.isEmpty) return '';
    if (d.length <= 3) return d;
    if (d.length <= 6) return '${d.substring(0, 3)}.${d.substring(3)}';
    if (d.length <= 9) return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6)}';
    // length >= 10
    final end = math.min(d.length, 11);
    return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9, end)}';
  }

  String _formatPhone(String raw) {
    final digits = _onlyDigits(raw);
    return _formatPhoneFromDigits(digits);
  }

  String _formatPhoneFromDigits(String d) {
    if (d.isEmpty) return '';

    // area code (2 digits)
    if (d.length <= 2) return '(${d}';

    final area = d.substring(0, 2);
    final rest = d.substring(2);

    if (rest.length <= 4) return '($area) $rest';

    if (rest.length <= 7) {
      final left = rest.substring(0, rest.length - 4);
      final right = rest.substring(rest.length - 4);
      return '($area) $left-$right';
    }

    final left = rest.substring(0, rest.length - 4);
    final right = rest.substring(rest.length - 4);
    return '($area) $left-$right';
  }

  int _cursorIndexForDigits(String formatted, int digitsBefore) {
    if (digitsBefore <= 0) return 0;
    int seen = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (RegExp(r'\d').hasMatch(formatted[i])) {
        seen++;
        if (seen == digitsBefore) return i + 1; // place after this digit
      }
    }
    return formatted.length;
  }

  Future<void> _loadPlans() async {
    setState(() => _loading = true);
    try {
      final plans = await _api.getPlans();
      setState(() {
        _plans = plans;
        final userPlan = widget.user['idPlano'] ?? widget.user['id_plan'] ?? widget.user['plano'] ?? widget.user['nomePlano'];
        if (userPlan != null) {
          final byId = _plans.firstWhere((p) => (p['id'] ?? p['idPlano']).toString() == userPlan.toString(), orElse: () => null);
          if (byId != null) {
            _selectedPlanId = (byId['id'] ?? byId['idPlano']);
            _selectedPlanName = (byId['nome'] ?? byId['nomePlano'])?.toString();
          } else {
            final byName = _plans.firstWhere((p) => (p['nome'] ?? p['nomePlano']).toString() == userPlan.toString(), orElse: () => null);
            if (byName != null) {
              _selectedPlanId = (byName['id'] ?? byName['idPlano']);
              _selectedPlanName = (byName['nome'] ?? byName['nomePlano'])?.toString();
            }
          }
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao carregar planos: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);

    final pass = _passwordController.text;
    final passConfirm = _confirmPasswordController.text;
    if (pass.isNotEmpty && pass != passConfirm) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senha e confirmação não coincidem')));
      setState(() => _loading = false);
      return;
    }

    try {
      final id = widget.user['id'] ?? widget.user['usuario'];
      final body = {
        'idUsuario': id,
        'primeiroNome': _firstNameController.text,
        'sobrenome': _lastNameController.text,
        'apelido': _nicknameController.text,
        'cpf': _onlyDigits(_cpfController.text),
        'email': _emailController.text,
        'telefone': _onlyDigits(_phoneController.text),
        'nascimento': _birthController.text,
        if (pass.isNotEmpty) 'senha': pass,
        if (_selectedPlanId != null) 'idPlano': _selectedPlanId,
      };

      debugPrint('[AdminUserEditPage] request body: $body');
      final resp = await _api.updateUserData(body);
      debugPrint('[AdminUserEditPage] response: $resp');

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário atualizado')));
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao salvar: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Usuário')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _cpfController,
                      decoration: const InputDecoration(labelText: 'CPF'),
                      enabled: false,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(labelText: 'Primeiro nome'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(labelText: 'Sobrenome'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(labelText: 'Apelido'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                        controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Telefone'),
                      keyboardType: TextInputType.phone,
                      maxLength: 14,
                      onChanged: (v) {
                        // preserve logical cursor position based on number of digits before cursor
                        final rawText = v;
                        int pos = _phoneController.selection.baseOffset;
                        if (pos < 0) pos = rawText.length;
                        if (pos > rawText.length) pos = rawText.length;
                        final digitsBefore = _onlyDigits(rawText.substring(0, pos)).length;
                        final formatted = _formatPhoneFromDigits(_onlyDigits(rawText));
                        final newPos = _cursorIndexForDigits(formatted, digitsBefore);
                        _phoneController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: newPos),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _birthController,
                      decoration: const InputDecoration(labelText: 'Data de nascimento (dd/mm/aaaa)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Senha'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPasswordController,
                      decoration: const InputDecoration(labelText: 'Confirmar senha'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    const Text('Plano'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedPlanName,
                      items: _plans.map<DropdownMenuItem<String>>((p) {
                        final name = (p['nome'] ?? p['nomePlano'] ?? p['descricao'] ?? '').toString();
                        return DropdownMenuItem<String>(value: name, child: Text(name));
                      }).toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedPlanName = v;
                          final found = _plans.firstWhere((p) => (p['nome'] ?? p['nomePlano'] ?? '').toString() == v, orElse: () => null);
                          if (found != null) _selectedPlanId = (found['id'] ?? found['idPlano']);
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                        const SizedBox(width: 8),
                        ElevatedButton(onPressed: _save, child: const Text('Salvar')),
                      ],
                    )
                  ],
                ),
              ),
      ),
    );
  }
}
