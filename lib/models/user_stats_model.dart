class UserStats {
  final int folderCount;
  final int subfolderCount;
  final int totalFotos; // <-- Adicionar esta linha
  final double spaceUsedMb;

  UserStats({
    required this.folderCount,
    required this.subfolderCount,
    required this.totalFotos, // <-- Adicionar esta linha
    required this.spaceUsedMb,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      folderCount: json['total_pastas'] as int? ?? 0,
      subfolderCount: json['total_subpastas'] as int? ?? 0,
      totalFotos: json['total_fotos'] as int? ?? 0, // <-- Adicionar esta linha
      spaceUsedMb: (json['espaco_usado_mb'] as num? ?? 0.0).toDouble(),
    );
  }
}