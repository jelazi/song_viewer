#Logger for dart

## Features

logger for dart
- print log
- save log file

## Getting started

add dependency to pubspec.yaml

```yaml
dependencies:
  logger: ^last_version
```


## Initialization


```dart
logger = MyLogger(
    debug: true,
    saveToFile: true,
    level: 2,
  );
```

## Usage

debug -  bool debug

error - always level 0
error, warning - level 1
error, warning, info - level 2
error, warning, info, verbose - level 3

```dart
logger.d('debug');
logger.i('info');
logger.v('verbose');
logger.w('warning');
logger.e('error');
```


