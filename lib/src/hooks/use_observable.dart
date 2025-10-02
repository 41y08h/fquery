import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/src/core/observable.dart';

void useObservable(Observable observable) {
  final rebuild = useState(0);

  useEffect(() {
    final id = identityHashCode(rebuild);

    void listener() {
      rebuild.value++; // triggers rebuild
    }

    observable.addListener(id, listener);

    return () {
      observable.removeListener(id);
    };
  }, [observable]);
}
