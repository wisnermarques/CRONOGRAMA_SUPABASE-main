class Instrutores {
  final int? idinstrutor;
  final String nomeinstrutor;
  final String? especializacao; // New optional field
  final String? email; // New optional field
  final String? telefone; // New optional field

  Instrutores(
      {this.idinstrutor,
      required this.nomeinstrutor,
      this.especializacao,
      this.email,
      this.telefone});

  // Factory constructor to create object from Map (database result)
  factory Instrutores.fromMap(Map<String, dynamic> map) {
    return Instrutores(
        idinstrutor: map['idinstrutor'] as int?,
        nomeinstrutor: map['nomeinstrutor'] as String,
        especializacao: map['especializacao'] as String?,
        email: map['email'] as String?,
        telefone: map['telefone'] as String?);
  }

  // Convert object to Map for database operations
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = <String, dynamic>{
      'nomeinstrutor': nomeinstrutor,
      'especializacao': especializacao,
      'email': email,
      'telefone': telefone,
    };
    if (idinstrutor != null) {
      map['idinstrutor'] = idinstrutor;
    }
    return map;
  }

  // Helper method to display instructor info
  String get infoCompleta {
    return [
      nomeinstrutor,
      if (especializacao != null) 'Especialização: $especializacao',
      if (email != null) 'Email: $email',
      if (telefone != null) 'Telefone: $telefone',
    ].join('\n');
  }

  // Method to validate email format
  bool get emailValido {
    if (email == null) return false;
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email!);
  }

  // Method to format phone number
  String? get telefoneFormatado {
    if (telefone == null) return null;
    // Basic formatting for (XX) XXXX-XXXX or (XX) XXXXX-XXXX
    final cleanNumber = telefone!.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanNumber.length == 10) {
      return '(${cleanNumber.substring(0, 2)}) ${cleanNumber.substring(2, 6)}-${cleanNumber.substring(6)}';
    } else if (cleanNumber.length == 11) {
      return '(${cleanNumber.substring(0, 2)}) ${cleanNumber.substring(2, 7)}-${cleanNumber.substring(7)}';
    }
    return telefone;
  }
}
