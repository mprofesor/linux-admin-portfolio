# Zarządzanie użytkownikami

## Utworzenie użytkownika 'adminuser'

Polecenie:
```bash
sudo adduser adminuser
```

### Nadanie uprawnień sudo

Dodanie adminuser do grupy sudo (a - append nadpisz nie podmieniaj, G - group):

```bash
sudo usermod -aG sudo adminuser
```

### Weryfikacja grup

Sprawdziłem grupy poleceniem:

```bash
groups adminuser
```

Efekt:

```bash
adminuser : adminuser sudo
```

### Test sudo

Zalogowałem się jako adminuser i przetestowałem:

```bash
sudo whoami
```

Wynik:

```
root
```

Co oznacza, że użycie sudo na koncie użytkownika adminuser skutkuje uzyskaniem uprawnień roota.

---

## Teoria: Zarządzanie Użytkownikami + Backupy

### Cheat sheet:

| Zadanie                           | Komenda lub opis                       |
| --------------------------------- | -------------------------------------- |
| Dodaj użytkownika                 | `sudo adduser nazwa_usera`             |
| Usuń użytkownika (bez home)       | `sudo userdel nazwa_usera`             |
| Usuń użytkownika (z home)         | `sudo userdel -r nazwa_usera`          |
| Dodaj do grupy sudo               | `sudo usermod -aG sudo nazwa_usera`    |
| Zobacz grupy użytkownika          | `groups nazwa_usera`                   |
| Wymuś zmianę hasła przy logowaniu | `sudo chage -d 0 nazwa_usera`          |
| Zablokuj konto                    | `sudo usermod -L nazwa_usera`          |
| Odblokuj konto                    | `sudo usermod -U nazwa_usera`          |
| Ustaw datę wygaśnięcia konta      | `sudo chage -E 2025-12-31 nazwa_usera` |
| Lista wszystkich użytkowników     | `cut -d: -f1 /etc/passwd`              |

### Pliki systemowe związane z użytkownikami:

- `/etc/passwd` - użytkownicy
- `/etc/shadow` - hasła(zaszyfrowane)
- `/etc/group` - grupy

### Backupy - Teoria + Najlepsze Praktyki

#### Rodzaje backupów:
- `Full` - cała maszyna / system / katalog.
- `Incremental` - tylko zmiany od ostatniego backupu.
- `Differential` - zmiany od ostatniego ***pełnego*** backupu.

#### Gdzie trzymać backupy:
- `Lokalnie` (np. na innym dysku)
- `Zdalnie` (np. na NAS, VPS, chmurze)
- `Zasada 3-2-1`: **3 kopie, na 2 różnych nośnikach, 1 poza lokalizacją.** (czyli na przykład oryginał i jedna kopia na innym dysku i jeszcze jedna kopia w chmurze)

#### Narzędzia:

| Narzędzie      | Opis                                                   |
| -------------- | ------------------------------------------------------ |
| `rsync`        | Kopiowanie plików i backupy lokalne/zdalne             |
| `tar`          | Tworzenie archiwów (`tar -czvf backup.tar.gz /folder`) |
| `scp` / `sftp` | Zdalne kopiowanie backupów                             |
| `borgbackup`   | Zaawansowane, deduplikacja                             |
| `restic`       | Chmurowe, szyfrowane backupy                           |

---

## Praktyka: Zarządzanie Użytkownikami + Backupy

### Dodaję nowego sudo użytkownika `backupadmin`

```bash
sudo adduser backupadmin
sudo usermod -aG sudo backupadmin
```

### Tworzę regularny backup katalogu /etc (ważne konfigi)

```bash
sudo tar -czvf /home/backupadmin/etc-backup-$(date +%F).tar.gz /etc
```

Gdzie:

- `sudo` - jest potrzebne by wczytać wszystko w /etc
- `tar` - komenda do tworzenia archiwów ("tarballi")
- `-c` - parametr tar "create" - stwórz nowe archiwum
- `-z` - parametr tar "gzip" - skompresuj (tworzy .tar.gz)
- `-v` - parametr tar "verbose" - wypisuj co robi (lista plików)
- `-f` - parametr tar "file" - podaj nazwę pliku do którego zapisze archiwum
- `$(date + %F)` - daje datę w formacie YYYY-MM-DD

Podsumowując - ta komenda tworzy jeden skompresowany plik w formacie .tar.gz zawierający katalog /etc. 

### Tworzę backup z użyciem rsync

```bash
sudo rsync -av --delete /etc /home/backupadmin/etc-backup-rsync
```

- `rsync` - program do synchronizacji (kopiuje tylko zmiany, bardzo szybki do regularnych backupów).
- `a` - parametr rsync "archive mode" - zochowuje prawa, daty, itd.
- `v` - parametr rsync "verbose" - wypisuje co kopiuje
- `--delete` - usuwa pliki z backupu, jeśli zniknęły z /etc (coś jak git trackig)

Podsumowując - rsync tworzy kopię /etc w /home/backupadmin/etc-backup-rsync. Dzięki --delete: jeśli usuniesz coś z /etc to przy kolejnym backupie też zniknie z backupu (backup jest "lustrzany")

### Kopia backupu na inną maszynę z użyciem scp

W moim przypadku na szybko utworzyłem maszynę wirtualną na tym samym hoście i zmieniłem tylko network adapter na bridged by był widzialny w mojej sieci domowej.

```bash
scp -P 22 /home/backupadmin/etc-backup-*.tar.gz vboxuser@192.168.88.225:~/
```

![Screenshot 1: przeniesienie pliku backupowego na innego vm](/screenshots/user-management-and-backups/Screenshot%20From%202025-05-06%2012-03-16.webp)

### Porównanie tar i rsync:

| Metoda                                          | `tar`                   | `rsync`                           |
| ----------------------------------------------- | ----------------------- | --------------------------------- |
|  Tworzy plik                                  | ✅ Tak (`.tar.gz`)       | ❌ Nie, robi kopię katalogu        |
|  Zajmuje mniej miejsca                        | ✅ (bo spakowane)        | ❌ (pełna kopia 1:1)               |
|  Pełne kopie za każdym razem                  | ✅ Tak                   | ❌ Nie, kopiuje tylko zmiany       |
|  Łatwe do wysłania np. `scp`                  | ✅ (1 plik łatwo wysłać) | ❌ (musisz synchronizować katalog) |
|  Super na archiwum (np. na zew. dysk)         | ✅                       | ❌                                 |
|  Super na „żywy” backup (szybkie odtwarzanie) | ❌                       | ✅                                 |

---

## Podsumowanie:

Na koniec chciałbym dodać tylko, że powstanie jeszcze jeden plik `cron.md` gdzie zlecę wykonywanie się backupu poprzez rsync co jakiś określony czas.




