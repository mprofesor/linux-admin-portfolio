# Zarządzanie użytkownikami

## Utworzenie użytkownika 'adminuser'

Polecenie:
```bash
sudo adduser adminuser
```

## Nadanie uprawnień sudo

Dodanie adminuser do grupy sudo (a - append nadpisz nie podmieniaj, G - group):

```bash
sudo usermod -aG sudo adminuser
```

## Weryfikacja grup

Sprawdziłem grupy poleceniem:

```bash
groups adminuser
```

Efekt:

```bash
adminuser : adminuser sudo
```

## Test sudo

Zalogowałem się jako adminuser i przetestowałem:

```bash
sudo whoami
```

Wynik:

```
root
```

Co oznacza, że użycie sudo na koncie użytkownika adminuser skutkuje uzyskaniem uprawnień roota.
