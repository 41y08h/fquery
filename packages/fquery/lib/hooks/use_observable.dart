import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery_core/observable.dart';

void useObservable(Observable observable) {
  final rebuild = useState(0);

  useEffect(() {
    final id = identityHashCode(rebuild);

    void listener() {
      rebuild.value++; // triggers rebuild
    }

    observable.subscribe(id, listener);

    return () {
      observable.unsubscribe(id);
    };
  }, [observable]);
}
