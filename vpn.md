# VPN - OpenVPN i WireGuard

## Cel projektu
Postawienie własnego serwera VPN przy użyciu **WireGuard** i **OpenVPN**, aby zademonstrować umiejętność konfiguracji różnych protokołów VPN i pracy z różnymi klientami.

---

## Krok 1: Otwieranie portów w UFW (Firewall)

### Na serwerze otwieram odpowiednie porty dla VPN:

```bash
sudo ufw allow 51820/udp    # WireGuard
sudo ufw allow 1194/udp     # OpenVPN
sudo ufw reload
sudo ufw status
```

---

## Krok 2: WireGuard - szybka konfiguracja

### Instaluję WireGuard'a:

```bash
sudo apt update
sudo apt install wireguard
```

### Generuję klucze:

```bash
umask 077
```

To pozornie krótkie polecenie przed utworzeniem kluczy zmienia całkiem sporo tutaj zdjęcia `ls -la`:

Utworzenie kluczy bez umask:

![Screenshot 1: Bez umask](/screenshots/vpn/Screenshot%20From%202025-05-05%2017-03-47.webp)

Utworzenie kluczy z umask:

![Screenshot 2: Z umask](/screenshots/vpn/Screenshot%20From%202025-05-05%2017-04-49.webp)

```bash
wg genkey | tee privatekey | wg pubkey > publickey
```

gdzie:
- `wg genkey` - Generuje losowy klucz prywatny dla WireGuarda
- `|` - pipe przekazuje output poprzedniej komendy do następnej komendy
- `tee privatekey` - Zapisuje ten wygenerowany klucz prywatny do pliku o nazwie `privatekey`. (A jednocześnie przekazuje ten klucz dalej do następnej komendy, bo tee działa troche jak "T" - zapisuje i przepuszcza dalej).
- `wg pubkey` - Bierze ten klucz prywatny i na jego podstawie oblicza klucz publiczny. (Klucz publiczny to ten który możesz wysłać komuś innemu - on nie zdradza Twojego prywatnego klucza, ale pozwala się z Tobą bezpiecznie łączyć).
- `> publickey` - Zapisuje ten obliczony klucz publiczny do pliku o nazwie bulickey

### Konfiguruję `/etc/wireguard/wg0.conf` na serwerze:

```bash
[Interface]
PrivateKey = <wklej zawartość server_private.key>
Address = 10.0.0.1/24
ListenPort = 51820
SaveConfig = true

# Klient 1
[Peer]
PublicKey = <klucz publiczny klienta>
AllowedIPs = 10.0.0.2/32
```

### Aktywuję i uruchamiam VPN na serwerze:

```bash
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0
```

### Sprawdzam status VPN:

```bash
sudo wg
```
lub

```bash
sudo systemctl status wg-quick@wg0
```

#### `OPCJONALNIE - jeśli chcę by serwer stał się moim Gatewayem`

### Zezwalam na forwarding pakietów:

```bash
sudo sysctl -w net.ipv4.ip_forward=1
```

W ten sposób informuję serwer, że chce by pakiety które wysyłam do innych adresów IP poprzez VPN i serwer jako host usługi były przekazywane do tych adresatów. To polecenie `włącza funkcję routera` na naszym serwerze.\
Dodatkowo by ustawić to polecenie jako stałe musimy dodać do pliku `/etc/sysctl.conf` taką linię:

```bash
net.ipv4.ip_forward=1
```

Wtedy działa nawet po restarcie. (To ważne w przypadku gdy krytyczne funkcje naszego hosta są powiązane z innymi maszynami na przykład backend naszego firmowego oprogramowania opierający się o komunikację tunelowaną wysyła zapytania do endpointów API poprzez sieć internet).

### Chcę tunelować cały ruch więc potrzebuję dodać reguły NAT:

```bash
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

Jest to reguła NAT, która ukrywa rzeczywistego nadawcę przed endpointem. Kiedy ruch wychodzi do internetu mówisz: "Zamień nadawcę na IP serwera (ukryj oryginalnego klienta VPN)."
- Do takiego zadania serwer musi mieć prywatne IP więc najlepiej jeśli jest to VPS, w innym wypadku kolejny węzeł nie będzie rozumiał dlaczego dostaje zapytania od adresu z prywatnej podsieci 10.0.0.1 i nie prześle pakietów dalej.

#### `OPCJONALNIE - KONIEC`

### Konfiguruję Klienta (W moim przypadku to po prostu host - kali - debian):

Tworzę w `/etc/wireguard/` plik `wg0.conf`:

```bash
sudo nano /etc/wireguard/wg0.conf
```

W którym umieszczam:

```bash
[Interface]
PrivateKey = <klucz prywatny klienta>
Address = 10.0.0.2/24

