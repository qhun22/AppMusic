class Song {
  final int id;
  final String title;
  final String url;
  final String? type; // Remix hoặc Lofi
  final String? artUrl;

  Song({
    required this.id,
    required this.title,
    required this.url,
    this.type,
    this.artUrl,
  });

  factory Song.fromJson(Map<String, dynamic> json, {String? defaultType}) {
    return Song(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? 'Unknown Title',
      url: json['url']?.toString() ?? '',
      type: json['type']?.toString() ?? defaultType,
      artUrl: json['artUrl']?.toString() ??
          json['art_url']?.toString() ??
          json['cover']?.toString(),
    );
  }

  Song copyWith({
    int? id,
    String? title,
    String? url,
    String? type,
    String? artUrl,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      type: type ?? this.type,
      artUrl: artUrl ?? this.artUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      if (type != null) 'type': type,
      if (artUrl != null) 'artUrl': artUrl,
    };
  }

  /// Đoán ca sĩ từ tiêu đề dạng "Tên bài - Ca sĩ" (dùng cho xáo trộn thông minh)
  String get artistGuess {
    final parts = title.split(RegExp(r'\s+-\s+'));
    if (parts.length > 1) {
      final last = parts.last.trim();
      if (last.isNotEmpty) return last;
    }
    return title;
  }

  /// Khoá so sánh ca sĩ (chữ thường, bỏ khoảng trắng thừa)
  String get artistKey => artistGuess.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  /// Bỏ đuôi tên file kiểu "(Official Lyric Video)" cho gọn (nếu có)
  String get shortTitle {
    var t = title;
    t = t.replaceAll(RegExp(r'\s*[\(\[]\s*official[^\)\]]*[\)\]]', caseSensitive: false), '');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t.isEmpty ? title : t;
  }

  @override
  String toString() => '#$id $title';
}
