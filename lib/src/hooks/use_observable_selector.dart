import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/src/observable.dart';

T useObservableSelector<T>(Observable observable, T Function() getValue) {
  final state = useState<T>(getValue());

  useEffect(() {
    final id = identityHashCode(state);

    void listener() {
      state.value = getValue();
    }

    observable.addListener(id, listener);

    return () {
      observable.removeListener(id);
    };
  }, [observable]);

  return state.value;
}
