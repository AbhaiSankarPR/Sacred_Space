class FamilyRequest {
  final String id;
  final String relation;
  final RelatedUser relatedUser;

  FamilyRequest({
    required this.id,
    required this.relation,
    required this.relatedUser,
  });

  factory FamilyRequest.fromJson(Map<String, dynamic> json) {
    return FamilyRequest(
      id: json['id'],
      relation: json['relation'],
      relatedUser: RelatedUser.fromJson(json['relatedUser']),
    );
  }
}

class FamilyConnection {
  final String relation;
  final RelatedUser relatedUser;
  final String? displayRelation;
  final bool? inferred;
  final String? source;

  FamilyConnection({
    required this.relation,
    required this.relatedUser,
    this.displayRelation,
    this.inferred,
    this.source,
  });

  factory FamilyConnection.fromJson(Map<String, dynamic> json) {
    return FamilyConnection(
      relation: json['relation'] ?? '',
      relatedUser: RelatedUser.fromJson(json['relatedUser'] ?? {}),
      displayRelation: json['displayRelation'],
      inferred: json['inferred'] is bool
          ? json['inferred']
          : (json['inferred']?.toString().toLowerCase() == 'true'),
      source: json['source'],
    );
  }
}

class RelatedUser {
  final String id;
  final String? role;
  final FamilyProfile profile;
  final String? profilePicUrl;

  RelatedUser({
    required this.id,
    this.role,
    required this.profile,
    this.profilePicUrl,
  });

  factory RelatedUser.fromJson(Map<String, dynamic> json) {
    return RelatedUser(
      id: json['id'],
      role: json['role'],
      profile: FamilyProfile.fromJson(json['profile'] ?? {}),
      profilePicUrl: json['profilePicUrl'] ?? json['profile']?['profilePicUrl'] ?? json['profilePicUrl'],
    );
  }
}

class FamilyProfile {
  final String name;
  final String? gender;
  final String? dob;
  final String? permanentAddress;
  final String? houseNumber;
  final String? residenceType;
  final String? houseName;
  final String? profilePicUrl;

  FamilyProfile({
    required this.name,
    this.gender,
    this.dob,
    this.permanentAddress,
    this.houseNumber,
    this.residenceType,
    this.houseName,
    this.profilePicUrl,
  });

  factory FamilyProfile.fromJson(Map<String, dynamic> json) {
    return FamilyProfile(
      name: json['name'] ?? '',
      gender: json['gender'],
      dob: json['dob'],
      permanentAddress: json['permanentAddress'],
      houseNumber: json['houseNumber'],
      residenceType: json['residenceType'],
      houseName: json['houseName'],
      profilePicUrl: json['profilePicUrl'] ?? json['profile']?['profilePicUrl'],
    );
  }
}
