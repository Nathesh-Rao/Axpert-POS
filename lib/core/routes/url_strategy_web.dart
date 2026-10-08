import 'package:flutter_web_plugins/url_strategy.dart';

/// Path URLs (`/customers`) instead of hash URLs on web.
void configureUrlStrategy() => usePathUrlStrategy();
