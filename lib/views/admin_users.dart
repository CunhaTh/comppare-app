import 'package:application_progress/infra/api_services.dart';
import 'package:flutter/material.dart';
import 'admin_user_edit.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = false;
  String? _error;
  List<dynamic> _allUsers = [];
  String _searchQuery = '';
  // Track rows currently updating (by id string)
  final Set<String> _loadingRows = {};
  // Controller for vertical scrolling of the data table
  final ScrollController _tableScrollController = ScrollController();

  // Pagination
  int _page = 0;
  int _pageSize = 25;

  // Helpers to normalize status values
  int _statusToInt(dynamic raw) {
    if (raw == null) return 1; // default Inativo
    if (raw is int) return raw;
    final s = raw.toString().toLowerCase();
    if (s == '0' || s == 'ativo' || s == 'true') return 0;
    if (s == '1' || s == 'inativo' || s == 'false') return 1;
    final parsed = int.tryParse(s);
    if (parsed != null) return parsed;
    return 1;
  }

  String _statusLabel(int status) => status == 0 ? 'Ativo' : 'Inativo';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tableScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _api.getAdminUsers();
      debugPrint('[AdminUsersPage] _fetch: received ${data is List ? data.length : 'non-list'} items');
      setState(() {
        _allUsers = data;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  List<dynamic> get _filteredUsers {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _allUsers;

    return _allUsers.where((u) {
      final nome = '${u['primeiroNome'] ?? ''} ${u['sobrenome'] ?? ''}'.toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final plano = (u['plano'] ?? '').toString().toLowerCase();
      return nome.contains(query) || email.contains(query) || plano.contains(query);
    }).toList();
  }

  List<dynamic> get _pageItems {
    final users = _filteredUsers;
    final start = _page * _pageSize;
    if (start >= users.length) return [];
    final end = (_page + 1) * _pageSize;
    return users.sublist(start, end.clamp(0, users.length));
  }

  Future<void> _deleteUser(dynamic id) async {
    setState(() => _loading = true);
    try {
      await _api.deleteAdminUser(int.parse(id.toString()));
      // remove locally
      setState(() {
        _allUsers.removeWhere((u) => (u['id'] ?? u['usuario']).toString() == id.toString());
        // adjust page if needed
        final maxPage = (_allUsers.length - 1) ~/ _pageSize;
        if (_page > maxPage) _page = maxPage.clamp(0, maxPage);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário excluído')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao excluir: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openEditDialog(dynamic user) async {
    // open full-page editor for better UX
    final res = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(builder: (_) => AdminUserEditPage(user: user)),
    );

    if (res == true) {
      // reload list after successful save
      await _fetch();
    }
  }

  Future<void> _updateUser(dynamic id, Map<String, dynamic> updates) async {
    setState(() => _loading = true);
    try {
      await _api.updateAdminUser(int.parse(id.toString()), updates);
      // reflect local change
      setState(() {
        final idx = _allUsers.indexWhere((u) => (u['id'] ?? u['usuario']).toString() == id.toString());
        if (idx >= 0) {
          _allUsers[idx] = {..._allUsers[idx], ...updates};
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário atualizado')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao atualizar: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleStatus(dynamic user) async {
    final id = user['id'] ?? user['usuario'];
    final idStr = id.toString();

    // Optimistic UI: flip local status immediately for responsiveness
    setState(() {
      _loadingRows.add(idStr);
      final idx = _allUsers.indexWhere((u) => (u['id'] ?? u['usuario']).toString() == idStr);
      if (idx >= 0) {
        final current = _allUsers[idx];
        final raw = current['status'] ?? current['ativo'];
        final curInt = _statusToInt(raw);
        // toggle
        current['status'] = curInt == 0 ? 1 : 0;
        _allUsers[idx] = current;
      }
    });

    try {
      final resp = await _api.updateUserStatus(int.parse(idStr));
      debugPrint('[AdminUsersPage] _toggleStatus: response: $resp');

      // After response, try fetching until the server reflects the change
      // expectedStatus is the status we toggled optimistically above
      final expectedStatusRaw = (user['status'] ?? '');
      final expectedInt = _statusToInt(expectedStatusRaw);
      final msgToUser = expectedInt == 0 ? 'Usuário ativado com sucesso.' : 'Usuário desativado com sucesso.';
      bool matched = false;
      const attempts = 3;
      final delays = [Duration(milliseconds: 300), Duration(milliseconds: 700), Duration(milliseconds: 1200)];
      for (var i = 0; i < attempts; i++) {
        await _fetch();
        // find the user in the fresh list
        final fresh = _allUsers.firstWhere(
          (u) => (u['id'] ?? u['usuario']).toString() == idStr,
          orElse: () => null,
        );
        if (fresh != null) {
          final freshStatus = _statusToInt(fresh['status'] ?? fresh['ativo']);
          if (freshStatus == expectedInt) {
            matched = true;
            break;
          }
        }
        // wait before next attempt (if any)
        await Future.delayed(delays[i]);
      }

      if (!matched) {
        // final fetch to ensure UI shows latest server state
        await _fetch();
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msgToUser)));
    } catch (e) {
      // On error, reload to restore previous state
      await _fetch();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha ao atualizar status: $e')));
    } finally {
      setState(() {
        _loadingRows.remove(idStr);
      });
    }
  }

  Widget _buildTable(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;

    if (isSmall) {
      // Mobile-friendly list
      return ListView.builder(
        itemCount: _pageItems.length,
        itemBuilder: (context, index) {
          final u = _pageItems[index];
          final id = u['id'] ?? u['usuario'];
          final nome = u['nome'] ?? u['nome_completo'] ?? '';
          final email = u['email'] ?? '';
          final statusRaw = u['status'] ?? u['ativo'];
          final status = _statusToInt(statusRaw);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nome.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(email.toString()),
                  const SizedBox(height: 6),
                  Text('Status: ${_statusLabel(status)}'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _openEditDialog(u),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Editar'),
                      ),
                      const SizedBox(width: 8),
                        _loadingRows.contains(id.toString())
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: status == 0 ? Colors.green : Colors.grey,
                                ),
                                onPressed: () => _toggleStatus(u),
                                child: Text(_statusLabel(status)),
                              ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      );
    }

    // Desktop/tablet: DataTable with vertical scrollbar
    return Scrollbar(
      controller: _tableScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _tableScrollController,
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
        columns: const [
          DataColumn(label: Text('Nome')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('CPF')),
          DataColumn(label: Text('Plano')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Ações')),
        ],
        rows: _pageItems.map((u) {
          final nome = u['primeiroNome'] + ' ' + (u['sobrenome'] ?? '');
          final email = u['email'] ?? '';
          final cpf = u['cpf'] ?? '';
          final plano = u['plano'] ??  '';
          final statusRaw = u['status'] ?? u['ativo'];
          final status = _statusToInt(statusRaw);

          return DataRow(cells: [
            DataCell(Text(nome.toString())),
            DataCell(Text(email.toString())),
            DataCell(Text(cpf.toString())),
            DataCell(Text(plano.toString())),
            DataCell(Text(_statusLabel(status))),
            DataCell(Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _openEditDialog(u),
                ),
                              _loadingRows.contains((u['id'] ?? u['usuario']).toString())
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(
                        icon: Icon(
                          status == 0 ? Icons.check_circle : Icons.cancel,
                          color: status == 0 ? Colors.green : Colors.grey,
                          size: 18,
                        ),
                        onPressed: () => _toggleStatus(u),
                      ),
              ],
            )),
          ]);
        }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_filteredUsers.length / _pageSize).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuários (Admin)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetch,
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _page = 0;
                });
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: 'Pesquisar usuários',
                hintText: 'Pesquisar...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _page = 0;
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('Erro: $_error'))
                      : _buildTable(context),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _page > 0 ? () => setState(() => _page--) : null,
                  child: const Text('Anterior'),
                ),
                const SizedBox(width: 12),
                Text('Página ${_page + 1} de ${totalPages == 0 ? 1 : totalPages}'),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: (_page + 1) < totalPages ? () => setState(() => _page++) : null,
                  child: const Text('Próxima'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
