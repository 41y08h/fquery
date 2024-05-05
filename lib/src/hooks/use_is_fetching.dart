import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fquery/fquery.dart';

int useIsFetching() {
  final client = useQueryClient();
  final result = useState(0);

  useListenable(client.queryCache);

  WidgetsBinding.instance.addPostFrameCallback((_) {
    result.value = client.isFetching();
  });

  return result.value;
}
