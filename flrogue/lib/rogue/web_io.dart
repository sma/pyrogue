class Platform {
  static const environment = {'USER': 'Rogue'};
}

class File {
  File(this.path);

  final String path;

  void createSync() {}

  bool existsSync() => false;

  List<String> readAsLinesSync() => [];

  void writeAsStringSync(String contents, {FileMode mode = FileMode.write}) {}
}

enum FileMode { write, append }

Never exit(int code) => throw Exception();
