# Hardening SSH

## Cel projektu
Zabezpieczenie połączenia SSH z serwerem w środowisku wirtualnym.

---

## Krok 1: Edycja i konfiguracja SSH

Otwieram plik konfiguracyjny ssh:

```bash
sudo nano /etc/ssh/sshd_config
```

Zmieniam te linie (jeśli są zakomentowane usuwam znak komentarza `#`):

```bash
Port 2222
PermitRootLogin no
PasswordAuthentication no
LoginGraceTime 30
```

Port 2222 - ustawiam port komunikacyjny na `2222` (to zmiana ze standardowego 22)\
PermitRootLogin no - zamykam możliwość logowania się przez ssh na konto `root`\
PasswordAuthentication no - usuwam możliwość logowania się przy pomocy hasła (tylko klucze)\
LoginGraceTime 30 - ograniczam czas logowania się do sesji ssh do `30 sekund` (0 == forever)


### WAŻNA INFORMACJA PRZED DALSZĄ CZĘŚCIĄ!
Taka konfiguracja wymaga wcześniejszej konfiguracji `kluczy ssh` by móc łączyć się z hostem. Poniżej krótki poradnik jak to zrobić:

Na hoście generujemy klucze dla połączenia z tym serwerem:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/debian-vm-rsa
```

Utworzyliśmy parę kluczy. `debian-vm-rsa.pub` to klucz publiczny który musimy przenieść na VM do pliku `~/.ssh/authorized_keys`. W moim przypadku zrobiłem to tak:

Na hoście:

```bash
cat ~/.ssh/debian-vm-rsa.pub
```

skopiowałem zawartość i wkleiłem do pliku `authorized_keys` na VM ale można to zrobić na przykład poprzez `scp` (Secure Copy) działającym po SSH.

![Screenshot 1: Kopiowanie kluczy i hardening w pliku sshd_config](/screenshots/ssh-hardening/Screenshot%20From%202025-05-01%2010-34-27.webp)

---

## Krok 2: Restart SSH

```bash
sudo systemctl restart ssh
```

---

## Krok 3: Test nowego logowania

Z drugiej konsoli (zanim zamknąłem starą sesję):

```bash
ssh -p 2222 adminuser@192.168.88.227
```

Jeśli działa to wszystko poszło zgodnie z planem.

## Podsumowanie

Skonfigurowałem ssh by był bezpieczniejszy i nie trzeba było podawać hasła za każdym razem gdy łączymy się z serwerem.