[Peer]
PublicKey = <klucz publiczny serwera>
Endpoint = <IP-serwera>:51820
AllowedIPs = 0.0.0.0/0
```

### Uruchamiam na WireGuard'a na kliencie:

```bash
sudo wg-quick up wg0
```

### Podsumowanie WireGuarda:

Instalacja i konfiguracja tego VPN'a jest bardzo prosta i przyjemna.

---

## Krok 2: OpenVPN - szybka konfiguracja

### Instaluję OpenVPN:

```bash
sudo apt update
sudo apt install openvpn easy-rsa
```

easy-rsa pomoże nam w wygenerowaniu kluczy dla openvpn.

### Tworzenie CA i certyfikatów:

```bash
make-cadir ~/openvpn-ca     # Tworzę nowy katalog ~/openvpn-ca z gotowymi skryptami i szablonami do generowania certyfikatów (easy-rsa)
cd ~/openvpn-ca             # Wchodzę w katalog, w którym będę pracował i generował klucze
source vars                 # To ładuje zmienne środowiskowe z pliku vars
./clean-all                 # Usuwa wszystkie stare certyfikaty i klucze w katalogu keys/
./build-ca                  # Generuje klucz prywatny dla Twojego CA: ca.key oraz certyfikat: ca.crt
./build-key-server server   # Generuje klucz prywatny dla serwera: server.key oraz certyfikat serwera: server.crt
./build-key client1         # Generuje klucz prywatny dla klienta: client1.key oraz certyfikat klienta: client1.crt
./build-dh                  # Generuje plik dh2048.pem.
```

| Plik          | Do kogo należy  | Cel                                 |
| ------------- | --------------- | ----------------------------------- |
| `ca.crt`      | CA (Twój urząd) | Certyfikat CA (dajesz klientom)     |
| `ca.key`      | CA              | Klucz prywatny CA (**tajny!**)      |
| `server.crt`  | Serwer VPN      | Certyfikat serwera                  |
| `server.key`  | Serwer VPN      | Klucz prywatny serwera (**tajny!**) |
| `client1.crt` | Klient          | Certyfikat klienta                  |
| `client1.key` | Klient          | Klucz prywatny klienta (**tajny!**) |
| `dh2048.pem`  | Serwer VPN      | Do bezpiecznego uzgadniania kluczy  |


### Więcej o bezpieczeństwie i różnicach tych dwóch systemów będzie dostępne w pliku pod nazwą `vpn-hacking.md` gdy zostanie utworzony. Póki co kluczowe różnice to:

| Cecha                      | **WireGuard**                    | **OpenVPN + CA**                                |
| -------------------------- | -------------------------------- | ----------------------------------------------- |
| Dodanie nowego klienta     | Wystarczy dodać `PublicKey`      | Potrzebny **certyfikat podpisany** przez CA     |
| Gdy serwer jest zhakowany  | Haker może łatwo dodać peerów    | Haker **nie** doda nowych klientów bez `ca.key` |
| Mechanizm kontroli dostępu | Prosty: lista kluczy publicznych | Silny: certyfikaty + podpisywanie przez CA      |
| Utrzymanie                 | Bardzo proste                    | Wymaga zarządzania CA                           |


### Uwaga!

W moim przypadku nie kopiowałem plików zdalnie (scp/ftp), ponieważ nie miałem otwartych portów SSH na hoście Kali Linux.
Przenosiłem pliki lokalnie między terminalami — to też jest poprawna i bezpieczna metoda, jeśli działasz w jednym środowisku.

### Przykładowy plik klienta `client1.ovpn`

```bash
client
dev tun
proto udp
remote YOUR_SERVER_IP 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
verb 3

<ca>
-----BEGIN CERTIFICATE-----
[ZAWARTOŚĆ ca.crt]
-----END CERTIFICATE-----
</ca>

<cert>
-----BEGIN CERTIFICATE-----
[ZAWARTOŚĆ client1.crt]
-----END CERTIFICATE-----
</cert>

<key>
-----BEGIN PRIVATE KEY-----
[ZAWARTOŚĆ client1.key]
-----END PRIVATE KEY-----
</key>
```

### Gdzie trzymać pliki na kliencie?

Zalecane miejsce:

```bash
mkdir -p ~/vpn/openvpn-client1
chmod 700 ~/vpn/openvpn-client1
```

Tutaj plik client1.ovpn lub jeszcze (jeśli osobno): client1.crt, client1.key, ca.crt.\
Następnie zmiana uprawnień:

```bash
chmod 600 ~/vpn/openvpn-client1/*
```

Wtedy tylko właściciel ma dostęp do kluczy i certyfikatów.

---

## Krok 3: Porównanie cech tych rozwiązań:

| Cecha                | OpenVPN                       | WireGuard                 |
| -------------------- | ----------------------------- | ------------------------- |
| Typ kluczy           | Certyfikaty (PKI)             | Klucze publiczne/prywatne |
| Łatwość konfiguracji | Trochę bardziej skomplikowana | Bardzo prosta             |
| Szybkość             | Wolniejszy                    | Szybszy (kernel-space)    |
| Uruchamianie         | `openvpn --config`            | `wg-quick up wg0`         |

---

## Bonus - najlepsze praktyki:

- Trzymaj klucze prywatne tylko na klientach w katalogu z ograniczonym dostępem.

- Używaj UFW do kontrolowania dostępu do portów VPN.

- Dokumentuj IP przypisane do klientów (szczególnie przy WireGuard).

- Preferuj WireGuard do szybkich połączeń, OpenVPN gdy wymagana jest kompatybilność (np. Windows) i bezpieczeństwo.

---

## Podsumowanie

 Podsumowanie Dnia 4 — VPN (WireGuard + OpenVPN)

Dziś udało się postawić dwa różne typy serwerów VPN:

    WireGuard — nowoczesny, szybki i prosty w konfiguracji (bazujący na kluczach publicznych, jak SSH).

    OpenVPN — bardziej klasyczny, ale powszechnie używany i wymaga znajomości systemu certyfikatów (PKI).

W ramach ćwiczeń:

    Otworzyłem odpowiednie porty na firewallu (ufw) dla obu protokołów.

    Wygenerowałem i bezpiecznie przechowałem certyfikaty oraz klucze.

    Połączyłem się z serwerem jako klient, testując poprawne zestawianie tunelu VPN.

    Zrozumiałem różnice w filozofii działania WireGuard (prosty, klucze) vs OpenVPN (PKI, więcej plików).

 Co zyskałem:

    Umiejętność konfiguracji i uruchamiania VPN na Linuksie.

    Wiedzę o bezpiecznym przechowywaniu plików konfiguracyjnych i kluczy.

    Gotowe do pokazania portfolio w postaci plików .md i konfigów.




