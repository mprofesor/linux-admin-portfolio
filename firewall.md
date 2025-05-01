# Uruchomienie zapory ogniowej

## Cel projektu
Zabezpieczenie serwera przed atakami przez otwarte porty. Nauka podstawowej konfiguracji `ufw`

`UFW` to prosty w użyciu frontend (nakładka) do zarządzania zaporą sieciową iptables na systemach Linux.
Pozwala łatwo włączać, wyłączać i kontrolować ruch sieciowy (np. otwierać lub blokować porty) za pomocą prostych komend.

---

## Krok 1: Instalacja potrzebnych pakietów

```bash
sudo apt install ufw -y
```

---

## Krok 2: Ustawienie domyślnej polityki

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

---

## Krok 3: Otwarcie nowego portu

```bash
sudo ufw allow 2222/tcp
```

---

## Krok 4: Otwarcie portów na przyszłość (dla serwera WWW)

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

---

## Krok 5: Uruchom UFW

```bash
sudo ufw enable
```

---

## Krok 6: Sprawdzenie statusu

```bash
sudo ufw status verbose
```

![Screenshot 1: Sprawdzenie statusu ufw](/screenshots/ssh-hardening/Screenshot%20From%202025-05-01%2013-18-27.webp)

---

## Podsumowanie

UFW domyślnie blokuje wszystko, a ja świadomie otwieram tylko niezbędne porty. Minimalna powierzchnia ataku.
