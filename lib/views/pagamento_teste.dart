import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_js/flutter_js.dart';

import 'pagamento_teste3.dart';

class EfiTokenPage extends StatefulWidget {
  const EfiTokenPage({super.key});

  @override
  State<EfiTokenPage> createState() => _EfiTokenPageState();
}

class _EfiTokenPageState extends State<EfiTokenPage> {
  InAppWebViewController? webViewController;
  bool isLoading = false;
  String? errorMessage;
  String? _capturedToken;

  final sendEndpoint =
      'https://api.comppare.com.br/api/vendas/criar-assinatura';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gerar token do cartão"),
      ),
      body: Stack(
        children: [
          //         InAppWebView(
          //           initialData: InAppWebViewInitialData(data: _htmlContent),
          //           initialSettings: InAppWebViewSettings(
          //             javaScriptEnabled: true,
          //             allowFileAccessFromFileURLs: true,
          //             allowUniversalAccessFromFileURLs: true,
          //             mediaPlaybackRequiresUserGesture: false,
          //             useShouldOverrideUrlLoading: true,
          //             useOnLoadResource: true,
          //             javaScriptCanOpenWindowsAutomatically: true,
          //             mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
          //             domStorageEnabled: true,
          //             databaseEnabled: true,
          //             useWideViewPort: false,
          //             safeBrowsingEnabled: false,
          //             incognito: false,
          //             cacheEnabled: true,
          //             supportZoom: true,
          //             preferredContentMode: UserPreferredContentMode.RECOMMENDED,
          //             allowContentAccess: true,
          //             clearCache: false,
          //             allowFileAccess: true,
          //           ),
          //           onWebViewCreated: (controller) {
          //             webViewController = controller;
          //             print("WebView criada");

          //             if (!kIsWeb) {
          //               try {
          //                 controller.addJavaScriptHandler(
          //                   handlerName: 'onTokenReceived',
          //                   callback: (args) {
          //                     final token = args.first;
          //                     print("Token recebido: $token");
          //                     Navigator.pop(context, token);
          //                   },
          //                 );

          //                 controller.addJavaScriptHandler(
          //                   handlerName: 'onError',
          //                   callback: (args) {
          //                     final error = args.first;
          //                     print("Erro detalhado: $error");
          //                     setState(() {
          //                       errorMessage = error.toString();
          //                       isLoading = false;
          //                     });
          //                   },
          //                 );

          //                 controller.addJavaScriptHandler(
          //                   handlerName: 'logDebug',
          //                   callback: (args) {
          //                     print("Debug: ${args.first}");
          //                     return true;
          //                   },
          //                 );

          //                 controller.addJavaScriptHandler(
          //                   handlerName: 'setLoading',
          //                   callback: (args) {
          //                     final isLoadingNow = args.first as bool;
          //                     setState(() {
          //                       isLoading = isLoadingNow;
          //                     });
          //                     return true;
          //                   },
          //                 );
          //               } catch (e) {
          //                 print("Erro ao configurar handlers: $e");
          //               }
          //             }
          //           },
          //           onLoadStop: (controller, url) async {
          //             print("WebView carregada completamente");

          //             await controller.evaluateJavascript(source: """
          //   // Verificar se a ponte Flutter-JavaScript está disponível
          //   if (typeof window.flutter_inappwebview === 'undefined') {
          //     console.log("A ponte flutter_inappwebview não está disponível. Interação JavaScript-Flutter pode falhar.");
          //   } else {
          //     console.log("Ponte flutter_inappwebview está disponível e pronta para uso.");
          //   }

          //   function setupPage() {
          //     console.log("Configurando a página");

          //     const form = document.getElementById('cardForm');
          //     if (form) {
          //       form.style.display = 'block';
          //       console.log("Formulário exibido com sucesso");
          //     }

          //     const isWeb = ${kIsWeb ? 'true' : 'false'};
          //     if (isWeb) {
          //       // Seu código existente para web
          //     }

          //     if (typeof initializePage === 'function') {
          //       initializePage();
          //     }
          //   }

          //   setupPage();
          // """);

          //             if (kIsWeb) _startTokenCheckTimer();
          //           },
          //           onConsoleMessage: (controller, consoleMessage) {
          //             print(
          //                 "Console [${consoleMessage.messageLevel}]: ${consoleMessage.message}");

          //             if (consoleMessage.message.contains('undefined') ||
          //                 consoleMessage.message.contains('TypeError') ||
          //                 consoleMessage.message.contains('EfiPay')) {
          //               print("ERRO IMPORTANTE: ${consoleMessage.message}");
          //             }
          //           },
          //         ),

          TextButton(onPressed: trazerPagamento, child: Text('GERAR')),

          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      "Processando...",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Mensagem de erro
          if (errorMessage != null && !isLoading)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Erro ao gerar token:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(errorMessage!),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          errorMessage = null;
                        });
                      },
                      child: const Text("Fechar"),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _startTokenCheckTimer() {
    if (!kIsWeb || webViewController == null) return;

    print("Iniciando verificação periódica de token para Web");

    Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        if (!mounted) {
          timer.cancel();
          return;
        }

        final token = await webViewController!
            .evaluateJavascript(source: "window.tokenCaptured") as String?;

        if (token != null &&
            token != "null" &&
            token.isNotEmpty &&
            token != _capturedToken) {
          print("Token encontrado na verificação periódica: $token");
          _capturedToken = token;

          if (mounted) Navigator.pop(context, token);

          timer.cancel();
        }
      } catch (e) {
        print("Erro na verificação de token: $e");
      }
    });
  }

  final String _htmlContent = r"""
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <script src="https://cdn.jsdelivr.net/gh/efipay/js-payment-token-efi/dist/payment-token-efi-umd.min.js"></script>
  <title>Gerar Payment Token</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      max-width: 500px;
      margin: 0 auto;
      padding: 20px;
    }
    h1 {
      color: #4CAF50;
      text-align: center;
    }
    .form-group {
      margin-bottom: 15px;
    }
    label {
      display: block;
      margin-bottom: 5px;
      font-weight: bold;
    }
    input, select {
      width: 100%;
      padding: 8px;
      border: 1px solid #ddd;
      border-radius: 4px;
      box-sizing: border-box;
    }
    button {
      background-color: #4CAF50;
      color: white;
      padding: 10px 15px;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      font-size: 16px;
      display: block;
      width: 100%;
      margin-top: 20px;
    }
    button:hover {
      background-color: #45a049;
    }
    .card-flags {
      display: flex;
      gap: 10px;
      margin-bottom: 15px;
    }
    .card-flag {
      flex: 1;
      text-align: center;
      padding: 10px;
      border: 1px solid #ddd;
      border-radius: 4px;
      cursor: pointer;
    }
    .card-flag.selected {
      border-color: #4CAF50;
      background-color: #e8f5e9;
    }
  </style>
</head>
<body>
  <h1>Gerar Payment Token</h1>
  
  <form id="cardForm">
    <div class="form-group">
      <label for="brand">Bandeira do Cartão:</label>
      <select id="brand" required>
        <option value="">Selecione a bandeira</option>
        <option value="visa">Visa</option>
        <option value="mastercard">MasterCard</option>
        <option value="amex">American Express</option>
        <option value="elo">Elo</option>
        <option value="hipercard">Hipercard</option>
      </select>
    </div>
    
    <div class="form-group">
      <label for="card_number">Número do Cartão:</label>
      <input type="text" id="card_number" placeholder="0000 0000 0000 0000" required>
    </div>
    
    <div class="form-group">
      <label for="name">Nome do Titular:</label>
      <input type="text" id="name" placeholder="Como está no cartão" required>
    </div>
    
    <div class="form-group">
      <label for="cpf">CPF do Titular:</label>
      <input type="text" id="cpf" placeholder="000.000.000-00" required>
    </div>
    
    <div style="display: flex; gap: 15px;">
      <div class="form-group" style="flex: 1;">
        <label for="expirationMonth">Mês de Validade:</label>
        <select id="expirationMonth" required>
          <option value="">Mês</option>
          <option value="01">01</option>
          <option value="02">02</option>
          <option value="03">03</option>
          <option value="04">04</option>
          <option value="05">05</option>
          <option value="06">06</option>
          <option value="07">07</option>
          <option value="08">08</option>
          <option value="09">09</option>
          <option value="10">10</option>
          <option value="11">11</option>
          <option value="12">12</option>
        </select>
      </div>
      
      <div class="form-group" style="flex: 1;">
        <label for="expirationYear">Ano de Validade:</label>
        <select id="expirationYear" required>
          <option value="">Ano</option>
          <option value="2024">2024</option>
          <option value="2025">2025</option>
          <option value="2026">2026</option>
          <option value="2027">2027</option>
          <option value="2028">2028</option>
          <option value="2029">2029</option>
          <option value="2030">2030</option>
          <option value="2031">2031</option>
          <option value="2032">2032</option>
          <option value="2033">2033</option>
          <option value="2034">2034</option>
        </select>
      </div>
      
      <div class="form-group" style="flex: 1;">
        <label for="cvv">CVV:</label>
        <input type="text" id="cvv" placeholder="000" maxlength="4" required>
      </div>
    </div>
    
    <button type="button" onclick="generatePaymentToken()">Gerar Token</button>
  </form>

  <script>
    async function generatePaymentToken() {
      const brand = document.getElementById('brand').value.toLowerCase().replace(/\s/g, '');
      const card_number = document.getElementById('card_number').value.replace(/\D/g, '');
      const name = document.getElementById('name').value;
      const cpf = document.getElementById('cpf').value.replace(/\D/g, '');
      const expirationMonth = document.getElementById('expirationMonth').value;
      const expirationYear = document.getElementById('expirationYear').value;
      const cvv = document.getElementById('cvv').value;
      
      // if (!brand || !card_number || !name || !cpf || !expirationMonth || !expirationYear || !cvv) {
      //   alert('Por favor, preencha todos os campos!');
      //   return;
      // }

      function setLoading(isLoading) {
        if (window.flutter_inappwebview && typeof window.flutter_inappwebview.callHandler === 'function') {
          window.flutter_inappwebview.callHandler('setLoading', isLoading);
        } else {
          console.log("Estado de carregamento alterado:", isLoading);
        }
      }
  
      function reportError(error) {
        if (window.flutter_inappwebview && typeof window.flutter_inappwebview.callHandler === 'function') {
          const errorDetails = {
            code: error.code || 'unknown',
            name: error.error || 'Error',
            message: error.error_description || 'Erro desconhecido',
            stack: error.stack || ''
          };
          window.flutter_inappwebview.callHandler('onError', errorDetails);
        } else {
          console.error("Erro:", error);
          alert("Erro ao gerar token: " + (error.error_description || "Erro desconhecido"));
        }
      }
      
      try {
        setLoading(true);
        console.log("EFI PAY iniciando...");
        
        if (typeof EfiPay === 'undefined') {
          throw new Error("EfiPay não está definido. Verifique se o script foi carregado corretamente.");
        }
        
        console.log("EfiPay disponível:", EfiPay);
        console.log("CreditCard disponível:", EfiPay.CreditCard);

        const result = await EfiPay.CreditCard
          .setAccount("dab94c73c24695ee58451c59298b151c")
          .setEnvironment("production")
          .setCreditCardData({
            brand: "mastercard",
            number: "5226268872411681",
            cvv: "542",
            expirationMonth: "05",
            expirationYear: "2032",
            holderName: "Andrew S Vieira",
            holderDocument: "14248350700",
            reuse: false,
          })
          .getPaymentToken();

        const payment_token = result.payment_token;
        const card_mask = result.card_mask;

        console.log("payment_token", payment_token);
        console.log("card_mask", card_mask);
        
        if (window.flutter_inappwebview && typeof window.flutter_inappwebview.callHandler === 'function') {
          window.flutter_inappwebview.callHandler('onTokenReceived', payment_token);
        } else {
          alert("Token gerado com sucesso:\n" + payment_token);
          // Para versão web
          window.tokenCaptured = payment_token;
        }
      } catch (error) {
        console.log("Código de erro: ", error.code);
        console.log("Nome do erro: ", error.error);
        console.log("Mensagem de erro: ", error.error_description);
        reportError(error);
      } finally {
        setLoading(false);
      }
    }

    document.getElementById('card_number').addEventListener('input', function(e) {
      let value = e.target.value.replace(/\D/g, '');
      if (value.length > 16) value = value.slice(0, 16);

      let formatted = '';
      for (let i = 0; i < value.length; i++) {
        if (i > 0 && i % 4 === 0) formatted += ' ';
        formatted += value[i];
      }
      
      e.target.value = formatted;
    });
    
    document.getElementById('cpf').addEventListener('input', function(e) {
      let value = e.target.value.replace(/\D/g, '');
      if (value.length > 11) value = value.slice(0, 11);
      
      let formatted = '';
      for (let i = 0; i < value.length; i++) {
        if (i === 3 || i === 6) formatted += '.';
        if (i === 9) formatted += '-';
        formatted += value[i];
      }
      
      e.target.value = formatted;
    });
    
    document.getElementById('cvv').addEventListener('input', function(e) {
      e.target.value = e.target.value.replace(/\D/g, '').slice(0, 4);
    });
  </script>

</body>
</html>
""";
}
