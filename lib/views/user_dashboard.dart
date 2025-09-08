// lib/user_dashboard_screen.dart
import 'package:application_progress/infra/api_exception.dart';
import 'package:application_progress/infra/token_helper.dart';
import 'package:application_progress/infra/user_helper.dart';
import 'package:application_progress/login.dart';
import 'package:application_progress/models/folder_model.dart';
import 'package:application_progress/models/user_stats_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as foundation;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../controllers/plans/plans_controller.dart';
import '../infra/api_services.dart';
import '../helpers/helpers.dart';

class UserDashboardScreen extends StatefulWidget {
  final List<Folder> folders;

  const UserDashboardScreen({super.key, required this.folders});

  @override
  _UserDashboardScreenState createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  late User user;

  late PlansController plansController;

  final ApiService _apiService = ApiService(); 

  int? _selectedFolderId;
  List<Folder> _folders = [];
  bool _isLoading = true;
  int? _folderCount;
  int? _subfolderCount;
  int? _photoCount;
  double? _spaceUsedMb;

  @override
  void initState() {
    super.initState();
    user = UserHelper().user ?? User.empty();
    plansController = PlansController(apiService: ApiService());
    plansController.getPlanById(user.idPlano ?? 0);
    _updateStats();
  }

    @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoading) {
      _fetchFoldersFromApiAndRefreshState();
    }
  }

  // FUNÇÃO DE CÁLCULO LOCAL DE ESTATÍSTICAS
  void _updateStats() {
    // Usa a lista de pastas recebida pelo widget
    final folders = widget.folders;

    if (folders.isEmpty) {
      setState(() {
        _folderCount = 0;
        _subfolderCount = 0;
        _photoCount = 0;
        _spaceUsedMb = 0.0;
      });
      return;
    }

    int subfolderCount = 0;
    int photoCount = 0;

    // Itera sobre a lista que já contém a estrutura aninhada
    for (final folder in folders) {
      final subs = folder.subpastas ?? [];
      subfolderCount += subs.length;
      for (final subfolder in subs) {
        photoCount += subfolder.imagens?.length ?? 0;
      }
    }

    // Atualiza o estado com os valores finais calculados
    setState(() {
      _folderCount = folders.length;
      _subfolderCount = subfolderCount;
      _photoCount = photoCount;
      // Estimativa: cada foto ocupa em média 2.5 MB.
      _spaceUsedMb = photoCount * 2.5;
    });
  }


  
  void _navigateToLogin() {
    if (!mounted) return;
    TokenHelper().clear();
    UserHelper().removeUser();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _fetchFoldersFromApiAndRefreshState() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final user = UserHelper().user;
      if (user == null || user.id == null) {
        _navigateToLogin();
        return;
      }

      // Este método deve vir do UserHelper, que foi populado no login
      final List<Folder> updatedFolders =
          await _apiService.getAllFoldersForUser();
      if (mounted) {
        setState(() {
          _folders = updatedFolders;
          if (_folders.isNotEmpty && _selectedFolderId == null) {
            _selectedFolderId = _folders.first.id;
          }
        });
        // Após buscar os álbuns, calcula as estatísticas
        _updateStats();
      }
    } catch (e) {
      //... seu tratamento de erro
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final foldersCount = widget.folders.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Dashboard do Usuário',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
                  _buildHeaderSection(user), // <-- Passando o objeto User completo
                const SizedBox(height: 24),
                // Plan Section
                _buildPlanSection(),
                const SizedBox(height: 24),

                // Stats Section
                _buildStatsSection(),
                const SizedBox(height: 24),

                // Quick Actions Section
                _buildQuickActionsSection(),
                const SizedBox(height: 32),

                // Back Button
                _buildBackButton(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Header Section - para receber o objeto User
  Widget _buildHeaderSection(User user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFaed513).withOpacity(0.1),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFaed513).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // User Avatar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFaed513),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFaed513).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              color: Colors.black,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nome ?? 'Usuário',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // MOSTRANDO O EMAIL E CPF
                _buildUserInfoRow(Icons.email_outlined, user.email ?? 'Email não cadastrado'),
                const SizedBox(height: 4),
                _buildUserInfoRow(Icons.badge_outlined, user.cpf ?? 'CPF não cadastrado'),
              ],
            ),
          ),
        ],
      ),
    );
  }

    // NOVO WIDGET AUXILIAR para exibir informações do usuário
  Widget _buildUserInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 16),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // WIDGET DE ESTATÍSTICAS (sem alterações, apenas usará os novos valores)
  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estatísticas',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildStatItem(
                icon: Icons.folder,
                title: 'Álbuns Criados',
                value: _folderCount?.toString() ?? '...',
                color: const Color(0xFFaed513),
              ),
              const SizedBox(height: 16),
              _buildStatItem(
                icon: Icons.folder_copy,
                title: 'Subálbuns Totais',
                value: _subfolderCount?.toString() ?? '...',
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              _buildStatItem(
                icon: Icons.photo_library,
                title: 'Total de Fotos',
                value: _photoCount?.toString() ?? '...',
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 16),
              // Escondendo por enquanto
             /* _buildStatItem(
                icon: Icons.storage,
                title: 'Espaço Utilizado (Est.)',
                value: _spaceUsedMb != null
                    ? '${_spaceUsedMb!.toStringAsFixed(1)} MB'
                    : '...',
                color: Colors.orange,
              ),*/
            ],
          ),
        ),
      ],
    );
  }


  // Plan Section
  Widget _buildPlanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seu Plano',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        BlocBuilder<PlansController, PlansState>(
          buildWhen: (previous, current) => previous.status != current.status,
          bloc: plansController,
          builder: (context, state) {
            final plan = state.plan;

            if (state.status == AppStateStatus.loading) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFaed513),
                  ),
                ),
              );
            }

            if (plan.id == 0) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Nenhum plano ativo',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFaed513).withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFaed513).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.card_membership,
                          color: Color(0xFFaed513),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.nome,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'R\$ ${plan.valor.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    plan.descricao,
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildPlanFeature(
                        icon: Icons.folder,
                        value: '${plan.quantidadePastas} álbum',
                      ),
                      const SizedBox(width: 16),
                      _buildPlanFeature(
                        icon: Icons.photo_library,
                        value: '${plan.quantidadeFotos} fotos',
                      ),
                      const SizedBox(width: 16),
                      _buildPlanFeature(
                        icon: Icons.tag,
                        value: '${plan.quantidadeTags} categorias',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (user.idPlano != null && user.idPlano != 1)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showCancelPlanDialog(plan.nome),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[50],
                          foregroundColor: Colors.red[700],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: Colors.red[300]!,
                              width: 1,
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Cancelar Assinatura',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // Plan Feature Helper
  Widget _buildPlanFeature({
    required IconData icon,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: const Color(0xFFaed513),
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Cancel Plan Dialog
  void _showCancelPlanDialog(String planName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Cancelar Assinatura',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Deseja mesmo cancelar a sua assinatura?',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.card_membership,
                      color: Color(0xFFaed513),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      planName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Voltar',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        plansController.cancelPlan(
                          userId: user.id ?? 0,
                          context: context,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red[700],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: Colors.red[300]!,
                            width: 1,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirmar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // Stat Item Helper
  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Quick Actions Section
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ações Rápidas',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.add_photo_alternate,
                title: 'Criar Álbum',
                subtitle: 'Novo álbum',
                onTap: () {
                  // Pode ser expandido para criar álbum diretamente
                  Navigator.of(context).pop();
                },
              ),
            ),
            // const SizedBox(width: 12),
            // Expanded(
            //   child: _buildActionCard(
            //     icon: Icons.upload,
            //     title: 'Upload',
            //     subtitle: 'Adicionar fotos',
            //     onTap: () {
            //       // Pode ser expandido para upload
            //       Navigator.of(context).pop();
            //     },
            //   ),
            // ),
          ],
        ),
      ],
    );
  }

  // Action Card Helper
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFaed513).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFFaed513),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Back Button
  Widget _buildBackButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFaed513),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: const Color(0xFFaed513).withValues(alpha: 0.3),
        ),
        child: const Text(
          'Voltar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
