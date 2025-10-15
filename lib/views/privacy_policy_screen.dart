import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
// Pacote para abrir URLs externos
import 'package:url_launcher/url_launcher.dart'; 


/// Função auxiliar para lançar URLs externos ou esquemas (mailto, tel).
Future<void> _launchUrl(String urlString) async {
  // Converte a string em Uri. Se o esquema for inválido (como 'mailto'), o parse ainda funciona.
  final Uri url = Uri.parse(urlString);
  
  // Usamos o 'canLaunchUrl' para verificar se o dispositivo pode lidar com o esquema (http, https, mailto, etc.).
  if (await canLaunchUrl(url)) {
    // Abre a URL usando o navegador externo do sistema (ex: Chrome, Safari).
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    // Tratar erro (logar) se não puder abrir o link (pode ser problema de permissão ou URL inválida)
    debugPrint('ERRO: Não foi possível abrir o link externo: $urlString');
  }
}

/// A tela genérica que exibe conteúdo HTML em um WebView,
/// mas com lógica defensiva para evitar o uso do WebView em plataformas não suportadas.
class DocumentWebViewScreen extends StatefulWidget {
  final String title;
  final String htmlContent;

  const DocumentWebViewScreen({
    super.key,
    required this.title,
    required this.htmlContent,
  });

  @override
  State<DocumentWebViewScreen> createState() => _DocumentWebViewScreenState();
}

class _DocumentWebViewScreenState extends State<DocumentWebViewScreen> {
  // O controlador será opcional, pois não será criado em todas as plataformas.
  WebViewController? _controller;
  
  // Flag para verificar se o WebView é suportado na plataforma atual.
  bool isWebViewSupported = false;

  @override
  void initState() {
    super.initState();

    // 1. Determina se a plataforma atual deve usar um WebView nativo
    if (!kIsWeb && 
        (defaultTargetPlatform == TargetPlatform.android || 
         defaultTargetPlatform == TargetPlatform.iOS || 
         defaultTargetPlatform == TargetPlatform.macOS)
    ) {
      isWebViewSupported = true;

      // 2. CRIAÇÃO CONDICIONAL DA IMPLEMENTAÇÃO DA PLATAFORMA
      late final PlatformWebViewControllerCreationParams params;
      if (WebViewPlatform.instance is WebKitWebViewPlatform) {
        // Usa parâmetros específicos para iOS/macOS
        params = WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        );
      } else {
        // Usa parâmetros padrão para Android e outras
        params = const PlatformWebViewControllerCreationParams();
      }

      // 3. Inicializa o controlador USANDO os parâmetros da plataforma
      final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

      // 4. Configurações Específicas da Plataforma
      if (defaultTargetPlatform == TargetPlatform.android) {
        AndroidWebViewController.enableDebugging(true);
      } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
        
        // CORREÇÃO: Cria o delegado de navegação específico do WebKit
        final WebKitNavigationDelegate platformDelegate = WebKitNavigationDelegate(
            (request) async {
              // Permitir todas as navegações por padrão
              return NavigationDecision.navigate;
            } as PlatformNavigationDelegateCreationParams,
        );
        
        // Atribui o delegado específico da plataforma
        controller.setNavigationDelegate(platformDelegate as NavigationDelegate);
      }

      // 5. Define configurações gerais do WebView e DELEGAÇÃO DE NAVEGAÇÃO
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              // Você pode adicionar um indicador de progresso aqui
            },
            onPageStarted: (String url) {},
            onPageFinished: (String url) {},
            onWebResourceError: (WebResourceError error) {},
            // Lógica CRÍTICA para interceptar links!
            onNavigationRequest: (NavigationRequest request) {
              final url = request.url;

              // Verifica se a URL é um link externo (http, https, mailto, tel)
              if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('mailto:') || url.startsWith('tel:')) {
                // Se for um link externo ou um esquema (e-mail, telefone), lança-o fora do WebView
                _launchUrl(url);
                
                // Impede o WebView de tentar carregar a URL internamente
                return NavigationDecision.prevent;
              }
              
              // Para qualquer outra coisa (links internos ou 'about:blank'), permite a navegação
              return NavigationDecision.navigate;
            },
          ),
        );

      // 6. Carrega o conteúdo HTML
      controller.loadHtmlString(widget.htmlContent);

      // 7. Atribui o controlador ao estado
      _controller = controller;

    }
  }

  @override
  Widget build(BuildContext context) {
    // Lógica de limpeza do HTML
    String cleanedHtmlContent = widget.htmlContent;
    cleanedHtmlContent = cleanedHtmlContent.replaceAll(RegExp(r'<style\b[^>]*>[\s\S]*?<\/style>', caseSensitive: false), '');
    cleanedHtmlContent = cleanedHtmlContent.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '');
    cleanedHtmlContent = cleanedHtmlContent.trim();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: isWebViewSupported && _controller != null
          ? WebViewWidget(controller: _controller!)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: SelectableText(
                cleanedHtmlContent,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
    );
  }
}
