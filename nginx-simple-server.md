# Stawianie prostego serwera nginx i host własnej srony na LAN

## Cel projektu

Zdobycie umiejętności uruchomienia pierwszej usługi w moim środowisku labowym.\
W poprzednich dniach skonfigurowałem już `ufw` na przyszłość gdzie otwarłem porty `80` oraz `443` HTTP i HTTPS(To w przyszłości tylko muszę wykupić domenę).\

Dziś:
- Pobiorę i skonfiguruję nginx
- Przeniosę szablon strony internetowej, który stworzyłem już jakiś czas temu.
- Pokażę, że to działa

---

## Krok 1: Instalacja potrzebnych pakietów

Instaluję `nginx`, który będzie odpowiadał za serwowanie mojej strony, `unzip` ponieważ przenoszę skompresowany folder poprzez `scp` oraz `curl` by pokazać, że wszystko działa jak należy.

```bash
sudo apt install nginx unzip curl
```

---

## Krok 2: Konfiguracja nginx

W moim przypadku porty `80` oraz `443` były już zajęte przez działający `apache2`.\
Sprawdziłem to tak:

```bash
sudo ss -tulnp | grep -E ':80|:443'
```
gdzie:
- `ss` to narzędzie do wyświetlania aktywnych połączeń sieciowych i gniazd (socketów). Jest szybsze i nowsze niż stare netstat
- `tulnp`:
    - `t` - TCP
    - `u` - UDP
    - `l` - LISTEN (Nasłuchujące porty)
    - `n` - pokaż numery portów, a nie nazwy
    - `p` - pokaż PID i nazwę programu (`sudo` jest do tego niezbędne)
- `grep -E ':80|:443'` - filtruje wyniki, żeby zobaczyć tylko porty 80(HTTP) i 443(HTTPS)

Dezaktywowałem serwer apache komendą:

```bash
sudo systemctl stop apache2
sudo systemctl disable apache2
```

Następnie aktywowałem serwer nginx komendą:

```bash
sudo systemctl enable nginx
sudo systemctl start nginx
```

I sprawdziłem czy działa na tych portach co wcześniej apache

```bash
sudo ss -tulnp | grep -E ':80|:443`
```

![Screenshot 1: Zatrzymanie apache i uruchomienie nginx](/screenshots/nginx-simple-server/Screenshot%20From%202025-05-02%2011-38-47.webp)

---

## Krok 3: Przeniesienie szablonu strony z hosta na vm:

Wykorzystam do tego `scp` Secure copy jako, że firewall puszcza mi ruch poprzez port 2222, a nie mam czasu go przekonfigurowywać i stawiać FTP ani bawić się w wymianę kluczy z githubem.

```bash
scp -P 2222 BusinessCard-main.zip adminuser@192.168.88.227:/home/adminuser
```

alternatywnie mógłbym tutaj użyć `rsync`:

```bash
rsync -avz -e "ssh -p 2222" BusinessCard-main.zip adminuser@192.168.88.227:/home/adminuser/
```

rsync daje więcej możliwości ale w tym przypadku użyłem scp.\
Następnie użyłem komendy by rozpakować plik .zip:

```bash
unzip /home/adminuser/BusinessCard-main.zip
```

I przeniosłem wszystkie pliki z folderu do folderu dla serwerów www:

```bash
sudo rm -rf /var/www/html/*
sudo cp -r /home/adminuser/BusinessCard-main/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html/
```

Wytłumaczenie:
1. Na początku usuwam komendą rm wszystkie pliki oraz foldery rekurencyjnie z folderu do którego zagląda nginx (apache2 też).
2. Następnie kopiuję wszystkie pliki z folderu mojej strony do tego folderu.
3. Na koniec używam chown -R (rekurencja) czyli zmieniam właściciela i grupę `www-data:www-data` dla wszystkich plików i podkatalogów w folderze. Robię to by strona nie wywalała błędów.

---

## Krok 4: Wchodzę na przeglądarkę na swoim hoście i wpisuję adres IP naszego VM'a:

![Screenshot 1: Zatrzymanie apache i uruchomienie nginx](/screenshots/nginx-simple-server/Screenshot%20From%202025-05-02%2012-06-39.webp)

Na dole zdjęcia widać adres naszego VM'a: `192.168.88.227` oraz wersję serwera: `nginx/1.22.1`.

---

## Podsumowanie

Jak widać w kilku prostych krokach można postawić działający serwer hostujący prostą stronę internetową. W kolejnych projektach chciałbym skupić się na lepszym zabezpieczeniu takiej strony poprzez przejście na HTTPS oraz konfigurację Fail2Ban czy zmianę portu.


