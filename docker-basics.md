# Docker basics + Prosty Stack

## Cel projektu

Zdobycie podstawowej wiedzy z zakresu **konteneryzacji** przy użyciu `Dockera`.

---

## Teoria: Co to jest Docker (dla admina)

| Docker                                                          | VirtualBox / VM                              |
| --------------------------------------------------------------- | -------------------------------------------- |
| Izolacja na poziomie procesów (Linux namespaces, cgroups)       | Pełna izolacja na poziomie OS (własne jądro) |
| Działa szybciej, zużywa mniej RAM                               | Cięższe (pełny OS)                           |
| „Kontener” uruchamia konkretną aplikację (np. nginx)            | VM to cały system z usługami                 |
| Pliki konfiguracyjne to **Dockerfile** i **docker-compose.yml** | VM ma swój własny dysk i config w VirtualBox |
| Świetny do skalowania aplikacji i CI/CD                         | Lepszy do izolacji od malware (sandbox)      |

Docker = konteneryzacja (lightweight)
VM = wirtualizacja (heavy, pełna izolacja)

### Dlaczego?

Odpowiedzi na to pytanie może być wiele w zależności od kontekstu... ale tutaj nie ma większej filozofii, wszystko co będziemy tutaj robić ma swój sens i logikę.\
Do tego co będziemy robić warto wiedzieć, że na Debianie/Ubuntu/Mint:
- system APT domyślnie ciągnie pakiety z własnych repozytoriów.
- W przypadku Dockera - repo Debiana zazwyczaj zawiera dość stare wersje Dockera.
- Dlatego Docker Inc. zaleca, żeby dodać ich oficjalne repozytorium - wtedy instalujesz najnowsze wersje Dockera i jego komponentów.

---

## Krok 1: Usuwanie starych wersji Dockera

### Na początku czyszczę potencjalne stare wersje Dockera z systemu, żeby uniknąć konfliktow z nowszymi pakietami z oficjalnego repozytorium Dockera.

```bash
sudo apt remove docker docker-engine docker.io containerd runc
```

W ten sposób upewniam się, że stare paczki Dockera (np. z repo Debiana) są usunięte, żeby nie mieszały się z nowymi.
- `docker`, `docker.io` - stare wersje Dockera
- `containerd`, `runc` - runtime'y kontenerów, też mogą być w starych wersjach.

---

## Krok 2: Instalacja pakietów pomocniczych

### Te pakiety są wymagane do dodania repozytorium Dockera i weryfikacji podpisów GPG, żeby zapewnić bezpieczeństwo.

```bash
sudo apt update
sudo apt install ca-certificates curl gnupg
```

Te pakiety są potrzebne, żeby dodać bezpiecznie nowe repozytorium Dockera.
- `ca-certificates` - umożliwia weryfikację certyfikatów SSL (ważne przy pobieraniu GPG i paczek).
- `curl` - do pobrania plików z internetu.
- `gnupg` - do weryfikacji podpisów GPG repozytorium Dockera.

---

## Krok 3: Dodanie klucza GPG Dockera

### Dodaję oficjalny klucz GPG Dockera, żeby apt mógł weryfikować podpisy paczek i mieć pewność, że są autentyczne.

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

- `GPG` to mechanizm, którym Linux weryfikuje paczki.
- Pobieram klucz publiczny Dockera i zapisuję go w /etc/apt/keyrings.
- `gpg --dearmor` - konwertuje klucz do farmuta binarnego (``.gpg`), który `apt` potrafi przeczytać.

Dodatkowo:
- `install` nie tylko kopiuje pliki ale też tworzy katalogi z odpowiednimi uprawnieniami.
- `-m 0755` oznacza: właściciel może czytać, pisać i wykonywać, a grupa i inni mogą tylko czytać i wykonywać w notacji symbolicznej: `rwxr-xr-x`.
- `-d` każe `install` utworzyć katalog /etc/apt/keyrings <-tutaj

Dlaczego tak?

- /etc/apt/keyrings to nowe, zalecane miejsce na klucze GPG w formacie binarnym (.gpg), zamiast starego /etc/apt/trusted.gpg (który ładował wszystkie klucze globalnie, co było mniej bezpieczne).

- Uprawnienia 0755 są standardowe dla katalogów systemowych, żeby wszyscy mogli czytać, ale tylko root mógł pisać.

**tobecontinued**