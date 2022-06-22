class Logger {
  final LogFunction log;
  final LogFunction warn;
  final LogFunction error;

  Logger({
    required this.log,
    required this.warn,
    required this.error,
  });
}

typedef LogFunction = void Function(List<dynamic> args);

final Logger defaultLogger = Logger(
  log: (args) => print('warning: $args'),
  warn: (args) => print('warning: $args'),
  error: (args) => print('error: $args'),
);
