../pulsatrix/flutter/bin/flutter clean
../pulsatrix/flutter/bin/flutter pub get
cd ios
pod install
cd ..
../pulsatrix/flutter/bin/flutter gen-l10n --untranslated-messages-file=untranslated.txt

# flutter build appbundle --release --no-tree-shake-icons