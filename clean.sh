../../flutter/bin/flutter clean
../../flutter/bin/flutter pub get
cd ios
pod install
cd ..
../../flutter/bin/flutter gen-l10n --untranslated-messages-file=untranslated.txt

# flutter build appbundle --release --no-tree-shake-icons