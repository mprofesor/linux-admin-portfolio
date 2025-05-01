# Monitoring logowania

## Cel projektu
Zabezpieczenie serwera przed atakami brute force poprzez użycie `Fail2Ban`.

`Fail2Ban` to narzędzie zabezpieczające serwery Linux, które automatycznie blokuje adresy IP wykonujące podejrzane lub zbyt liczne nieudane logowania, chroniąc przed atakami typu brute force.

---

## Krok 1: Instalacja potrzebnych pakietów

Ja nie miałem rsyslog i iptables więc doinstalowałem:

```bash
sudo apt install fail2ban rsyslog iptables -y
```

---

## Krok 2: Utworzenie lokalnego pliku konfiguracyjnego:

```bash
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
```
Nie edytuję pliku jail.conf!

---

## Krok 3: Edycja jail.local

```bash
sudo nano /etc/fail2ban/jail.local
```

Używam `ctrl+w` by wyszukać `[sshd]` i zmieniam :

```bash
[sshd]
enabled = true
port = 2222
bantime = 600
maxretry = 5
logpath = /var/log/auth.log
```

![Screenshot 1: Monitorowanie logów logowania poprzez SSH](/screenshots/ssh-hardening/Screenshot%20From%202025-05-01%2011-19-19.webp)

W pliku by uniknąć błędów komentuję `[sshd]` w innych miejscach oraz ustawienia pod tym nagłówkiem.


---

## Krok 4: Konfiguracja rsyslog

```bash
sudo nano /etc/rsyslog.d/50-default.conf
```

I stwórz linię:

```bash
auth,authpriv.*      /var/log/auth.log
```

Następnie restartuję rsysloga:

```bash
sudo systemctl restart rsyslog
```

Sprawdzam, czy `/var/log/auth.log` zapisuje logi z prób połączenia przez `ssh`:

```bash
sudo tail -f /var/log/auth.log
```

W innym terminalu wykonuję:
    - Próbę logowania (udana/nieudana)
    - Obserwuję logi
    

### Dlaczego tak?
Debian, Ubuntu i CentOS domyślnie używają `systemd-journal` do logów, a nie starego sysloga z plikami. Ale Fail2Ban domyślnie lubi czytać właśnie z plików logów (np.`/var/log/auth.log`), bo tak działa jego "logpath" od lat.

---

## Krok 5: Restart fail2ban

```bash
sudo systemctl restart fail2ban
```

Sprawdzamy status banów:

```bash
sudo fail2ban-client status sshd
```

Fail2Ban monitoruje logi i automatycznie banuje IP za zbyt wiele nieudanych prób logowania.

---

## Krok 6: Test na "żywym organizmie"

1. Próbuję z poziomu hosta zalogować się na nieistniejące konto, mylę hasło więcej niż 5 razy i dostaję bana.\
2. Na VM:
```bash
sudo iptables -L
```

![Screenshot 2: Zablokowany host](/screenshots/ssh-hardening/Screenshot%20From%202025-05-01%2011-55-36.webp)

Mój host znajduje się na liście więc jestem zbanowany.

3. Odbanowuję siebie:
```bash
sudo fail2ban-client set sshd unbanip 192.168.88.241
```

![Screenshot 3: Odblokowany host](/screenshots/ssh-hardening/Screenshot%20From%202025-05-01%2011-58-31.webp)

Jak widać host został odblokowany.

---

## Podsumowanie

Skonfigurowałem fail2ban który banuje mi nieudane próby logowania do serwera poprzez ssh oraz stworzyłem plik logujący te próby.


