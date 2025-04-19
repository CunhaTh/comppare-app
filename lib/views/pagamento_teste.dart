import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gerar token do cartão"),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialData: InAppWebViewInitialData(data: _htmlContent),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              allowFileAccessFromFileURLs: true,
              allowUniversalAccessFromFileURLs: true,
              mediaPlaybackRequiresUserGesture: false,
              useShouldOverrideUrlLoading: true,
              useOnLoadResource: true,
              javaScriptCanOpenWindowsAutomatically: true,
              mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
              domStorageEnabled: true,
              databaseEnabled: true,
              useWideViewPort: false,
              safeBrowsingEnabled: false,
              incognito: true,
              cacheEnabled: false,
            ),
            onWebViewCreated: (controller) {
              webViewController = controller;
              print("WebView criada");

              // Apenas no mobile, configurar handlers
              if (!kIsWeb) {
                try {
                  controller.addJavaScriptHandler(
                    handlerName: 'onTokenReceived',
                    callback: (args) {
                      final token = args.first;
                      print("Token recebido: $token");
                      Navigator.pop(context, token);
                    },
                  );

                  controller.addJavaScriptHandler(
                    handlerName: 'onError',
                    callback: (args) {
                      final error = args.first;
                      print("Erro: $error");
                      setState(() {
                        errorMessage = error.toString();
                        isLoading = false;
                      });
                    },
                  );

                  controller.addJavaScriptHandler(
                    handlerName: 'logDebug',
                    callback: (args) {
                      print("Debug: ${args.first}");
                      return true;
                    },
                  );

                  controller.addJavaScriptHandler(
                    handlerName: 'setLoading',
                    callback: (args) {
                      final isLoadingNow = args.first as bool;
                      setState(() {
                        isLoading = isLoadingNow;
                      });
                      return true;
                    },
                  );
                } catch (e) {
                  print("Erro ao configurar handlers: $e");
                }
              }
            },
            onLoadStop: (controller, url) async {
              print("WebView carregada completamente");

              // Injetar código para adaptar de acordo com a plataforma
              await controller.evaluateJavascript(source: """

                function setupPage() {
                  console.log("Configurando a página");
     
                  const form = document.getElementById('cardForm');
                  if (form) {
                    form.style.display = 'block';
                    console.log("Formulário exibido com sucesso");
                  }
                  
                  const isWeb = ${kIsWeb ? 'true' : 'false'};
                  if (isWeb) {
                    console.log("Executando em ambiente web");
                    
                    window.tokenCaptured = null;
                    window.flutterBridge = function(method, data) {
                      console.log("Chamada de bridge simulada: " + method);
                      
                      if (method === 'onTokenReceived') {
                        window.tokenCaptured = data;
                        console.log("Token capturado:", data);
                        
                        alert("Token gerado: " + data);

                        const display = document.createElement('div');
                        display.style.position = 'fixed';
                        display.style.bottom = '10px';
                        display.style.left = '0';
                        display.style.right = '0';
                        display.style.backgroundColor = '#4CAF50';
                        display.style.color = 'white';
                        display.style.padding = '10px';
                        display.style.textAlign = 'center';
                        display.innerHTML = '<b>Token:</b> ' + data;
                        document.body.appendChild(display);
                      }
                      
                      return Promise.resolve(true);
                    }
                  }
                  
                  if (typeof initializePage === 'function') {
                    initializePage();
                  }
                }
                
                setupPage();
              """);

              // Para web, iniciar verificação periódica do token
              if (kIsWeb) {
                _startTokenCheckTimer();
              }
            },
            onConsoleMessage: (controller, consoleMessage) {
              print("Console: ${consoleMessage.message}");
            },
          ),

          // Overlay de loading
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
      bottomNavigationBar: kIsWeb
          ? Container(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () async {
                  if (webViewController != null) {
                    final token = await webViewController!.evaluateJavascript(
                        source: "window.tokenCaptured") as String?;

                    if (token != null && token != "null" && token.isNotEmpty) {
                      if (mounted) {
                        Navigator.pop(context, token);
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Nenhum token gerado ainda"),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text("Recuperar Token Gerado"),
              ),
            )
          : null,
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

          // Retornar o token para a tela anterior
          if (mounted) {
            Navigator.pop(context, token);
          }

          timer.cancel();
        }
      } catch (e) {
        print("Erro na verificação de token: $e");
      }
    });
  }

  final String _htmlContent = r"""
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="Content-Security-Policy" content="default-src * 'self' 'unsafe-inline' 'unsafe-eval' data: gap: https://ssl.gstatic.com https://cdn.jsdelivr.net https://cdn.efipay.com.br https://app.efipay.com.br https://sandbox.gerencianet.com.br; style-src * 'self' 'unsafe-inline'; script-src * 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.jsdelivr.net https://cdn.efipay.com.br https://app.efipay.com.br https://sandbox.gerencianet.com.br;">
    <title>Token do Cartão</title>

    <script src="https://sandbox.gerencianet.com.br/v1/cdn/gerencianet.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/payment-token-efi/dist/payment-token-efi-umd.min.js"></script>
    <script src="https://cdn.efipay.com.br/sdk/js/efipay-sdk.min.js"></script>
    <script src="https://cdn.gerencianet.com.br/v1/gerencianet.js"></script>

    <script>
      window.addEventListener('load', function() {
        setTimeout(function() {
          console.log("Verificando disponibilidade do SDK após carregamento completo da página");
          
          if (typeof EfiPay !== 'undefined' && EfiPay.CreditCard) {
            console.log("EfiPay.CreditCard está disponível na inicialização");
  
            const methods = ['setAccount', 'setEnvironment', 'setCreditCardData', 'getPaymentToken'];
            const availableMethods = methods.filter(method => typeof EfiPay.CreditCard[method] === 'function');
            console.log(`Métodos EfiPay disponíveis (${availableMethods.length}/${methods.length}):`, availableMethods.join(', '));
            
          } else if (typeof gn !== 'undefined' && gn.checkout) {
            console.log("gn.checkout está disponível na inicialização");
          } else if (typeof $gn !== 'undefined' && $gn.checkout) {
            console.log("$gn.checkout está disponível na inicialização");
          } else {
            console.warn("Nenhum SDK disponível após carregamento da página");
          }
        }, 1000);
      });
    </script>
    
    <style>
      body { font-family: Arial, sans-serif; padding: 20px; margin: 0; background-color: #f9f9f9; }
      input { width: 100%; padding: 12px; margin-bottom: 12px; border-radius: 4px; border: 1px solid #ccc; box-sizing: border-box; font-size: 16px; }
      button { padding: 12px 20px; background-color: #4CAF50; border: none; color: white; border-radius: 4px; cursor: pointer; width: 100%; font-size: 16px; }
      button:disabled { background-color: #cccccc; cursor: not-allowed; }
      .form-container { max-width: 500px; margin: 0 auto; padding: 20px; background-color: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
      h3 { text-align: center; color: #333; margin-bottom: 20px; }
      #status { background-color: #f8f8f8; padding: 12px; border-radius: 4px; margin-bottom: 20px; }
      #errorDetails { display: none; background-color: #fff0f0; padding: 12px; border-radius: 4px; margin: 10px 0; max-height: 150px; overflow-y: auto; border: 1px solid #ffcccc; font-family: monospace; white-space: pre-wrap; }
      label { display: block; margin-bottom: 8px; font-weight: bold; }
      .error { color: #f44336; background-color: #ffebee; border-left: 4px solid #f44336; padding-left: 8px; }
      .success { color: #4CAF50; background-color: #e8f5e9; border-left: 4px solid #4CAF50; padding-left: 8px; }
      .warning { color: #ff9800; background-color: #fff8e1; border-left: 4px solid #ff9800; padding-left: 8px; }
      select { width: 100%; padding: 12px; margin-bottom: 12px; border-radius: 4px; border: 1px solid #ccc; background-color: white; font-size: 16px; }
      .debug-section { margin-top: 20px; padding: 10px; background-color: #f5f5f5; border-radius: 4px; }
      .sdk-status { font-weight: bold; }
      .show-details { color: blue; cursor: pointer; text-decoration: underline; margin-top: 5px; display: block; }
    </style>
  </head>
  <body>
    <div class="form-container">
      <h3>Preencha os dados do cartão</h3>
      
      <div style="border: 1px solid #ddd; border-radius: 8px; padding: 16px; margin-bottom: 20px; background-color: white;">
        <div style="display: flex; align-items: center; margin-bottom: 16px;">
          <div style="margin: 0; font-size: 18px;">Tokenização Efi/GerenciaNet</div>
        </div>
        <p>Esta página utiliza a biblioteca oficial da Efi para gerar tokens reais de cartão.</p>
      </div>
      
      <div id="status" class="success">Formulário pronto para uso</div>
      <div id="errorDetails"></div>
      <div id="toggleDetails" class="show-details" style="display: none;">Mostrar detalhes completos</div>
      
      <form id="cardForm">
        <div>
          <label for="brand">Bandeira do cartão:</label>
          <select id="brand" name="brand" required>
            <option value="">Selecione a bandeira</option>
            <option value="visa">Visa</option>
            <option value="mastercard">Mastercard</option>
            <option value="amex">American Express</option>
            <option value="elo">Elo</option>
            <option value="hipercard">Hipercard</option>
          </select>
        </div>
        
        <div>
          <label for="number">Número do cartão:</label>
          <input id="number" name="number" type="text" placeholder="Número do cartão" maxlength="19" required />
        </div>
        
        <div>
          <label for="cvv">Código de segurança (CVV):</label>
          <input id="cvv" name="cvv" type="text" placeholder="CVV" maxlength="4" required />
        </div>
        
        <div>
          <label for="expiration_month">Mês de expiração:</label>
          <select id="expiration_month" name="expiration_month" required>
            <option value="">Selecione o mês</option>
            <option value="01">01 - Janeiro</option>
            <option value="02">02 - Fevereiro</option>
            <option value="03">03 - Março</option>
            <option value="04">04 - Abril</option>
            <option value="05">05 - Maio</option>
            <option value="06">06 - Junho</option>
            <option value="07">07 - Julho</option>
            <option value="08">08 - Agosto</option>
            <option value="09">09 - Setembro</option>
            <option value="10">10 - Outubro</option>
            <option value="11">11 - Novembro</option>
            <option value="12">12 - Dezembro</option>
          </select>
        </div>
        
        <div>
          <label for="expiration_year">Ano de expiração:</label>
          <select id="expiration_year" name="expiration_year" required>
            <option value="">Selecione o ano</option>
            <script>
              const currentYear = new Date().getFullYear();
              for (let i = 0; i < 15; i++) {
                const year = currentYear + i;
                document.write(`<option value="${year}">${year}</option>`);
              }
            </script>
          </select>
        </div>
        
        <div>
          <label for="holderName">Nome impresso no cartão:</label>
          <input id="holderName" name="holderName" type="text" placeholder="Nome como impresso no cartão" required />
        </div>
        
        <div>
          <label for="holderDocument">CPF do titular:</label>
          <input id="holderDocument" name="holderDocument" type="text" placeholder="CPF do titular (somente números)" maxlength="11" required />
        </div>
        
        <button type="button" id="generateButton" onclick="gerarToken()">Gerar Token Real Efi</button>
      </form>
    </div>

    <script>
      const statusEl = document.getElementById('status');
      const formEl = document.getElementById('cardForm');
      const generateButton = document.getElementById('generateButton');
      const errorDetailsEl = document.getElementById('errorDetails');
      const toggleDetailsEl = document.getElementById('toggleDetails');

      toggleDetailsEl.addEventListener('click', function() {
        if (errorDetailsEl.style.display === 'none') {
          errorDetailsEl.style.display = 'block';
          toggleDetailsEl.textContent = 'Ocultar detalhes';
        } else {
          errorDetailsEl.style.display = 'none';
          toggleDetailsEl.textContent = 'Mostrar detalhes completos';
        }
      });
      
      const ACCOUNT_IDENTIFIER = 'dab94c73c24695ee58451c59298b151c';
      const ENVIRONMENT = 'sandbox'; // 'sandbox' ou 'production'
      
      function logToUi(message, type = 'info') {
        console.log(message);
        
        if (type === 'error') {
          statusEl.className = 'error';
          statusEl.textContent = "Erro: " + (typeof message === 'string' ? message : 'Veja os detalhes abaixo');
          
          if (typeof message === 'object') {
            const detailedError = JSON.stringify(message, null, 2);
            errorDetailsEl.textContent = detailedError;
            errorDetailsEl.style.display = 'block';
            toggleDetailsEl.style.display = 'block';
          } else if (typeof message === 'string' && message.length > 50) {
            errorDetailsEl.textContent = message;
            errorDetailsEl.style.display = 'block';
            toggleDetailsEl.style.display = 'block';
          }
        } else if (type === 'success') {
          statusEl.className = 'success';
          statusEl.textContent = message;
          toggleDetailsEl.style.display = 'none';
        } else if (type === 'warning') {
          statusEl.className = 'warning';
          statusEl.textContent = message;
        } else {
          statusEl.className = '';
          statusEl.textContent = message;
        }
      }
      
      document.getElementById('number').addEventListener('input', function(e) {
        let value = e.target.value.replace(/\D/g, '');
        if (value.length > 0) {
          value = value.match(new RegExp('.{1,4}', 'g')).join(' ');
        }
        e.target.value = value;
      });

      document.getElementById('cvv').addEventListener('input', function(e) {
        e.target.value = e.target.value.replace(/\D/g, '');
      });

      document.getElementById('holderDocument').addEventListener('input', function(e) {
        e.target.value = e.target.value.replace(/\D/g, '');
      });
      
      async function identificarBandeira(numero) {
        try {
          if (typeof EfiPay !== 'undefined' && EfiPay.CreditCard) {
            return await EfiPay.CreditCard
              .setCardNumber(numero.replace(/\D/g, ''))
              .verifyCardBrand();
          } else if (typeof gn !== 'undefined' && gn.checkout) {
            return await gn.checkout.getCardBrand(numero.replace(/\D/g, ''));
          } else if (typeof $gn !== 'undefined' && $gn.checkout) {
            return await $gn.checkout.getCardBrand(numero.replace(/\D/g, ''));
          }
          return null;
        } catch (error) {
          console.error("Erro ao identificar bandeira:", error);
          return null;
        }
      }

      function sendToFlutter(method, data) {
        if (window.flutter_inappwebview && typeof window.flutter_inappwebview.callHandler === 'function') {
          return window.flutter_inappwebview.callHandler(method, data)
            .catch(e => {
              console.error("Erro na comunicação nativa:", e);
              if (method === 'onTokenReceived') {
                window.tokenCaptured = data;
              }
            });
        } else {
          console.log("Usando comunicação alternativa para web");
          if (method === 'onTokenReceived') {
            window.tokenCaptured = data;
            
            alert("Token gerado: " + data);
          }
          return Promise.resolve(true);
        }
      }
      
      async function gerarToken() {
        errorDetailsEl.style.display = 'none';
        toggleDetailsEl.style.display = 'none';
        
        const form = document.getElementById('cardForm');
        const inputs = form.querySelectorAll('input, select');
        let isValid = true;
        
        inputs.forEach(input => {
          if (input.hasAttribute('required') && !input.value) {
            input.style.borderColor = 'red';
            isValid = false;
          } else {
            input.style.borderColor = '#ccc';
          }
        });
        
        if (!isValid) {
          logToUi("Por favor, preencha todos os campos obrigatórios.", 'error');
          return;
        }

        generateButton.disabled = true;
        generateButton.textContent = "Processando...";

        logToUi("Inicializando serviço de tokenização...");
        
        try {
          let sdkType = null;
  
          if (typeof EfiPay !== 'undefined') {
            console.log("Objeto EfiPay encontrado:", EfiPay);
            
            if (EfiPay.CreditCard) {
              console.log("EfiPay.CreditCard encontrado");
   
              const requiredMethods = ['setAccount', 'setEnvironment', 'setCreditCardData', 'getPaymentToken'];
              const missingMethods = requiredMethods.filter(method => typeof EfiPay.CreditCard[method] !== 'function');
              
              if (missingMethods.length === 0) {
                sdkType = 'EfiPay';
                console.log("SDK EfiPay detectado e validado com todos os métodos necessários");
              } else {
                console.warn("SDK EfiPay detectado, mas faltam os métodos:", missingMethods.join(', '));
              }
            } else {
              console.warn("Objeto EfiPay encontrado, mas EfiPay.CreditCard não está disponível");
            }
          } else if (typeof gn !== 'undefined' && gn.checkout) {
            sdkType = 'gn';
            console.log("SDK gn detectado");
          } else if (typeof $gn !== 'undefined' && $gn.checkout) {
            sdkType = '$gn';
            console.log("SDK $gn detectado");
          }
          
          if (!sdkType) {
            console.log("SDK não detectado, tentando carregar novamente...");
            const loaded = tryLoadSDK();
            if (!loaded) {
              throw new Error("SDK da Efi não está disponível. Não é possível gerar o token.");
            }
            
            if (typeof EfiPay !== 'undefined' && EfiPay.CreditCard) {
              sdkType = 'EfiPay';
            } else if (typeof gn !== 'undefined' && gn.checkout) {
              sdkType = 'gn';
            } else if (typeof $gn !== 'undefined' && $gn.checkout) {
              sdkType = '$gn';
            } else {
              throw new Error("SDK da Efi não está disponível mesmo após tentativa de carregamento.");
            }
          }
          
          const cardNumber = document.getElementById('number').value.replace(/\D/g, '');
          const brand = document.getElementById('brand').value;
          const cvv = document.getElementById('cvv').value;
          const expMonth = document.getElementById('expiration_month').value;
          const expYear = document.getElementById('expiration_year').value;
          const holderName = document.getElementById('holderName').value;
          const holderDocument = document.getElementById('holderDocument').value;
          
          try {
            const detectedBrand = await identificarBandeira(cardNumber);
            if (detectedBrand && detectedBrand !== 'undefined' && detectedBrand !== brand) {
              logToUi(`A bandeira selecionada (${brand}) não corresponde à bandeira detectada (${detectedBrand}). Usando ${detectedBrand}.`, 'warning');
              
              document.getElementById('brand').value = detectedBrand;
            }
          } catch (brandError) {
            console.error("Erro ao verificar bandeira:", brandError);
          }
          
          logToUi("Gerando token do cartão...");
          
          let result = null;
          
          const cardData = {
            brand: document.getElementById('brand').value,
            number: cardNumber,
            cvv: cvv,
            expirationMonth: expMonth,
            expirationYear: expYear,
            holderName: holderName,
            holderDocument: holderDocument,
            reuse: false
          };
          
          console.log("Dados do cartão preparados:", JSON.stringify({
            ...cardData,
            number: cardData.number.substring(0, 4) + "********" + cardData.number.substring(cardData.number.length - 4),
            cvv: "***"
          }));
          
          if (sdkType === 'EfiPay') {
            console.log("Usando EfiPay para gerar token");
            try {
              if (typeof EfiPay.CreditCard.debugger === 'function') {
                EfiPay.CreditCard.debugger(true);
              }
              
              let creditCard = EfiPay.CreditCard;
              
              console.log("Configurando conta:", ACCOUNT_IDENTIFIER);
              creditCard = creditCard.setAccount(ACCOUNT_IDENTIFIER);
              
              console.log("Configurando ambiente:", ENVIRONMENT);
              creditCard = creditCard.setEnvironment(ENVIRONMENT);
              
              console.log("Configurando dados do cartão");
              creditCard = creditCard.setCreditCardData(cardData);
              
              console.log("Solicitando token de pagamento");
              try {
                result = await creditCard.getPaymentToken();
              } catch (tokenError) {
                console.warn("Erro na obtenção do token com método encadeado. Tentando método alternativo...", tokenError);
                
                result = await EfiPay.CreditCard
                  .setAccount(ACCOUNT_IDENTIFIER)
                  .setEnvironment(ENVIRONMENT)
                  .setCreditCardData(cardData)
                  .getPaymentToken();
              }
                
              console.log("Resposta do EfiPay:", result);
            } catch (efiError) {
              console.error("Erro específico do EfiPay:", efiError);
              
              if (efiError instanceof TypeError && efiError.message && (
                  efiError.message.includes("is not a function") || 
                  efiError.message.includes("Cannot read properties of") ||
                  efiError.message.includes("undefined")
              )) {
                console.log("Erro parece ser de encadeamento de métodos. Tentando abordagem alternativa...");
                
                try {
                  if (typeof EfiPay.getPaymentToken === 'function') {
                    console.log("Tentando EfiPay.getPaymentToken diretamente");
                    
                    const tokenParams = {
                      account: ACCOUNT_IDENTIFIER,
                      environment: ENVIRONMENT,
                      card: cardData
                    };
                    
                    result = await EfiPay.getPaymentToken(tokenParams);
                    console.log("Token obtido com método alternativo:", result);
                    
                    return;
                  }
                } catch (alternativeError) {
                  console.error("Erro também no método alternativo:", alternativeError);
                }
              }
              
              let errorDetail = "";
              if (efiError instanceof Error) {
                errorDetail = `${efiError.name}: ${efiError.message}\n${efiError.stack || 'Sem stack trace'}`;
              } else {
                errorDetail = JSON.stringify(efiError, null, 2);
              }
              
              errorDetailsEl.textContent = errorDetail;
              errorDetailsEl.style.display = 'block';
              toggleDetailsEl.style.display = 'block';
        
              if (errorDetail.includes("account") || errorDetail.includes("setAccount")) {
                throw new Error(`Erro na configuração da conta Efi. Verifique ACCOUNT_IDENTIFIER: ${ACCOUNT_IDENTIFIER}`);
              } else if (errorDetail.includes("environment") || errorDetail.includes("setEnvironment")) {
                throw new Error(`Erro na configuração do ambiente. Verifique ENVIRONMENT: ${ENVIRONMENT}`);
              } else {
                throw new Error(`Erro do EfiPay: ${efiError.message || 'Erro desconhecido'}`);
              }
            }
          } else if (sdkType === 'gn') {
            console.log("Usando gn para gerar token");
            gn.checkout.setMode(ENVIRONMENT);

            const getTokenPromise = new Promise((resolve, reject) => {
              const handleResponse = function(error, response) {
                if (error) {
                  console.error("Erro na getPaymentToken:", error);
                  
                  errorDetailsEl.textContent = JSON.stringify(error, null, 2);
                  errorDetailsEl.style.display = 'block';
                  toggleDetailsEl.style.display = 'block';
                  
                  reject(error);
                } else {
                  console.log("Token recebido:", response);
                  resolve(response);
                }
              };

              try {
                console.log("Chamando gn.checkout.getPaymentToken");
                gn.checkout.getPaymentToken(cardData, handleResponse);
              } catch (callError) {
                console.error("Erro ao chamar gn.checkout.getPaymentToken:", callError);
                reject(callError);
              }
            });
            
            result = await getTokenPromise;
          } else if (sdkType === '$gn') {
            console.log("Usando $gn para gerar token");
            $gn.checkout.setMode(ENVIRONMENT);
            
            const getTokenPromise = new Promise((resolve, reject) => {
              const handleResponse = function(error, response) {
                if (error) {
                  console.error("Erro na getPaymentToken:", error);

                  errorDetailsEl.textContent = JSON.stringify(error, null, 2);
                  errorDetailsEl.style.display = 'block';
                  toggleDetailsEl.style.display = 'block';
                  
                  reject(error);
                } else {
                  console.log("Token recebido:", response);
                  resolve(response);
                }
              };
              
              try {
                console.log("Chamando $gn.checkout.getPaymentToken");
                $gn.checkout.getPaymentToken(cardData, handleResponse);
              } catch (callError) {
                console.error("Erro ao chamar $gn.checkout.getPaymentToken:", callError);
                reject(callError);
              }
            });
            
            result = await getTokenPromise;
          }
          
          if (!result || !result.payment_token) {
            throw new Error("Não foi possível obter o token de pagamento. Resposta inválida do servidor.");
          }
          
          console.log("Token gerado com sucesso:", result);

          logToUi("Token gerado com sucesso!", 'success');

          errorDetailsEl.textContent = JSON.stringify(result, null, 2);
          errorDetailsEl.style.display = 'block';
          toggleDetailsEl.style.display = 'block';
          toggleDetailsEl.textContent = 'Mostrar detalhes do token';

          await sendToFlutter('onTokenReceived', result.payment_token);
          
        } catch (error) {
          console.error("Erro ao gerar token:", error);

          let errorMessage = "Erro ao gerar token";
          let errorDetails = "";
          
          if (error instanceof Error) {
            errorMessage = error.message;
            errorDetails = `${error.name}: ${error.message}\n${error.stack || 'Sem stack trace'}`;
          } else if (typeof error === 'object') {
            try {
              errorMessage = error.message || error.error_description || "Erro ao gerar token";
              errorDetails = JSON.stringify(error, null, 2);
            } catch (e) {
              errorDetails = "Erro não pode ser convertido para texto";
            }
          }

          logToUi(errorMessage, 'error');

          console.error("Detalhes completos do erro:", error);

          errorDetailsEl.textContent = errorDetails;
          errorDetailsEl.style.display = 'block';
          toggleDetailsEl.style.display = 'block';

          try {
            sendToFlutter('onError', errorMessage);
          } catch (e) {
            console.warn("Não foi possível enviar erro para o Flutter:", e);
          }
        } finally {
          generateButton.disabled = false;
          generateButton.textContent = "Gerar Token Real Efi";
        }
      }
      
      function tryLoadSDK() {
        if ((typeof EfiPay !== 'undefined' && EfiPay.CreditCard) || 
            (typeof gn !== 'undefined' && gn.checkout) || 
            (typeof $gn !== 'undefined' && $gn.checkout)) {
          console.log("SDK já disponível");
          return true;
        }
        
        console.log("SDK não disponível, tentando carregar...");

        const sdkUrls = [
          'https://cdn.jsdelivr.net/npm/payment-token-efi/dist/payment-token-efi-umd.min.js',
          'https://cdn.efipay.com.br/sdk/js/efipay-sdk.min.js',
          'https://cdn.gerencianet.com.br/v1/gerencianet.js',
          'https://sandbox.gerencianet.com.br/v1/cdn/gerencianet.js'
        ];

        function loadScript(url) {
          return new Promise((resolve, reject) => {
            console.log(`Tentando carregar SDK de: ${url}`);
            const script = document.createElement('script');
            script.src = url;
            script.async = true;
            
            script.onload = () => {
              console.log(`Script carregado com sucesso: ${url}`);
              resolve(true);
            };
            
            script.onerror = (e) => {
              console.error(`Erro ao carregar o script: ${url}`, e);
              resolve(false); // Resolver com false para continuar tentando outros URLs
            };
            
            document.head.appendChild(script);
          });
        }

        sdkUrls.forEach(url => {
          loadScript(url).then(success => {
            if (success) {
              console.log(`SDK carregado de ${url}`);

              setTimeout(() => {
                if (typeof EfiPay !== 'undefined' && EfiPay.CreditCard) {
                  console.log("EfiPay.CreditCard disponível após carregamento");
                  
                  // Teste de métodos
                  const methods = ['setAccount', 'setEnvironment', 'setCreditCardData', 'getPaymentToken'];
                  const availableMethods = methods.filter(method => typeof EfiPay.CreditCard[method] === 'function');
                  console.log(`Métodos disponíveis (${availableMethods.length}/${methods.length}):`, availableMethods.join(', '));
                  
                } else if (typeof gn !== 'undefined' && gn.checkout) {
                  console.log("gn.checkout disponível após carregamento");
                } else if (typeof $gn !== 'undefined' && $gn.checkout) {
                  console.log("$gn.checkout disponível após carregamento");
                } else {
                  console.warn("SDK ainda não disponível após carregamento do script");
                }
              }, 500);
            }
          });
        });
        
        return false;
      }
      
      function initializePage() {
        console.log("Inicializando página");
        tryLoadSDK();
        
        const container = document.querySelector('.debug-section') || document.body;
        const debugBtn = document.createElement('button');
        debugBtn.textContent = 'Verificar SDK';
        debugBtn.style.marginTop = '10px';
        debugBtn.style.backgroundColor = '#2196F3';
        debugBtn.onclick = function() {
          let status = "SDK não detectado";
          
          if (typeof EfiPay !== 'undefined' && EfiPay.CreditCard) {
            status = "EfiPay.CreditCard disponível";
          } else if (typeof gn !== 'undefined' && gn.checkout) {
            status = "gn.checkout disponível";
          } else if (typeof $gn !== 'undefined' && $gn.checkout) {
            status = "$gn.checkout disponível";
          }
          
          alert(status);
          console.log(status);
        };
        container.appendChild(debugBtn);
      }

      document.addEventListener('DOMContentLoaded', initializePage);
      
      setTimeout(function() {
        if (document.readyState === 'complete') {
          initializePage();
        }
      }, 1000);
    </script>
  </body>
</html>
""";
}
