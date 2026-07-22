# Shop Cloud Production Flags

Usa una sola configuracion coherente para evitar modos hibridos de la tienda.

## Desarrollo cloud

```powershell
flutter run --dart-define-from-file=dart_defines/dev.json
```

## Android release

```powershell
flutter build appbundle --release --dart-define-from-file=dart_defines/release.json
```

## APK release de prueba

```powershell
flutter build apk --release --dart-define-from-file=dart_defines/release.json
```

## iOS release

```powershell
flutter build ipa --release --dart-define-from-file=dart_defines/release.json
```

## Regla de arranque

Una release sin los cinco flags cloud activos debe detenerse al arrancar.
Esto evita volver de forma accidental al almacenamiento local o a una configuracion mixta.

## Flags requeridos

- `SHOP_CLOUD_READ_ENABLED`
- `SHOP_CLOUD_PURCHASE_ENABLED`
- `CLOUD_COSMETICS_ENABLED`
- `CLOUD_UTILITY_CONSUMPTION_ENABLED`
- `CLOUD_MYSTERY_BOX_ENABLED`
