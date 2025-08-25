
class Plano {
  final int id;
  final String nome;
  final String descricao;
  final double valor;
  final int tempoGratuidade;
  final int quantidadeTags;
  final int quantidadeFotos;
  final int quantidadePastas;
  final int frequenciaCobranca;
  final int quantidadeConvites;
  final int status;
  final int quantidadeSubPastas;


  var entries;

  Plano({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.valor,
    required this.tempoGratuidade,
    required this.quantidadeTags,
    required this.quantidadeFotos,
    required this.quantidadePastas,
    required this.frequenciaCobranca,
    required this.quantidadeConvites,
    required this.status,
    required this.quantidadeSubPastas,
  });

  factory Plano.fromJson(Map<String, dynamic> json) {
    return Plano(
      id: json['id'],
      nome: json['nome'],
      descricao: json['descricao'],
      valor: json['valor'].toDouble(),
      tempoGratuidade: json['tempoGratuidade'],
      quantidadeTags: json['quantidadeTags'],
      quantidadeFotos: json['quantidadeFotos'],
      quantidadePastas: json['quantidadePastas'],
      frequenciaCobranca: json['frequenciaCobranca'],
      quantidadeConvites: json['quantidadeConvites'],
      status: json['status'],
      quantidadeSubPastas: json['quantidadeSubPastas'],
    );
  }
}
