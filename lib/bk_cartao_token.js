import EfiPay from "payment-token-efi";

<script src="https://cdn.jsdelivr.net/npm/payment-token-efi/dist/payment-token-efi-umd.min.js"></script>

async function identifyBrand() {
    try {
      const brand = await EfiPay.CreditCard
        .setCardNumber("4485785674290087")
        .verifyCardBrand();
  
      console.log("Bandeira: ", brand);
      return brand;
    } catch (error) {
      console.log("Código: ", error.code);
      console.log("Nome: ", error.error);
      console.log("Mensagem: ", error.error_description);
    }
  }

  async function listInstallments() {
    try {
      const installments = await EfiPay.CreditCard
        .setAccount("dab94c73c24695ee58451c59298b151c")
        .setEnvironment("sandbox") // 'production' or 'sandbox'
        .setBrand("visa")
        .setTotal(28990)
        .getInstallments();
  
        console.log("Parcelas", installments);
    } catch (error) {
      console.log("Código: ", error.code);
      console.log("Nome: ", error.error);
      console.log("Mensagem: ", error.error_description);
    }
  }

  async function generatePaymentToken() {
    alert('Chega logo caralho');
    return null;
    try {
        var brand = identifyBrand();
      const result = await EfiPay.CreditCard
        .setAccount("dab94c73c24695ee58451c59298b151c")
        .setEnvironment("sandbox")
        .setCreditCardData({
          brand: brand,
          number: "4485785674290087",
          cvv: "123",
          expirationMonth: "05",
          expirationYear: "2029",
          holderName: "Gorbadoc Oldbuck",
          holderDocument: "94271564656",
          reuse: false,
        })
        .getPaymentToken();
  
      const payment_token = result.payment_token;
      const card_mask = result.card_mask;
  
      console.log("payment_token", payment_token);
      console.log("card_mask", card_mask);
    } catch (error) {
      console.log("Código: ", error.code);
      console.log("Nome: ", error.error);
      console.log("Mensagem: ", error.error_description);
    }
  }