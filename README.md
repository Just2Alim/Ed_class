# EduClass Flutter

Это Flutter-версия проекта, собранная на основе страниц из `pages.zip`.

Что уже перенесено:
- welcome / login / register
- classes / class detail / people / chat
- tasks / calendar / notifications / profile
- account settings / notification settings / privacy settings
- teacher manage class
- mock state через `provider`
- demo-логин для teacher и student

## Демо-вход
- teacher@edu.com / teacher123
- student@edu.com / student123

## Запуск
```bash
flutter pub get
flutter run
```

## Структура
- `lib/main.dart` — маршруты и запуск
- `lib/providers/app_state.dart` — мок-данные и логика
- `lib/models/models.dart` — модели
- `lib/screens/` — экраны
- `lib/widgets/` — общие виджеты
