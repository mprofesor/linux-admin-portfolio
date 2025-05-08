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
- `gpg --dearmor` - konwertuje klucz do formatu binarnego (`.gpg`), który `apt` potrafi przeczytać.

Dodatkowo:
- `install` nie tylko kopiuje pliki ale też tworzy katalogi z odpowiednimi uprawnieniami.
- `-m 0755` oznacza: właściciel może czytać, pisać i wykonywać, a grupa i inni mogą tylko czytać i wykonywać w notacji symbolicznej: `rwxr-xr-x`.
- `-d` każe `install` utworzyć katalog /etc/apt/keyrings <-tutaj

Dlaczego tak?

- /etc/apt/keyrings to nowe, zalecane miejsce na klucze GPG w formacie binarnym (.gpg), zamiast starego /etc/apt/trusted.gpg (który ładował wszystkie klucze globalnie, co było mniej bezpieczne).

- Uprawnienia 0755 są standardowe dla katalogów systemowych, żeby wszyscy mogli czytać, ale tylko root mógł pisać.

- curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg:

    - -f -> fail silently przy błędzie HTTP.
    - -s -> silent (bez progresu).
    - -S -> pokaż błąd, jeśli -s włączone.
    - L -> podążaj za przekirowaniami
    - To polecenie pobiera klucz publiczny Dockera a następnie poprzez `|` przekazuje do gpg gdzie konwertuje ten klucz.

- Bezpieczne (unika apt-key).
- Stosuje nowe standardy APT (/etc/apt/keyrings).
- Odpowiednie uprawnienia katalogu i pliku.
- Przechowuje klucz w formacie binarnym, jak wymaga signed-by w plikach .list.


---

## Krok 4: Dodanie repozytorium Dockera do APT

### Dodaję oficjalne repozytorium Dockera podpisane ich kluczem GPG, co umożliwia mi instalację najnowszych wersji Dockera, buildx i Compose z zachowaniem bezpieczeństwa APT.

```bash
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

To długie polecenie to nic innego jak dodanie linijki do pliku /etc/apt/sources.list.d/docker.list no i przekierowywujemy output z tee do terminala do /dev/null ("czarnej dziury").

---

## Krok 5: Instalacja Dockera i komponentów

### Instaluję główny silnik Dockera, klienta CLI, runtime containerd, oraz wtyczki do Buildx i Compose — wszystko z oficjalnego repozytorium.

```bash
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

- Teraz, gdy mam repozytorium Dockera dodane używam sudo apt update by Debian "zobaczył" nowo dodane repozytorium.

- Następnie instaluję kilka komponentów Dockera:

| Pakiet                  | Co to jest?                                         |
| ----------------------- | --------------------------------------------------- |
| `docker-ce`             | **Docker Community Edition** (silnik dockera)       |
| `docker-ce-cli`         | Komenda `docker` w terminalu                        |
| `containerd.io`         | Runtime do kontenerów, na którym działa Docker      |
| `docker-buildx-plugin`  | Narzędzie do budowania obrazów (obsługuje BuildKit) |
| `docker-compose-plugin` | Oficjalny **plugin Compose v2** (`docker compose`)  |


---

## Krok 6: Dodanie użytkownika do grupy docker

### Dodaję użytkownika do grupy docker, żeby można było używać Dockera bez sudo — to wygodne, ale trzeba pamiętać, że użytkownicy w tej grupie mają uprawnienia podobne do roota.


```bash
sudo usermod -aG docker $USER # Dodaje zalogowanego użytkownika do grupy docker
newgrp docker`                # Updatuje grupę w tej sesji
```

- Domyślnie Docker wymaga `sudo` bo działa jako `root`

- Jeżeli chcemy uruchamiać kontenery bez sudo, musimy dodać siebie do grupy `docker`


Odradzam tego w środowisku komercyjnym. Jeśli mamy `sudo` to go używajmy.

---

## Krok 7: Test Dockera

```bash
docker run hello-world
```

---

## Podsumowanie pierwszej części:

Na Debianie najpierw usuwam stare wersje Dockera, żeby uniknąć konfliktów. Potem dodaję wymagane pakiety do obsługi GPG i HTTPS, ściągam oficjalny klucz GPG Dockera i dodaję ich repozytorium, żeby móc zainstalować najnowsze wersje Dockera i jego wtyczek. Po instalacji dodaję użytkownika do grupy docker, żeby pracować bez sudo. Testuję działanie, uruchamiając testowy kontener hello-world. Dzięki temu mam świeżą, bezpieczną instalację Dockera z pełnym wsparciem Compose i Buildx.

---

# Część druga: Budowa prostego stacka: NGINX + Portainer (do zarządzania dockerem przez www)

---

## Krok 1: Utworzenie katalogu na stack

```bash
mkdir ~/docker-stack
cd ~/docker-stack
sudo nano docker-compose.yml
```
W pliku docker-compose.yml

```yml
version: '3'

services:
  nginx:
    image: nginx
    ports:
      - "8080:80"
    restart: always

  portainer:
    image: portainer/portainer-ce
    ports:
      - "9443:9443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    restart: always

volumes:
  portainer_data:
```

![Screenshot 1: docker-composes.yml](/screenshots/docker-basics/Screenshot%20From%202025-05-08%2014-50-06.webp)

---

## Krok 2: Uruchomienie stacka

```bash
docker compose up -d
```

![Screenshot 2: compose up -d](/screenshots/docker-basics/Screenshot%20From%202025-05-08%2014-49-49.webp)

---

## Krok 3: Sparwdzenie działających kontenerów

```bash
docker ps
```
- NGINX działa na http://server-ip:8080
- Portainer działa na https://server-ip:9443 (to graficzny panel Dockera, rejestrujesz admina przy pierwszym logowaniu)

Warto tutaj dodać, że pomimo zablokowanego portu `9443` portainer i tak będzie dostępny ponieważ docker mapuje porty przed firewallem naszego OS'a.

- UFW działa na poziomie tzw. ***INPUT** chain.
- Docker dodaje swoje własne reguły w **DOCKER** chain i robi tzw. `-A PREROUTING -p tcp --dport 9443 -j DNAT` - czyli ruch idzie do kontenera obok zwykłego firewalla.

Czy to jest bezpieczne?

- Nie do końca dlatego warto:
    - Ręcznie ograniczyć, żeby Docker mapował tylko na localhost, np tak:
    ```yml
    ports:
        - "127.0.0.1:9443:9443"
    ```
    To sprawi, że Portainer będzie dostępny tylko lokalnie (czyli np. z localhost, ale nie z internetu)

![Screenshot 3: portainer z hosta](/screenshots/docker-basics/Screenshot%20From%202025-05-08%2014-49-14.webp)

#### Więcej informacji w `docker-hardening.md`






