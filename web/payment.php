<!DOCTYPE html>
<html lang="pt-BR">

<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Comppare | Confirmar compra</title>

  <!-- Bootstrap 5 CSS -->
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">

  <!-- jQuery -->
  <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>

  <!-- EfiPay Token JS -->
  <script src="https://cdn.jsdelivr.net/gh/efipay/js-payment-token-efi/dist/payment-token-efi-umd.min.js"></script>

  <!-- Seu CSS personalizado -->
  <link rel="stylesheet" href="token.css">

  <style>
    body {
      background-color: #ffffff;
    }

    .app-bar {
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 60px;
      background-color: #ffffff;
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 1000;
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
    }

    .app-logo {
      height: 40px;
    }

    .container {
      margin-top: 100px;
    }

    .btn-confirmar {
      background-color: #aed513;
      border-color: #aed513;
      color: #000000;
    }

    .btn-confirmar:hover {
      background-color: #9fc912;
      border-color: #9fc912;
      color: #000000;
    }
  </style>
</head>

<body>

  <div class="app-bar">
    <img src="logo.jpg" alt="Logo" class="app-logo">
  </div>

  <div class="container mt-5">
    <div class="card shadow">
      <div class="card-body">
        <h2 class="card-title text-center mb-4">Confirme os dados do cartão</h2>

        <form id="cardForm">
          <div class="mb-3">
            <label for="brand" class="form-label">Bandeira do Cartão:</label>
            <select class="form-select" id="brand" required>
              <option value="">Selecione a bandeira</option>
              <option value="visa">Visa</option>
              <option value="mastercard">MasterCard</option>
              <option value="amex">American Express</option>
              <option value="elo">Elo</option>
              <option value="hipercard">Hipercard</option>
            </select>
          </div>

          <div class="mb-3">
            <label for="card_number" class="form-label">Número do Cartão:</label>
            <input type="text" class="form-control" id="card_number" placeholder="0000 0000 0000 0000" required>
          </div>

          <div class="mb-3">
            <label for="name" class="form-label">Nome do Titular:</label>
            <input type="text" class="form-control" id="name" placeholder="Como está no cartão" required>
          </div>

          <div class="mb-3">
            <label for="cpf" class="form-label">CPF do Titular:</label>
            <input type="text" class="form-control" id="cpf" placeholder="000.000.000-00" required>
          </div>

          <div class="row align-items-end mb-4">
            <div class="col-sm-12 col-md-4 mb-3 mb-md-0">
              <label for="expirationMonth" class="form-label">Mês de Validade:</label>
              <select id="expirationMonth" class="form-select" required>
                <option value="">Mês</option>
                <?php for ($month = 1; $month <= 12; $month++): ?>
                  <?php $formattedMonth = sprintf('%02d', $month); ?>
                  <option value="<?= $formattedMonth ?>"><?= $formattedMonth ?></option>
                <?php endfor; ?>
              </select>
            </div>

            <div class="col-sm-12 col-md-4 mb-3 mb-md-0">
              <label for="expirationYear" class="form-label">Ano de Validade:</label>
              <?php
                $currentYear = date('Y');
                $startYear = $currentYear - 1;
                $endYear = $currentYear + 10;
              ?>
              <select id="expirationYear" class="form-select" required>
                <option value="">Ano</option>
                <?php for ($year = $startYear; $year <= $endYear; $year++): ?>
                  <option value="<?= $year ?>"><?= $year ?></option>
                <?php endfor; ?>
              </select>
            </div>

            <div class="col-sm-12 col-md-4">
              <label for="cvv" class="form-label">CVV:</label>
              <input type="text" class="form-control" id="cvv" placeholder="000" maxlength="4" required>
            </div>
          </div>

          <div class="d-grid">
            <button type="button" class="btn btn-lg btn-confirmar" onclick="generatePaymentToken()">Confirmar dados</button>
          </div>
        </form>
      </div>
    </div>
  </div>

  <!-- Bootstrap Bundle JS -->
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

  <!-- Seu JS -->
  <script src="token.js"></script>
</body>

</html>
