class MembershipStatusModel {
  final bool hasMembership;
  final String? activeMembershipId;
  final String? membershipName;
  final DateTime? membershipExpiration;
  final DateTime? trialEndDate;
  final DateTime? effectiveExpirationDate;
  final int daysRemaining;

  MembershipStatusModel({
    required this.hasMembership,
    this.activeMembershipId,
    this.membershipName,
    this.membershipExpiration,
    this.trialEndDate,
    this.effectiveExpirationDate,
    required this.daysRemaining,
  });

  factory MembershipStatusModel.fromJson(Map<String, dynamic> json) {
    return MembershipStatusModel(
      hasMembership: json['hasMembership'] ?? false,
      activeMembershipId: json['membership']?['id'],
      membershipName: json['membership']?['membresia']?['nombre'],
      membershipExpiration: json['membership']?['fechaExpiracion'] != null
          ? DateTime.parse(json['membership']['fechaExpiracion'])
          : null,
      trialEndDate: json['trialEndDate'] != null
          ? DateTime.parse(json['trialEndDate'])
          : null,
      effectiveExpirationDate: json['effectiveExpirationDate'] != null
          ? DateTime.parse(json['effectiveExpirationDate'])
          : null,
      daysRemaining: json['daysRemaining'] ?? 0,
    );
  }

  /// Calculate new expiration date based on membership months
  DateTime calculateNewExpiration(int months) {
    final now = DateTime.now();

    // If has active expiration date in the future, extend from there
    if (effectiveExpirationDate != null &&
        effectiveExpirationDate!.isAfter(now)) {
      return DateTime(
        effectiveExpirationDate!.year,
        effectiveExpirationDate!.month + months,
        effectiveExpirationDate!.day,
      );
    }

    // Otherwise start from today
    return DateTime(now.year, now.month + months, now.day);
  }

  String get statusText {
    if (hasMembership && membershipName != null) {
      return membershipName!;
    }
    return 'Período de Prueba';
  }
}
