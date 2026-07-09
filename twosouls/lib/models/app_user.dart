import 'package:cloud_firestore/cloud_firestore.dart';

// ---------------------------------------------------------------------------
// AppUser
//
// The logged-in user's full profile as stored in Firestore at /users/{uid}.
// This is separate from UserProfile (profile_screen.dart) which is the
// local in-memory model used by the profile UI. Eventually these should
// be merged; for now AppUser is the persisted version and UserProfile is
// the display version — UserService.toUserProfile() converts between them.
// ---------------------------------------------------------------------------

class AppUser {
  final String uid;
  final String email;
  final String name;
  final DateTime dob;
  final DateTime createdAt;

  // Profile fields
  final String bio;
  final String career;
  final String institution;
  final String location;
  final String? photoUrl;
  final int? looksScore;
  final List<String> hobbyIds;
  final String? careerId;
  final String? sexualOrientation;
  final String? lookingFor;

  // Country of birth — ISO 3166-1 alpha-2 code (e.g. "AU", "US", "GB"),
  // used to render the flag on the Face Rank FIFA-style card. Null until
  // the user picks one via the profile edit / signup country dropdown.
  final String? countryCode;

  // Pool membership
  final bool inShortTermPool;
  final bool inLongTermPool;

  // Compat scores
  final Map<String, int> compatScores;

  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.dob,
    required this.createdAt,
    this.bio = '',
    this.career = '',
    this.institution = '',
    this.location = '',
    this.photoUrl,
    this.looksScore,
    this.hobbyIds = const [],
    this.careerId,
    this.sexualOrientation,
    this.lookingFor,
    this.countryCode,
    this.inShortTermPool = false,
    this.inLongTermPool = false,
    this.compatScores = const {
      'hobbies': 0,
      'careerEducation': 0,
      'looks': 0,
      'lifestyle': 0,
      'coreValues': 0,
    },
  });

  int get age {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  String get firstName => name.split(' ').first;

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: d['email'] ?? '',
      name: d['name'] ?? '',
      dob: (d['dob'] as Timestamp?)?.toDate() ?? DateTime(2000),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      bio: d['bio'] ?? '',
      career: d['career'] ?? '',
      institution: d['institution'] ?? '',
      location: d['location'] ?? '',
      photoUrl: d['photoUrl'],
      looksScore: d['looksScore'],
      hobbyIds: List<String>.from(d['hobbyIds'] ?? []),
      careerId: d['careerId'],
      sexualOrientation: d['sexualOrientation'],
      lookingFor: d['lookingFor'],
      countryCode: d['countryCode'],
      inShortTermPool: d['inShortTermPool'] ?? false,
      inLongTermPool: d['inLongTermPool'] ?? false,
      compatScores: Map<String, int>.from(
        (d['compatScores'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), (v as num).toInt()),
            ) ??
            {},
      ),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'email': email,
    'name': name,
    'dob': Timestamp.fromDate(dob),
    'bio': bio,
    'career': career,
    'institution': institution,
    'location': location,
    'photoUrl': photoUrl,
    'looksScore': looksScore,
    'hobbyIds': hobbyIds,
    'careerId': careerId,
    'sexualOrientation': sexualOrientation,
    'lookingFor': lookingFor,
    'countryCode': countryCode,
    'inShortTermPool': inShortTermPool,
    'inLongTermPool': inLongTermPool,
    'compatScores': compatScores,
  };

  AppUser copyWith({
    String? bio,
    String? career,
    String? institution,
    String? location,
    String? photoUrl,
    int? looksScore,
    List<String>? hobbyIds,
    String? careerId,
    String? sexualOrientation,
    String? lookingFor,
    String? countryCode,
    bool? inShortTermPool,
    bool? inLongTermPool,
    Map<String, int>? compatScores,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      name: name,
      dob: dob,
      createdAt: createdAt,
      bio: bio ?? this.bio,
      career: career ?? this.career,
      institution: institution ?? this.institution,
      location: location ?? this.location,
      photoUrl: photoUrl ?? this.photoUrl,
      looksScore: looksScore ?? this.looksScore,
      hobbyIds: hobbyIds ?? this.hobbyIds,
      careerId: careerId ?? this.careerId,
      sexualOrientation: sexualOrientation ?? this.sexualOrientation,
      lookingFor: lookingFor ?? this.lookingFor,
      countryCode: countryCode ?? this.countryCode,
      inShortTermPool: inShortTermPool ?? this.inShortTermPool,
      inLongTermPool: inLongTermPool ?? this.inLongTermPool,
      compatScores: compatScores ?? this.compatScores,
    );
  }
}
