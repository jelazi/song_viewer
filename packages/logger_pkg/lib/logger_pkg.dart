import 'dart:developer';

// Podmíněný import pro dart:io
import 'logger_io.dart' if (dart.library.html) 'logger_web.dart' as platform;

late MyLogger logger;

///
///My Logger class
///
///debug -  bool debug
///
///error - always level 0
///error, warning - level 1
///error, warning, info - level 2
///error, warning, info, verbose - level 3
///
///
///
///to main function:
///   logger = MyLogger(
///     debug: true,
///     saveToFile: true,
///     level: 2,);

class MyLogger {
  dynamic _file;
  dynamic _sink;
  bool _isClosing = false; // Prevents concurrent operations

  int _level;
  bool _debug;
  bool _saveToFile;
  bool _isDebugConsole;

  String _pathDirectory;
  final String _initializationPathDirectory;
  String _suffix = '';
  int _numberFiles = 0;
  String _currentFileDate = ''; // Track current file date
  bool isOpenLogFile = false;
  int _numberLogs = 0;
  final Map<String, int> _repetitionCounts = {};

  MyLogger({
    int level = 3,
    bool debug = true,
    bool saveToFile = true,
    bool isDebugConsole = false,
    String pathDirectory = '',
    int numberRepitions = 0,
  })  : _level = level,
        _debug = debug,
        _saveToFile = saveToFile && !platform.isWeb, // Na webu nelze ukládat do souboru
        _isDebugConsole = isDebugConsole,
        _pathDirectory = pathDirectory,
        _initializationPathDirectory = pathDirectory {
    // Initialize current file date
    _currentFileDate = _getNameFileByCurrentDate();
  }

  void changePathDirectory(String path) async {
    if (platform.isWeb) return; // Na webu nelze měnit cestu
    _pathDirectory = path.isEmpty ? _initializationPathDirectory : path;
    await _reopenLogFile();
  }

  Future<void> _reopenLogFile() async {
    if (platform.isWeb) return; // Na webu nelze otevřít soubor
    await _closeSink();
    if (_saveToFile) {
      await _openLogFile();
    }
  }

  void changeDebug(bool debug) => _debug = debug;
  void changeSaveToFile(bool saveToFile) {
    if (platform.isWeb) {
      _saveToFile = false; // Na webu nelze ukládat do souboru
    } else {
      _saveToFile = saveToFile;
    }
  }
  void changeIsDebugConsole(bool isDebugConsole) => _isDebugConsole = isDebugConsole;
  void changeLevel(int level) => _level = level;

  int get getLevel => _level;
  bool get getDebug => _debug;
  bool get getSaveToFile => _saveToFile;
  bool get getIsDebugConsole => _isDebugConsole;
  String get getPathDirectory => _pathDirectory;

  // Safely close the sink
  Future<void> _closeSink() async {
    if (platform.isWeb) return; // Na webu není sink
    if (_isClosing) return; // Prevent concurrent closing
    _isClosing = true;

    final currentSink = _sink;

    // Clear references immediately
    _sink = null;
    _file = null;
    isOpenLogFile = false;

    if (currentSink != null) {
      try {
        await currentSink.flush();
        await currentSink.close();
      } catch (e) {
        // Silently handle closing errors
      }
    }

    _isClosing = false;
  }

  Future<void> _openLogFile() async {
    if (platform.isWeb) return; // Na webu nelze otevřít soubor
    if (_isClosing) return; // Don't open while closing

    try {
      // Only close sink, keep file reference for date checking
      final currentSink = _sink;
      _sink = null;

      if (currentSink != null) {
        try {
          await currentSink.flush();
          await currentSink.close();
        } catch (e) {
          // Silently handle closing errors
        }
      }

      final dirPath = _pathDirectory.isEmpty ? 'logs' : '$_pathDirectory/logs';
      final dir = platform.createDirectory(dirPath);
      if (!await platform.directoryExists(dir)) await platform.createDirectoryRecursive(dir);

      final fileName = '${_getNameFileByCurrentDate()}$_suffix.log';
      final filePath = '$dirPath/$fileName';

      _file = platform.createFile(filePath);
      if (!await platform.fileExists(_file)) await platform.createFileRecursive(_file);

      // Create a new sink
      _sink = platform.openFileWrite(_file);
      isOpenLogFile = true;

      // Update current file date
      _currentFileDate = _getNameFileByCurrentDate();
    } catch (e) {
      isOpenLogFile = false;
      _sink = null;
      _file = null;
      print('Error openLogFile: $e');
    }
  }

