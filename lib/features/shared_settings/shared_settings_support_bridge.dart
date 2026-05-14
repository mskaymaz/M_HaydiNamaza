import 'package:flutter/foundation.dart';

final ValueNotifier<int> supportSectionOpenRevision = ValueNotifier<int>(0);

void requestOpenSupportSection() {
  supportSectionOpenRevision.value += 1;
}
