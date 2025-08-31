class PlanModel {
  int id;
  final String nome;
  final String descricao;
  final double valor;
  final int quantidadeTags;
  final int quantidadeFotos;
  final int quantidadeConvites;
  final int quantidadePastas;
  final int status;
  final int frequenciaCobranca;
  final int tempoGratuidade;

  PlanModel({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.valor,
    required this.quantidadeTags,
    required this.quantidadeFotos,
    required this.quantidadeConvites,
    required this.quantidadePastas,
    required this.status,
    required this.frequenciaCobranca,
    required this.tempoGratuidade,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'valor': valor,
      'quantidadeTags': quantidadeTags,
      'quantidadeFotos': quantidadeFotos,
      'quantidadeConvites': quantidadeConvites,
      'quantidadePastas': quantidadePastas,
      'status': status,
      'frequenciaCobranca': frequenciaCobranca,
      'tempoGratuidade': tempoGratuidade,
    };
  }

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'] ?? 0,
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? '',
      valor: (json['valor'] ?? 0.0).toDouble(),
      quantidadeTags: json['quantidadeTags'] ?? 0,
      quantidadeFotos: json['quantidadeFotos'] ?? 0,
      quantidadeConvites: json['quantidadeConvites'] ?? 0,
      quantidadePastas: json['quantidadePastas'] ?? 0,
      status: json['status'] ?? 1,
      frequenciaCobranca: json['frequenciaCobranca'] ?? 1,
      tempoGratuidade: json['tempoGratuidade'] ?? 1,
    );
  }

  factory PlanModel.empty() {
    return PlanModel(
      id: 0,
      nome: '',
      descricao: '',
      valor: 0.0,
      quantidadeTags: 0,
      quantidadeFotos: 0,
      quantidadeConvites: 0,
      quantidadePastas: 0,
      status: 0,
      frequenciaCobranca: 0,
      tempoGratuidade: 0,
    );
  }
}