  bool _checkRepetition(String stack, int? repetitionCount) {
    if (repetitionCount == null) return false;
    final count = _repetitionCounts[stack] ?? 0;
    if (count >= repetitionCount) return true;
    _repetitionCounts[stack] = count + 1;
    return false;
  }

  void d(dynamic message, {int? repetitionCount}) {
    if (!_debug) return;
    if (_checkRepetition(_getStack(), repetitionCount)) return;
    final text = 'Debug';
    final output = '\x1B[33m$text\x1B[0m | \x1B[35mmessage:\x1B[0m $message | ${_getTimeStamp(false)} ${_getStack()}';
    _isDebugConsole ? log(output) : print(output);
  }

  Future<void> v(dynamic message, {int? repetitionCount}) async {
    if (_level < 3) return;
    if (_checkRepetition(_getStack(), repetitionCount)) return;
    final output = '\x1B[32mVerbose\x1B[0m | \x1B[35mmessage:\x1B[0m $message | ${_getTimeStamp(false)} ${_getStack()}';
    _isDebugConsole ? log(output) : print(output);
    if (_saveToFile && !platform.isWeb) await _writeLog('Verbose | message: $message ${_getStack(toFile: true)}');
  }

  Future<void> i(dynamic message, {int? repetitionCount}) async {
    if (_level < 2) return;
    if (_checkRepetition(_getStack(), repetitionCount)) return;
    final output = '\x1B[34mInfo\x1B[0m | \x1B[35mmessage:\x1B[0m $message | ${_getTimeStamp(false)} ${_getStack()}';
    _isDebugConsole ? log(output) : print(output);
    if (_saveToFile && !platform.isWeb) await _writeLog('Info | message: $message ${_getStack(toFile: true)}');
  }

  Future<void> w(dynamic message, {int? repetitionCount}) async {
    if (_level < 1) return;
    if (_checkRepetition(_getStack(), repetitionCount)) return;
    final output = '\x1B[36mWarning\x1B[0m | \x1B[35mmessage:\x1B[0m $message | ${_getTimeStamp(false)} ${_getStack()}';
    _isDebugConsole ? log(output) : print(output);
    if (_saveToFile && !platform.isWeb) await _writeLog('Warning | message: $message ${_getStack(toFile: true)}');
  }

  Future<void> e(dynamic message, {int? repetitionCount}) async {
    if (_checkRepetition(_getStack(), repetitionCount)) return;
    final output = '\x1B[31mError\x1B[0m  | \x1B[35mmessage:\x1B[0m $message | ${_getTimeStamp(false)} ${_getStack()}';
    _isDebugConsole ? log(output) : print(output);
    if (_saveToFile && !platform.isWeb) await _writeLog('Error | message: $message ${_getStack(toFile: true)}');
  }

  String _getStack({bool toFile = false}) {
    final stack = StackTrace.current.toString().split('\n');
    if (stack.length > 2) {
      if (toFile) {
        return '| method: ${stack[2].replaceFirst(RegExp(r'#2[ ]{2,}'), '')}';
      }
      return '| \x1B[34mmethod:\x1B[0m ${stack[2].replaceFirst(RegExp(r'#2[ ]{2,}'), '')}';
    }
    return '';
  }

  String _getNameFileByCurrentDate() {
    final now = DateTime.now();
    return 'logs_${now.year}_${_two(now.month)}_${_two(now.day)}';
  }

