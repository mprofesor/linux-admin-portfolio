# Bazy danych i kopie zapasowe

Zbiór ćwiczeń i procedur administracyjnych związanych z bazami danych SQL i NoSQL.  
Backupy, restore, przesyłanie danych, automatyzacja — wszystko w jednym miejscu.

---

## Spis treści
- [MySQL / MariaDB](#mysql--mariadb)
- [PostgreSQL](#postgresql)
- [MongoDB](#mongodb)
- [Redis](#redis)
- [Backupy i Przywracanie](#backupy-i-przywracanie)
- [Automatyzacja Backupów](#automatyzacja-backupów)

---

## MySQL / MariaDB

- Instalacja
- Tworzenie bazy i tabel
- Backup (`mysqldump`)
- Restore

### Instalacja

```bash
sudo apt update
sudo apt install mariadb-server
sudo systemctl enable mariadb
```

Sprawdzam status usługi

```bash
sudo systemctl status mariadb
```

Zabezpieczam(opcjonalnie bazę)

```bash
sudo mysql_secure_installation
```

Podczas tego kroku ustawiam hasło dla *root* i usuwam anonimowych użytkowników...\
Następnie loguję się jako root

```bash
sudo mysql -u root -p
```

### Tworzenie bazy i tabel

#### Z poziomu mysql tworzymy bazę jako root

1. Tworzę bazę danych:

```sql
CREATE DATABASE testowa_baza;
USE testowa_baza;
```

2. Tworzę (pustą) tabelę *uzytkownicy*

```sql
CREATE TABLE uzytkownicy (
    id INT AUTO_INCREMENT PRIMARY KEY,
    imie VARCHAR(50),
    nazwisko VARCHAR(50),
    wiek INT
);
```
3. Wstawiam przykładowe dane do tabeli:

```sql
INSERT INTO uzytkownicy (imie, nazwisko, wiek) VALUES
('Jan', 'Kowalski', 30),
('Anna', 'Nowak', 25);
```

4. Sprawdzam dane:

```sql
SELECT * FROM uzytkownicy;
```

![Screenshot 1: MariaDB](/screenshots/databases/Screenshot%20From%202025-05-12%2016-43-17.webp)

### Backup

Po wyjściu z mysql (exit;) robię zrzut do pliku

```bash
mysqldump -u root -p testowa_baza > backup_testowa_baza.sql
```

efekt:

```pgsql
backup_testowa_baza.sql
```

### Przywracanie backupu

1. Tworzę nową bazę

```bash
sudo mysql -u root -p -e "CREATE DATABASE testowa_baza_odtworzona;"
```

2. Przywracam dane:

```bash
mysql -u root -p testowa_baza_odtworzona < backup_testowa_baza.sql
```

---

## PostgreSQL

- Instalacja
- Tworzenie bazy i tabel
- Backup (`pg_dump`)
- Restore

### Instalacja

```bash
sudo apt update
sudo apt install postgresql
```

Sprawdzam status:

```bash
sudo systemctl status postgresql
```

#### Loguję się jako użytkownik postgres

```bash
sudo -i -u postgres
psql # To uruchamia klienta PostgreSQL - interaktywną konsolę, gdzie możesz wykonywać zapytania SQL
```

 Efekt: Przełączasz się na użytkownika systemowego postgres, który domyślnie zarządza serwerem PostgreSQL. To konieczne, bo tylko ten użytkownik ma prawo bezpośrednio łączyć się z bazą bez hasła przez tzw. lokalne gniazdo (socket).


### Tworzenie bazy i tabeli

1. Tworzę bazę:
```sql
CREATE DATABASE testowa_baza;
\c testowa_baza
```

2. Tworzę tabelę *uzytkownicy*
```sql
CREATE TABLE uzytkownicy (
    id SERIAL PRIMARY KEY,
    imie VARCHAR(50),
    nazwisko VARCHAR(50),
    wiek INT
);
```

3. Wstawiam dane:

```sql
INSERT INTO uzytkownicy (imie, nazwisko, wiek) VALUES
('Jan', 'Kowalski', 30),
('Anna', 'Nowak', 25);
```

4. Sprawdzam:
```sql
SELECT * FROM uzytkownicy;
```

![Screenshot 2: PostgreSQL](/screenshots/databases/Screenshot%20From%202025-05-12%2017-01-19.webp)

5. Wychodzę:
```sql
\q
```

### Backup PostgreSQL

```bash
sudo -u postgres pg_dump testowa_baza > backup_testowa_baza_postgres.sql
```

### Restore backup

1. Tworzę nową bazę:
```bash
sudo -u postgres createdb testowa_baza_odtworzona
```

2. Przywracam z dumpa:
```bash
sudo -u postgres psql testowa_baza_odtworzona < backup_testowa_baza_postgres.sql
```

---

## MongoDB

- Instalacja
- Tworzenie kolekcji i wstawianie dokumentów
- Backup (`mongodump`)
- Restore (`mongorestore`)

### Instalacja

By zainstalować MongoDB na Debianie należy najpierw dodać repozytorium MongoDB do APT

1. Krok 1: Instalacja wymaganych pakietów

```bash
sudo apt update
sudo apt install gnupg curl
```

2. Krok 2: Dodanie kluczy GPG MongoDB

```bash
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
```

3. Krok 3: Dodanie repozytorium MongoDB do APT (ja mam wersję bookworm)
```bash
echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
```

4. Krok 5: Aktualizacja *apt* i instalacja MongoDB
```bash
sudo apt update
sudo apt install mongodb-org
```

5. Krok 6: Uruchomienie MongoDB po instalacji:
```bash
sudo systemctl start mongod
sudo systemctl enable mongod
```

sprawdzam status usługi:

```bash
sudo systemctl status mongod
```

### Tworzenie kolekcji i wstawianie dokumentów

1. Start klienta MongoDB w terminalu:
```bash
mongosh
```

2. Stworzenie nowej bazy danych:
```js
use testowa_baza
```

3. Stworzenie kolekcji i wstawienie przykładowego dokumentu:
```js
db.uzytkownicy.insertOne({
    imie: "Jan",
    nazwisko: "Kowalski",
    wiek: 30,
    zainteresowania: ["programowanie", "bieganie"]
})
```

4. Sprawdzenie czy dokument został zapisany:
```js
db.uzytkownicy.find().pretty()
```

![Screenshot 3: MongoDB](/screenshots/databases/Screenshot%20From%202025-05-12%2019-40-25.webp)

**To jest właśnie JavaScript Object Notation.**

---

## Redis

- Instalacja
- Tworzenie kluczy i danych
- Backup (plik `dump.rdb`)
- Restore

### Instalacja

```bash
sudo apt update
sudo apt install redis-server
```

Sprawdzam czy Redis działa:
```bash
sudo systemctl status redis
```

Uruchamiam klienta Redisa:
```bash
redis-cli
```

### Tworzenie kluczy i danych

Redis nie ma "baz danych" jak MongoDB, ale można używać przestrzeni kluczy. Domyślnie jesteśmy w bazie 0. Możemy przełączyć się na bazę 1:

```bash
SELECT 1
```

Dodam teraz kilka testowych danych:

```bash
SET uzytkownik:1 "Jan Kowalski"
SET uzytkownik:2 "Anna Nowak"
HSET produkt:1 nazwa "Laptop" cena "2500"
LPUSH lista_zadan "Zrob backup" "Napisz raport"
```

Sprawdzam czy są zapisane:
```bash
GET uzytkownik:1
HGETALL produkt:1
LRANGE lista_zadan 0 -1
```

![Screenshot 4: Redis](/screenshots/databases/Screenshot%20From%202025-05-12%2019-38-25.webp)

### Tworzenie backupu

W redis-cli wymuszam natychmiastowy zapis(backup):
```bash
SAVE
```

Redis zapisze dane do pliku:
```bash
/var/lib/redis/dump.rdb
```

Kopiuję backup do swojego katalogu domowego:
```bash
sudo cp /var/lib/redis/dump.rdb ~/backup_redis_dump.rdb
```

### Restore

***By przywrócić backup po prostu trzeba wrzucić backup file do /var/lib/redis i zrestartować usługę Redis jako, że to baza danych w RAM.**

---

## Backupy i Przywracanie

| System      | Backup           | Restore         |
|-------------|------------------|-----------------|
| MySQL       | `mysqldump`      | `mysql`         |
| PostgreSQL  | `pg_dump`        | `psql`          |
| MongoDB     | `mongodump`      | `mongorestore`  |
| Redis       | `SAVE`/`BGSAVE`  | kopiowanie `dump.rdb` |

![Screenshot 5: Backup na inny VM](/screenshots/databases/Screenshot%20From%202025-05-12%2017-17-36.webp)

---

## Automatyzacja Backupów

- Skrypt Bash do backupu baz (MySQL, PostgreSQL, MongoDB, Redis)

```bash
#!/bin/bash

# Data w formacie YYYY-MM-DD
DATA=$(date +%F)

# Katalog na backupy
BACKUP_DIR=~/backups/$DATA
mkdir -p "$BACKUP_DIR"

echo "Rozpoczynam backup do katalogu: $BACKUP_DIR"

# Backup MySQL
echo "Backup MySQL..."
mysqldump -u root -pYourMySQLPassword testowa_baza > "$BACKUP_DIR/mysql_testowa_baza.sql"

# Backup PostgreSQL
echo "Backup PostgreSQL..."
sudo -u postgres pg_dump testowa_baza > "$BACKUP_DIR/postgres_testowa_baza.sql"

# Backup MongoDB
echo "Backup MongoDB..."
mongodump --db testowa_baza --out "$BACKUP_DIR/mongo_testowa_baza"

# (Opcjonalnie) Backup Redis (kopiujemy dump.rdb)
echo "Backup Redis..."
sudo cp /var/lib/redis/dump.rdb "$BACKUP_DIR/redis_dump.rdb"

# Wysyłka przez SCP
echo "Wysyłka backupu na serwer zdalny..."
scp -r "$BACKUP_DIR" user@192.168.1.100:/home/user/odbior/backups

echo "Backup i wysyłka zakończone!"

```

- Cron job do codziennej automatyzacji

```bash
crontab -e
```

I dodaję linię:

```bash
0 2 * * * /home/youruser/backup_i_wysylka.sh
```

## Podsumowanie

Bazy danych to rozbudowany temat i zdaję sobię sprawę, że w tym pliku nie wyczerpałem wszystkiego co można o nich i o niuansach między nimi powiedzieć. Dodam na koniec tylko, że praca z nimi w przypadku serwera Linuxowego była łatwa i przyjemna. Ciekawym rozwiązaniem może być baza danych Redis, która działa w RAM'ie naszego serwera więc jest bardzo szybka. Bazy danych na pewno powrócą jak bumerang gdy przyjdzie wszystko składać do kupy ponieważ to właśnie ustrukturyzowane dane na serwerach są podstawą internetu.