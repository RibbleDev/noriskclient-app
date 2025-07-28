flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter gen-l10n --untranslated-messages-file=untranslated.txt

# flutter build appbundle --release --no-tree-shake-icons
# flutter build apk --release --no-tree-shake-icons