  String _getNameFileByDate(DateTime date) {
    return 'logs_${date.year}_${_two(date.month)}_${_two(date.day)}';
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  String _getTimeStamp(bool toFile) {
    final now = DateTime.now();
    final stamp = '${now.year}-${_two(now.month)}-${_two(now.day)} ${_two(now.hour)}:${_two(now.minute)}:${_two(now.second)}.${now.millisecond.toString().padLeft(3, '0')}';
    return toFile ? 'stamp: $stamp' : '\x1B[33mstamp:\x1B[0m $stamp';
  }

  Future<void> _writeLog(String message) async {
    if (platform.isWeb) return; // Na webu nelze zapisovat do souboru
    if (_isClosing || !_saveToFile) return;

    try {
      // Check if we need to open/reopen the file
      if (_sink == null || !isOpenLogFile) {
        await _openLogFile();
        if (_sink == null) return;
      }

      // Test file size before writing
      bool needRotate = await _testFileSize();
      if (needRotate) {
        await _openLogFile();
        if (_sink == null) return;
      }

      // Write to file using local reference
      final currentSink = _sink;
      if (currentSink != null && !_isClosing) {
        currentSink.writeln('$message | ${_getTimeStamp(true)}');
        // Don't flush on every write - only when rotating
      }
    } catch (e) {
      // In case of error, close and try to reopen once
      await _closeSink();
      try {
        await _openLogFile();
        final currentSink = _sink;
        if (currentSink != null && !_isClosing) {
          currentSink.writeln('$message | ${_getTimeStamp(true)}');
        }
      } catch (retryError) {
        // Give up after retry
      }
    }
  }

  Future<bool> _testFileSize() async {
    if (platform.isWeb) return false; // Na webu nelze testovat velikost souboru
    // Check every 50 logs instead of 100 for more frequent rotation
    if (_numberLogs < 50) {
      _numberLogs++;
      return false;
    }
    _numberLogs = 0;

    final currentFile = _file;
    if (currentFile == null) return false;

    try {
      // Check if date changed - compare with stored date, not file path
      final todayDate = _getNameFileByCurrentDate();
      if (_currentFileDate != todayDate) {
        _suffix = '';
        _numberFiles = 0;
        _currentFileDate = todayDate;
        return true;
      }

      // Check file size - exactly 10MB = 10,485,760 bytes
      final size = await platform.fileLength(currentFile);
      if (size > 10485760) {
        _numberFiles++;
        _suffix = '.$_numberFiles';

        // Flush before rotation
        final currentSink = _sink;
        if (currentSink != null) {
          await currentSink.flush();
        }

        return true;
      }
    } catch (e) {
      // In case of error, try to rotate
      return true;
    }

    return false;
  }

  Future<List<DateTime>> getAllDatesWithLogs() async {
    if (platform.isWeb) return []; // Na webu nelze číst logy ze souborů
    List<DateTime> dates = [];
    final dirPath = _pathDirectory.isEmpty ? _initializationPathDirectory : _pathDirectory;
    if (dirPath.isEmpty) return dates;
    try {
      final dir = platform.createDirectory('$dirPath/logs');
      final files = platform.listDirectory(dir);
      for (var file in files) {
        final path = platform.getFilePath(file);
        if (path.endsWith('.log')) {
          final name = path.split('logs_').last.split('.log').first;
          final parts = name.split('_');
          if (parts.length == 3) {
            dates.add(DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])));
          }
        }
      }
    } catch (e) {
      print('Error getDateWithLogs: $e');
    }
    dates.sort();
    return dates;
  }

  Future<List<String>> getLogsByDate({required DateTime start, required DateTime end, bool? isDesc, List<int>? levels}) async {
    if (platform.isWeb) return []; // Na webu nelze číst logy ze souborů
    List<String> logs = [];
    final dirPath = _pathDirectory.isEmpty ? _initializationPathDirectory : _pathDirectory;
    if (dirPath.isEmpty) return logs;
    try {
      List<String> allDate = [];
      DateTime current = start;
      while (!current.isAfter(end)) {
        allDate.add(_getNameFileByDate(current));
        current = current.add(const Duration(days: 1));
      }
      final dir = platform.createDirectory('$dirPath/logs');
      final files = platform.listDirectory(dir);
      for (var date in allDate) {
        for (var file in files) {
          final path = platform.getFilePath(file);
          if (path.contains(date)) {
            logs.addAll(platform.readFileLines(platform.createFile(path)));
          }
        }
      }
    } catch (e) {
      print('Error getLogsByDate: $e');
    }
    if (isDesc == true) logs = logs.reversed.toList();
    if (levels != null && levels.isNotEmpty) {
      logs = logs.where((log) {
        return (levels.contains(0) && log.contains('Error')) ||
            (levels.contains(1) && log.contains('Warning')) ||
            (levels.contains(2) && log.contains('Info')) ||
            (levels.contains(3) && log.contains('Verbose'));
      }).toList();
    }
    return logs;
  }

  Future<void> dispose() async {
    if (!platform.isWeb) {
      await _closeSink();
    }
    _repetitionCounts.clear();
  }

  Future<List<String>> getNamesLogFiles() async {
    if (platform.isWeb) return []; // Na webu nelze číst názvy souborů
    List<String> names = [];
    final dirPath = _pathDirectory.isEmpty ? _initializationPathDirectory : _pathDirectory;
    if (dirPath.isEmpty) return names;
    try {
      final dir = platform.createDirectory('$dirPath/logs');
      final files = platform.listDirectory(dir);
      for (var file in files) {
        final path = platform.getFilePath(file);
        if (path.endsWith('.log')) {
          names.add(path.split('/').last);
        }
      }
    } catch (e) {
      print('Error getNamesLogFiles: $e');
    }
    names.sort();
    return names;
  }
}
