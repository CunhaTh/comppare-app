import 'package:application_progress/infra/token_helper.dart';
import 'package:application_progress/infra/user_helper.dart';
import 'package:application_progress/principal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// --- Widget Principal da Aplicação ---
void main() {
  runApp(const GerenciamentoApp());
}

class GerenciamentoApp extends StatefulWidget {
  const GerenciamentoApp({super.key});

  @override
  State<GerenciamentoApp> createState() => _GerenciamentoAppState();
}

class _GerenciamentoAppState extends State<GerenciamentoApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerenciamento',
      // Define o tema escuro como na imagem de referência
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black, // Fundo preto puro para iOS Dark Mode
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const TelaGerenciamento(),
      debugShowCheckedModeBanner: false
    );
    
  }
}

// --- Tela de Gerenciamento ---
class TelaGerenciamento extends StatelessWidget {
  const TelaGerenciamento({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = screenWidth > 520 && screenHeight > 889;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: GestureDetector(
          onTap: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const PrincipalPage()),
              (Route<dynamic> route) => false,
            );
          },
          child: Center(
            child: Image.asset(
              "assets/logo_all_green.png",
              width: isLargeScreen ? screenWidth * 0.2 : screenWidth * 0.3,
              height: isLargeScreen ? screenHeight * 0.05 : screenHeight * 0.07,
              fit: BoxFit.contain,
            ),
          ),
        ),
        actions: [ ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // Campo de Busca
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 30, 30, 30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar',
                    hintStyle: TextStyle(color: Color.fromARGB(255, 150, 150, 150)),
                    border: InputBorder.none,
                    prefixIcon: Icon(CupertinoIcons.search, color: Color.fromARGB(255, 150, 150, 150)),
                  ),
                ),
              ),
            ),
            
            // Simulação da seção superior (Perfil)
            _buildSettingsSection(
              context,
              children: [
                _buildProfileTile(
                  context,
                  title: 'Thiago Gomes',
                  subtitle: 'Desenvolvedor',
                  onTap: () {
                    // Ação ao tocar no perfil
                  },
                ),
                _buildSuggestionTile(
                  context,
                  title: 'Sugestões',
                  count: 3,
                  onTap: () {
                    // Ação ao tocar nas sugestões
                  },
                ),
              ],
            ),

            // Item de Atualização Disponível
            const Padding(
              padding: EdgeInsets.only(top: 20.0),
              child: _CustomSettingTile(
                title: 'Atualização Disponível',
                showDisclosure: true,
                badgeCount: 1,
                onTap: null, // Pode ser uma função de navegação
                backgroundColor: Color.fromARGB(255, 30, 30, 30),
              ),
            ),

            // --- Seção de Gerenciamento Personalizada ---
            const SizedBox(height: 20),
            _buildSettingsSection(
              context,
              children: [
                _CustomSettingTile(
                  title: 'Gerenciar Planos',
                  icon: CupertinoIcons.tag_fill,
                  iconColor: Colors.blue,
                  onTap: () {
                    debugPrint('Navegar para Gerenciar Planos');
                  },
                  subtitle: 'Premium, Básico, etc.',
                ),
                _CustomSettingTile(
                  title: 'Cupons e Descontos',
                  icon: CupertinoIcons.percent,
                  iconColor: Colors.red,
                  onTap: () {
                    debugPrint('Navegar para Cupons e Descontos');
                  },
                  subtitle: 'Criar, Ativar, Desativar',
                ),
                _CustomSettingTile(
                  title: 'Usuários e Permissões',
                  icon: CupertinoIcons.group_solid,
                  iconColor: Colors.green,
                  onTap: () {
                    debugPrint('Navegar para Usuários');
                  },
                  subtitle: 'Administradores, Colaboradores',
                  isLast: true,
                ),
              ],
            ),
            // --- Fim da Seção de Gerenciamento Personalizada ---

            const SizedBox(height: 20),
            // Seção Inferior (Geral, Acessibilidade, etc.)
            _buildSettingsSection(
              context,
              children: [
                _CustomSettingTile(
                  title: 'Geral',
                  icon: CupertinoIcons.gear_alt_fill,
                  iconColor: Colors.grey,
                  onTap: () {},
                ),
                _CustomSettingTile(
                  title: 'Acessibilidade',
                  icon: CupertinoIcons.person_alt_circle_fill,
                  iconColor: Colors.blue,
                  onTap: () {},
                  isLast: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Constrói uma seção de ajustes em estilo iOS com um Container de fundo
  Widget _buildSettingsSection(BuildContext context, {required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 30, 30, 30), // Fundo escuro dos blocos
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          children: children.map((widget) {
            // Adiciona um divisor a menos que seja o último item
            final isLast = children.indexOf(widget) == children.length - 1;
            return Column(
              children: [
                widget,
                if (!isLast && widget is! _ProfileTile) // Não coloca divisor após o Perfil
                  const Divider(
                    height: 0,
                    indent: 15,
                    color: Color.fromARGB(255, 50, 50, 50), // Cor do divisor mais clara
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // Tile específico para a área de Perfil/Conta
  Widget _buildProfileTile(BuildContext context, {required String title, required String subtitle, required VoidCallback onTap}) {
    return _ProfileTile(
      title: title,
      subtitle: subtitle,
      onTap: onTap,
    );
  }

  // Tile específico para a área de Sugestões com badge
  Widget _buildSuggestionTile(BuildContext context, {required String title, required int count, required VoidCallback onTap}) {
    return _CustomSettingTile(
      title: title,
      badgeCount: count,
      onTap: onTap,
      showDisclosure: true,
      backgroundColor: Colors.transparent, // Já está dentro do Container pai
    );
  }
}


// --- Widget para o Item Personalizado de Configuração ---
class _CustomSettingTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool showDisclosure;
  final int? badgeCount;
  final bool isLast;
  final Color backgroundColor;

  const _CustomSettingTile({
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.onTap,
    this.showDisclosure = true,
    this.badgeCount,
    this.isLast = false,
    this.backgroundColor = const Color.fromARGB(255, 30, 30, 30),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: backgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
        child: Row(
          children: [
            // Ícone (se existir)
            if (icon != null)
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
            if (icon != null) const SizedBox(width: 10),

            // Título e Subtítulo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

            // Badge (se existir)
            if (badgeCount != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

            // Indicador de Divulgação (Seta)
            if (showDisclosure)
              const Icon(
                CupertinoIcons.chevron_right,
                color: Color.fromARGB(255, 80, 80, 80),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}


// --- Widget para o Item de Perfil (Área Superior) ---
class _ProfileTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
        child: Row(
          children: <Widget>[
            // Ícone/Avatar de Perfil (Simulação)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 120, 120, 120),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  '中', // Simulação do ícone
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 15),
            
            // Texto do Perfil
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Seta de Divulgação
            const Icon(
              CupertinoIcons.chevron_right,
              color: Color.fromARGB(255, 80, 80, 80),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}