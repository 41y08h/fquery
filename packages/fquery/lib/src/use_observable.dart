import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery_core/fquery_core.dart';

void useObservable(Observable observable) {
  final rebuild = useState(0);
  final mounted = useRef(true);

  useEffect(() {
    mounted.value = true;
    final id = identityHashCode(rebuild);

    void listener() {
      if (mounted.value) {
        rebuild.value++; // triggers rebuild
      }
    }

    observable.subscribe(id, listener);

    return () {
      mounted.value = false;
      observable.unsubscribe(id);
    };
  }, [observable]);
}
