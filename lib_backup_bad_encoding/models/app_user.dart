class AppUser {
  final int id;
  final int? roleId;
  final int? idLk;
  final String? organization;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String? typeCompany;
  final String usertype;
  final String? createdAt;
  final String? updatedAt;

  AppUser({
    required this.id,
    this.roleId,
    this.idLk,
    this.organization,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    this.typeCompany,
    required this.usertype,
    this.createdAt,
    this.updatedAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: int.tryParse(json['id'].toString()) ?? 0,
      roleId: json['role_id'] == null
          ? null
          : int.tryParse(json['role_id'].toString()),
      idLk: json['id_lk'] == null
          ? null
          : int.tryParse(json['id_lk'].toString()),
      organization: json['organization']?.toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      avatar: json['avatar']?.toString(),
      typeCompany: json['type_company']?.toString(),
      usertype: json['usertype']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  String get roleTitle {
    if (usertype == 'admin' || roleId == 1) {
      return 'РђРґРјРёРЅРёСЃС‚СЂР°С‚РѕСЂ';
    }

    if (usertype == '2' || usertype == 'executor' || roleId == 2) {
      return 'РСЃРїРѕР»РЅРёС‚РµР»СЊ';
    }

    if (usertype == 'manager' || roleId == 3) {
      return 'РњРµРЅРµРґР¶РµСЂ';
    }

    return usertype.isEmpty ? 'РџРѕР»СЊР·РѕРІР°С‚РµР»СЊ' : usertype;
  }

  bool get isAdmin {
    return usertype == 'admin' || roleId == 1;
  }

  bool get isExecutor {
    return usertype == '2' || usertype == 'executor' || roleId == 2;
  }

  bool get isManager {
    return usertype == 'manager' || roleId == 3;
  }
}



