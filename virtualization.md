# Wirtualizacja: VirtualBox + Debian 12

## Cel projektu
Stworzenie środowiska do nauki administracji systemami Linux w wirtualnej maszynie przy użyciu VirtualBox.

## Środowisko
- Host OS: Linux amd64: Debian flavour ;p (Operating System: Kali GNU/Linux Rolling Kernel: Linux 6.12.20-amd64)
- Virtualizator: VirtualBox Graphical User Interface Version 7.0.20_Debian
- Guest OS: Debian 12 "Bookworm" (netinst ISO)

---

## Dlaczego wybrałem Debiana?
Wybrałem Debiana, ponieważ zapewnia dobrą równowagę między prostotą, dostępem do szerokiej bazy paczek i lekkością systemu. Jest to kompromis między systemami ultralekkimi a bardziej rozbudowanymi jak Ubuntu. Debian ma też bardzo dobrą dokumentację i jest standardem w środowiskach serwerowych.

---

## Krok 1: Utworzenie maszyny wirtualnej w VirtualBox

1. Otworzyłem VirtulBox i kliknąłem `New`.
2. Nazwa: `debian-test-server-vm`
3. Typ: `Linux`, Wersja: `Debian(64-bit)`
4. Pamięć RAM 2048 MB
5. Dysk twardy:
    - Typ VDI (VirtualBox Disk Image)
    - Dynamicznie przydzielany
    - Rozmiar: 20 GB

![Screenshot 1: Tworzenie nowej VM 1](./screenshots/virtualization/Screenshot%20From%202025-04-30%2019-11-05.webp)
![Screenshot 2: Tworzenie nowej VM 2](./screenshots/virtualization/Screenshot%20From%202025-04-30%2019-12-38.webp)
![Screenshot 2: Tworzenie nowej VM 3](./screenshots/virtualization/Screenshot%20From%202025-04-30%2019-13-02.webp)
![Screenshot 2: Tworzenie nowej VM 4](./screenshots/virtualization/Screenshot%20From%202025-04-30%2019-13-16.webp)
![Screenshot 2: Tworzenie nowej VM 5](./screenshots/virtualization/Screenshot%20From%202025-04-30%2019-13-23.webp)


### Dlaczego wybrałem VDI dynamicznie przydzielany?
VDI dynamicznie przydzielany oznacza, że fizyczny rozmiar pliku dysku rośnie tylko w miarę potrzeb, co oszczędza miejsce na dysku hosta. Umożliwia to tworzenie VM z dużym "maksymalnym" dyskiem, bez natychmiastowego zajmowania całej przestrzeni.

---

## Krok 2: Instalacja systemu Debian 12

1. Podpiąłem obraz ISO `debian-12.10.0-amd64-netinst.iso`
2. Uruchomiłem maszynę i wybrałem `Graphical Install`
3. Wybrałem język: `English`
4. Ustawiłem nazwę hosta: `debian-server`
5. Utworzyłem użytkownika:
    - Root: z hasłem
    - Zwykły użytkownik: `anon`
6. Schemat partycjonowania: cały dysk na `ext4`
7. Zainstalowałem system z domyślnym środowiskiem `standard system utilities` (bez GUI - środowiska graficznego)

### Dlaczego nie użyłem LVM i szyfrowania?
Chociaż LVM i szyfrowanie dysku są korzystne pod względem bezpieczeństwa, na potrzeby środowiska testowego i nauki celowo je pominąłem. Szyfrowanie w środowisku wirtualnym nie wnosi dużej wartości, a upraszcza proces backupu i klonowania maszyn.

### Dlaczego nie instalowałem środowiska graficznego?
Maszyna ma tylko 2048 MB RAM, więc środowisko graficzne nie jest potrzebne, a jego brak zwiększa wydajność i bezpieczeństwo. Gdyby była potrzeba GUI, wybrałbym lekkie środowisko takie jak XFCE lub ewentualnie KDE Plasma, które obecnie jest zaskakująco lekkie w najnowszych wersjach. Alternatywą są jeszcze lżejsze jak LXQt lub i3.

---

## Krok 3: Aktualizacja systemu i instalacja sudo

Po pierwszym uruchomieniu zalogowałem się jako `root` i wykonałem aktualizację systemu:
```bash
apt update && apt upgrade -y
apt install sudo -y
```

---

## Krok 4: Utworzenie użytkownika adminuser

Stworzyłem użytkownika adminuser z uprawnieniami sudo:

```bash
sudo adduser adminuser
sudo usermod -aG sudo adminuser
```

---

## Krok 5: Ustawienia sieci w VirtualBox

Zmieniłem ustawienia virtualnej karty sieciowej dla utworzonej maszyny:
    - Tryb sieci: `Bridged Adapter`
    - Karta sieciowa: `Intel PRO/1000 MT Desktop`
    - Efekt: maszyna ma adres IP w tej samej sieci co komputer host.

![Screenshot 2: Ustawienia sieci w VB](./screenshots/virtualization/Screenshot%20From%202025-04-30%2021-56-04.webp)

### Dlaczego wybrałem Bridged Adapter?
Tryb Bridged pozwala maszynie wirtualnej funkcjonować jak oddzielny komputer w sieci lokalnej — dostaje własny IP od routera, co ułatwia testy np. zdalnego SSH, WWW, VPN.
Uwaga: W przypadku używania VM do testowania złośliwego oprogramowania (malware) lub pentestów, Bridged Adapter to zła praktyka — wtedy należy wybrać `Host-Only` lub `Internal Network`, by izolować VM od sieci hosta.

---

## Krok 6: Test połączenia z VM

Zainstalowałem net-tools by móc użyć `ifconfig` z poziomu `debian-server`:

![Screenshot 2: Test połączenia z VM 1](./screenshots/virtualization/Screenshot%20From%202025-04-30%2021-59-00.webp)

```bash
sudo ifconfig
```

Efekt:
```bash
inet 192.168.88.227
```
Czyli adres przydzielony przez mój router.

Następnie z poziomu `hosta`:
```bash
ping 192.168.88.227 -c 5
```

![Screenshot 2: Test połączenia z VM 1](./screenshots/virtualization/Screenshot%20From%202025-04-30%2022-01-05.webp)

I mamy odpowiedź razy 5.

---

## Podsumowanie

W tym projekcie utworzyłem wirtualne środowisko laboratoryjne oparte na Debianie 12, wykorzystując Oracle VirtualBox. Zastosowałem lekką i bezpieczną konfigurację — bez środowiska graficznego, z użytkownikiem posiadającym uprawnienia sudo, oraz z siecią ustawioną na tryb bridged dla pełnej funkcjonalności w sieci lokalnej.

Środowisko to służy mi jako baza do dalszej nauki i testów z zakresu administracji Linuksem, w tym zarządzania użytkownikami, hardeningu SSH, konfiguracji firewalli i budowy prostych usług serwerowych (np. WWW, VPN, monitoring).

Decyzje podejmowane podczas konfiguracji były świadome — zbalansowałem lekkość systemu z funkcjonalnością, nie stosowałem szyfrowania i GUI ze względu na ograniczone zasoby i potrzebę maksymalnej wydajności.

W kolejnych etapach planuję rozwijać środowisko o:
- hardening systemu (SSH, firewall, fail2ban)
- instalację usług (serwer WWW, VPN)
- automatyzację zadań administracyjnych (np. backupy, skrypty)

Ten projekt stanowi element mojego portfolio jako przyszłego administratora systemów Linux, dokumentując nie tylko **co** robię, ale też **dlaczego** tak robię.