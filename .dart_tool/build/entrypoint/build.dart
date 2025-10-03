// @dart=3.6
// ignore_for_file: directives_ordering
// build_runner >=2.4.16
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:build_runner_core/build_runner_core.dart' as _i1;
import 'dart:isolate' as _i2;
import 'package:build_runner/src/build_script_generate/build_process_state.dart'
    as _i3;
import 'package:build_runner/build_runner.dart' as _i4;
import 'dart:io' as _i5;

final _builders = <_i1.BuilderApplication>[];
void main(
  List<String> args, [
  _i2.SendPort? sendPort,
]) async {
  await _i3.buildProcessState.receive(sendPort);
  _i3.buildProcessState.isolateExitCode = await _i4.run(
    args,
    _builders,
  );
  _i5.exitCode = _i3.buildProcessState.isolateExitCode!;
  await _i3.buildProcessState.send(sendPort);
}
