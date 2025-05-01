# Hardening - teoria - Dlaczego robię te kroki? (Hardening i Sieć)

## Cel
Wytłumaczenie praktyki do hardeningu-ssh, monitoringu oraz konfiguracji firewalla z bonusami.

---

## Hardening SSH

- Zmiana portu SSH (np. z 22 na 2222). Utrudnia ataki botow które skanują standardowy port 22.
- Wyłączenie logowania root. Root to domyślne konto, które zawsze istnieje - wyłączając logowanie roota, eliminuję 50% prób ataku.
- Wyłączenie logowania hasłowego (tylko klucze SSH). Hasła można złamać bruteforcem. Klucze SSH są znacznie bezpieczniejsze.

---

## Fail2Ban - Automatyczna ochrona
- Fail2Ban analizuje logi (np. /var/log/auth.log) i jeśli wykryje 5 błędnych logowań z jednego IP, banuje to IP na określony czas.
- Dzięki temu nawet jeśli ktoś próbuje ataku słownikowego - zostaje zablokowany po kilku próbach.

---

## UFW (Firewall)
- Domyślnie blokuję cały ruch przychodzący (deny incoming), a otwieram tylko to, co potrzebne.
- Otwieram porty świadomie:
    - 2222/tcp dla SSH
    - 80/tcp dla HTTP (jeśli stawiam stronę)
    - 443/tcp dla HTTPS (jeśli stawiam stronę z SSL)
- Zasada: minimalna powierzchnia ataku. Otwieram tylko to, co aktualnie potrzebne.

---

## Tryby sieci w VirtualBox - świadomy wybór
| Tryb sieci         | Dostęp do internetu | Widoczny w LAN?  | Komunikacja z hostem? | Bezpieczny do malware? | Opis                                   |
|--------------------|---------------------|------------------|-----------------------|-------------------------|-----------------------------------------|
| NAT                | ✅                  | ❌              | ✅                   | ✅                       | Maszyna widzi internet, LAN jej nie widzi. Dobry do ogólnych testów. |
| Bridged Adapter    | ✅                  | ✅              | ✅                   | ❌                       | VM dostaje IP z routera. Widoczna w sieci LAN jak każde inne urządzenie. |
| Host-only Adapter  | ❌                  | ❌              | ✅                   | ✅                       | Izolowana od internetu, widzi tylko hosta i inne maszyny Host-only. |
| NAT Network        | ✅                  | ❌              | ✅                   | ✅                       | NAT + możliwość komunikacji między maszynami w tej samej NAT sieci. |
| Internal Network   | ❌                  | ❌              | ❌                   | ✅                       | Pełna izolacja. Komunikacja tylko między VM w tej samej Internal sieci. |
| Generic Driver     | ⚠️ zależy           | ⚠️ zależy        | ⚠️ zależy             | ⚠️ zależy                 | Używane do specjalnych przypadków (np. sieci USB, chmurowe). Rzadko stosowane. |

- NAT — Najczęściej używany. VM ma internet, ale LAN jej nie widzi. Bezpieczny.

- Bridged Adapter — VM dostaje IP z sieci domowej/firmowej. Widać ją w LAN (uwaga na malware!).

- Host-only Adapter — Brak internetu, ale VM widzi hosta i inne VM na Host-only. Bezpieczne środowisko.

- NAT Network — jak NAT, ale kilka VM może się między sobą komunikować (np. testujesz sieć z 3 VM).

- Internal Network — totalna izolacja. VM komunikują się tylko ze sobą. Idealne do testów ataków i malware.

- Generic Driver — zaawansowane przypadki, np. customowe sieci. Nie używane w standardowych scenariuszach.

---

## Komendy sieciowe w Linux - Ściągawka admina
| Komenda                 | Co robi?                                   | Kiedy używać?                              |
|-------------------------|---------------------------------------------|--------------------------------------------|
| `ip a`                  | Pokazuje wszystkie interfejsy i IP          | Sprawdzam, czy VM dostała IP               |
| `ip r`                  | Pokazuje trasę (routing)                    | Sprawdzam, którędy maszyna wychodzi do sieci |
| `ping 8.8.8.8`           | Testuje połączenie z internetem (ICMP)      | Diagnozuję brak internetu                  |
| `ss -tuln`              | Pokazuje otwarte porty i usługi             | Sprawdzam, co nasłuchuje na serwerze       |
| `nmap -sn 192.168.88.0/24`| Skanuje sieć i pokazuje aktywne hosty       | Wykrywam inne urządzenia w LAN             |
| `traceroute 8.8.8.8`     | Pokazuje trasę pakietów do celu             | Lokalizuję, gdzie ginie ruch w sieci       |
| `dig google.com`        | Testuje DNS (rozwiązywanie nazw)            | Sprawdzam, czy DNS działa poprawnie        |
| `netstat -i`            | Statystyki interfejsów sieciowych           | Diagnozuję błędy, np. kolizje pakietów     |
| `tcpdump -i eth0`       | Podsłuchuje ruch sieciowy na interfejsie    | Głęboka diagnoza lub analiza ataków        |

---

## Checklista Hardeningu Linux (podstawy dla admina)
| Czynność                           | Komenda / Plik                    | Po co to robimy?                          |
|------------------------------------|-----------------------------------|-------------------------------------------|
| ✅ Utwórz nowego admina (nie root)  | `adduser adminuser` + `usermod -aG sudo adminuser` | Zmniejszamy ryzyko związane z rootem      |
| ✅ Wyłącz logowanie root przez SSH  | Edytuj `/etc/ssh/sshd_config` → `PermitRootLogin no` | Utrudnia ataki brute-force na root        |
| ✅ Zmień port SSH                   | Edytuj `/etc/ssh/sshd_config` → `Port 2222` | Utrudnia automatyczne skanowanie          |
| ✅ Włącz firewall (UFW)             | `apt install ufw` + `ufw enable`  | Blokuje nieautoryzowany dostęp do portów  |
| ✅ Otwórz tylko potrzebne porty     | `ufw allow 22` lub `ufw allow 2222` | Minimalizujemy powierzchnię ataku         |
| ✅ Zainstaluj fail2ban              | `apt install fail2ban`            | Blokuje IP po zbyt wielu nieudanych logowaniach |
| ✅ Ustaw automatyczne aktualizacje  | `apt install unattended-upgrades` | System zawsze ma najnowsze łatki          |
| ✅ Usuń niepotrzebne usługi         | `ss -tuln`, `systemctl disable <usługa>` | Mniej usług = mniej potencjalnych luk    |
| ✅ Zainstaluj i użyj Lynis          | `apt install lynis` + `lynis audit system` | Automatyczny audyt bezpieczeństwa         |
| ✅ Zabezpiecz GRUB (opcjonalnie)    | Edytuj `/etc/grub.d/40_custom`    | Chroni przed atakami fizycznymi           |



